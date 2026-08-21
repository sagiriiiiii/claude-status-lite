#!/bin/bash
# claude-status-lite installer/uninstaller
set -e

INSTALL_DIR="$HOME/.claude/claude-status-lite"
SETTINGS_FILE="$HOME/.claude/settings.json"
REPO_URL="https://raw.githubusercontent.com/sagiriiiiii/claude-status-lite/main"
STATUSLINE_CMD="bash ~/.claude/claude-status-lite/statusline.sh"
CONFIG_FILE="$INSTALL_DIR/config.json"

# Parse args: --uninstall | --stocks sh000001,sz399006
STOCKS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) UNINSTALL=1 ;;
    --stocks) STOCKS="$2"; shift ;;
    --stocks=*) STOCKS="${1#--stocks=}" ;;
    *) echo "Unknown option: $1"; echo "Usage: install.sh [--uninstall] [--stocks sh000001,sz399006]"; exit 1 ;;
  esac
  shift
done

# Check jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it first:"
  echo "  macOS:  brew install jq"
  echo "  Linux:  apt install jq"
  exit 1
fi

# Uninstall
if [ "${UNINSTALL:-}" = "1" ]; then
  # Restore backup if exists
  if [ -f "$INSTALL_DIR/statusline.backup.json" ]; then
    backup=$(cat "$INSTALL_DIR/statusline.backup.json")
    jq --argjson sl "$backup" '.statusLine = $sl' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "Restored previous statusLine from backup."
  elif [ -f "$SETTINGS_FILE" ]; then
    jq 'del(.statusLine)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  fi
  rm -rf "$INSTALL_DIR"
  echo "Uninstalled. Restart Claude Code to apply."
  exit 0
fi

# Install
mkdir -p "$INSTALL_DIR"
echo "Downloading statusline.sh..."
curl -fsSL "$REPO_URL/statusline.sh" -o "$INSTALL_DIR/statusline.sh"
chmod +x "$INSTALL_DIR/statusline.sh"

# Configure settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Backup existing statusLine if any
if jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null; then
  echo "Backing up existing statusLine to $INSTALL_DIR/statusline.backup.json"
  jq '.statusLine' "$SETTINGS_FILE" > "$INSTALL_DIR/statusline.backup.json"
fi

# Write statusLine config. With stocks, add refreshInterval so quotes keep ticking while the session is idle
# (Claude Code otherwise only re-runs the statusline on conversation events).
if [ -n "$STOCKS" ]; then
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd, "refreshInterval": 2}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
else
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
fi
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# Optional stock watch: write/merge stocks into config.json
if [ -n "$STOCKS" ]; then
  [ -f "$CONFIG_FILE" ] || echo '{}' > "$CONFIG_FILE"
  jq --arg s "$STOCKS" '.stocks = ($s | split(",") | map(select(length > 0)))' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
  mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  echo "Stock watch enabled: $STOCKS (edit $CONFIG_FILE to tweak)"
fi

echo "Done! Restart Claude Code to see the statusline."
