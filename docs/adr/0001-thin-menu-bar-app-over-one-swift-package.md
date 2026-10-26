# 0001. Build version 1 as a thin menu bar app over one Swift package

Status: accepted

## Context

Version 1 (Linear AA-296) is a menu bar dictation app for one user, Alec, on an
M1 running macOS 27, with friends in version 2. It must paste into any app, so it
needs Microphone and Accessibility permission, and macOS ties those permissions to
the app's code signature. FluidAudio supplies speech-to-text but not microphone
capture (AA-295). The repo's test runner should not have to launch the app, and
the real speech model never runs in tests (AA-302).

## Decision

An Xcode app target, `Fluidity`, holds only what needs the app: the menu bar item
(no Dock icon), popover, settings window, the pill window (`NSPanel`), permission
checks and launch at login (`SMAppService`). All logic lives in one local Swift
package, `FluidityCore`, split into `DictationController`, `Hotkey`,
`AudioCapture`, `Transcriber`, `CleanupClient`, `Finisher`, `Paster`,
`EditWatcher`, `DictationStore` and `Settings`. The speech engine, cleanup
service, clipboard, focused text field and clock sit behind small protocols so
tests use fakes. SwiftUI for screens, AppKit for the pill window and menu bar.
Minimum macOS 26. Every build is signed with the Apple Development certificate.
FluidAudio is the only package; any other package is added only where it clearly
earns its place and gets its own ADR. `scripts/build.sh` and `scripts/test.sh`
call `~/.claude/scripts/remote-run`.

## Consequences

- Package tests run without the app, the microphone or the model.
- A stable signature keeps permissions granted across rebuilds; unsigned or
  ad-hoc builds would ask again every time.
- macOS 26 lets the screens use current SwiftUI, but friends on macOS 14 or 15
  can't run version 2.
- The app target stays small, so most build work can happen in the package
  without touching Xcode project settings.
