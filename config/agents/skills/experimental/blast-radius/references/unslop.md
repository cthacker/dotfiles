# Writeup rules (blast-radius internal)

Condensed from the standalone unslop skill, trimmed to what a risk writeup needs. The writeup gets read by someone deciding whether to merge; every vague sentence costs them a wrong decision.

- **Say the concrete thing.** Every claim is a mechanism, a `file:line`, a number, or a pasted output. "This could cause issues downstream" is banned; "the consumer at `sync.ts:141` assumes this field is non-null and will throw" is the standard. If you can't restate a sentence as a fact, instruction, or number, cut it.
- **Calibrated language, not inflated hedging.** "Proven" only for facts you ran code to check. "Appears to" / "likely" for inference. "Unproven" said plainly when that's the truth. Never "could potentially possibly".
- **Active voice.** "The loader parses the file", not "the file is parsed". Name the actor.
- **No filler, no chatbot phrases.** Cut "it is important to note that", "I hope this helps", "Great news!". No decorative emojis, no bold on every noun.
- **Plain words.** "use" not "utilize"/"leverage", "way" not "vector", "base" not "substrate". No abstract metaphor nouns.
- **One idea per sentence.** If the reader must backtrack to parse it, split it.
- **Don't pad.** A risk section with three real entries beats ten maybes. An empty "Cleared" list is a valid result.
