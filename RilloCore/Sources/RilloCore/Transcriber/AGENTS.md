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
- **No word-list recheck in speech-to-text;** it swaps common words for listed
  names. The word list goes to cleanup only (ADR 0005).
- **Streaming engines get no voice check;** their partials drive the preview.
- **A switch waits for the launch load, the open recording and its final
  pass.** It leaves the old engine loaded for `ModelCoordinator`.
- **Fluid Voice's FluidAudio keeps its word-timing builder private,** so
  `Transcript(_:)` joins token timings into words itself.
- **A `SpeechTranscriber` attaches to only one `SpeechAnalyzer`,** so
  `AppleSpeechEngine` builds one per stream; reuse traps.

## Map

- `Transcriber` → preview passes, final pass, stage timings.
- `SpeechEngine`, `VoiceDetecting` → what it needs from the models.
- `StreamingSpeechEngine` → an engine fed chunk by chunk, reporting partials.
- `Transcript` → one pass's text and word timings.
- `RawTranscript` → what `finish` returns, with stage timings.
- `FluidAudioEngine` → both protocols over Parakeet TDT v2 and Silero.
- `FluidSpeechProEngine` → Fluid Speech Pro, loaded from the folder its download filled.
- `AppleSpeechEngine` → Apple's SpeechAnalyzer.
- `CompareSession` → one recording through two transcribers, side by side.
