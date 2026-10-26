# Fluidity (app target)

## Purpose

The Xcode app target: only what needs a running app, such as the menu bar
item and, later, windows and permission checks. It holds no logic.

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
- **This folder is a synchronized group.** Xcode compiles every Swift file
  dropped in it; non-code files need an exception in the project file, or
  they get copied into the app.

## Map

- `FluidityApp` → app entry point; the menu bar item with a Quit button.
- `Fluidity.entitlements` → hardened-runtime entitlements (microphone input only).
