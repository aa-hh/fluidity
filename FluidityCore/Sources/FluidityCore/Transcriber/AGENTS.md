# Transcriber

## Purpose

Turns a recording into the live preview and the raw transcript. Each speech
engine lives in its own file and stays a thin wrapper over its model;
`Transcriber` owns every preview and switching rule.

## Rules

- **Never two passes on the engine at once.** Preview and final passes share
  one `AsrManager`. `runningPass` can belong to a recording that already
  ended or was cancelled, and the next recording's preview passes and final pass must
  still wait for it. Preview passes also wait while `finalPassRunning` is set.
- **The recheck needs the speech model's token timings.** `Transcript`
  carries them internally; one built with the public initialiser has none,
  so the real candidate check always says no. Pass the recheck the
  transcript the engine returned.
- **Streaming engines get no voice check;** their partials drive the preview.
- **A switch waits for the recording in progress and its final pass.** It
  leaves the old engine loaded; the app shell unloads it.
- **Keep `spotterRescueEnabled: false`.** With it on, the candidate check
  says yes to every word list of 10 terms or fewer, so the recheck never
  skips, and false replacements rise.
- **A nil `wordListRecheckTime` means the recheck was skipped,** so saved
  records show how often the candidate check saves the cost.
- When a recheck merges or splits words, the word timings keep the speech
  model's words.

## Map

- `Transcriber` → preview passes, final pass, recheck, stage timings.
- `SpeechEngine`, `VoiceDetecting`, `WordListRechecking` → what it needs from the models.
- `StreamingSpeechEngine` → an engine fed chunk by chunk that reports partials.
- `Transcript` → one pass's text and word timings.
- `RawTranscript` → what `finish` returns, with the stage timings.
- `FluidAudioEngine` → all three protocols over Parakeet TDT v2, Silero and CTC 110M.
