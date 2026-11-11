# 0001. Save every dictation, with its recording and the user's correction

Status: proposed

## Context

- Wispr Flow's lead comes from data, not from a hidden prompt. It trains its own speech model (Canto) with reinforcement learning, scored by word error rate, on dictations where users corrected the result, and it fine-tunes a Llama 3.1 8B cleanup model on its own pairs. Its app reads the text field back for 60 seconds after pasting to capture those corrections. Source: the Wispr Flow teardown, summarised in `docs/utterance-library.md`.
- Both apps used so far delete old recordings. On the Mule, Wispr Flow held 49 recordings on the morning of 22 Oct 2026 and 3 that evening. FluidVoice keeps only recent files in `DictationAudioHistory`. A recording that is gone can never train or test a speech model again.
- The library collected so far (6,310 text pairs, 350 recordings, about 3 hours of audio) is enough to measure models, not to train a good one. It grows only if each new dictation is kept.
- Stored audio runs at about 110 MB per hour. At 20 minutes of dictation a day that is about 37 MB a day, or about 13 GB a year.

## Decision

Fluidity keeps a permanent record of every dictation. Each record holds: the recording (16 kHz mono 16-bit WAV, never deleted automatically); the raw transcript and the speech model that made it; the cleaned text and the cleanup model that made it; the final text the user kept, read back from the text field for 60 seconds after pasting, plus why watching stopped; the context the models were given (app bundle id, window title, URL, nearby names, dictionary words); and timings for speech, cleanup and the whole dictation. Records can be exported in the format `docs/utterance-library.md` describes, so they join the existing library.

## Consequences

- Every dictation becomes test and training material: audio plus final text for the speech model, raw plus final text for the cleanup model, and edits for the misheard-word list.
- The share of dictations the user had to correct scores the pipeline without a hand-made test set.
- Fluidity keeps screen text and voice recordings indefinitely, so it needs a clear place on disk, a way to delete one record or all of them, and a way to pause saving.
- Reading the text field back needs macOS Accessibility permission.
- Storage grows by roughly 13 GB a year at the usage above; the library already lives on an external drive for this reason.
