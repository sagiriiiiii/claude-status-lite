# claude-status-lite

A lightweight statusline for Claude Code. Pure bash + jq, no Node.js required.

![preview](https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/preview.png?t=20260407)

Shows three metrics:
- **Context** — context window usage
- **5h** — 5-hour rate limit usage and time until reset
- **7d** — 7-day rate limit usage and time until reset

Percentage numbers are colored by severity: green (<70%), yellow (70–85%), red (>85%).

## Install

Inside a Claude Code instance, run:

**Step 1:** Add the marketplace

```
/plugin marketplace add sagiriiiiii/claude-status-lite
```

**Step 2:** Install the plugin

```
/plugin install claude-status-lite
```

Then restart Claude Code.

**Step 3:** Configure the statusline

```
/claude-status-lite:setup
```

## Manual Install

If you prefer not to use the plugin system:

**Step 1:** Download the script

```bash
mkdir -p ~/.claude/claude-status-lite
curl -o ~/.claude/claude-status-lite/statusline.sh https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main/statusline.sh
```

**Step 2:** Add to `~/.claude/settings.json`

```jsonc
{
  // ... other settings
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/claude-status-lite/statusline.sh"
  }
}
```

Then restart Claude Code.

## Requirements

- [jq](https://jqlang.github.io/jq/) — `brew install jq` (macOS) or `apt install jq` (Linux)

## License

MIT
