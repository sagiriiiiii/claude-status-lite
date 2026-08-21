# claude-status-lite

A lightweight statusline for Claude Code that shows your **usage limits** — and lets you **watch the stock market** in the same line. Pure bash + jq, no Node.js required.

```
Context 42% | 5h: 12% (1h30m) | 7d: 77% (2d7h) | 上证指数 3908.74 ↗0.13% | 腾讯控股 447.80 ↘-0.80%
```

![preview](https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/preview.png?t=20260407)

## Features

**Claude usage at a glance**
- **Context** — context window usage
- **5h** / **7d** — rate limit usage and time until reset
- Percentages colored by severity: green (<70%), yellow (70–85%), red (>85%)

**📈 Stock watch, right in your terminal**
- A-share (stocks / ETFs / indexes), HK and US quotes, refreshed every **2 seconds** while you code
- **Stealth mode** for the office: show pinyin initials instead of names (`上证指数` → `sz`), numbers only, or custom aliases — it just looks like another metric
- Red-up / green-down coloring (off by default), optional change value, second-line layout
- Auto slows down outside trading hours, can hide itself after the close
- Zero impact on Claude Code: quotes are fetched in a detached background process and cached, the statusline itself stays instant

> 在 Claude Code 状态栏里摸鱼看盘：支持 A 股 / 港股 / 美股，2 秒刷新，拼音首字母隐身模式（`上证指数` → `sz`），不配股票时就是一个纯粹的额度状态栏。

## Install

Usage metrics only:

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash
```

With stock watch (pass the codes you want to follow):

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash -s -- --stocks sh000001,sz399006,hk00700
```

Then restart Claude Code.

## Stock watch

### Display modes

| `stock_name` | What you see | Use it when |
| --- | --- | --- |
| `full` | `上证指数 3908.74 ↗0.13%` | You don't care who's looking |
| `mini` | `上证 3908.74 ↗0.13%` | Save some width |
| `pinyin` | `sz 3908.74 ↗0.13%` | **Stealth** — looks like any other two-letter metric |
| `hidden` | `3908.74 ↗0.13%` | Maximum stealth, you know which is which |

Aliases (`stock_aliases`) override all of the above, e.g. `{"sh601318": "平安"}` or even `{"sh000001": "cpu"}`.

### Configuration

`~/.claude/claude-status-lite/config.json` (created by `--stocks`, or write it by hand):

```json
{
  "stocks": ["sh000001", "sz399006", "hk00700", "usAAPL"],
  "stock_aliases": { "sh000001": "大盘" },
  "stock_name": "pinyin",
  "stock_name_len": 2,
  "stock_show_change": false,
  "stock_colorful": false,
  "stock_interval": 2,
  "stock_interval_closed": 600,
  "stock_hide_closed": false,
  "stock_newline": false
}
```

| Key | Default | Description |
| --- | --- | --- |
| `stocks` | `[]` | Codes to watch. A-share `sh600519` / `sz000001` / `bj899050` (stocks, ETFs, indexes), HK `hk00700`, US `usAAPL`. Empty = feature off. |
| `stock_aliases` | `{}` | Custom short names per code; always win over `stock_name`. |
| `stock_name` | `"full"` | `full` · `mini` first N chars · `pinyin` first N pinyin initials (looked up once via Tencent search, cached) · `hidden` numbers only. |
| `stock_name_len` | `2` | How many chars/initials `mini` and `pinyin` keep. |
| `stock_show_change` | `false` | Append the change value, e.g. `↗0.13%(5.02)`. |
| `stock_colorful` | `false` | Color quotes A-share style: red up, green down. Off by default to stay low-key. |
| `stock_interval` | `2` | Quote refresh interval in seconds during A-share trading sessions (min 1). |
| `stock_interval_closed` | `600` | Refresh interval outside trading sessions. |
| `stock_hide_closed` | `false` | Hide the stock segment outside market hours (weekdays 09:15–15:00 Asia/Shanghai). |
| `stock_newline` | `false` | Put stocks on a second line instead of appending to the first. |

### How it works

- Quotes come from Tencent's public finance API (`qt.gtimg.cn`), the same source used by popular "watch stock" editor extensions. No key required.
- Claude Code only re-runs the statusline on conversation events, so to keep quotes ticking while you're idle the installer sets `statusLine.refreshInterval: 2` in `~/.claude/settings.json` when `--stocks` is used. If you configured stocks by hand, add that field yourself (minimum `1`).
- Fetching runs in a detached background process and is cached on disk (`.stock_cache`), so the statusline script itself returns in milliseconds and never blocks Claude Code.
- Pinyin initials are resolved once per code (`.stock_pinyin`) and fall back to `mini` when a code isn't found.
- Config path can be overridden with the `CLAUDE_STATUS_LITE_CONFIG` env var.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash -s -- --uninstall
```

If you had a previous statusline, it restores from backup. Otherwise it removes the config and cleans up.

## Requirements

- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) or `apt install jq` (Linux)
- `curl` — only needed for stock watch

## License

MIT
