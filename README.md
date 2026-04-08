# claude-status-lite

A lightweight statusline for Claude Code. Pure bash + jq, no Node.js required.

![preview](https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/preview.png?t=20260407)

Shows three metrics:
- **Context** — context window usage
- **5h** — 5-hour rate limit usage and time until reset
- **7d** — 7-day rate limit usage and time until reset

Percentage numbers are colored by severity: green (<70%), yellow (70–85%), red (>85%).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/install.sh | bash
```

Then restart Claude Code.

## Requirements

- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) or `apt install jq` (Linux)

## License

MIT
