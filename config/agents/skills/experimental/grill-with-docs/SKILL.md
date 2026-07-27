---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also builds the project's glossary and ADRs as decisions land.
disable-model-invocation: true
---

# Grill With Docs

Interview me relentlessly about every aspect of this until we reach a shared understanding, building the project's domain docs as we go.

## The grilling loop

Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions **one at a time**, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the environment (filesystem, tools, etc.), look it up rather than asking me. The *decisions*, though, are mine — put each one to me and wait for my answer.

Do not act on the plan until I confirm we have reached a shared understanding.

## Domain modeling — active, inline

While grilling, actively build and sharpen the project's domain model. Docs live under `.scratch/` in the repo root:

```
.scratch/
├── CONTEXT.md        ← the glossary
└── adr/
    ├── 0001-slug.md  ← architectural decision records
    └── 0002-slug.md
```

Create files lazily — only when you have something to write. If no `.scratch/CONTEXT.md` exists, create one when the first term is resolved. If no `.scratch/adr/` exists, create it when the first ADR is needed.

Whenever `.scratch/CONTEXT.md` exists (including right after you create it), make sure the repo's `CLAUDE.md` and `AGENTS.md` each contain this line, so other sessions find the glossary:

> Domain vocabulary lives in .scratch/CONTEXT.md; use its terms.

Add it if missing; never duplicate it. Create the file with just that line if it doesn't exist. If `AGENTS.md` is a symlink to `CLAUDE.md`, editing one covers both.

During the session:

- **Challenge against the glossary.** When I use a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
- **Sharpen fuzzy language.** When I use vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."
- **Discuss concrete scenarios.** When domain relationships are being discussed, stress-test them with specific scenarios that probe edge cases and force precision about the boundaries between concepts.
- **Cross-reference with code.** When I state how something works, check whether the code agrees. If you find a contradiction, surface it.
- **Update CONTEXT.md inline.** When a term is resolved, update it right there. Don't batch these up — capture them as they happen.

## CONTEXT.md format

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{One or two sentence description of the term.}
_Avoid_: Purchase, transaction
```

Rules:

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project.** General programming concepts don't belong even if the project uses them extensively.
- **Glossary only.** `CONTEXT.md` must be totally devoid of implementation details. It is not a spec, a scratch pad, or a repository for implementation decisions.
- **Group terms under subheadings** when natural clusters emerge; a flat list is fine otherwise.

## ADRs — offer sparingly

Only offer to create an ADR when all three are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR.

ADRs live in `.scratch/adr/` with sequential numbering (`0001-slug.md` — scan for the highest existing number and increment). The format is deliberately tiny:

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

A single paragraph is a complete ADR. The value is in recording *that* a decision was made and *why* — not in filling out sections. Add **Status**, **Considered Options**, or **Consequences** sections only when they genuinely add value.

What qualifies: architectural shape, integration patterns, technology choices with real lock-in, boundary/scope decisions, deliberate deviations from the obvious path, constraints not visible in the code, and rejected alternatives when the rejection is non-obvious.
