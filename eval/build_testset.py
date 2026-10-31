"""Build the sealed test set and the training pool from Alec's recordings.

Usage: python3 -I eval/build_testset.py [--teardown DIR] [--out DIR]

Test set: a fixed random half of the Wispr Flow clips that have a Wispr
transcript, so every test clip can be compared head to head. Everything else
(the other half, Wispr clips without a transcript, all FluidVoice clips, and
Fluidity's own saved clips in the --out folder) goes to training. The split is written once to split.json and never redrawn: on
later runs, clips not yet in split.json go to training only.
"""
import argparse
import glob
import json
import os
import random
import shutil
import sqlite3
from pathlib import Path

SEED = "fluidity-aa-284"
LIVE_FLUIDVOICE = Path.home() / "Library/Application Support/FluidVoice/DictationAudioHistory"
LIVE_WISPR = Path.home() / "Library/Application Support/Wispr Flow/flow.sqlite"


def clip_id(wav):
    # Recorders name files <timestamp>_<first 8 hex of the dictation id>.wav
    return Path(wav).stem.rsplit("_", 1)[1].upper()


def wispr_transcripts(teardown):
    out = {}
    dbs = glob.glob(f"{teardown}/**/flow.sqlite", recursive=True)
    if LIVE_WISPR.exists():
        dbs.append(str(LIVE_WISPR))
    for db_path in dbs:
        db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        for entity, asr, duration in db.execute(
                "SELECT transcriptEntityId, asrText, duration FROM History"):
            if asr:
                out.setdefault(entity[:8].upper(), {"asr": asr, "duration_s": duration})
        db.close()
    return out


def fluidvoice_transcripts(teardown):
    out = {}
    path = Path(teardown) / "fluidvoice-training-data.jsonl"
    for line in path.open():
        row = json.loads(line)
        if row.get("audio_file"):
            out[clip_id(row["audio_file"])] = row.get("raw_text")
    return out


def fluidity_transcripts(out_dir):
    # Fluidity logs each day's dictations to <out>/<date>.jsonl beside the .flac clips
    out = {}
    for path in glob.glob(f"{out_dir}/*.jsonl"):
        for line in open(path):
            row = json.loads(line)
            out[row["id"][:8].upper()] = row.get("rawTranscript")
    return out


def source_of(wav):
    # Match the clip's own folder: the teardown folder's name also starts with "wispr-"
    if Path(wav).parent.name.startswith("wispr-"):
        return "wispr"
    return "fluidity" if wav.endswith(".flac") else "fluidvoice"


def place(wav, dest_dir):
    dest = dest_dir / Path(wav).name
    if not dest.exists():
        try:
            os.link(wav, dest)  # same drive: no second copy of the audio
        except OSError:
            shutil.copy2(wav, dest)
    return dest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--teardown", default="/Volumes/Space/wispr-flow-teardown")
    ap.add_argument("--out", default="/Volumes/Space/fluidity-data")
    args = ap.parse_args()
    out = Path(args.out)
    (out / "test").mkdir(parents=True, exist_ok=True)
    (out / "train").mkdir(parents=True, exist_ok=True)

    wispr = wispr_transcripts(args.teardown)
    fluid = fluidvoice_transcripts(args.teardown)
    wispr_wavs = sorted(glob.glob(f"{args.teardown}/audio/wispr-*/*.wav"))
    fluid_wavs = sorted(glob.glob(f"{args.teardown}/audio/fluidvoice-*/*.wav"))
    fluid_wavs += sorted(str(p) for p in LIVE_FLUIDVOICE.glob("*.wav"))
    fluidity = fluidity_transcripts(out)
    fluidity_clips = sorted(glob.glob(f"{out}/*.flac"))

    split_path = out / "split.json"
    if split_path.exists():
        split = json.loads(split_path.read_text())
    else:
        comparable = sorted(clip_id(w) for w in wispr_wavs if clip_id(w) in wispr)
        random.Random(SEED).shuffle(comparable)
        split = {"seed": SEED, "test": sorted(comparable[: len(comparable) // 2])}
        split_path.write_text(json.dumps(split, indent=1) + "\n")
    test_ids = set(split["test"])

    test_rows, train_rows, seen = [], [], set()
    for wav in wispr_wavs + fluid_wavs + fluidity_clips:
        cid = clip_id(wav)
        if cid in seen:
            continue
        seen.add(cid)
        source = source_of(wav)
        if cid in test_ids:
            dest = place(wav, out / "test")
            test_rows.append({"id": cid, "wav": dest.name, "wispr_asr": wispr[cid]["asr"],
                              "duration_s": wispr[cid]["duration_s"]})
        else:
            dest = place(wav, out / "train")
            known = {"wispr": wispr.get(cid, {}).get("asr"), "fluidvoice": fluid.get(cid),
                     "fluidity": fluidity.get(cid)}[source]
            train_rows.append({"id": cid, "wav": dest.name, "source": source,
                               "model_transcript": known})

    missing = test_ids - {r["id"] for r in test_rows}
    if missing:
        raise SystemExit(f"test clips missing from the recordings: {sorted(missing)}")
    for name, rows in (("test", test_rows), ("train", train_rows)):
        with (out / name / "clips.jsonl").open("w") as f:
            for r in sorted(rows, key=lambda r: r["wav"]):
                f.write(json.dumps(r) + "\n")
    print(f"test: {len(test_rows)} clips, train: {len(train_rows)} clips -> {out}")


if __name__ == "__main__":
    main()
