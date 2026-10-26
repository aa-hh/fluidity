# 0004. Save every dictation's audio and texts, and sort corrections later

Status: accepted

## Context

Version 1 exists partly to collect training data for retraining the speech model
(AA-272). Google found that training on every user edit "quickly and dramatically
degraded" its speech model; only edits filtered to likely misheard words were
safe (AA-304, arXiv 2310.00141). The retraining code (AA-284) reads audio and
JSONL from `/Volumes/Space/fluidity-data`, an encrypted external drive that can
be unmounted or locked. Edit thresholds are untested and will change.

## Decision

`DictationStore` writes one 16 kHz mono FLAC file and one JSONL line per
dictation to `/Volumes/Space/fluidity-data`. The line holds the raw transcript,
cleaned text, pasted text and final text, Parakeet word timings, the 500
characters before and after the cursor and the selected text at paste time, the
app, why watching stopped, timings per stage (transcription, word-list recheck,
cleanup, finishing, paste), model and word list versions, and any fallback
reason. While the drive is missing it writes to Application Support and moves the
files across on mount. Nothing is saved from secure text fields. `EditWatcher`
reads the field back through Accessibility as AA-297 specifies and records only
the final text; the app does not classify edits. A Python script in `eval/` sorts
corrections into AA-304's nine categories when training data is built, and any
dictation containing a rewrite stays out of speech-to-text training.

## Consequences

- Changing a threshold re-sorts every past dictation; nothing is lost to an early
  wrong rule.
- The text around the cursor can contain other people's words, so friends' data
  in version 2 needs the consent and review rules from AA-297.
- The store grows by roughly 0.35 GB a month of FLAC at Alec's volume.
- No correction feedback reaches the user in version 1.
