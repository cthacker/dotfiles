# How: ground the subsystem (blast-radius internal)

Procedure for building a real mental model of the code a change touches, before judging what it could break. Run it yourself for a narrow change; hand this file plus the target area to a read-only subagent (or several, one per slice) for a broad one.

## Approach

1. **Scope the question.** The target is the subsystem the diff touches plus everything that consumes its outputs. State your interpretation of the boundary before exploring.
2. **Explore for real.** Start broad (glob relevant directories, grep key types/interfaces/symbols), then follow the thread: from each entry point, trace the call chain — callers, callees, data flow, type definitions. Read the actual code; don't guess from file names.
3. **Stop condition.** You're done when you can describe the full path from input to output (or trigger to effect) without hand-waving any step. A step you can't narrate is a step you haven't read.
4. **Note the traps.** Record anything surprising, non-obvious, or that a newcomer would get wrong — those are where breakage hides.

## Return format

- **Overview.** What this subsystem is and does, 1-2 paragraphs.
- **Key concepts.** The types, services, or abstractions needed to follow the rest.
- **How it works.** The flow step by step: what triggers it, where data goes, the decision points. Prose with `file:line` references, not code dumps.
- **Where things live.** The files that matter, briefly.
- **Gotchas.** Non-obvious behavior, historical weirdness, sharp edges.

Overlap between parallel explorers is fine; the parent reconciles.
