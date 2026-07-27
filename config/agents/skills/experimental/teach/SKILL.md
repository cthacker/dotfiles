---
name: teach
description: Teach the user a new skill or concept over multiple sessions, using a .teach/ directory as a stateful teaching workspace.
disable-model-invocation: true
argument-hint: "What would you like to learn about?"
---

# Teach

The user has asked you to teach them something. This is a stateful request — they intend to learn the topic over multiple sessions.

## Teaching Workspace

The teaching workspace is the `.teach/` directory inside the current directory — create it on first use. The state of the user's learning is captured in these files (create each lazily, only when there is something to write):

- `.teach/MISSION.md` — the _reason_ the user is interested in the topic. Grounds all teaching.
- `.teach/RESOURCES.md` — curated trusted sources for knowledge and communities for wisdom.
- `.teach/GLOSSARY.md` — the canonical language for the workspace.
- `.teach/learning-records/*.md` — what the user has actually learned; the ADRs of teaching. Numbered `0001-<dash-case-name>.md`, incrementing.
- `.teach/lessons/*.html` — self-contained HTML lessons, numbered `0001-<dash-case-name>.html`, incrementing. The primary unit of teaching.
- `.teach/reference/*.html` — compressed learnings: cheat sheets, reference algorithms, glossaries. Beautiful documents that print well, designed for quick reference.
- `.teach/assets/*` — reusable components shared across lessons (stylesheets, quiz widgets, simulators).
- `.teach/NOTES.md` — a scratchpad for user preferences and working notes.

## Philosophy

To learn at a deep level, the user needs three things:

- **Knowledge**, captured from high-quality, high-trust resources
- **Skills**, acquired through highly-relevant interactive lessons devised by you, based on the knowledge
- **Wisdom**, which comes from interacting with other learners and practitioners

Before `RESOURCES.md` is well-populated, your focus should be to find high-quality resources which will help the user acquire knowledge. Never trust your parametric knowledge.

Some topics need more skills than knowledge (yoga); others more knowledge than skills (theoretical physics).

### Fluency vs storage strength

- **Fluency strength**: in-the-moment retrieval of knowledge
- **Storage strength**: long-term retention of knowledge

Fluency can give an illusory sense of mastery; storage strength is the real goal. Design lessons that build retention through desirable difficulty: retrieval practice (recall from memory), spacing (distributing practice over time), and interleaving (mixing related topics — for skills practice only).

## The Mission

Every lesson must tie into the mission. If the user is unclear about the mission, or `MISSION.md` is not populated, your first job is to question them on why they want to learn this. Failing to understand the mission means lessons feel abstract and you have no way to judge what comes next.

Missions change as skills develop. Update `MISSION.md` and add a learning record when they do — confirming with the user first.

`MISSION.md` format — keep it under a screen; it's a compass, not a plan:

```md
# Mission: {Topic}

## Why
{1-3 sentences. The concrete real-world goal. "Ship a Rust CLI to my team" beats "learn Rust".}

## Success looks like
- {A specific, observable thing the user will be able to do}

## Constraints
- {Time, budget, learning preferences}

## Out of scope
- {Adjacent topics explicitly not being chased right now}
```

One mission per workspace. Push back on vagueness — a bad mission is worse than no mission.

## Zone of Proximal Development

Each lesson, the user should feel challenged 'just enough'. If they don't specify what to learn next, find the zone by reading `.teach/learning-records/`, weighing the mission, and teaching the most relevant thing that fits.

## Lessons

A lesson is one self-contained HTML file in `.teach/lessons/` teaching one tightly-scoped thing tied to the mission.

- **Beautiful** — clean, readable typography and layout. Think Tufte. The user returns to these.
- **Short** — completable very quickly; working memory is small. Each lesson delivers a single tangible win.
- Link via HTML anchors to other lessons and reference documents.
- Recommend one primary source — the highest-trust resource you found on the topic.
- Remind the user they can ask you follow-up questions; you are the teacher.
- If possible, open the lesson file for the user by running a CLI command.

### Assets

Lessons are built from reusable components in `.teach/assets/` — stylesheets, quiz widgets, simulators. Reuse is the default: before authoring a lesson, read `.teach/assets/` and build from what's there; when something new and reusable is needed, write it as a component and link it, never inline code a future lesson would duplicate. A shared stylesheet is the first component every workspace earns.

## Knowledge

Design each lesson around a skill; include only the knowledge required to acquire it. Teach the knowledge first, then practice the skill via an interactive feedback loop. Gather knowledge from the trusted sources in `RESOURCES.md`, and litter lessons with citations. For knowledge acquisition, difficulty is the enemy — it eats working memory.

## Skills

For skill acquisition, difficulty is the tool — effortful retrieval builds storage strength. Teach through interactive lessons: quizzes and light in-browser tasks, or guided real-world steps (e.g. yoga poses). Base each on a **feedback loop** that is as tight and automatic as possible.

For quizzes, each answer option should be the same number of words (and characters, if possible) — no formatting clues.

## Wisdom

Wisdom comes from real-world interaction — testing skills outside the learning environment. When a question needs wisdom, attempt an answer but ultimately delegate to a **community**: a high-reputation forum, subreddit, class, or local group. If the user opts out of communities, respect it and note it in `RESOURCES.md`.

## RESOURCES.md format

```md
# {Topic} Resources

## Knowledge

- [Book: _Title_ — Author](url)
  One line: what it covers, and when to reach for it.

## Wisdom (Communities)

- [Community name](url)
  One line: why it's high-signal, and what to use it for.

## Gaps

- {Areas the mission needs where no good resource has been found yet}
```

High-trust only — primary sources, recognised experts, strongly-moderated communities. Annotate every entry. Prune ruthlessly: five sharp sources beat thirty mediocre ones.

## GLOSSARY.md format

Same shape as a domain glossary: `**Term**:` followed by a one-or-two sentence definition and an `_Avoid_:` alias line. Add a term **only when the user understands it** — the glossary is a record of compressed knowledge, not a dictionary to learn from. Be opinionated, keep definitions tight, use the glossary's own terms inside definitions, and revise as understanding deepens. Once a term is in, adhere to it in every lesson.

## Learning records

The ADRs of teaching: they capture non-obvious lessons, key insights, corrected misconceptions, and stated prior knowledge — the record that steers future sessions and defines the zone of proximal development.

```md
# {Short title of what was learned or established}

{1-3 sentences: what was learned, and why it matters for future sessions.}
```

Write one when: the user **demonstrated** genuine understanding of something non-trivial; disclosed prior knowledge ("I already know X" — record claimed depth); a misconception was corrected (high-value — predicts future stumbling blocks); or the mission shifted in response to learning.

What does _not_ qualify: material merely covered (coverage is not learning — wait for evidence), anything already captured in `GLOSSARY.md`, or session-by-session activity logs.

When a later record contradicts an earlier one, mark the old one `Status: superseded by LR-NNNN` rather than deleting it — how understanding evolved is itself useful signal.
