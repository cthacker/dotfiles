---
name: arena
description: >-
  Use Rex to run independent native-agent candidates, cross-judge their artifacts, choose a
  base, incorporate useful alternatives, and verify the result.
disable-model-invocation: true
---

# Arena

Run independent attempts at the same task. A cross-family judge compares them; the parent helps
the user review that verdict, grafts useful ideas into the chosen base, and verifies one final
result. The parent owns the decision and verification.

Track Frame, Fan out, Judge, Review, Graft, Verify, and Clean up with a short checklist.

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

This table is the default in every harness. Explicit user requests for models, count, or effort
take precedence. Extra candidates may use other models or independent
repeats at different effort levels. Set each runner's model and effort explicitly.

## Execution

Rex owns worker startup, status, waiting, inspection, and cleanup. Workers use native Claude Code
or Codex CLI sessions, regardless of the parent's harness. Read [runners](./references/runners.md)
before launching; it covers waiting, status updates, wrap-up requests, and cleanup. Use a separate,
unselected Rex session so workers do not steal focus. If Rex is unavailable, announce a
direct-subprocess fallback using the same native commands.

## Phase A: Frame

1. State the artifact, goal, constraints, and scope. Brief exactly the artifact the user asked
   for: a request for Markdown skills or a design does not imply scripts, tests, or tooling.
   Propose material additions to the user instead of adding them to the brief.
2. Define 3-6 concrete criteria, separating required behavior from preferences. Give candidates
   all requirements and acceptance criteria; keep comparative scoring with the parent and judge.
   Treat length targets as guidance, not something candidates spend their run counting.
3. Select the roster and permissions. Only the user sets time or cost limits; if they set none,
   the run has none. If a model or effort is unavailable, report it and any substitution; never
   silently change the roster.
4. Give candidates the same brief, relevant repository instructions, and source snapshot, including
   relevant uncommitted work. Use separate worktrees or output directories and isolate mutable
   test data or services. Candidates write only in assigned locations, not the parent workspace
   or shared brief. Their briefs forbid further delegation or nested arenas.
5. Tell the user the plan in a few lines before launching: artifact, roster, criteria, and where
   you will stop for their input.

## Phase B: Fan out

Do only the preflight that launch needs, then start candidates concurrently through Rex in fresh
native CLI sessions. Each receives the same task and grounding plus its own output path. Request
the artifact, a short rationale with rejected alternatives, and checks actually run with results
and limitations. Candidates never see each other's work.

While candidates run, the parent only monitors: liveness, blockers, and finished artifacts. It
does not review or test candidates early. Keep waiting and give short status updates as described
in the runner reference until every writer has finished or been stopped.

Execution failures and missing artifacts are dropouts, not low scores. Check that outputs exist.
Retry only an affected worker, at most once for a plausible transient failure within the user's
limits.

With two or more usable artifacts, compare the survivors. With one, verify it and disclose that
no comparison completed. With none, report the failures and stop. Do not simulate independent
candidates in the parent context when separate runs are unavailable.

## Phase C: Judge

Run the parent-relative judge through Rex in a fresh, read-only context at xhigh effort. Give it
only the task, rubric, and artifacts under neutral labels, without model identities, effort levels,
worker logs, the parent's preferred solution, or the user's passing reactions. Ask for findings
against each criterion with artifact evidence, required repairs separated from optional additions,
what it actually checked versus only read, and a recommended base with its tradeoffs.

The judge owns the comparison. Launch it once every candidate writer has stopped, then wait for it
rather than running a parallel comparison of your own. Save its verdict unchanged as a readable
file. If no judge can run, disclose that the parent judged alone. With one surviving candidate,
use the judge as an independent reviewer, not a comparative judge.

## Phase D: Review and pick

Present the verdict to the user as soon as it lands: the recommended base, its main evidence,
required repairs, and suggested borrowings. Then check the claims that decide the pick against the
artifacts themselves and say which you confirmed, which you dispute, and which remain open.

Prefer the base a maintainer can extend without breaking invariants; use simplicity as a tiebreaker,
not size. A candidate that still violates requirements is a starting point for repair, not a
completed winner.

**Evidence outranks agreement.** A demonstrated defect outweighs reassuring votes. Explain any
departure from the judge's recommendation. Fresh contexts and neutral labels do not eliminate shared
blind spots or model-family biases.

Propose the base and a short keep/borrow/omit plan, then stop for the user's approval unless they
already authorized synthesis. Say plainly that you are waiting on them, not on a running job.

## Phase E: Graft

Read the approved base and each donor end to end; for code, the complete changed diff and the
context needed to assess it. Port changes that improve the result against the criteria, reworking
them to fit the base rather than pasting implementations together. Optional additions the judge
suggested are not required, and material scope growth needs the user's approval. Record important
borrowed and rejected ideas with their source labels and reasons. If nothing improves the base, no
graft is needed.

Convergence still requires verification. Divergence calls for comparing tradeoffs, not an automatic
rerun. Reframe only when evidence shows the contract was misunderstood or a new experiment is
needed.

## Phase F: Verify

Verify the final artifact the way that kind of artifact is used, not a proxy:

- Markdown skills and docs: links, metadata, consistency, and a walkthrough of realistic scenarios.
  Say that this is static review, not a live agent run.
- Code: relevant tests, the final diff, and exercising the changed behavior.
- Visual output: the rendered result, not the generator's exit status.

Candidate and judge summaries are not verification. Fix ordinary bugs or bad grafts and rerun
the checks; revisit framing only when evidence challenges the design or contract. Repeated failures
on one assumption call for testing that assumption, not another full arena by default.
Report required behavior that remains broken or unverified; do not claim success.

## Outputs and cleanup

One artifact, the unchanged judge verdict, and a short synthesis note, in the reply or alongside
it. Name the chosen base and why, important grafts and rejections, actual checks and unresolved
gaps, and every runner's native CLI, model, and effort. Disclose substitutions, dropouts,
interruptions, absent judging, and family overlap with a candidate. For a multi-file result, add a
short map of what each file is for so the user can inspect it; make a browseable page when asked.

Preserve the deliverable, verdict, judged artifacts, prompts, and logs, then clean up this run's
Rex resources and scratch files as the runner reference describes.
