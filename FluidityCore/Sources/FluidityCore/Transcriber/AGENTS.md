# Transcriber

## Purpose

Turns a recording into the live preview and the raw transcript. `Transcriber`
holds the timing rules; `FluidAudioEngine` is the only file that calls
FluidAudio, and stays a thin wrapper.

## Rules

- **Never two passes on the engine at once.** Preview and final passes share
  one `AsrManager`. `runningPass` can belong to a recording that already
  ended or was cancelled, and the next recording's ticks and final pass must
  still wait for it.
- **The recheck needs the speech model's token timings.** `Transcript`
  carries them internally; one built with the public initialiser has none,
  so the real candidate check always says no. Pass the recheck the
  transcript the engine returned.
- **Keep `spotterRescueEnabled: false`.** With it on, the candidate check
  says yes to every word list of 10 terms or fewer, so the recheck never
  skips, and false replacements rise.
- **A nil `wordListRecheckTime` means the recheck was skipped,** so saved
  records show how often the candidate check saves the cost.
- When a recheck merges or splits words, the word timings keep the speech
  model's words.

## Map

- `Transcriber` → preview ticks, final pass, recheck, stage timings.
- `SpeechEngine`, `VoiceDetecting`, `WordListRechecking` → what it needs from the models.
- `Transcript` → one pass's text and word timings.
- `RawTranscript` → what `finish` returns, with the stage timings.
- `FluidAudioEngine` → all three protocols over Parakeet TDT v2, Silero and CTC 110M.
