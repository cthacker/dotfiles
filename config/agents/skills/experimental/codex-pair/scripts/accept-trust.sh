#!/bin/bash
set -euo pipefail

# Answer Codex's first-run "trust this folder" prompt in a pane, but only when the prompt names
# exactly the repository the task is in. Any other folder is left for the user.
# Waits up to 30 seconds; exits quietly when Codex starts without a prompt.
# Usage: accept-trust.sh SESSION BLOCK ABS_REPO_PATH

session=$1
block=$2
repo=${3%/}
ready=0

SECONDS=0
while [ "$SECONDS" -lt 30 ]; do
  if ! text=$(rex capture -s "$session" -b "$block" --trim --unwrap); then
    echo "codex: could not read the pane" >&2
    exit 1
  fi
  if grep -q "1. Trust and continue" <<<"$text"; then
    # The prompt shows the folder on a line of its own; compare it as plain text.
    if ! sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s:/$::' <<<"$text" | grep -qxF -- "$repo"; then
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
