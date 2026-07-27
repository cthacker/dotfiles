# Why: intent archaeology (blast-radius internal)

Procedure for recovering why the code being changed is shaped the way it is, so a "cleanup" doesn't delete a load-bearing decision. Run it yourself, or hand this file plus the code anchor to a read-only subagent.

## Posture

Evidence before narrative. Commit messages lie, tickets go stale, and the current shape is often the accretion of many earlier decisions. Never pick a story and recruit evidence that fits it. Code tells you what it does, rarely why it exists — resist inferring intent from code shape.

## Procedure

1. **Anchor in the code.** File paths, line ranges, key symbols.

```bash
git blame -L <start>,<end> <file>        # last-touch commits per line
git log --follow --oneline -20 -- <file> # history through renames
git log -1 --format=%B <commit>          # full message; PR numbers look like (#1234)
```

2. **Pull the review-time record.** For each substantive commit:

```bash
gh pr view <number> --json title,body,author,comments,reviews,closingIssuesReferences
```

PR descriptions state the problem; review threads debate alternatives; test names encode motivating edge cases. This is the most trustworthy source because it ties directly to the diff that shipped.

3. **Chase linked artifacts.** Ticket IDs, issue links, and doc URLs referenced from commits and PRs. Defensive-looking code (null checks, retries, timeouts, rate limits, feature flags) usually traces to an incident or bug report — hunt for it before touching the guard.

## Return format

Keep the confidence tiers separate; that separation is the product.

- **What we found.** Claims with citations (commit hash, PR #, ticket, `file:line` comment). Direct evidence only.
- **What we can reasonably infer.** Hedged ("appears to", "likely"), each with its inference chain.
- **What we don't know.** Searches that came up empty, named specifically. An honest "no ticket discusses this threshold" beats a confident guess.

If the change would alter this code, end with the constraints: what to preserve, what's safe to change, what to avoid, and the risk if the inference is wrong.
