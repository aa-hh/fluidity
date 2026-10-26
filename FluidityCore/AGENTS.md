# FluidityCore (Swift package)

## Purpose

All of Fluidity's logic, in one local Swift package the app links. Its tests
run without the app, the microphone or the speech model.

## Rules

- **Every part sits behind a small protocol with a fake for tests.** The
  speech engine, cleanup service, clipboard, focused text field and clock
  are reached only through those protocols.
- **The real speech model, microphone, clipboard and network never run in
  tests.** A test that downloads or loads a model is a bug. Timing code takes
  `any Clock<Duration>`; tests inject `ManualClock`, never real time.
- **FluidAudio is imported with no traits:** speech-to-text and voice
  detection only, no text-to-speech or diarizer. Turning a trait on needs an
  ADR. Its revision is pinned to the one ADR 0002 measured.
- **Every test belongs to one of four test targets,** so the runner can
  select one with `--filter` and run them as parallel jobs:
  - `DictationTests`: DictationController, Hotkey, DictationStore
  - `AudioTests`: AudioCapture, Transcriber
  - `CleanupTests`: CleanupClient, Settings, Finisher
  - `FieldTests`: FocusedField, Paster, EditWatcher
- **Use the words in `CONTEXT.md`** for types, tests and comments.
- **Test only through `scripts/test.sh`.**

## Map

- `FluidityCore` → the library target the app imports.
- `Sources/FluidityCore/<Part>/` → one folder per part, named as ADR 0001 (`DictationController`, `Hotkey`, `AudioCapture`, `Transcriber`, `CleanupClient`, `Settings`, `FocusedField`, `Finisher`, `Paster`, `EditWatcher`, `DictationStore`); a part's traps live in its own `AGENTS.md`.
- `DictationRecord` → the saved record of one dictation, shared by every part.
- `FluidityTestSupport` → helpers all four test targets share, such as `ManualClock`.
- `DictationTests`, `AudioTests`, `CleanupTests`, `FieldTests` → the four test targets.
