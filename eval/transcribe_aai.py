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


def transcribe(wav, key):
    url = call("POST", "/upload", key, wav.read_bytes(), "application/octet-stream")["upload_url"]
    body = json.dumps({"audio_url": url, "speech_models": ["universal-3-5-pro"]}).encode()
    t = call("POST", "/transcript", key, body)
    try:
        while t["status"] not in ("completed", "error"):
            time.sleep(3)
            t = call("GET", f"/transcript/{t['id']}", key)
    finally:
        # The recordings hold Alec's emails and messages; don't leave them on AssemblyAI.
        try:
            call("DELETE", f"/transcript/{t['id']}", key)
        except Exception as e:
            print(f"transcribe_aai.py: could not delete transcript {t['id']} ({e}); delete it by hand")
    if t["status"] == "error":
        raise RuntimeError(t["error"])
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
        try:
            t = transcribe(test / clip["wav"], key)
        except RuntimeError as e:
            print(f"transcribe_aai.py: failed on {clip['wav']}: {e}")
            continue
        (out / f"{clip['id']}.txt").write_text((t["text"] or "") + "\n")
        (out / f"{clip['id']}.json").write_text(json.dumps(t))
    print(f"aai: {len(list(out.glob('*.json')))} clips transcribed")


if __name__ == "__main__":
    main()
