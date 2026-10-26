"""Build the sealed test set and the training pool from Alec's recordings.

Usage: python3 -I eval/build_testset.py [--teardown DIR] [--out DIR]

Test set: a fixed random half of the Wispr Flow clips that have a Wispr
transcript, so every test clip can be compared head to head. Everything else
(the other half, Wispr clips without a transcript, all FluidVoice clips) goes
to training. The split is written once to split.json and never redrawn: on
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


def clip_id(wav):
    # Recorders name files <timestamp>_<first 8 hex of the dictation id>.wav
    return Path(wav).stem.rsplit("_", 1)[1].upper()


def wispr_transcripts(teardown):
    out = {}
    for db_path in glob.glob(f"{teardown}/**/flow.sqlite", recursive=True):
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


def place(wav, dest_dir):
    dest = dest_dir / Path(wav).name
    if not dest.exists():
        try:
            os.link(wav, dest)  # same drive: no second copy of the audio
        except OSError:
            shutil.copy2(wav, dest)
    return dest


def load_or_draw_split(split_path, comparable_ids):
    """The test ids: read from split_path if it exists, else drawn once from
    comparable_ids and written there. Never redrawn."""
    if split_path.exists():
        return set(json.loads(split_path.read_text())["test"])
    ids = sorted(comparable_ids)
    random.Random(SEED).shuffle(ids)
    split = {"seed": SEED, "test": sorted(ids[: len(ids) // 2])}
    split_path.write_text(json.dumps(split, indent=1) + "\n")
    return set(split["test"])


def route(wispr_wavs, fluid_wavs, wispr, fluid, test_ids):
    """Yield (set name, wav path, row) for every clip, once per clip id. The
    source comes from which list a clip is in, never from its path: the data
    drive's own folder is named wispr-flow-teardown."""
    seen = set()
    for source, wavs in (("wispr", wispr_wavs), ("fluidvoice", fluid_wavs)):
        for wav in wavs:
            cid = clip_id(wav)
            if cid in seen:
                continue
            seen.add(cid)
            if source == "wispr" and cid in test_ids:
                yield "test", wav, {"id": cid, "wispr_asr": wispr[cid]["asr"],
                                    "duration_s": wispr[cid]["duration_s"]}
            else:
                known = wispr.get(cid, {}).get("asr") if source == "wispr" else fluid.get(cid)
                yield "train", wav, {"id": cid, "source": source, "model_transcript": known}


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

    comparable = [clip_id(w) for w in wispr_wavs if clip_id(w) in wispr]
    test_ids = load_or_draw_split(out / "split.json", comparable)

    rows = {"test": [], "train": []}
    for name, wav, row in route(wispr_wavs, fluid_wavs, wispr, fluid, test_ids):
        rows[name].append({**row, "wav": place(wav, out / name).name})

    missing = test_ids - {r["id"] for r in rows["test"]}
    if missing:
        raise SystemExit(f"test clips missing from the recordings: {sorted(missing)}")
    for name, rs in rows.items():
        with (out / name / "clips.jsonl").open("w") as f:
            for r in sorted(rs, key=lambda r: r["wav"]):
                f.write(json.dumps(r) + "\n")
    print(f"test: {len(rows['test'])} clips, train: {len(rows['train'])} clips -> {out}")


if __name__ == "__main__":
    main()
