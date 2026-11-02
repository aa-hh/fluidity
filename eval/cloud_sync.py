"""Copy saved dictations to Cloudflare: records to D1, recordings to R2 (AA-461).

Usage: python3 -I eval/cloud_sync.py [--data DIR] [--dry-run]

Reads the day files (*.jsonl) and their FLAC recordings in the data folder,
writes each new or changed record into the D1 database by id, and uploads each
recording not yet in the R2 bucket. What was sent is kept in
.cloud-sync-state.json in the data folder, so a run sends only what changed.
Uses Wrangler's saved login (`npx wrangler login`). dev/install-cloud-sync.sh
runs this every three hours.
"""
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

DATA = Path("/Volumes/Space/rillo-data")
NAME = "rillo-dictations"  # both the D1 database and the R2 bucket
WRANGLER = ["npx", "-y", "wrangler@4.156.1"]
STATE = ".cloud-sync-state.json"
# razor: D1 refuses a statement over 100 KB; records peak at 25 KB today. If one
# outgrows it, store the record itself in R2 and keep only its key in D1.
MAX_STATEMENT = 100_000
SCHEMA = ("CREATE TABLE IF NOT EXISTS dictations "
          "(id TEXT PRIMARY KEY, started_at TEXT, audio_key TEXT, record TEXT NOT NULL);")


def read_records(data):
    """Each record by id, the last line winning. A line the app is still writing is skipped."""
    records = {}
    for day in sorted(data.glob("*.jsonl")):
        for line in day.read_text(encoding="utf-8").splitlines():
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(r, dict) and r.get("id"):
                records[r["id"]] = r
    return records


def recordings(data):
    """Recording file names by clip id, the uppercase text after the last `_`."""
    return {p.stem.rsplit("_", 1)[-1]: p.name for p in data.glob("*.flac")}


def sql_text(v):
    return "NULL" if v is None else "'" + v.replace("'", "''") + "'"


def upsert(record, audio_key):
    # json.dumps escapes control characters, so the literal never holds a raw NUL.
    body = json.dumps(record, sort_keys=True, ensure_ascii=False)
    values = ", ".join(sql_text(v) for v in (record["id"], record.get("startedAt"), audio_key, body))
    return (f"INSERT INTO dictations (id, started_at, audio_key, record) VALUES ({values}) "
            "ON CONFLICT(id) DO UPDATE SET started_at = excluded.started_at, "
            "audio_key = excluded.audio_key, record = excluded.record;")


def changed_rows(records, clips, sent):
    """(id, digest, statement) for each record whose row differs from the one last sent."""
    rows = []
    for rid, record in records.items():
        stmt = upsert(record, clips.get(rid[:8].upper()))
        digest = hashlib.sha256(stmt.encode()).hexdigest()
        if sent.get(rid) != digest:
            rows.append((rid, digest, stmt))
    return rows


def wrangler(*args, cwd):
    subprocess.run([*WRANGLER, *args], cwd=cwd, check=True)


def save(path, state):
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=1))
    tmp.replace(path)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--data", type=Path, default=DATA)
    ap.add_argument("--dry-run", action="store_true", help="count what would be sent, send nothing")
    args = ap.parse_args(argv)

    # An unmounted drive leaves no folder: skip rather than create one.
    if not args.data.is_dir():
        print(f"{args.data} not found (drive not mounted?); nothing sent")
        return 0
    state_path = args.data / STATE
    state = json.loads(state_path.read_text()) if state_path.exists() else {"records": {}, "audio": []}

    clips = recordings(args.data)
    rows = changed_rows(read_records(args.data), clips, state["records"])
    too_big = [r for r in rows if len(r[2].encode()) > MAX_STATEMENT]
    rows = [r for r in rows if r not in too_big]
    for rid, _, _ in too_big:
        print(f"record {rid} is over D1's 100 KB statement limit; not sent", file=sys.stderr)
    sent_audio = set(state["audio"])
    new_audio = sorted(n for n in clips.values() if n not in sent_audio)
    print(f"{len(rows)} records and {len(new_audio)} recordings to send")
    if args.dry_run:
        return 0

    with tempfile.TemporaryDirectory() as tmp:
        if rows:
            sql = Path(tmp, "rows.sql")
            sql.write_text("\n".join([SCHEMA, *(stmt for _, _, stmt in rows)]), encoding="utf-8")
            wrangler("d1", "execute", NAME, "--remote", "--yes", f"--file={sql}", cwd=tmp)
            state["records"].update({rid: digest for rid, digest, _ in rows})
            save(state_path, state)
        if new_audio:
            pairs = Path(tmp, "audio.json")
            pairs.write_text(json.dumps([{"key": n, "file": str(args.data / n)} for n in new_audio]))
            wrangler("r2", "bulk", "put", NAME, "--remote", "--content-type=audio/flac",
                     f"--filename={pairs}", cwd=tmp)
            state["audio"] = sorted(sent_audio | set(new_audio))
            save(state_path, state)
    return 1 if too_big else 0


if __name__ == "__main__":
    sys.exit(main())
