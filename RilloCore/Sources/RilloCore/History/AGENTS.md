# History

## Purpose

What the History page keeps for the user: every dictation with a transcript,
its recording when Save recordings is on, and the retention rules that
delete them. Kept apart from the training data `DictationStore` writes;
nothing here reads or deletes that.

## Rules

- **`history.json` must keep reading files written as a plain list of
  records.** `HistoryItem` encodes its extra fields flat beside the record's
  keys for that reason; wrapping the record would empty every user's history.
- **Deleting a dictation deletes its recording,** in every path: a single
  delete, Delete All and a retention purge.
- **A shortened period never deletes what the user chose to keep.** Items
  started before an `exemptBefore` date stay until the user deletes them;
  lengthening a period keeps that date, or a purge would delete them.
- **Keep recordings is never longer than Keep history.** A recording with no
  dictation has nowhere to show.
- **Turning Save recordings off deletes nothing.** Saved recordings run out
  at their Keep recordings period.

## Map

- `HistoryStore` → the dictations, their recordings, deletes, purges, space used.
- `Retention`, `RetentionRules` → the periods and the Keep or Delete choice.
- `HistoryComparison` → raw transcript beside pasted text, one sentence per row.
