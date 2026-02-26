#!/bin/bash
# English Grammar Tip Statusline for Claude Code
# Reads the latest correction from file and displays it in the statusline

# Consume stdin (required by Claude Code statusline protocol)
input=$(cat)

# Load prefix from .env (default: ✍️)
ENV_FILE="$HOME/.claude/scripts/.env"
PREFIX="✍️"
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r key value; do
        [ "$key" = "ENGLISH_COACH_PREFIX" ] && PREFIX="$value"
    done < "$ENV_FILE"
fi

TIP_FILE="$HOME/.claude/english-tip-latest.txt"

[ -f "$TIP_FILE" ] || exit 0

content=$(cat "$TIP_FILE")

# Only display if there's an actual correction (not LGTM, not empty)
if [ -n "$content" ] && [ "$content" != "LGTM" ]; then
    echo "$PREFIX  $content"
fi
