#!/usr/bin/env python3
"""
English Grammar and Typo Checker for Claude Code.
Triggered by UserPromptSubmit hook, runs in background (non-blocking).
Writes correction tip to ~/.claude/english-tip-latest.txt
"""

import json
import os
import sys


def load_env():
    """Load API key from .env file"""
    env_file = os.path.expanduser("~/.claude/scripts/.env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, _, value = line.partition("=")
                    os.environ[key.strip()] = value.strip()


def is_mostly_english(text):
    """Return True only if English letters make up >= 50% of all alphabetic characters"""
    english_chars = sum(1 for c in text if c.isalpha() and ord(c) < 128)
    total_alpha   = sum(1 for c in text if c.isalpha())
    if total_alpha == 0:
        return False
    return (english_chars / total_alpha) >= 0.5


def check_grammar(prompt_text, api_key):
    """Call Haiku 4.5 to check grammar and typos"""
    from anthropic import Anthropic

    client = Anthropic(api_key=api_key)
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=256,
        system=(
            "You are a concise English writing coach for non-native speakers. "
            "Only check English text. Ignore code, URLs, and technical terms. "
            "If the text sounds natural and correct, respond with exactly: LGTM\n"
            "If the text has errors OR sounds unnatural/non-native, suggest improvements. "
            "Respond with only the key fixes, one per line, in format: awkward → natural\n"
            "No explanations. No parentheses. Just the fix.\n"
            "Prioritize how native speakers actually express ideas over strict grammar rules. "
            "Be minimal. Max 2 suggestions."
        ),
        messages=[{"role": "user", "content": prompt_text}],
    )
    return response.content[0].text.strip()


def write_tip(content):
    """Write correction tip to file for statusline to read"""
    tip_file = os.path.expanduser("~/.claude/english-tip-latest.txt")
    with open(tip_file, "w") as f:
        f.write(content)


def main():
    load_env()

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        sys.exit(0)

    # Read hook payload from stdin
    try:
        raw = sys.stdin.read()
        data = json.loads(raw)
        prompt_text = data.get("prompt", "")
    except Exception:
        sys.exit(0)

    if not prompt_text or not is_mostly_english(prompt_text):
        write_tip("")  # Clear stale tip when prompt is not English-dominant
        sys.exit(0)

    # Fork to background — parent exits immediately so the hook doesn't block
    pid = os.fork()
    if pid > 0:
        sys.exit(0)  # Parent returns control to Claude Code right away

    # Child process: detach from session and do the API call silently
    os.setsid()
    sys.stdin.close()

    try:
        result = check_grammar(prompt_text, api_key)
        write_tip(result)
    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
