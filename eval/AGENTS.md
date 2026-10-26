# eval

## Purpose

Scripts that turn Alec's recordings into a sealed test set and a training
pool, run speech models over the test set, and draft reference text for
scoring. The scripts live here; the data never does.

## Rules

- **Recordings and transcripts never enter git.** They hold Alec's emails and
  messages and this repo is on GitHub. Data lives under
  `/Volumes/Space/fluidity-data/`; scripts take the folder as an argument.
- **The test split is drawn once and never redrawn.** `split.json` on the data
  drive is the record. Deleting it and rerunning reshuffles which clips are
  test, and any model already trained on the old training pool has seen test
  clips, so every later score is meaningless.
- **Test clips never become training data**, including after their reference
  text is corrected. New recordings always go to training.
- **Score only against references Alec has checked by ear.** A draft
  reference is model output, and scoring a model against it measures
  agreement, not accuracy.
- Runs happen on this Mac: the mule cannot see the `Space` drive.

## Map

- `build_testset.py` → exports clips, draws or reuses the split.
- `transcribe.sh` → runs each Parakeet model over the test clips.
- `draft_refs.py` → majority-vote draft references, disagreements marked.
- `test_draft_refs.py` → regression tests for the draft alignment.
- `test_build_testset.py` → tests that the split holds and clips route by source.
