#!/bin/bash
set -uo pipefail

# Type one line into a Codex pane and submit it, once Codex has finished its current turn.
# Waits up to two minutes for Codex to be idle and sends nothing if it stays busy.
# Usage: ask.sh SESSION BLOCK "MESSAGE"

session=$1
block=$2
message=$3

for _ in $(seq 1 60); do
  text=$(rex capture -s "$session" -b "$block" --trim 2>/dev/null | tail -12)
  if grep -q "^›" <<<"$text" && ! grep -q "esc to interrupt" <<<"$text"; then
    rex send -s "$session" -b "$block" "$message"
    sleep 1
    rex send-key -s "$session" -b "$block" Enter
    echo "codex: sent"
    exit 0
  fi
  sleep 2
done
echo "codex: still busy after two minutes; nothing sent" >&2
exit 1
