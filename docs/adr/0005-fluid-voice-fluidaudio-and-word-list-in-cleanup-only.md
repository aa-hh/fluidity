# 0005. Run speech models on Fluid Voice's FluidAudio, and leave the word list to cleanup

Status: accepted

## Context

Fluid Voice published Fluid Speech Pro (FluidVoice-Labs, CC BY 4.0), a Parakeet TDT v3 fine-tune in 25
languages. On the 108 test clips, scored against AssemblyAI on real words only, it made 3.6% errors through
Fluid Voice's copy of FluidAudio (`altic-dev/FluidAudio`) and 3.9% loaded as a v3 model through
FluidInference's, against 3.8% for Parakeet TDT v2.

Fluid Voice's copy split from FluidInference's in March 2026. It has no Parakeet Unified, no
`VocabularyBoostingSession` and no `hasCTCRescoringCandidates`, and it declares no package traits, so
text-to-speech, the diarizer and swift-transformers with seven more packages build in with it.

The word-list recheck (Parakeet CTC 110M) with a 27-word list raised errors on the same clips with every
model: Parakeet TDT v2 from 3.85% to 5.04% with the pre-check (37 of its 49 swaps wrong per the answer key),
and both v2 and Pro to about 7% without it. Typical swaps: "actually" to "Tautulli", "kind" to "Mini",
"seconds" to "Sonos". The app had already stopped passing the word list to it.

## Decision

`RilloCore` pins Fluid Voice's FluidAudio at `386f7195670b77f2954c7ee143ec63fcb50b6c3b` and offers Fluid Speech
Pro as the multilingual speech model, with its credit line. Parakeet Unified and the speech-side word-list
recheck are removed; the word list goes to cleanup only. This replaces the FluidAudio pin and the recheck
in ADR 0002.

## Consequences

- Pro runs with the decoding its makers tuned it on, and Parakeet TDT v2 stays the default.
- The app carries text-to-speech, the diarizer and eight more packages it does not use, and follows Fluid
  Voice's changes to FluidAudio rather than FluidInference's. Moving back needs FluidInference's copy to load
  Pro.
- A Mac that chose Parakeet Unified falls back to Parakeet TDT v2; the Unified and CTC 110M folders stay on
  disk.
- Listed names spelled the way the speech model heard them are left for cleanup to fix from context.
