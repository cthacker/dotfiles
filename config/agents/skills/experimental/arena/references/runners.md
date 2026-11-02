# Native workers through Rex

Use these commands from any parent harness. Rex manages processes; Claude Code and Codex own
their native agent loops. Neither the parent's subagent API nor Pi provider IDs are required.

## Prepare

Check `rex whoami --json`, `claude --help`, and `codex exec --help` only when capabilities are
uncertain, and reuse what you already verified. Launch as soon as the roster, auth, and paths are
confirmed; the user is waiting on the candidates, not on preflight. Use the local Rex server that
can access the worktrees. Do not mistake a remote server's paths or credentials for local ones.

Create a unique run directory with a shared brief, separate candidate worktrees, and one job
directory per worker. Use absolute paths. Keep prompts and logs outside candidate write scope.
Retries get fresh job directories so old exit markers cannot look like new successes.

The brief includes the task, required behavior, relevant repository instructions, allowed writes,
checks, and requested rationale. Forbid further delegation. Native runtimes can differ in tools
and instructions; this compares agent setups, not model quality in isolation.

Keep a small manifest in the run directory: session and block IDs, each runner's model and effort,
launch and finish times, output paths, and any user-set limits. Status updates and cleanup use it.

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
Create an unselected session whose first tab says what it is:

```bash
rex new "arena-$SLUG" -c "$RUN_DIR" --window Overview --keep-open --json \
  -- /bin/bash -c 'printf "%s\n" "Session anchor only; no agent runs here." \
    "Candidates and the judge have their own tabs. Logs live in this run directory."'
```

Save `.session_id` as `SID`. The Overview tab is an idle anchor, not a controller or the judge.
This does not ask Rex.app to display the session. Launch each candidate with its own `WORKTREE`
and `OUT`:

```bash
rex run -s "$SID" -c "$WORKTREE" --label "$LABEL" --focus=false --keep-open --json \
  -- bash "$SKILL_DIR/scripts/record-worker.sh" "$OUT" "$BRIEF" -- \
  codex exec --ignore-user-config --ephemeral --disable multi_agent \
  --model gpt-6.1-sol -c 'model_reasoning_effort="xhigh"' --approve-for-me \
  --json --output-last-message "$OUT/result.md" -
```

The example launches Candidate B; use the corresponding native arguments above for other roles.
Save every returned `.block_ids[0]` and `.window_id`. Start all candidates before waiting, and
report when each one actually launched. Rex uses the login shell's environment; confirm the
required CLIs resolve there if startup fails. If a launch request times out, inspect before
retrying so it cannot create duplicate workers.

## Wait and report status

Rex does not wake the parent when a worker exits, so the parent keeps waiting until every worker
in the current phase has finished. Ending the turn with "I'll keep monitoring" leaves nobody
monitoring.

- Claude Code: run `rex wait -s "$SID" "$BLOCK"` with no `--for` as a background Bash command
  for each worker. The harness wakes the parent when it exits.
- Other harnesses, such as pi: loop on `rex wait -s "$SID" "$BLOCK" --for 5m --json`. A timeout
  only means the worker is still running; check the exit marker and wait again.

After each wait round and at every phase change, post one status line naming the phase, each
worker's state, what the parent is doing, and what comes next:
`Drafting: A done, B running. Parent: waiting. Next: judge.`
Report observations, not guesses about why one worker is slower. After answering a status
question, keep waiting. If you must stop waiting, say so and say what is still running.

```bash
rex block call -s "$SID" -b "$BLOCK" process
rex capture -s "$SID" -b "$BLOCK" --trim --unwrap
```

## Collect

Read logs from disk, not only terminal scrollback. A zero process exit is necessary, not sufficient:
verify the requested artifact and checks. For Claude, inspect the final `result` event and its
`is_error`, `result`, and permission-denial fields. Codex writes its final reply to `result.md`.
Report actual native model identities from metadata when available, plus the effort requested.
Only launch the judge after all candidate writers have exited or been stopped. Copy the judge's
final reply to a readable `verdict.md` in the run directory and present it right away.

## Wrap-up requests and stops

On "wrap up", first check whether the worker already finished. The print-mode commands above take
no new instructions mid-run; typing into the pane does not reach the agent. Say so, and let the
user choose:

1. Keep waiting.
2. Stop it and use what it has written.
3. Stop it and launch a continuation in the same worktree with a fresh job directory and a brief
   to finish the smallest complete deliverable from the existing work, with no new features or
   polish.

Stop a worker only on the user's decision, a limit the user set, or a concrete safety or resource
problem: `rex send-key -s "$SID" -b "$BLOCK" ctrl+c`, then confirm it stopped and keep its partial
files. A run that looks stalled gets a process and log check, reported to the user, not a deadline.
Disclose stops and continuations in the synthesis note. Do not synthesize while a writer is
still running.

## Clean up

Only clean up what this run created, as recorded in its manifest. First preserve the deliverable,
the unchanged verdict, the judged artifacts, prompts, logs, and manifest. Then:

- Close completed blocks with `rex block close -s "$SID" "$BLOCK"`, keeping failed ones until their
  failure is understood. Close the session with `rex kill "$SID"` only after confirming it is the
  one this run created, never the parent's or an unrelated session.
- Delete disposable scratch: judge staging copies, caches, and superseded outputs.
- Remove worktrees with the VCS's own procedure, never force-removing unmerged work.

Leave anything whose ownership or preservation is uncertain, and report what was kept and removed.

If Rex is unavailable, announce the fallback and run the same wrapped commands as subprocesses.
Track their PIDs, exit statuses, and outputs, and wait for or stop every writer. Do not silently
switch models or runtimes.
