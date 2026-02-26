#!/bin/bash
set -e

SCRIPT_DIR="$HOME/.claude/scripts"
SETTINGS_FILE="$HOME/.claude/settings.json"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code English Grammar Statusline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Python3
if ! command -v python3 &>/dev/null; then
    echo "❌ Python3 is required but not found. Please install it first."
    exit 1
fi

# Install anthropic package
echo "📦 Installing anthropic package..."
pip3 install anthropic --quiet
echo "   Done."

# Create scripts directory
mkdir -p "$SCRIPT_DIR"

# Load existing config if present
existing_api_key=""
existing_prefix=""
if [ -f "$SCRIPT_DIR/.env" ]; then
    while IFS='=' read -r key value; do
        [ "$key" = "ANTHROPIC_API_KEY" ]     && existing_api_key="$value"
        [ "$key" = "ENGLISH_COACH_PREFIX" ]  && existing_prefix="$value"
    done < "$SCRIPT_DIR/.env"
fi

# Ask for API key (skip if already set)
if [ -n "$existing_api_key" ]; then
    echo "🔑 API key already set, skipping. (Edit $SCRIPT_DIR/.env to change it)"
    api_key="$existing_api_key"
else
    echo ""
    echo "🔑 Enter your Anthropic API key (from https://console.anthropic.com):"
    read -r -s api_key
    echo ""
    # Strip control characters that may be injected by terminal paste
    api_key=$(echo "$api_key" | tr -d '[:cntrl:]')
    if [ -z "$api_key" ]; then
        echo "❌ API key cannot be empty."
        exit 1
    fi
fi

# Ask for statusline prefix (skip if already set)
if [ -n "$existing_prefix" ]; then
    echo "✏️  Prefix already set to: $existing_prefix (press Enter to keep, or type a new one):"
    read -r prefix
    prefix="${prefix:-$existing_prefix}"
else
    echo "✏️  Statusline prefix emoji (press Enter for default ✍️ ):"
    read -r prefix
    prefix="${prefix:-✍️}"
fi

# Save config securely
{
  echo "ANTHROPIC_API_KEY=$api_key"
  echo "ENGLISH_COACH_PREFIX=$prefix"
} > "$SCRIPT_DIR/.env"
chmod 600 "$SCRIPT_DIR/.env"
echo "🔒 Config saved to $SCRIPT_DIR/.env (chmod 600)"

# Copy the grammar checker script
echo ""
echo "📋 Copying scripts..."
cp "$REPO_DIR/scripts/english-coach.py" "$SCRIPT_DIR/"
chmod +x "$SCRIPT_DIR/english-coach.py"
echo "   Done."

# Backup settings.json
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
    echo "💾 Backed up settings.json → settings.json.bak"
fi

# Merge hook + statusline into settings.json using Python
echo ""
echo "⚙️  Updating settings.json..."

python3 << PYEOF
import json, os, re, sys

settings_file = os.path.expanduser("~/.claude/settings.json")
script_dir    = os.path.expanduser("~/.claude/scripts")
repo_dir      = "$REPO_DIR"

# Load existing settings or start fresh
if os.path.exists(settings_file):
    with open(settings_file, "r") as f:
        settings = json.load(f)
else:
    settings = {}

# ── Clean up legacy lowercase "statusline" key (old format) ──────────────────
if "statusline" in settings:
    del settings["statusline"]
    print("   Removed legacy 'statusline' key.")

# ── statusLine: check if user already has one ────────────────────────────────
existing = settings.get("statusLine")

if existing is None:
    # No existing statusLine → install our standalone statusline-command.sh
    target = os.path.join(script_dir, "statusline-command.sh")
    import shutil
    shutil.copy(os.path.join(repo_dir, "scripts", "statusline-command.sh"), target)
    os.chmod(target, 0o755)
    settings["statusLine"] = {"type": "command", "command": f"sh {target}"}
    print(f"   Installed statusline-command.sh → {target}")
    print("   Set statusLine to new command format.")
else:
    # User already has a statusLine → try to inject tip logic into their script
    script_path = None

    if isinstance(existing, str):
        # Old string format: the value is the path directly
        script_path = existing
    elif isinstance(existing, dict):
        cmd = existing.get("command", "")
        # Extract path from commands like "sh /path/to/script.sh"
        m = re.match(r'(?:sh|bash)\s+(.+\.sh)', cmd.strip())
        if m:
            script_path = m.group(1).strip()

    MARKER_START = "# --- [english-coach-start]"
    MARKER_END   = "# --- [english-coach-end]"

    tip_block = r"""
# --- [english-coach-start] English grammar tip (injected by english-coach installer) ---
_EC_TIP_FILE="\$HOME/.claude/english-tip-latest.txt"
if [ -f "\$_EC_TIP_FILE" ]; then
  _ec_tip=\$(cat "\$_EC_TIP_FILE")
  if [ -n "\$_ec_tip" ] && [ "\$_ec_tip" != "LGTM" ]; then
    _EC_YELLOW=\$'\033[93m'
    _EC_RESET=\$'\033[0m'
    _EC_PREFIX="✍️"
    _EC_ENV="\$HOME/.claude/scripts/.env"
    if [ -f "\$_EC_ENV" ]; then
      while IFS='=' read -r _ec_key _ec_val; do
        [ "\$_ec_key" = "ENGLISH_COACH_PREFIX" ] && _EC_PREFIX="\$_ec_val"
      done < "\$_EC_ENV"
    fi
    printf " %s%s  %s%s" "\$_EC_YELLOW" "\$_EC_PREFIX" "\$_ec_tip" "\$_EC_RESET"
  fi
fi
# --- [english-coach-end] ---
"""

    if script_path and os.path.isfile(script_path):
        with open(script_path, "r") as f:
            content = f.read()

        if MARKER_START in content:
            print(f"   Tip logic already injected in {script_path}, skipping.")
        else:
            with open(script_path, "a") as f:
                f.write(tip_block)
            print(f"   ✅ Injected tip logic into your existing statusline: {script_path}")
    else:
        print(f"   ⚠️  Could not locate your statusLine script at: {script_path}")
        print("   Tip logic was NOT injected. Add it manually or re-check your statusLine path.")

# ── Hook: add UserPromptSubmit entry (idempotent) ────────────────────────────
hook_command = f"python3 {script_dir}/english-coach.py"
new_hook_group = {"hooks": [{"type": "command", "command": hook_command}]}

hooks = settings.setdefault("hooks", {})
submit_hooks = hooks.setdefault("UserPromptSubmit", [])

already_exists = any(
    h.get("command") == hook_command
    for group in submit_hooks
    for h in group.get("hooks", [])
)

if not already_exists:
    submit_hooks.append(new_hook_group)
    print("   Hook added.")
else:
    print("   Hook already exists, skipping.")

# Write back
with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("   settings.json updated.")
PYEOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation complete!"
echo ""
echo "   Restart Claude Code to apply changes."
echo "   Grammar tips will appear in the statusline"
echo "   after each message you type in English."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
