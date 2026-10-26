# 0003. Clean up in the cloud, and fall back to the raw transcript

Status: accepted

## Context

Fluid-1 Pico, the local cleanup model Alec used in FluidVoice, can't be used
outside FluidVoice under its licence (AA-294). Cerebras `gpt-oss-120b` measured a
332 ms median and 617 ms p90 over 128 of his cleanups. 94% of his dictations go
into the Claude desktop app, so most transcripts are questions or instructions
the model must not answer (AA-303). Reasoning can't be switched off on Cerebras,
and a fresh connection cost about 310 ms in one test.

## Decision

`CleanupClient` sends AA-298's request: a system message that stays identical
between dictations (cleanup rules the user can edit, 4 to 6 fixed examples of
questions and instructions cleaned rather than answered, then the word list), and
a user message of only `{"transcript": "..."}`, with `reasoning_effort: "low"`,
`temperature: 0` and a strict one-field schema `{"cleaned": string}`. Provider is
a base URL plus model name in OpenAI's format; the key lives in Keychain. One
shared `URLSession`; a warm-up request at recording start when the last request
was over 30 s ago. The raw transcript is pasted instead (a fallback, saved with
its reason) when the reply hasn't arrived after about 1 s, `NWPathMonitor`
reports no network, or the output check fails: the reply doesn't parse or was cut
off, under 85% of its words appear in the transcript or word list, its length is
outside 0.5 to 1.5 times the transcript's (8 words or more), or it opens with
"Sure", "Here's" or "I can't" when the transcript doesn't. `Finisher` then
applies the spacing and capitals rules before `Paster` runs.

## Consequences

- Dictation never waits more than about a second on the network, and never
  depends on it.
- Text goes to Cerebras's US data centres; Cerebras says it keeps none.
- Switching to Groq or OpenAI is a settings change.
- The output-check thresholds are starting values to tune from saved fallbacks.
- Predicted output stays a later, measured trial.
