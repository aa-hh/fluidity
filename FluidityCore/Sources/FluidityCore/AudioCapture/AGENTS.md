# AudioCapture

## Purpose

Records each dictation's audio from the microphone as 16 kHz mono Float32, with
pre-roll, tail, the 19/20 minute limits and the dead-microphone check. The
logic sits over `AudioInput` so tests feed it by hand; only
`AVAudioEngineInput` touches the hardware, and it stays thin and untested.

## Rules

- **Voice processing stays off.** The speech model and retraining both need the
  raw audio, room noise included.
- **Never call `AudioInput.start()` or `stop()` while holding the state lock.**
  `AVAudioEngine` waits for a tap callback in progress when it stops, and that
  callback takes the state lock, so the two would deadlock. A separate lock
  orders the start, stop and warm-period calls.
- **Sample counts decide pre-roll, tail and limits.** Buffers arrive in bursts,
  so wall time would cut them unevenly. The clock decides only the warm period
  and how long `stop()` waits for tail audio that never comes.
- **`stop()` marks the release point before its first suspension.** It is
  `nonisolated(nonsending)` so the mark lands at the call; the tests rely on
  this to deliver tail audio without a race.
- **Timer deadlines are fixed when scheduled,** not when the task first runs,
  so a test clock that moves before the task sleeps cannot skip them.

## Map

- `AudioCapture` → the recording logic and warm period.
- `AudioInput` → what the logic needs from a microphone.
- `AVAudioEngineInput` → the real microphone, converted with FluidAudio.
- `AudioRecording` → one dictation's samples and duration.
- `AudioCaptureEvent` → silence, limit and lost-input warnings.
