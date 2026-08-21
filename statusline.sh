#!/bin/bash
# claude-status-lite: Lightweight statusline for Claude Code
# Shows: Context % | 5h rate limit | 7d rate limit | (optional) stock quotes
# Reads JSON from stdin provided by Claude Code

input=$(cat)

ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Format remaining time from unix timestamp
fmt_remaining() {
  local reset_at="$1"
  [ -z "$reset_at" ] && return
  local now=$(date +%s)
  local diff=$(( reset_at - now ))
  [ "$diff" -le 0 ] && echo "0m" && return
  local days=$(( diff / 86400 ))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    if [ "$hours" -gt 0 ]; then
      echo "${days}d${hours}h"
    else
      echo "${days}d"
    fi
  elif [ "$hours" -gt 0 ]; then
    if [ "$mins" -gt 0 ]; then
      echo "${hours}h${mins}m"
    else
      echo "${hours}h"
    fi
  else
    echo "${mins}m"
  fi
}

# Color only the percentage number
colorize_pct() {
  local pct="$1"
  if [ -z "$pct" ]; then
    echo "${pct}%"
  elif [ "$pct" -ge 85 ]; then
    echo "\x1b[31m${pct}%\x1b[0m"
  elif [ "$pct" -ge 70 ]; then
    echo "\x1b[33m${pct}%\x1b[0m"
  else
    echo "\x1b[32m${pct}%\x1b[0m"
  fi
}

parts=()

# Context
if [ -n "$ctx" ]; then
  ctx_int=${ctx%.*}
  parts+=("Context $(colorize_pct "$ctx_int")")
fi

# 5h usage
if [ -n "$five_pct" ]; then
  five_int=${five_pct%.*}
  remaining=$(fmt_remaining "$five_reset")
  part="5h: $(colorize_pct "$five_int")"
  [ -n "$remaining" ] && part+=" (${remaining})"
  parts+=("$part")
fi

# 7d usage
if [ -n "$seven_pct" ]; then
  seven_int=${seven_pct%.*}
  remaining=$(fmt_remaining "$seven_reset")
  part="7d: $(colorize_pct "$seven_int")"
  [ -n "$remaining" ] && part+=" (${remaining})"
  parts+=("$part")
fi

# ---------------------------------------------------------------------------
# Stock quotes (optional, enabled when config.json has a non-empty "stocks")
# Data source: Tencent finance public quote API (same as watch-stock).
# Fetching runs in the background and is cached, so the statusline never blocks.
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CLAUDE_STATUS_LITE_CONFIG:-$SCRIPT_DIR/config.json}"
CACHE_FILE="$SCRIPT_DIR/.stock_cache"
LOCK_FILE="$SCRIPT_DIR/.stock_lock"
STOCK_API="https://qt.gtimg.cn/utf8/q="

stock_codes=""
stock_name="full"
stock_show_change="false"
stock_colorful="false"
stock_interval=30
stock_interval_closed=600
stock_hide_closed="false"
stock_newline="false"
stock_aliases="{}"

# Load config in a single jq call: codes on line 1, scalar options on line 2, aliases on line 3
load_stock_config() {
  [ -f "$CONFIG_FILE" ] || return 1
  local cfg
  cfg=$(jq -r '
    ((.stocks // [])
      | map(if (.[:2] | ascii_downcase) == "us" then "us" + (.[2:] | ascii_upcase) else ascii_downcase end)
      | map(select(test("^(sh|sz|bj)[0-9]{6}$|^hk[0-9]{5}$|^us[A-Z.]+$"))) | join(",")),
    ([(.stock_name // "full"), (.stock_show_change // false), (.stock_colorful // false),
      (.stock_interval // 30), (.stock_interval_closed // 600), (.stock_hide_closed // false), (.stock_newline // false)] | map(tostring) | join("\t")),
    ((.stock_aliases // {}) | tojson)
  ' "$CONFIG_FILE" 2>/dev/null) || return 1
  stock_codes=$(echo "$cfg" | sed -n 1p)
  IFS=$'\t' read -r stock_name stock_show_change stock_colorful stock_interval stock_interval_closed stock_hide_closed stock_newline \
    <<< "$(echo "$cfg" | sed -n 2p)"
  stock_aliases=$(echo "$cfg" | sed -n 3p)
  case "$stock_interval" in ''|*[!0-9]*) stock_interval=30 ;; esac
  case "$stock_interval_closed" in ''|*[!0-9]*) stock_interval_closed=600 ;; esac
  [ "$stock_interval" -lt 5 ] && stock_interval=5
  [ "$stock_interval_closed" -lt 5 ] && stock_interval_closed=5
  [ -n "$stock_codes" ]
}

# A-share trading session: weekdays 09:15-11:30 / 13:00-15:00 Asia/Shanghai
is_trading_time() {
  local dow hm
  dow=$(TZ=Asia/Shanghai date +%u)
  hm=$(TZ=Asia/Shanghai date +%H%M)
  [ "$dow" -ge 6 ] && return 1
  hm=$((10#$hm))
  { [ "$hm" -ge 915 ] && [ "$hm" -le 1130 ]; } || { [ "$hm" -ge 1300 ] && [ "$hm" -le 1500 ]; }
}

# Market day window used by stock_hide_closed (lunch break included, so the line doesn't flicker at noon)
is_market_hours() {
  local dow hm
  dow=$(TZ=Asia/Shanghai date +%u)
  hm=$(TZ=Asia/Shanghai date +%H%M)
  [ "$dow" -ge 6 ] && return 1
  hm=$((10#$hm))
  [ "$hm" -ge 915 ] && [ "$hm" -le 1500 ]
}

# Seconds since file mtime (portable across GNU/BSD stat)
file_age() {
  local mtime
  mtime=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || { echo 999999; return; }
  echo $(( $(date +%s) - mtime ))
}

# Fetch quotes and rewrite cache as "code<TAB>name<TAB>price<TAB>change<TAB>pct" lines.
# Runs detached in background; only replaces cache on a successful, non-empty response.
fetch_stocks_bg() {
  local query
  query=$(echo "$stock_codes" | sed 's/,/,s_/g; s/^/s_/')
  (
    raw=$(curl -fsS -m 8 -A "Mozilla/5.0" "${STOCK_API}${query}" 2>/dev/null) || exit 0
    parsed=$(echo "$raw" | awk -F'~' '
      /^v_s_/ {
        split($1, h, "_"); code = h[3]
        sub(/=.*/, "", code)
        # Normalize like the config loader: US symbols stay upper-case (the API is case-sensitive), others lower
        if (tolower(substr(code, 1, 2)) == "us") code = "us" toupper(substr(code, 3)); else code = tolower(code)
        if ($4 == "") next
        printf "%s\t%s\t%s\t%s\t%s\n", code, $2, $4, $5, $6
      }')
    [ -n "$parsed" ] || exit 0
    printf '%s\n' "$parsed" > "$CACHE_FILE.tmp" && mv -f "$CACHE_FILE.tmp" "$CACHE_FILE"
    rm -f "$LOCK_FILE"
  ) </dev/null >/dev/null 2>&1 &
}

# Refresh cache when stale. Outside A-share sessions quotes barely move, so fall back to the slower interval.
maybe_refresh_stocks() {
  local ttl="$stock_interval"
  is_trading_time || ttl="$stock_interval_closed"
  [ -f "$CACHE_FILE" ] && [ "$(file_age "$CACHE_FILE")" -lt "$ttl" ] && return
  # Lock prevents a stampede of parallel fetches; a lock older than 20s is considered dead.
  if [ -f "$LOCK_FILE" ] && [ "$(file_age "$LOCK_FILE")" -lt 20 ]; then return; fi
  : > "$LOCK_FILE"
  fetch_stocks_bg
}

# Resolve display name by stock_name mode: full | mini | hidden. Aliases always win when set.
stock_display_name() {
  local code="$1" name="$2" alias
  alias=$(echo "$stock_aliases" | jq -r --arg c "$code" '.[$c] // empty' 2>/dev/null)
  if [ -n "$alias" ]; then
    echo "$alias"
    return
  fi
  case "$stock_name" in
    hidden) ;;
    mini)
      # Truncate to first 2 characters (jq slicing is codepoint-safe, unlike bash 3.2 in a C locale)
      jq -rn --arg n "$name" '$n[:2]'
      ;;
    *) echo "$name" ;;
  esac
}

# Render one stock: "<name> <price> ↗0.13%" with optional change value and A-share colors (red up / green down)
render_stock() {
  local code="$1" name="$2" price="$3" change="$4" pct="$5"
  local disp arrow color="" reset="" text
  disp=$(stock_display_name "$code" "$name")
  case "$change" in
    ""|0|-0|0.0|-0.0|0.00|-0.00|0.000|-0.000) arrow="" ;;
    -*) arrow="↘"; color="\x1b[32m" ;;
    *) arrow="↗"; color="\x1b[31m" ;;
  esac
  text="${price} ${arrow}${pct}%"
  [ "$stock_show_change" = "true" ] && text+="(${change})"
  if [ "$stock_colorful" = "true" ] && [ -n "$color" ]; then
    text="${color}${text}\x1b[0m"
  fi
  [ -n "$disp" ] && text="${disp} ${text}"
  echo "$text"
}

stock_parts=()
if load_stock_config; then
  if [ "$stock_hide_closed" = "true" ] && ! is_market_hours; then
    : # market closed, user asked to hide
  else
    maybe_refresh_stocks
    if [ -f "$CACHE_FILE" ]; then
      # Keep the user's configured order; skip codes missing from cache
      IFS=',' read -ra wanted <<< "$stock_codes"
      for code in "${wanted[@]}"; do
        line=$(grep -m1 "^${code}"$'\t' "$CACHE_FILE") || continue
        IFS=$'\t' read -r c name price change pct <<< "$line"
        stock_parts+=("$(render_stock "$c" "$name" "$price" "$change" "$pct")")
      done
    fi
    [ ${#stock_parts[@]} -eq 0 ] && stock_parts+=("stocks: loading...")
  fi
fi

# Join with separator
join_parts() {
  local out="" i
  for i in "$@"; do
    [ -n "$out" ] && out+=" | "
    out+="$i"
  done
  echo "$out"
}

result=$(join_parts "${parts[@]}")
if [ ${#stock_parts[@]} -gt 0 ]; then
  stock_line=$(join_parts "${stock_parts[@]}")
  if [ "$stock_newline" = "true" ] || [ -z "$result" ]; then
    [ -n "$result" ] && result+="\n"
    result+="$stock_line"
  else
    result+=" | ${stock_line}"
  fi
fi
echo -e "$result"
