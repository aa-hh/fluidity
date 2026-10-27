# AA-335: The 250 ms back-to-back preview loop against the 1 s tick and Unified streaming

Measured on 26 October 2026 on this Mac (Apple M1, 16 GB, macOS 27), release build, FluidAudio `main` at commit `1b0ed50`. Code: `spike/LiveWordsSpike`, modes `a` and `a250`. Same 40 clips and method as AA-305 and AA-332; the Unified 320 ms column is copied from AA-332 (same clips, same day). All numbers are median / 90th percentile unless marked.

Mode `a250` mirrors the loop that merged in AA-333 (`Transcriber.swift`): sleep 250 ms; if no pass is running, run Silero on the whole recording so far until it first hears speech; from then on run a TDT v2 pass on the whole recording so far and wait for it; sleep 250 ms; repeat. On release the final pass waits for a running preview pass, as the app does.

## Answer

The merged loop is the best of the three on the columns that decide the preview.

- First correct word 546 ms after speech starts (1 s tick: 1103 ms; Unified 320 ms: 956 ms), and every one of the 40 clips showed a correct first word (the others: 37 and 35).
- Words before speech on 1 clip of 40, against 22 for the 1 s tick. The Silero gate costs 2 / 17 ms a check, about 4 checks a clip, and hears speech 255 ms after it starts.
- Live text closest to the final text: 1.6% word error rate (1 s tick 5.2%, Unified 9.0%), with one stalled clip excluded (below); 4.9% with it in.
- Updates every 383 ms against 1003 ms. Release to final text is unchanged at 163 / 440 ms, because the wait for a running preview pass is 3 / 118 ms (15 of 40 clips had one running at release).

What it costs: twice the passes (1777 against 884 over the 40 clips, 41 a clip at the median), and so more rewriting on screen: 36% of updates change a word already shown (27% for the 1 s tick, 14% for Unified), 10 / 75 words rewritten a clip (4 / 50, 3 / 11). Unified still wins only on how little it rewrites and on compute per update.

One clip stalled: on the 41.6 s clip a single preview pass took 65 s, the final pass 5.2 s, and the release waited 6.0 s. The 1 s tick run and an earlier `a250` run (before a harness fix, see Method) showed no such pass; cause not found. Rows it dominates are given both with and without it.

## Results

Short clips are under 5 s (10), typical 5 to 25 s (20), long 40 to 80 s (10). WER columns compare the last live text shown before release with the TDT v2 final text.

| | A: TDT v2 re-run on a 1 s tick | a250: merged loop | Unified 320 ms streaming (AA-332) |
|---|---|---|---|
| First correct live word after speech starts | 1103 / 2818 ms (37 of 40 clips) | 546 / 2461 ms (40 of 40) | 956 / 1332 ms (35 of 40) |
| Clips showing words before speech started | 22 of 40 | 1 of 40 | 0 |
| Time between live updates | 1003 / 1048 ms | 383 / 662 ms | 203 / 1102 ms |
| Compute per live pass | 160 / 413 ms (all, 884 passes); 114 / 159 ms at 15 s or less; 244 / 473 ms beyond | 129 / 410 ms (all, 1777 passes); 94 / 150 ms at 15 s or less; 289 / 493 ms beyond (max 1552 ms without the stalled clip) | 29 / 38 ms per 160 ms window (5466 windows) |
| Passes that queued, or (a250) how late a pass started after its 250 ms gap | 1 of 884 ran past the next tick (573 ms late) | 2 / 3 ms late, max 97 ms | none; live words lag the audio by at most 380 ms |
| Voice checks before the first pass | | 4 a clip (max 77); 2 / 17 ms each (max 223 ms); speech heard 255 / 544 ms after it starts | |
| Last live text against final text (WER, all words pooled) | 5.2% | 4.9%; 1.6% without the stalled clip | 9.0% |
| ... short / typical / long clips | 27.4% / 5.8% / 1.9% | 0.0% / 1.3% / 8.8%; long 2.2% without the stalled clip | 26.0% / 5.6% / 10.0% |
| Updates that changed words already shown (per-clip median / p90) | 27% / 50% | 36% / 53% | 14% / 25% |
| Words rewritten per clip | 4 / 50 | 10 / 75 | 3 / 11 |
| Release to final text, all clips | 161 / 436 ms | 163 / 440 ms; 155 / 414 ms without the stalled clip | 217 / 572 ms (TDT v2 final) |
| ... clips of 15 s or less | 100 / 182 ms | 102 / 163 ms | 168 / 344 ms |
| ... clips over 15 s | 296 / 661 ms | 354 / 1094 ms; 332 / 1013 ms without the stalled clip | 304 / 572 ms |
| ... of which waiting for a running preview pass | not waited for (11 clips had one running) | 3 / 118 ms, 14 clips over 10 ms, max 579 ms (6.0 s on the stalled clip) | |
| Memory while running clips (largest) | 87 MB | 83 MB | 99 MB |
| Footprint right after loading | 28 MB | 27 MB, 55 MB with Silero | 94 MB |
| Peak memory over the run | 127 MB | 467 MB (a 52 s cache-miss compile of TDT v2 at load; see AA-332) | 598 MB (same cause) |

An earlier `a250` run of the same 40 clips, before the harness fix below, gave the same picture: first correct word 570 / 1592 ms, 1 clip with words before speech, updates every 389 / 635 ms, 2.4% WER (9.6% / 0.6% / 3.3%), 36% / 50% of updates changing shown words, 8 / 91 words rewritten. Its release-to-final numbers are wrong and are not used.

Per-clip medians of the WER column: a250 0.0% (p90 2.7%), A 0.0% (p90 55.6%). The 1 s tick's short-clip errors come from its stray words before speech and from a first pass that often sees under a second of speech.

## Method

As AA-305, with these additions.

- `a250`: one `AsrManager` for previews and final, as the app. A task sleeps until 250 ms after the previous pass ended (or after the previous voice check, before speech is heard), stops sleeping as soon as release is seen, takes the recording so far, runs `VadManager.process` on it until any chunk is voice-active (default `VadConfig`, as `FluidAudioEngine.hasSpeech`), then runs a TDT v2 pass and waits for it. "Late after its 250 ms gap" is the time from the intended start to the actual start of each pass. At release the final pass waits for a running preview pass; "waiting for a running preview pass" is that wait, and release to final includes it.
- Harness fix: the first `a250` run slept its whole 250 ms gap before noticing release, where the app cancels that sleep. That overstated release to final by up to 250 ms; the loop now stops sleeping at release and the run was repeated.
- Mode `a` was re-run today, unchanged, so both columns come from the same machine state.
- Run order: `a` 12:05 to 12:20, `a250` 12:56 to 13:13, one at a time.

## Not established

- What stalled the 41.6 s clip for 65 s in the `a250` run. Nothing else was running under the harness's slots; the Core ML cache thrash in AA-332 is a candidate (a mid-run recompile), but it was not caught.
- How the extra rewriting (36% of updates, 10 words a clip) feels on screen against the 1 s tick's 27% and 4 words. Both come from TDT re-reading the whole recording, and past 15 s from its window seams.
- Whether a shorter gap than 250 ms, or previews on only the last 15 s of audio, moves the first word earlier still without raising the rewrite rate.
- The Silero gate's behaviour on recordings that start with noise rather than silence; the 40 clips start quiet.
