#!/bin/bash
set -euo pipefail

# Answer Codex's first-run "trust this folder" prompt in a pane, but only when the prompt names
# exactly the repository the task is in. Any other folder is left for the user.
# Waits up to 30 seconds; exits quietly when no prompt appears.
# Usage: accept-trust.sh SESSION BLOCK ABS_REPO_PATH

session=$1
block=$2
repo=$3
ready=0

for _ in $(seq 1 30); do
  text=$(rex capture -s "$session" -b "$block" --trim --unwrap 2>/dev/null) || true
  if grep -q "1. Trust and continue" <<<"$text"; then
    pattern=$(sed 's/[][\.*^$/]/\\&/g' <<<"$repo")
    if ! grep -qxE "[[:space:]]*$pattern/?[[:space:]]*" <<<"$text"; then
      echo "codex: the trust prompt is not for $repo; left for the user" >&2
      exit 1
    fi
    rex send-key -s "$session" -b "$block" Enter
    echo "codex: trusted the folder"
    exit 0
  fi
  # Codex can show its main screen for a moment before the prompt, so wait for it to settle.
  if grep -qE "GPT-|Ask Codex|esc to interrupt|Worked for" <<<"$text"; then
    ready=$((ready + 1))
    if [ "$ready" -ge 3 ]; then
      echo "codex: no trust prompt"
      exit 0
    fi
  else
    ready=0
  fi
  sleep 1
done
echo "codex: no trust prompt seen within 30s; check the pane" >&2
exit 1
