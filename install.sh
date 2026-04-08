#!/bin/bash
# claude-status-lite installer
set -e

INSTALL_DIR="$HOME/.claude/claude-status-lite"
SETTINGS_FILE="$HOME/.claude/settings.json"
REPO_URL="https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main"
STATUSLINE_CMD="bash ~/.claude/claude-status-lite/statusline.sh"

# Check jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it first:"
  echo "  macOS:  brew install jq"
  echo "  Linux:  apt install jq"
  exit 1
fi

# Download script
mkdir -p "$INSTALL_DIR"
echo "Downloading statusline.sh..."
curl -fsSL "$REPO_URL/statusline.sh" -o "$INSTALL_DIR/statusline.sh"
chmod +x "$INSTALL_DIR/statusline.sh"

# Configure settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Backup existing statusLine if any
old_statusline=$(jq -r '.statusLine // empty' "$SETTINGS_FILE")
if [ -n "$old_statusline" ]; then
  echo "Backing up existing statusLine to $INSTALL_DIR/statusline.backup.json"
  echo "$old_statusline" > "$INSTALL_DIR/statusline.backup.json"
fi

# Write statusLine config
jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

echo "Done! Restart Claude Code to see the statusline."
