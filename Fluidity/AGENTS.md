# Fluidity (app target)

## Purpose

The Xcode app target: only what needs a running app. It builds every
`FluidityCore` part once, connects them through `DictationController`, and
shows the controller's state in the recording pill, the menu bar item and the
Glass windows. It holds no logic.

## Rules

- **Logic never lives here.** It goes in `FluidityCore/`, where tests can
  reach it without launching the app.
- **No App Sandbox.** Pasting into other apps and listening for the global
  dictation key need Accessibility, which the sandbox forbids. The
  entitlements file carries only microphone input, which the hardened
  runtime requires.
- **The bundle id and signing identity stay fixed.** macOS ties the
  Microphone and Accessibility grants to them; changing either makes the
  user grant both again.
- **Build only through `scripts/build.sh`.** It runs on this Mac because the
  signed app must end up here.
- **Previews open only by environment variable.** `WindowPreview` and
  `PillPreview` run at every launch and do nothing unless their variable is
  set. Nothing else opens a window at launch except the first-run check.
- **This folder is a synchronized group.** Xcode compiles every Swift file
  dropped in it; non-code files need an exception in the project file, or
  they get copied into the app.

## Map

- `FluidityApp` → app entry point; a hidden scene and the pill preview.
- `AppDelegate` → builds the parts, mirrors `Settings` into `SettingsModel`,
  feeds the pill, the menu bar item and the first-run check.
- `Pill/` → the recording pill; see its `AGENTS.md`.
- `Glass/` → the Glass look shared by the windows; see its `AGENTS.md`.
- `Settings/`, `Compare/`, `Popover/`, `FirstRun/`, `Preview/` → the settings
  window, the compare window, the menu bar item and popover, the first-run
  check, the sample-data preview.
- `Fluidity.entitlements` → hardened-runtime entitlements (microphone input only).
