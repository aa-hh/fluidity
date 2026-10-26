# Transcriber

## Purpose

Turns a recording into the live preview and raw transcript. Each speech
engine is a thin wrapper over its model, in its own file; `Transcriber`
owns every preview and switching rule.

## Rules

- **Never two passes on the engine at once.** Preview and final passes share
  one `AsrManager`. `runningPass` can outlive its recording; later
  recordings' passes still wait for it. Preview passes also wait on
  `finalPassRunning`.
- **The recheck needs the speech model's token timings.** A `Transcript` from
  the public initialiser has none, so the candidate check always says no.
  Pass the recheck the engine's transcript.
- **Streaming engines get no voice check;** their partials drive the preview.
- **A switch waits for the recording in progress and its final pass.** It
  leaves the old engine loaded for the app shell to unload.
- **Keep `spotterRescueEnabled: false`.** On, the candidate check accepts
  every word list of 10 terms or fewer, so the recheck never skips and false
  replacements rise.
- **A nil `wordListRecheckTime` means the recheck was skipped,** so saved
  records show how often the candidate check avoids it.
- Word timings keep the speech model's words when a recheck merges or
  splits them.
- **A `SpeechTranscriber` attaches to only one `SpeechAnalyzer`,** so
  `AppleSpeechEngine` builds a fresh one per stream; reusing it traps on the
  second dictation.

## Map

- `Transcriber` → preview passes, final pass, recheck, stage timings.
- `SpeechEngine`, `VoiceDetecting`, `WordListRechecking` → what it needs from the models.
- `StreamingSpeechEngine` → an engine fed chunk by chunk, reporting partials.
- `Transcript` → one pass's text and word timings.
- `RawTranscript` → what `finish` returns, with stage timings.
- `FluidAudioEngine` → all three protocols over Parakeet TDT v2, Silero and CTC 110M.
- `UnifiedEngine` → Parakeet Unified 0.6B streaming.
- `AppleSpeechEngine` → Apple's SpeechAnalyzer.
