# AudioCapture

## Purpose

Records each dictation's audio from the microphone as 16 kHz mono Float32, with
a silent lead-in, tail, the 19/20 minute limits and the dead-microphone check.
The logic sits over `AudioInput` so tests feed it by hand; only
`CoreAudioInput` touches the hardware, and it stays thin and untested.

## Rules

- **The microphone runs only from `start()` until the recording is collected
  or cancelled.** An open mic holds AirPods in their low-quality call mode.
  Speed comes from building the input unit early and only starting it.
- **Raw audio only:** the model and retraining need room noise. Never use
  voice processing; on AirPods it delivered exact zeros after a second.
- **Never call `AudioInput.start()` or `stop()` while holding the state lock.**
  `stop()` waits for audio already queued, and delivering it takes the state
  lock, so the two would deadlock.
- **`CoreAudioInput`'s I/O callback never takes the unit lock.** Stopping a
  unit waits for a callback in progress.
- **Sample counts decide the tail and limits.** Buffers arrive in bursts, so
  wall time would cut them unevenly. The clock decides only how long `stop()`
  waits for tail audio that never comes.
- **`stop()` marks the release point before its first suspension.** It is
  `nonisolated(nonsending)` so the mark lands at the call; the tests rely on
  this to deliver tail audio without a race.
- **Timer deadlines are fixed when scheduled,** not when the task first runs,
  so a test clock that moves before the task sleeps cannot skip them.

## Map

- `AudioCapture` → the recording logic.
- `AudioInput` → what the logic needs from a microphone.
- `CoreAudioInput` → the real microphone, converted with FluidAudio.
- `AudioRecording` → one dictation's samples and duration.
- `AudioCaptureEvent` → silence, limit and lost-input warnings.
