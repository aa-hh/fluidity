"""Transcribe the test clips with AssemblyAI's Universal-3.5 Pro, the fourth
voice draft_refs.py votes with.

Usage: ASSEMBLYAI_API_KEY=... python3 -I eval/transcribe_aai.py [--out DIR] [--limit N]

Uploads each clip, waits for its transcript, writes
test/transcripts/aai/<id>.json (the full response) and <id>.txt, then deletes
the transcript on AssemblyAI's side, which also deletes the uploaded audio.
Clips already transcribed are skipped, so a stopped run can resume. --limit
caps how many new clips are uploaded.
"""
import argparse
import json
import os
import time
import urllib.request
from pathlib import Path

API = "https://api.assemblyai.com/v2"


def call(method, path, key, body=None, content_type="application/json"):
    req = urllib.request.Request(API + path, data=body, method=method,
                                 headers={"authorization": key, "content-type": content_type})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.load(r)


def delete(transcript_id, key):
    # The recordings hold Alec's emails and messages; don't leave them on AssemblyAI.
    try:
        call("DELETE", f"/transcript/{transcript_id}", key)
    except Exception as e:
        print(f"transcribe_aai.py: could not delete transcript {transcript_id} ({e}); delete it by hand")


def transcribe(wav, key):
    """The finished transcript, completed or errored. The caller deletes it once saved."""
    url = call("POST", "/upload", key, wav.read_bytes(), "application/octet-stream")["upload_url"]
    # disfluencies keeps "um"s and "uh"s, which the references keep and AssemblyAI drops by default.
    body = json.dumps({"audio_url": url, "speech_models": ["universal-3-5-pro"], "disfluencies": True}).encode()
    t = call("POST", "/transcript", key, body)
    try:
        while t["status"] not in ("completed", "error"):
            time.sleep(3)
            t = call("GET", f"/transcript/{t['id']}", key)
    except BaseException:
        delete(t["id"], key)
        raise
    return t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/Volumes/Space/fluidity-data")
    ap.add_argument("--limit", type=int)
    args = ap.parse_args()
    key = os.environ.get("ASSEMBLYAI_API_KEY")
    if not key:
        raise SystemExit("transcribe_aai.py: set ASSEMBLYAI_API_KEY")
    test = Path(args.out) / "test"
    out = test / "transcripts" / "aai"
    out.mkdir(parents=True, exist_ok=True)
    sent = 0
    for line in (test / "clips.jsonl").open():
        clip = json.loads(line)
        if (out / f"{clip['id']}.json").exists():
            continue
        if args.limit is not None and sent >= args.limit:
            break
        sent += 1
        t = transcribe(test / clip["wav"], key)
        if t["status"] == "error":
            print(f"transcribe_aai.py: failed on {clip['wav']}: {t['error']}")
            delete(t["id"], key)
            continue
        try:
            (out / f"{clip['id']}.txt").write_text((t["text"] or "") + "\n")
            (out / f"{clip['id']}.json").write_text(json.dumps(t))
        except OSError:
            print(f"transcribe_aai.py: could not save {clip['id']}; transcript {t['id']} is still on AssemblyAI")
            raise
        delete(t["id"], key)
    print(f"aai: {len(list(out.glob('*.json')))} clips transcribed")


if __name__ == "__main__":
    main()
