# claude-status-lite

A lightweight statusline for Claude Code. Pure bash + jq, no Node.js required.

```
Context 15% | 5h: 29% (1h23m) | 7d: 32% (1d)
```

Shows three metrics:
- **Context** — context window usage
- **5h** — 5-hour rate limit usage and time until reset
- **7d** — 7-day rate limit usage and time until reset

Percentage numbers are colored by severity: green (<70%), yellow (70–85%), red (>85%).

## Install

Add to your `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-status-lite": {
      "source": {
        "source": "github",
        "repo": "fangfangfang/claude-status-lite"
      }
    }
  },
  "enabledPlugins": {
    "claude-status-lite@claude-status-lite": true
  }
}
```

Then run `/setup` in Claude Code to configure the statusline.

## Requirements

- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) or `apt install jq` (Linux)

## License

MIT
