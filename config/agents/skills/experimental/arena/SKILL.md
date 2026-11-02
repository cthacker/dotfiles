---
name: arena
description: >-
  Use Rex to run independent native-agent candidates, cross-judge their artifacts, choose a
  base, incorporate useful alternatives, and verify the result.
disable-model-invocation: true
---

# Arena

Run independent attempts at the same task. Read each artifact, choose a base, graft useful ideas,
and verify one final result. The parent owns the decision and verification.

Track Frame, Fan out, Cross-judge, Pick, Graft, and Verify with a short checklist.

## Default roster

Use two candidates and one judge:

| Role | Native CLI | Model | Effort |
| --- | --- | --- | --- |
| Candidate A | `claude` | `claude-opus-5-5` | `high` |
| Candidate B | `codex` | `gpt-6.1-sol` | `xhigh` |
| Judge for a GPT parent | `claude` | `claude-opus-5-5` | `xhigh` |
| Judge for a Claude parent | `codex` | `gpt-6-astra` | `xhigh` |

Choose the judge by the parent's actual model family, not its CLI or hosting provider. Other
parent families use Astra xhigh. Resolve an unknown parent family before choosing the judge.
The judge must be from a different family than the parent; if unavailable, report absent judging
rather than silently using the parent's family. With these two families, it still shares a family
with one candidate. Disclose that overlap in the synthesis note.

Use this table, not external model-role configuration, for defaults. Explicit user requests for
models, count, or effort take precedence. Extra candidates may use other models or independent
repeats at different effort levels. Set each runner's model and effort explicitly.

## Execution

Rex owns worker startup, status, waiting, inspection, and cleanup. Workers use native Claude Code
or Codex CLI sessions, regardless of the parent's harness. Read [runners](./references/runners.md)
before launching. Use a separate, unselected Rex session so workers do not steal focus.
If Rex is unavailable, announce a direct-subprocess fallback using the same native commands.

## Phase A: Frame

1. State the artifact, goal, constraints, and scope.
2. Define 3-6 concrete criteria, separating required behavior from preferences. Give candidates
   all requirements and acceptance criteria; keep comparative scoring with the parent and judge.
3. Select the roster, permissions, and time limit. If a model or effort is unavailable, report it
   and any substitution; never silently change the roster.
4. Give candidates the same brief, relevant repository instructions, and source snapshot, including
   relevant uncommitted work. Use separate worktrees or output directories and isolate mutable
   test data or services. Candidates write only in assigned locations, not the parent workspace
   or shared brief. Their briefs forbid further delegation or nested arenas.

## Phase B: Fan out

Start candidates concurrently through Rex in fresh native CLI sessions. Each receives the same
task and grounding plus its own output path. Request the artifact, a short rationale with rejected
alternatives, and checks actually run with results and limitations. Candidates never see each
other's work.

Execution failures and missing artifacts are dropouts, not low scores. Check that outputs exist.
Retry only an affected worker, at most once for a plausible transient failure within the user's
limits. Wait until every writer has finished or been stopped before judging or synthesizing.

With two or more usable artifacts, compare the survivors. With one, verify it and disclose that
no comparison completed. With none, report the failures and stop. Do not simulate independent
candidates in the parent context when separate runs are unavailable.

## Phase C: Cross-judge

Run the parent-relative judge through Rex in a fresh, read-only context at xhigh effort. Give it
only the task, rubric, and artifacts under neutral labels, without model identities, effort levels,
worker logs, or the parent's preferred solution. Ask for findings against each criterion with
artifact evidence, then a recommended base and its tradeoffs.

The judge may run alongside the parent's reading, never alongside unfinished candidate writes.
If no judge can run, disclose that the parent judged alone. With one surviving candidate, use
the judge as an independent reviewer, not a comparative judge.

## Phase D: Pick a base

Read every artifact end to end. For code, read each complete changed diff and the context needed
to assess it. Compare candidates criterion by criterion: required behavior first, then preferences.
Prefer the base a maintainer can extend without breaking invariants; use simplicity as a tiebreaker.
A candidate that still violates requirements is a starting point for repair, not a completed winner.

**Evidence outranks agreement.** A demonstrated defect outweighs reassuring votes. Compare your
findings with the judge's and investigate disagreements. Fresh contexts and neutral labels do not
eliminate shared blind spots or model-family biases.

## Phase E: Graft

Inspect every alternative for useful differences. Port changes that improve the result against
the criteria, reworking them to fit the base rather than pasting implementations together.
Record important borrowed and rejected ideas with their source labels and reasons. If nothing
improves the base, no graft is needed.

Convergence still requires verification. Divergence calls for comparing tradeoffs, not an automatic
rerun. Reframe only when evidence shows the contract was misunderstood or a new experiment is
needed.

## Phase F: Verify

Exercise the final artifact, inspect the final diff, and run relevant checks after synthesis.
Candidate and judge summaries are not verification. Fix ordinary bugs or bad grafts and rerun
the checks; revisit framing only when evidence challenges the design or contract. Repeated failures
on one assumption call for testing that assumption, not another full arena by default.
Report required behavior that remains broken or unverified; do not claim success.

## Outputs

One artifact and a short synthesis note, in the reply or alongside it. Name the chosen base and why,
important grafts and rejections, actual checks and unresolved gaps, and every runner's native CLI,
model, and effort. Disclose substitutions, dropouts, absent judging, and family overlap with a
candidate. Preserve results and logs before closing this run's Rex resources.
