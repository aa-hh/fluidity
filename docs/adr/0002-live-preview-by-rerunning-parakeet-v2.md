# 0002. Make the live preview by re-running Parakeet TDT v2 about once a second

Status: accepted

## Context

AA-305 measured two options on Alec's M1 with 40 of his recordings fed at real
speed:

| | Re-run TDT v2 | Parakeet EOU 160 ms | Parakeet EOU 320 ms |
|---|---|---|---|
| Last live preview against final text (word error rate) | 5.0% | 16.3% | 12.8% |
| First correct word after speech starts (median) | 1.13 s | 0.53 s | 0.94 s |
| Release to final text, recordings up to 15 s (median / p90) | 121 / 165 ms | 135 / 162 ms | 134 / 188 ms |

Re-run passes took 121 / 163 ms up to 15 s of audio and never queued in 885
passes. One `AsrManager` served preview and final passes without crashes. The
re-run showed a stray word before speech on 21 of 40 clips. Parakeet's word-list
recheck (`VocabularyBoostingSession` with Parakeet CTC 110M) added 174 ms median
on recordings up to 15 s, measured on generated speech; its pre-check
`hasCTCRescoringCandidates` costs 4 ms.

## Decision

`Transcriber` keeps one Parakeet TDT v2 `AsrManager`. While recording it runs a
preview pass on the whole recording so far about once a second, only after
FluidAudio's voice detection has heard speech. On release (plus the 200 ms tail)
it runs the final pass. The word-list recheck runs after the final pass only when
`hasCTCRescoringCandidates` finds a possible term.

## Consequences

- The live preview matches the pasted text closely, and one model stays loaded
  (about 100 MB).
- The first preview word appears about 0.6 s later than with a streaming model.
- The recheck's cost on real dictation, and how often the pre-check skips it, is
  not yet measured; re-time it on Alec's clips and drop it if it is slow.
- Recordings over 15 s cost more per pass (248 / 451 ms) but still kept up.
