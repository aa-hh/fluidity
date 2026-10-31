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
  drive is the record; redrawing lets trained models see test clips.
- **Test clips never become training data**, even once corrected.
- **AssemblyAI's transcripts are the answer key** (`score.py --ref aai`);
  `--ref reviewed` uses Alec's checked clips to spot-check it. Never score
  against a majority-vote draft: that measures agreement, not accuracy.
- **Only misheard real words count.** `score.py` strips fillers, repeats and
  American/British spelling from both sides; cleanup handles those.
- **Clips leave this Mac only with Alec's yes** (AssemblyAI uploads, copies
  to the mule, which cannot see the `Space` drive).
- **Correction thresholds live in `correction_thresholds.json`, never in
  code**, so changing one re-sorts every past dictation.

## Map

- `build_testset.py` → exports clips, draws or reuses the split.
- `transcribe.sh` → runs each speech model over the test clips.
- `draft_refs.py` → majority-vote draft references, disagreements marked.
- `review_page.html` → template for the page where Alec settles each mark.
- `score.py` → each model's share of real words wrong.
- `sort_corrections.py` → sorts user edits into categories, writes training rows.
- `test_*.py` → tests for the script of the same name.
