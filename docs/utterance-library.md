# Utterance library

The collection of past dictations (transcripts and recordings) that Fluidity's speech and cleanup models will be tested and trained on. Why it exists: `docs/adr/0001-save-every-dictation.md`.

## Where it is

`/Volumes/Space/wispr-flow-teardown/` on the external drive Space. When Space isn't mounted, new files wait in `~/utterance-library-pending/` on the MacBook until the next run that finds the drive.

| Path | Contents |
|---|---|
| `training-data.jsonl` | Wispr Flow dictations, one JSON object per line |
| `fluidvoice-training-data.jsonl` | FluidVoice dictations, one JSON object per line |
| `audio/wispr-local/`, `audio/wispr-mule/` | Wispr Flow recordings |
| `audio/fluidvoice-local/`, `audio/fluidvoice-mule/` | FluidVoice recordings |
| `reproduction-sources.md` | Full research write-up: Wispr's pipeline, Baseten setup, fine-tuning walkthrough, methods from the Fluid-1 Pico teardown |
| `README.md`, `evidence/` | The Wispr Flow teardown itself |

"local" is the MacBook, "mule" is the work Mac (`alechamilton@SUMUP-M9Y197RFVG.local`).

On 22 Oct 2026 it held 745 Wispr pairs, 5,565 FluidVoice entries and 350 recordings (about 3 hours, 335 MB). Recordings are 16 kHz mono 16-bit WAV, named `<time>_<first 8 characters of the entry id>.wav`; each entry's `audio_file` field holds the path to its recording relative to the library folder, or null.

## Fields

Wispr Flow entries: `id`, `source_db` (local or mule), `timestamp`, `asr_text` (speech model output), `formatted_text` (after Wispr's cleanup), `server_finalized_text`, `pasted_text`, `edited_text` (after the user's edits), `app`, `url`, `textbox_contents`, `ax_context` (names pulled from the screen), `dictionary_context`, `transcript_origin` (speech model), timings, edit statistics, `audio_file`, `identical`.

FluidVoice entries: `id`, `source` (fluidvoice_local or fluidvoice_mule), `timestamp`, `raw_text` (Parakeet output), `processed_text` (after cleanup), `app`, `window_title`, `was_ai_processed`, `processing_model` (cleanup model; null on entries older than the field), `asr_model`, `audio_file`, `audio_duration_ms`, timings for speech and cleanup, `identical`.

FluidVoice records no screen context and no text after the user's edits. Fluidity should record both (ADR 0001).

## The daily collector

`~/bin/collect-utterances.py`, run by the launchd job `com.alec.collect-utterances` (`~/Library/LaunchAgents/com.alec.collect-utterances.plist`) every day at 22:00 and whenever a drive is mounted. A run that misses 22:00 because the MacBook was asleep happens on wake.

Each run:

1. If Space is mounted and `~/utterance-library-pending/` exists, moves its recordings and transcripts onto Space, then removes it.
2. Stops there if today's collection already ran (`~/Library/Logs/collect-utterances.last`).
3. Copies Wispr Flow's and FluidVoice's databases on the MacBook, and on the Mule over SSH when it answers. It writes out recordings that aren't in the library yet and adds or updates entries by id. Entries the apps have since deleted stay in the library.
4. Writes to Space, or to `~/utterance-library-pending/` when Space isn't mounted.

Log: `~/Library/Logs/collect-utterances.log`. Each JSONL file keeps one previous version next to it as `*.prev.jsonl`. `python3 -I ~/bin/collect-utterances.py --force` runs a collection by hand.

To remove it: `launchctl bootout gui/$(id -u)/com.alec.collect-utterances`, then delete the plist and `~/bin/collect-utterances.py`. The library itself is untouched.

AGENTS.md wants tooling like this named `{{PROJECT_SLUG}}.dev.…` and kept in the repo's `dev/` folder with a purge script. The project slug isn't set yet; move the job there once it is.

Not covered: the Mule is read only when it answers SSH at run time, so a day it sleeps through is caught the next day, unless Wispr has deleted the recordings in between.

## What the library is good for now

- Measuring speech models on this voice: run the recordings through a candidate and compare with the text the user kept.
- Finding misheard words from the user's edits, for a word list and find-and-replace rules.
- Writing the cleanup rulebook, from what good cleanup did and where it failed (corrections kept by mistake, the model printing its own instructions).
- Real inputs for labelling a cleanup fine-tune, mixed with generated dictation to reach the 50,000 or more examples a fine-tune needs.

About 3 hours of audio is enough to measure a speech model, not to retrain one. At 20 minutes of dictation a day, the library passes 50 hours in roughly six months.
