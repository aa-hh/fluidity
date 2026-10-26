# AA-332: Parakeet Unified 0.6B streaming against re-run TDT v2

Measured on 26 October 2026 on this Mac (Apple M1, 16 GB, macOS 27), release build, FluidAudio `main` at commit `1b0ed50` (the revision the app pins). Code: `spike/LiveWordsSpike`, modes `a`, `u320`, `u640`, `u1120`, `ufinal`, `load`. Same 40 clips and same method as AA-305 (`AA-305-live-words.md`); mode `a` was re-run today so the baseline is from the same machine state. All numbers are median / 90th percentile unless marked.

## Answer

Parakeet Unified streaming does not get the first word on screen much sooner than re-running TDT v2, but it updates five times as often and rewrites far less.

- First correct word after speech starts: 956 ms with Unified 320 ms, against 1150 ms for re-run TDT v2 (A). The 320 ms tier name is the model's look-ahead, not the time to the first word.
- Unified updates every 203 ms (320 ms tier) or 602 ms (640 and 1120 ms tiers) against 1003 ms for A, and never shows a word before speech starts (A: 21 of 40 clips).
- Unified rewrites much less: 14% of updates change a word already shown (A: 25%), 3 / 11 words rewritten per clip (A: 3 / 47). Its decoded words are never taken back; the rewrites come from the end of a word growing.
- Its live text is further from the TDT v2 final text: 9.0% word error rate (A: 5.4%). About half of that is two different models disagreeing, not drift: Unified's own offline final differs from TDT v2's by 4.5%, and the two finals are word-for-word identical on only 16 of 40 clips. Drift of Unified's live text against Unified's own final was not measured.
- Compute is light: 29 / 38 ms per 160 ms window on the 320 ms tier, lagging the audio by at most 380 ms, with no queuing.
- The costs: a second model of about 565 MB on disk per tier (2.3 GB for the four tested), about 100 MB more steady memory, and 30 to 51 s to load in every fresh process today. The 520 to 650 MB "peak memory" in the table is the model file being read through while Core ML compiles it for the Neural Engine, not process memory: the process footprint never passed 64 MB during a load (see "Where the load time and the memory peak come from"). The slow load is not Unified's alone: loaded the same way today, TDT v2's encoder took 34 to 41 s too, against 0.2 to 0.9 s yesterday.

The 1120 ms tier is worse on every column that matters here (first word 1571 ms, 11.7% WER). The 640 ms tier matches 320 ms on accuracy with a third of the windows but a slower first word (1069 ms) and three times the gap between updates.

Unified offline (`ufinal`) as a replacement for the TDT v2 final: same speed on clips of 15 s or less (151 / 220 ms against 139 / 188 ms), slower beyond (740 / 1716 ms against 465 / 1009 ms), 4.5% disagreement with TDT v2 with no ground truth to say which is right, and the same 30 to 44 s load. Not a win on these numbers.

## Results

Short clips are under 5 s (10), typical 5 to 25 s (20), long 40 to 80 s (10). WER columns compare the last live text shown before release with the TDT v2 final text, as in AA-305.

| | A: TDT v2 re-run ~1/s (today) | A (AA-305, 25 Oct) | Unified 320 ms | Unified 640 ms | Unified 1120 ms |
|---|---|---|---|---|---|
| First correct live word after speech starts | 1150 / 2905 ms (37 of 40 clips) | 1126 / 2351 ms (38 of 40) | 956 / 1332 ms (35 of 40) | 1069 / 1450 ms (35 of 40) | 1571 / 1967 ms (36 of 40) |
| Clips showing words before speech started | 21 of 40 | 21 of 40 | 0 | 0 | 0 |
| Time between live updates | 1003 / 1102 ms | 1003 / 1040 ms | 203 / 1102 ms | 602 / 1714 ms | 602 / 1704 ms |
| Compute per live pass | 183 / 569 ms (all); 123 / 280 ms at 15 s or less | 167 / 401 ms; 121 / 163 ms | 29 / 38 ms per 160 ms window (5466 windows) | 39 / 61 ms per 560 ms window (1561) | 43 / 68 ms per 560 ms window (1525) |
| Passes that queued behind the previous one | 16 of 879 (max 2327 ms late; one pass took 3321 ms) | 0 of 885 | none; live words lag the audio by 67 / 222 ms per clip, at most 380 ms | at most 414 ms | at most 358 ms |
| Last live text against final text (WER, all words pooled) | 5.4% | 5.0% | 9.0% | 9.2% | 11.7% |
| ... short / typical / long clips | 24.7% / 6.3% / 2.1% | 26.0% / 5.6% / 1.9% | 26.0% / 5.6% / 10.0% | 23.3% / 6.0% / 10.5% | 46.6% / 10.1% / 8.9% |
| Updates that changed words already shown (per-clip median / p90) | 25% / 50% | 27% / 50% | 14% / 25% | 6% / 18% | 7% / 23% |
| Words rewritten per clip | 3 / 47 | 3 / 46 | 3 / 11 | 1 / 3 | 1 / 3 |
| Release to final text (TDT v2, compute only), all clips | 243 / 514 ms | 172 / 406 ms | 217 / 572 ms | 203 / 517 ms | 209 / 657 ms |
| ... clips of 15 s or less | 141 / 290 ms | 121 / 165 ms | 168 / 344 ms | 127 / 213 ms | 153 / 179 ms |
| ... clips over 15 s | 370 / 557 ms | 341 / 566 ms | 304 / 572 ms | 295 / 648 ms | 383 / 669 ms |
| Unified `finish()` at release (its own final text) | | | 29 / 56 ms | 32 / 61 ms | 46 / 66 ms |
| Memory while running clips (largest) | 87 MB | 98 MB | 99 MB | 100 MB | 118 MB |
| Footprint right after loading | 28 MB (TDT) | | 94 MB | 99 MB | 64 MB |
| Peak memory over the run | 119 MB | 124 MB | 598 MB | 649 MB | 522 MB |
| Model load, warm | 0.3 s (TDT) | 0.2–0.9 s | 38 s | 30 s | 51 s |

Per-clip medians of the WER column by length, since the pooled long-clip figure is dominated by a few clips: Unified 320 ms 38.6% / 5.0% / 8.0%, 640 ms 36.5% / 5.2% / 7.9%, 1120 ms 60.2% / 8.9% / 6.7%.

### Unified offline 15 s as the final pass (`ufinal`)

TDT v2 final ran first at release, then Unified offline on the same whole clip.

| | TDT v2 final | Unified offline 15 s final |
|---|---|---|
| Release to final text, all clips | 238 / 812 ms | 299 / 1506 ms |
| ... clips of 15 s or less | 139 / 188 ms | 151 / 220 ms |
| ... clips over 15 s | 465 / 1009 ms | 740 / 1716 ms |
| Unified text against TDT v2 text (WER, pooled) | | 4.5%; per-clip median 2.7%, p90 28.6% |
| ... short / typical / long clips | | 16.4% / 3.0% / 4.5% |
| Clips where the two finals are identical | | 16 of 40 |
| Words in the finals (all clips) | 1192 | 1177 |
| Footprint right after loading | 26 MB | 126 MB |
| Memory while running clips (largest) | | 117 MB |
| Peak memory over the run | | 652 MB |
| Model load, warm | 42 s in this run (0.3 to 51 s across today's runs) | 44 s |

Past 15 s Unified splits the clip into 15 s windows with a 2 s overlap, which is where its long-clip cost comes from.

### Model load times and sizes

| Model | First load (download and Core ML compile) | Later loads (warm) | Footprint after load |
|---|---|---|---|
| Unified 320 ms encoder | 316 s | 34–38 s | 94 MB |
| Unified 640 ms encoder | 333 s | 30 s | 99 MB |
| Unified 1120 ms encoder | 261 s | 30–51 s | 64 MB |
| Unified offline encoder | 256 s | 31–44 s | 126 MB |
| TDT v2 (for comparison, today) | | 0.3 to 51 s | 26–28 MB |

The four Unified encoders are 2.3 GB on disk (int8, about 565 MB each; decoder and joint are shared). The first-load column includes the download and ran with the four tiers back to back, so the split between download and compile is not known. TDT v2 itself loaded in 35 to 51 s on three of today's six runs and under a second on the other three, which it did not do yesterday.

### Where the load time and the memory peak come from

Checked after the main run by calling Core ML's `MLModel.load` directly on the two encoder files, with no FluidAudio code in between, sampling the process footprint every 50 ms during the load, and loading each model twice in the same process. Two separate processes, 11:36 and 11:37.

| Load | Time, first load in the process | Process footprint, peak during the load | Resident set peak after it (what the "peak memory" row measures) | Second load, same process |
|---|---|---|---|---|
| TDT v2 encoder, CPU and Neural Engine | 34 s / 41 s | 63 / 61 MB | 466 / 469 MB | 0.30 s / 0.11 s |
| Unified 320 ms encoder, CPU and Neural Engine | 36 s / 28 s | 50 / 55 MB | 601 / 608 MB | 0.37 s / 36 s |
| Unified 320 ms encoder, CPU only | 8.8 s / 4.1 s | 50 / 64 MB | 1619 / 1740 MB | 0.04 s / 0.00 s |
| TDT v2 encoder, CPU only | 6.3 s / 4.4 s | 59 / 59 MB | same | 0.00 s / 0.00 s |

- The memory peak is not process memory. The footprint (what the app would be charged for) stays under 64 MB throughout; the resident-set peak rises by about the size of the model file (425 MB for TDT v2, 563 MB for Unified) because Core ML reads the weights through while compiling, and those pages are clean and reclaimable. Loading on the CPU alone maps the whole file and drives the resident set to 1.6 to 1.7 GB.
- The 30 to 40 s is Core ML compiling the encoder for the Neural Engine in each fresh process, and today it hits TDT v2 the same as Unified. Loaded through FluidAudio or straight through Core ML, with the same compute units, the time is the same. A second load in the same process is instant, except once (Unified, second process), which was not explained.
- The compiled programs are not being kept between processes. Core ML's per-app cache for the harness, `~/Library/Caches/LiveWordsSpike/com.apple.e5rt.e5bundlecache`, was recreated at 10:24 today (during the u640 run) and holds 37 entries of one 64-byte hash file each, with no compiled program behind them. This Mac has 7.1 GB free on a 228 GB disk after the 2.3 GB download, which is where macOS starts purging caches. That is the likely cause of both the slow loads and the loss of yesterday's cached TDT v2 compile, but the purge itself was not seen in the logs (not readable from here).

The probe is a 25-line mode (`loadprobe`) kept out of this branch to stay within the review's two rounds; it is in the session notes as a patch.

### Things that broke

- No crashes or errors in any run; every mode completed all 40 clips.
- Mode `a` today had 16 of 879 preview passes run past the next one-second tick (none yesterday), across 6 clips, all 17 s or longer; one pass took 3.3 s. The Space drive had been mounted minutes before the run, so Spotlight indexing it is the likely cause, but this was not checked. A's accuracy columns match yesterday's.
- The harness first mapped `u320` onto the EOU 320 ms model as well, because the old mode check matched any name ending in "320". Caught on the smoke test; fixed before the 40-clip run, which used the corrected build (mode `a` ran before the rebuild and does not use that code).
- The first-word column is missing for 4 to 5 clips per Unified tier: the 0.7 s and 1.2 s clips, and three others where the first live word never matched the TDT v2 final's first word.

## Method

As AA-305, with these additions.

- `u320`, `u640`, `u1120`: `StreamingUnifiedAsrManager` built from `StreamingModelVariant.parakeetUnified{320,640,1120}ms.unifiedConfig` (int8 encoder, FluidAudio's default). Each 100 ms buffer goes to `appendAudio` then `processBufferedAudio`; live text is what the partial-transcript callback reports. At release TDT v2 runs on the whole recording for the reference text; then Unified's `finish()` is timed and the manager reset. "Compute per window" is the time of each `processBufferedAudio` call that ran a window (anything over 5 ms); the other calls return at once.
- `ufinal`: `UnifiedAsrManager` (`.parakeetUnifiedOffline15s`). No live loop. At release TDT v2 runs first, then Unified's `transcribe` on the same samples; both are timed; the Unified text is scored against the TDT v2 text with the same word edit distance.
- `load`: warm load time and footprint change for each Unified tier through `createManager()`, after the clip runs.
- Clip order, feeding, speech-start detection, WER, rewrite counting and memory readings are unchanged from AA-305. `summarise.py` prints the new modes.
- Run order: `a`, `u320`, `u640`, `u1120`, `ufinal`, `load`, one at a time on an otherwise idle Mac, 09:52 to 11:20.

## Not established

- Drift of Unified's live text against Unified's own final text (the number that says how much the preview would change at release if Unified were used for both). The 9.0% here is against TDT v2's final.
- Which final is more accurate, TDT v2 or Unified. Both were scored against each other, not against a transcript.
- Whether the 30 to 51 s loads go away once the disk has room and Core ML can keep its compiled programs. If they do, Unified loads as fast as TDT v2 and the load-time objection disappears; if they do not, neither model is usable at app launch on this Mac. Free 10 GB or more and re-run the `load` mode twice.
- The 2080 ms Unified tier, fp16 encoders, and the 640 ms tier with vocabulary boosting.
- Unified streaming with the Silero gate in front of it, and whether its first word moves earlier when fed in smaller than 100 ms buffers.
- Running Unified streaming and the TDT v2 final from one shared model set; the two managers here are independent.
