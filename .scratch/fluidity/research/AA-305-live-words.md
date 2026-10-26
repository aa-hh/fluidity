# AA-305: Showing live words while Alec speaks

Measured on 25 October 2026 on this Mac (Apple M1, macOS 27), release build, FluidAudio `main` at commit `1b0ed50`. Code: `spike/LiveWordsSpike` on branch `claude/live-words-spike`. All numbers are median / 90th percentile unless marked.

## Answer

Use approach A: re-run batch Parakeet TDT v2 on the growing recording once a second, and use the same model for the final text.

- Its live text is much closer to the final text: 5.0% word error rate against the final transcript, against 16.3% (EOU 160 ms) and 12.8% (EOU 320 ms).
- It is cheap enough on the M1. A pass costs 121 / 163 ms while the recording is 15 s or shorter, and 248 / 451 ms (worst 828 ms) beyond that. None of 885 passes overran the next one-second tick, so passes never queued.
- The final pass stays fast with live words running: 121 / 165 ms from release to final text for recordings up to 15 s, close to FluidVoice's 115 ms. Over all 40 clips it is 172 / 406 ms. Add the 200 ms tail buffer for what Alec feels: about 320 ms for a typical dictation.
- It needs no second model: about 100 MB steady memory against about 145 MB with the EOU model loaded.

What A loses: the first correct word shows 1.13 s after speech starts, against 0.53 s for EOU 160 ms, because A waits for the next one-second tick. And on 21 of 40 clips A showed a stray word during the silence before speech, because TDT invents a word from near-silent audio. Gating the previews with the Silero voice activity detector that FluidAudio already ships should remove that (not tested).

One `AsrManager` for both previews and the final pass did not crash and did not change any output (details under "Things that broke"). Two managers are not needed on upstream FluidAudio.

## Results

| | A: TDT v2 re-run ~1/s | B: EOU 160 ms + TDT final | B: EOU 320 ms + TDT final | A and EOU 160 ms together (32 clips) |
|---|---|---|---|---|
| First correct live word after speech starts | 1126 / 2351 ms (38 of 40 clips) | 531 / 2226 ms (31 of 40) | 943 / 1838 ms (32 of 40) | 527 / 835 ms (26 of 32) |
| Clips showing words before speech started | 21 of 40 | 0 | 0 | 0 |
| Time between live updates | 1003 / 1040 ms | 203 / 1118 ms | 309 / 1307 ms | 198 / 897 ms |
| Compute per live pass | 167 / 401 ms (all); 121 / 163 ms at 15 s or less | 23 / 46 ms per 100 ms of audio | 0 / 34 ms per 100 ms of audio | TDT 131 / 201 ms; EOU 24 / 46 ms |
| Passes that queued behind the previous one | 0 of 885 | live words lag the audio by at most 496 ms | at most 153 ms | 0 of 404; EOU lag at most 198 ms |
| Last live text against final text (word error rate, all words pooled) | 5.0% | 16.3% | 12.8% | 14.6% for EOU text; 6.8% for the TDT text |
| ... short / typical / long clips | 26.0% / 5.6% / 1.9% | 19.2% / 14.5% / 17.5% | 37.0% / 12.3% / 10.3% | |
| Updates that changed words already shown (per-clip median / p90) | 27% / 50% | 18% / 27% | 15% / 24% | 17% / 28% |
| Words rewritten per clip | 3 / 46 | 4 / 13 | 3 / 9 | 4 / 9 |
| Release to final text, compute only, all clips | 172 / 406 ms | 175 / 484 ms | 205 / 496 ms | 136 / 226 ms |
| ... clips of 15 s or less | 121 / 165 ms | 135 / 162 ms | 134 / 188 ms | 110 / 152 ms |
| ... clips over 15 s | 341 / 566 ms | 330 / 586 ms | 349 / 569 ms | 175 / 377 ms |
| Memory while running clips (largest) | 98 MB | 146 MB | 145 MB | 132 MB |
| Peak memory over the run | 124 MB | 494 MB | 519 MB | not recorded (run cut short) |

TDT pass cost by recording length so far (approach A): 15–30 s 189 / 416 ms, 30–60 s 291 / 460 ms, 60–90 s 370 / 489 ms. Past 15 s FluidAudio splits the audio into windows, so cost grows with length.

Baseline with no live words (generated speech, 8 clips): final pass 108 / 152 ms at 15 s or less, 322 / 716 ms beyond.

### Vocabulary boosting on the final pass

20 invented names and brands; Parakeet CTC 110M rescoring after the TDT v2 final pass. Measured on 8 clips of speech generated with macOS `say` (3 to 95 s, scripted to contain the terms), because Alec's drive locked before this run. Treat the timings as indicative and the skip rate as unmeasured.

| | Value |
|---|---|
| Added time when rescoring runs | 608 / 1185 ms (174 / 201 ms at 15 s or less; 809 / 1722 ms beyond) |
| Candidate check (`hasCTCRescoringCandidates`) | 4 / 9 ms |
| Clips the check let skip | 2 of 8 (both had no term in the text) |
| Clips changed by rescoring | 6 of 8 |
| Extra memory | peak 207 MB against 124 MB without it; the steady footprint reading did not rise |
| CTC model load | 24.3 s first time, 0.57 s afterwards; session set-up 23 ms |

Rescoring costs more than the TDT pass itself: about 175 ms extra on a typical dictation and over a second on long ones.

### Model load times

| Model | First load (cold) | Later loads (warm) |
|---|---|---|
| TDT v2 | 30.7 s first run on this Mac; 270.6 s from a freshly copied model folder | 0.2–0.9 s |
| EOU 160 ms | not caught cold | 0.7–1.0 s |
| EOU 320 ms | 107.4 s (may include its download) | 0.8 s |
| CTC 110M | 24.3 s (may include its download) | 0.57 s |

Cold loads are Core ML preparing the models for this Mac's Neural Engine. They happen once per model folder, and the time varies a lot.

### Things that broke

- No crashes in any run.
- One manager for previews and final: in approach A, 11 of 40 clips still had a preview pass running when the final pass started on the same `AsrManager`. No errors or crashes. A stress test ran 50 pairs of simultaneous transcriptions of one 14.5 s clip on one manager: 0 errors and 0 outputs that differed from a lone run. Two managers sharing the same loaded models also gave 0 errors and 0 differences, and took longer (25.2 s against 18.5 s). The SIGTRAP Fluid-oss reported did not show up on upstream FluidAudio. Fluid-oss pins its own fork, which may be why.
- Alec's external drive ("Space") locked at about 23:35, partway through the run with A and EOU together. That run covers 32 of 40 clips, and the boosting run used generated speech instead.
- TDT on less than a second of near-silent audio returns a word, which explains the stray words before speech in approach A.

## Method

- 40 of Alec's recordings from `fluidity-data/test`, chosen evenly by length: 10 under 5 s, 4 of 5–10 s, 16 of 10–25 s, 10 of 40–80 s (882 s in all). Read in place; no audio or text was copied or kept. Only numbers were written.
- Each clip is fed in 100 ms buffers at real-time pace on the real clock, the way a microphone delivers them. Release is the moment the last buffer arrives; the final pass starts then.
- A: the first pass runs at 0.5 s, then one pass per second on the whole recording so far. If a pass ran past the next tick, the next would start straight after it. That counts as queued.
- B: each 100 ms buffer goes to `StreamingEouAsrManager.process`. Live text is what its partial-text callback reports. At release TDT v2 runs on the whole recording while EOU finishes any audio it still holds.
- A with EOU together: both loops run at once, with separate `AsrManager` instances for previews and final.
- Speech start is the first 100 ms frame louder than a fifth of the clip's typical loud level. It agreed with TDT's first word timing on the clips checked. "First correct live word" is the first update whose opening word matches the final text's opening word.
- Word error rate: word edit distance between the last live text shown before release and the final TDT v2 text, lowercased with punctuation removed. "Changed words already shown" counts an update when a word on screen is replaced or removed. Words added at the end do not count.
- Release to final text is the TDT pass alone. The 200 ms tail buffer is not included.
- Memory: largest process footprint during clips, and the operating system's peak resident memory for the whole run (which includes model loading).
- Runs: `spike/LiveWordsSpike`, modes `a`, `b160`, `b320`, `ab160`, `boost`, `stress`, `load`. `summarise.py` turns the output into these tables.

## Not established

- Vocabulary boosting on Alec's own recordings, including how often the candidate check skips rescoring on real dictation.
- The last 8 clips of the run with A and EOU together, and that run's peak memory. EOU 320 ms was not run together with A.
- Whether a preview every 0.5 s, or only on the last 15 s of audio, would bring A's first word closer to EOU's without queuing.
- Whether gating previews with voice activity detection removes the stray words before speech.
- Recordings over 90 s. Pass cost grows past 15 s and may reach the one-second tick.
- Warm-start variation after a reboot, and the true cold load of EOU 160 ms.
- How the changed-words rate feels on screen. A's 50% at the 90th percentile and 46 rewritten words come from clips over 15 s; the eight worst are all 18 s or longer. Past 15 s FluidAudio splits the audio into windows, and where the windows join, words shift between passes.
