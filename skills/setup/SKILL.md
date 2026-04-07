---
name: setup
description: Configure claude-status-lite as your Claude Code statusline
---

# claude-status-lite Setup

Configure the lightweight statusline for the user.

## Steps

1. Check that `jq` is installed by running `which jq`. If not found, tell the user to install it (`brew install jq` on macOS, `apt install jq` on Linux).

2. Read the user's `~/.claude/settings.json`.

3. Set the `statusLine` field to:

```json
{
  "type": "command",
  "command": "bash -c 'dir=$(ls -d \"${CLAUDE_CONFIG_DIR:-$HOME/.claude}\"/plugins/cache/claude-status-lite/claude-status-lite/*/ 2>/dev/null | sort -t. -k1,1n -k2,2n -k3,3n | tail -1); bash \"${dir}statusline.sh\"'"
}
```

4. Confirm to the user that setup is complete. The statusline will appear on the next message showing:

```
Context 15% | 5h: 29% (1h23m) | 7d: 32% (1d)
```

- Percentage numbers are colored: green (<70%), yellow (70-85%), red (>85%)
- Other text uses default terminal color
