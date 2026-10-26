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
`hasCTCRescoringCandidates` finds a possible term. `FluidityCore` pins FluidAudio to the revision the
spike measured, `1b0ed50d686873128a4129b3510ce3914c849bab`.

## Consequences

- The live preview matches the pasted text closely, and one model stays loaded
  (about 100 MB).
- The first preview word appears about 0.6 s later than with a streaming model.
- The recheck's cost on real dictation, and how often the pre-check skips it, is
  not yet measured; re-time it on Alec's clips and drop it if it is slow.
- Recordings over 15 s cost more per pass (248 / 451 ms) but still kept up.

## Amendment, 2026-10-26 (AA-333)

The preview no longer runs on a 1 s clock. `Transcriber` runs voice detection
and then a pass, waits 250 ms, and goes again, so the first pass starts within
250 ms of voice detection hearing speech and later passes follow each other as
fast as the engine allows. A pass costs about 121 ms for any audio up to 15 s,
because FluidAudio pads every input to 15 s, and 0 of 885 passes queued in the
AA-305 spike, so the engine has room for this. A slow pass delays the next pass
instead of dropping it. The measured numbers in this record are from the 1 s
design; AA-333 holds the new ones once measured.
