# DictationController

## Purpose

The state machine for one dictation, from key down to the end of watching,
and the pill and menu bar states it publishes. It reaches every other part
only through the protocols in `DictationParts.swift`; it never imports them.

## Rules

- **Escape writes the outputs itself and cancels the dictation's task.** In
  `DictationController`, every write to the phase or pill after an await
  must come straight after a `Task.isCancelled` check, or a cancelled
  dictation repaints the pill.
- **Every wait is until a deadline fixed when its event happened** (key down,
  release, last new words). Waiting a relative duration from inside a task
  breaks the tests: a `ManualClock` moved before the task starts waiting
  would never wake it.
- **The phase stays pasting until the record is saved.** A new dictation
  cancels the previous one only while watching; ending pasting earlier
  could cancel a watch that has not begun, and the new dictation would
  wait on it forever.
- **The values the parts exchange are nested in `DictationController`,**
  because every part shares one module and names like `Recording` would
  clash.

## Map

- `DictationController.swift` → the controller and its timers.
- `DictationParts.swift` → the protocols for the other parts and their values.
- `DictationStates.swift` → `PillState` and `MenuBarState`.
