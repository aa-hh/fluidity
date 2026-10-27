# ModelCoordinator

## Purpose

Decides which engine dictation uses and when each engine is loaded or
unloaded, for dictation and for the compare window. It lives outside the app
target so those decisions are tested with fakes. It never picks a model on
its own, except the launch fallback when the chosen one is gone.

## Rules

- **An engine is unloaded only when nothing needs it:** not the model
  dictating, not the chosen one, not a compare column. Dictation and the
  compare columns share engine instances, so unloading one still in use makes
  its next pass fail.
- **Closing the compare window unloads only after its discard ends.** A final
  pass may still run on an engine dictation shares; the next dictation waits
  on `waitForClosedCompare` for the same reason.
- **A compare column counts as loaded only when its load succeeded.** A failed
  one keeps the comparison from starting, by the key or by Speak Now.
- **The in-use set reaches `ModelDownloads`,** which refuses to delete or
  download those models.
- **The coordinator owns the launch steps** (voice detector, word check,
  speech model) and their order, so a step reported to the pill is one the
  user waits for.

## Map

- `ModelCoordinator` → launch choice, switching, compare loads and unloads.
- `ModelLoadProgress` → which launch load is running, and its download.
- `LoadingGrid` → when each of the pill's 32 loading squares lights.
