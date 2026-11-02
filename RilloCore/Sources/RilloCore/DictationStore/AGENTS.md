# DictationStore

## Purpose

Saves each dictation's audio and record for training the speech model, on the
Space drive, holding them in Application Support while the drive is missing.
It never decides whether a dictation should be saved: secure fields are
skipped by the caller.

## Rules

- **Never create the drive root.** An unmounted volume leaves its path free,
  so creating it would quietly put training data on the startup disk, where
  the training scripts never look. Only the holding folder is created.
- **A held line replaces the drive line with the same id.** That is what makes
  a repeated move duplicate nothing, and it is how a final text written while
  the drive was missing reaches the drive. Appending held lines blindly would
  break both.
- **An update must change every copy of a line,** on the drive and held,
  because an interrupted move can leave both and the next move copies the held
  one over the drive's.
- **Keep the file names as the recordings already on the drive are:** the
  training scripts read the clip id as the uppercase text after the last `_`.
- **The history file only feeds the popover.** A failure writing it never
  fails a save, so the caller never saves a dictation twice.

## Map

- `DictationStore` → writes FLAC and day files, moves held ones, keeps the history.
- `MountObserving` → mount events the store moves held dictations on.
- `WorkspaceMountObserver` → mount events from `NSWorkspace`.
- `DictationStoreError` → why a save, update or move failed.
