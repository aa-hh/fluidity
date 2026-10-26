# EditWatcher

## Purpose

Reads the text field back after a paste, so the final text saved with a
dictation carries the user's corrections. It reports the final text and why it
stopped; the caller hands both to the store. It never sorts or classifies edits.

## Rules

- **Never watch key presses.** The design needs no Input Monitoring permission:
  every edit fires a value change, so the reading before Enter clears the field
  is already in hand. A key monitor could not read the field in time anyway.
- **Never record a secure field.** `watch` returns nil the moment any reading
  says the field is secure, even mid-watch.
- **The final text comes from the last reading that still had the text on both
  sides of the paste,** never from a reading after the field cleared or that
  text vanished. Changing that turns every sent message into an empty final text.
- **A field's `notifications` stream has one reader.** Create a fresh
  `AccessibilityWatchedField` for each watch.
- **`cursor` counts UTF-16 code units,** as Accessibility reports it, not
  Swift characters.

## Map

- `EditWatcher` → the watch loop: timed reads, notifications, stop reasons.
- `WatchedField` → what the watcher needs from a field; faked in tests.
- `AccessibilityWatchedField` → the real field over Accessibility; untested glue.
