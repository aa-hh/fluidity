# Hotkey

## Purpose

Turns keyboard events into dictation key down and up, paste-again and cancel.
All decisions live in pure types that tests drive; `Hotkey` only wires the
event tap to them and must stay free of logic.

## Rules

- **`KeyModifiers` bit values must equal `CGEventFlags` raw values,** including
  the left and right bits, because `Hotkey` converts by raw value. Changing a
  value silently breaks left versus right decoding in the running app only.
- **Modifier changes are never swallowed,** or the focused app sees a modifier
  stuck down. `HotkeyDecision.swallows` enforces it.
- **Escape is swallowed only while recording.** `Hotkey.isRecording` must be
  kept in step with the dictation, or Escape stops working in every app.
- **`Hotkey` passes itself to the tap unretained;** keep it alive while the tap runs.
- Key names assume the US layout.

## Map

- `KeyChoice` → the saved shortcut and its settings text.
- `HotkeyDecoder` → keyboard event to `HotkeyDecision`.
- `ShortcutRecorder` → captures, checks and saves a new shortcut through `ShortcutStoring`.
- `Hotkey` → owns the event tap and re-enables it when macOS disables it.
