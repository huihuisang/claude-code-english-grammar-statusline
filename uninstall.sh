#!/bin/bash
set -e

SCRIPT_DIR="$HOME/.claude/scripts"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Uninstalling Claude Code English Grammar Statusline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Remove scripts and data files
echo "🗑️  Removing scripts..."
rm -f "$SCRIPT_DIR/english-coach.py"
rm -f "$SCRIPT_DIR/statusline-command.sh"
rm -f "$SCRIPT_DIR/statusline.sh"   # legacy name
rm -f "$SCRIPT_DIR/.env"
rm -f "$HOME/.claude/english-tip-latest.txt"
echo "   Done."

# Clean settings.json
if [ -f "$SETTINGS_FILE" ]; then
    echo "⚙️  Cleaning settings.json..."

    python3 << 'PYEOF'
import json, os, re

settings_file = os.path.expanduser("~/.claude/settings.json")
script_dir    = os.path.expanduser("~/.claude/scripts")

with open(settings_file, "r") as f:
    settings = json.load(f)

# ── Remove legacy lowercase "statusline" key ─────────────────────────────────
if "statusline" in settings:
    del settings["statusline"]
    print("   Removed legacy 'statusline' key.")

# ── Remove statusLine if it points to our statusline-command.sh ──────────────
existing = settings.get("statusLine")
our_script = os.path.join(script_dir, "statusline-command.sh")
removed_statusline = False

if isinstance(existing, dict):
    cmd = existing.get("command", "")
    if our_script in cmd:
        del settings["statusLine"]
        print("   Removed statusLine entry (was pointing to our script).")
        removed_statusline = True
elif isinstance(existing, str) and existing == our_script:
    del settings["statusLine"]
    print("   Removed statusLine entry.")
    removed_statusline = True

if not removed_statusline:
    # User had their own statusLine — remove injected tip block from their script
    script_path = None
    if isinstance(existing, dict):
        cmd = existing.get("command", "")
        m = re.match(r'(?:sh|bash)\s+(.+\.sh)', cmd.strip())
        if m:
            script_path = m.group(1).strip()
    elif isinstance(existing, str):
        script_path = existing

    MARKER_START = "# --- [english-coach-start]"
    MARKER_END   = "# --- [english-coach-end] ---"

    if script_path and os.path.isfile(script_path):
        with open(script_path, "r") as f:
            content = f.read()

        if MARKER_START in content:
            # Strip everything between (and including) the markers
            cleaned = re.sub(
                rf'\n?{re.escape(MARKER_START)}.*?{re.escape(MARKER_END)}\n?',
                "",
                content,
                flags=re.DOTALL
            )
            with open(script_path, "w") as f:
                f.write(cleaned)
            print(f"   Removed tip logic from {script_path}")
        else:
            print(f"   No injected tip logic found in {script_path}, skipping.")

# ── Remove our hook from UserPromptSubmit ────────────────────────────────────
hook_command = f"python3 {script_dir}/english-coach.py"
if "hooks" in settings and "UserPromptSubmit" in settings["hooks"]:
    before = len(settings["hooks"]["UserPromptSubmit"])
    settings["hooks"]["UserPromptSubmit"] = [
        group for group in settings["hooks"]["UserPromptSubmit"]
        if not any(h.get("command") == hook_command for h in group.get("hooks", []))
    ]
    after = len(settings["hooks"]["UserPromptSubmit"])
    if before != after:
        print("   Removed hook entry.")

    # Clean up empty keys
    if not settings["hooks"]["UserPromptSubmit"]:
        del settings["hooks"]["UserPromptSubmit"]
    if not settings["hooks"]:
        del settings["hooks"]

with open(settings_file, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("   settings.json updated.")
PYEOF
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Uninstall complete!"
echo "   Restart Claude Code to apply changes."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
