# claude-status-lite

A lightweight statusline for Claude Code. Pure bash + jq, no Node.js required.

![preview](https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/preview.png?t=20260407)

Shows three metrics:
- **Context** — context window usage
- **5h** — 5-hour rate limit usage and time until reset
- **7d** — 7-day rate limit usage and time until reset

Percentage numbers are colored by severity: green (<70%), yellow (70–85%), red (>85%).

Optionally, it can also show **stock quotes** right in the statusline (A-share / HK / US), so you can keep an eye on the market without leaving the terminal:

```
Context 42% | 5h: 12% (1h30m) | 7d: 77% (2d7h) | 上证指数 3908.74 ↗0.13% | 腾讯控股 447.80 ↘-0.80%
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash
```

Then restart Claude Code.

## Stock watch (optional)

Enable it at install time:

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash -s -- --stocks sh000001,sz399006,hk00700
```

Or create/edit `~/.claude/claude-status-lite/config.json` by hand:

```json
{
  "stocks": ["sh000001", "sz399006", "hk00700", "usAAPL"],
  "stock_aliases": { "sh000001": "大盘" },
  "stock_name": "full",
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
| `stock_aliases` | `{}` | Custom short names, e.g. `{"sh601318": "平安"}`. |
| `stock_name` | `"full"` | `full` real name · `mini` first N chars (`上证`) · `pinyin` first N pinyin initials (`sz`, looked up once via Tencent search and cached) · `hidden` numbers only. |
| `stock_name_len` | `2` | How many chars/initials `mini` and `pinyin` keep. |
| `stock_show_change` | `false` | Append the change value, e.g. `↗0.13%(5.02)`. |
| `stock_colorful` | `false` | Color quotes A-share style: red up, green down. Off by default to stay low-key. |
| `stock_interval` | `2` | Quote refresh interval in seconds during A-share trading sessions (min 1). |
| `stock_interval_closed` | `600` | Refresh interval outside trading sessions. |
| `stock_hide_closed` | `false` | Hide the stock segment outside market hours (weekdays 09:15–15:00 Asia/Shanghai). |
| `stock_newline` | `false` | Put stocks on a second line instead of appending to the first. |

Notes:
- Claude Code only re-runs the statusline on conversation events, so to keep quotes ticking while you're idle the installer sets `statusLine.refreshInterval: 2` in `~/.claude/settings.json` when `--stocks` is used. If you configured stocks by hand, add that field yourself (minimum `1`).
- Quotes come from Tencent's public finance API (`qt.gtimg.cn`), the same source used by popular "watch stock" editor extensions. No key required.
- Fetching runs in a detached background process and is cached on disk, so the statusline itself stays instant and never blocks Claude Code.
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
