#!/bin/bash
# claude-status-lite: Lightweight statusline for Claude Code
# Shows: Context % | 5h rate limit | 7d rate limit
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

# Join with separator
result=""
for i in "${!parts[@]}"; do
  [ "$i" -gt 0 ] && result+=" | "
  result+="${parts[$i]}"
done
echo -e "$result"
