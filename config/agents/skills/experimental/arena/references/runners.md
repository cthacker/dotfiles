# Native workers through Rex

Use these commands from any parent harness. Rex manages processes; Claude Code and Codex own
their native agent loops. Neither the parent's subagent API nor Pi provider IDs are required.

## Prepare

Check `rex whoami --json`, `claude --help`, and `codex exec --help` when capabilities are uncertain.
Use the local Rex server that can access the worktrees. Do not mistake a remote server's paths
or credentials for local ones.

Create a unique run directory with a shared brief, separate candidate worktrees, and one job
directory per worker. Use absolute paths. Keep prompts and logs outside candidate write scope.
Retries get fresh job directories so old exit markers cannot look like new successes.

The brief includes the task, required behavior, relevant repository instructions, allowed writes,
checks, and requested rationale. Forbid further delegation. Native runtimes can differ in tools
and instructions; this compares agent setups, not model quality in isolation.

## Native commands

Run each command from its assigned working directory. Set `BRIEF` to its prompt file and `OUT`
to an existing, unique job directory. Set `SKILL_DIR` to this skill's absolute directory. The local
[recording wrapper](../scripts/record-worker.sh) saves stdout, stderr, and exit status and mirrors
stdout into the Rex pane. These commands use existing CLI logins without changing user config.

### Claude candidate

```bash
bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  claude -p --model claude-opus-5-5 --effort high --safe-mode \
  --no-session-persistence --permission-mode auto --permission-prompts none \
  --tools "Read,Edit,Write,Glob,Grep,Bash" \
  --output-format stream-json --verbose
```

Auto mode lets a classifier approve routine actions, so the worker can run the task's checks
without a hand-written allowlist. Anything the classifier refuses is denied, not prompted. Treat
denials as blockers or verification gaps, not a reason to add permission-bypass flags.
`--safe-mode` preserves native auth, model selection, and tools while
disabling custom workflows, plugins, hooks, and automatic instruction loading. Therefore the
shared brief must carry the relevant project instructions and coding constraints.

### Codex candidate

```bash
bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  codex exec --ignore-user-config --ephemeral --disable multi_agent \
  --model gpt-6.1-sol -c 'model_reasoning_effort="xhigh"' --approve-for-me \
  --json --output-last-message "$OUT/result.md" -
```

This pins model and effort without editing Codex's settings. `--approve-for-me` runs in the
workspace-write sandbox and routes approval requests through automatic review. Repository
instructions and execution policies still apply. Do not enable nested agents or broaden the
sandbox to work around a failure.

### Judge

Choose by the parent model's family, using the roster in this skill's main file.

For a GPT parent:

```bash
bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  claude -p --model claude-opus-5-5 --effort xhigh --safe-mode \
  --no-session-persistence --permission-mode dontAsk --permission-prompts none \
  --tools "Read,Glob,Grep" --allowedTools "Read,Glob,Grep" \
  --output-format stream-json --verbose
```

For a Claude parent:

```bash
bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  codex exec --ignore-user-config --ephemeral --disable multi_agent \
  --model gpt-6-astra -c 'model_reasoning_effort="xhigh"' --sandbox read-only \
  --json --output-last-message "$OUT/result.md" -
```

Judges stay read-only rather than using auto-approval modes; they never need to write.
Stage completed artifacts and relevant context under neutral labels in a separate judge directory.
Do not include role manifests, worker logs, or model names. The parent performs any requested
reproduction that needs writes. Rex itself is not a sandbox; the native permission settings matter.

## Start through Rex

Use the recording wrapper directly as the Rex command; no interactive shell typing is needed.
Create an unselected session with a completed control tab:

```bash
rex new "arena-$SLUG" -c "$RUN_DIR" --window Control --keep-open --json \
  -- /bin/bash -c 'exit 0'
```

Save `.session_id` as `SID` and the returned control block ID. This does not ask Rex.app to
display the session. Launch each candidate with its own `WORKTREE` and `OUT`:

```bash
rex run -s "$SID" -c "$WORKTREE" --label "$LABEL" --focus=false --keep-open --json \
  -- bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  codex exec --ignore-user-config --ephemeral --disable multi_agent \
  --model gpt-6.1-sol -c 'model_reasoning_effort="xhigh"' --approve-for-me \
  --json --output-last-message "$OUT/result.md" -
```

The example launches Candidate B; use the corresponding native arguments above for other roles.
Save every returned `.block_ids[0]` and `.window_id`. Start all candidates before waiting.
Rex uses the login shell's environment; confirm the required CLIs resolve there if startup fails.

## Wait, inspect, and collect

```bash
rex wait -s "$SID" "$BLOCK" --for 30s --json
rex block call -s "$SID" -b "$BLOCK" process
rex capture -s "$SID" -b "$BLOCK" --trim --unwrap
```

A wait timeout does not stop the worker or establish failure. Check process state and the saved
exit marker. Poll within the task's time limit; Rex does not automatically notify the parent chat.
If a launch request times out, inspect before retrying so it cannot create duplicate workers.

Read logs from disk, not only terminal scrollback. A zero process exit is necessary, not sufficient:
verify the requested artifact and checks. For Claude, inspect the final `result` event and its
`is_error`, `result`, and permission-denial fields. Codex writes its final reply to `result.md`.
Report actual native model identities from metadata when available, plus the effort requested.
Only launch the judge after all candidate writers have exited or been stopped.

## Stop and clean up

At the time limit, interrupt only the worker's block with
`rex send-key -s "$SID" -b "$BLOCK" ctrl+c`, then check that it stopped. Do not synthesize while
a writer is still running.

Preserve the selected artifact, reports, and logs before closing successful worker blocks with
`rex block close -s "$SID" "$BLOCK"`. Keep failed blocks for inspection until their failure is
understood. Close the completed run's session with `rex kill "$SID"` only after verifying it is
the session this run created, never the parent's or an unrelated session. Closing Rex resources
does not authorize deleting worktrees or result files.

If Rex is unavailable, announce the fallback and run the same wrapped commands as subprocesses.
Track their PIDs, exit statuses, and outputs, and wait for or stop every writer. Do not silently
switch models or runtimes.
