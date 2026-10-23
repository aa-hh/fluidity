"""Draft word-for-word reference text for the test set, marking disagreements.

Usage: python3 -I eval/draft_refs.py [--out DIR]

Compares the transcripts of each clip: Wispr Flow's (from clips.jsonl),
Parakeet v2 and v3 (test/transcripts/<model>/<id>.txt, from transcribe.sh),
and AssemblyAI's where transcribe_aai.py has run on the clip. Where all agree
the words go straight into the draft. Where they differ, the draft takes the
most-voted version, AssemblyAI breaking ties, and the spot is marked for Alec
to check by ear. Writes test/references.draft.jsonl and test/review.html.
"""
import argparse
import difflib
import json
import re
from pathlib import Path

MODELS = ("v2", "v3")
OPTIONAL = ("aai",)  # AssemblyAI; votes only on clips transcribe_aai.py has done


def words(text):
    # Lowercase, keep apostrophes inside words, drop other punctuation.
    return re.findall(r"[a-z0-9]+(?:'[a-z0-9]+)*", text.lower())


def boundary_map(base, hyp):
    """For each boundary 0..len(base) in base, the (earliest, latest) matching
    boundary in hyp. They differ where hyp inserts words at that boundary, so a
    region starting there takes the earliest and one ending there the latest."""
    lo = [len(hyp)] * (len(base) + 1)
    hi = [0] * (len(base) + 1)
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, base, hyp, autojunk=False).get_opcodes():
        if tag == "equal":
            points = [(k, j1 + k - i1) for k in range(i1, i2 + 1)]
        else:
            points = [(i1, j1), (i2, j2)]
        for k, j in points:
            lo[k], hi[k] = min(lo[k], j), max(hi[k], j)
    return lo, hi


def diff_regions(base, hyp):
    sm = difflib.SequenceMatcher(None, base, hyp, autojunk=False)
    return [(i1, i2) for tag, i1, i2, _, _ in sm.get_opcodes() if tag != "equal"]


def merge(regions):
    out = []
    for a, b in sorted(regions):
        if out and a <= out[-1][1]:
            out[-1] = (out[-1][0], max(out[-1][1], b))
        else:
            out.append((a, b))
    return out


def draft(wispr, hyps):
    """Return (draft words, segments); a segment is a str (agreed) or a dispute dict."""
    maps = {m: boundary_map(wispr, h) for m, h in hyps.items()}
    regions = merge(r for h in hyps.values() for r in diff_regions(wispr, h))
    segments, pos = [], 0
    for a, b in regions:
        if pos < a:
            segments.append(" ".join(wispr[pos:a]))
        options = {"wispr": " ".join(wispr[a:b])}
        for m, h in hyps.items():
            lo, hi = maps[m]
            options[m] = " ".join(h[lo[a]:hi[b]])
        values = list(options.values())
        if len(set(values)) == 1:
            segments.append(values[0])
        else:
            top = max(map(values.count, values))
            leaders = [v for v in dict.fromkeys(values) if values.count(v) == top]
            if options.get("aai") in leaders:
                leaders = [options["aai"]]
            chosen = leaders[0] if len(leaders) == 1 else options["wispr"]
            at = {m: maps[m][0][a] for m in hyps}  # each model's word index where the spot starts
            to = {m: maps[m][1][b] for m in hyps}  # and where it ends
            segments.append({**options, "chosen": chosen, "majority": top >= 2, "at": at, "to": to})
        pos = b
    if pos < len(wispr):
        segments.append(" ".join(wispr[pos:]))
    text = " ".join(s if isinstance(s, str) else s["chosen"] for s in segments)
    return text.split(), segments


def word_starts(transcript_json):
    """Start time of each normalised word in a fluidaudiocli transcript, or None
    when its word timings don't line up with its text."""
    d = json.loads(transcript_json.read_text())
    starts = [t["startTime"] for t in d.get("wordTimings", []) for _ in words(t["word"])]
    return starts if len(starts) == len(words(d["text"])) else None


def word_confidences(transcript_json):
    """AssemblyAI's confidence for each normalised word, or None when its words
    don't line up with its text. One AssemblyAI word can normalise to several
    ("3.5" to "3", "5"), and each gets that word's confidence."""
    d = json.loads(transcript_json.read_text())
    confs = [w["confidence"] for w in d.get("words") or [] for _ in words(w["text"])]
    return confs if len(confs) == len(words(d["text"] or "")) else None


def segment_times(wispr, v2, segments, starts):
    """Start time of each word in the draft, laid out like segments: a list of
    times for an agreed segment, one time for a dispute. Agreed words are
    words v2 also heard, so their time is v2's time for that word."""
    lo, _ = boundary_map(wispr, v2)
    out, pos = [], 0
    for s in segments:
        if isinstance(s, str):
            n = len(s.split())
            out.append([starts[min(lo[k], len(starts) - 1)] for k in range(pos, pos + n)] if starts else [None] * n)
        else:
            n = len(s["wispr"].split())
            out.append(s["t"])
        pos += n
    return out


REVIEW_PAGE = Path(__file__).with_name("review_page.html")


def review_html(rows):
    data = [{"id": r["id"], "wav": r["wav"], "segments": r["segments"], "times": r["times"]} for r in rows]
    # Embedded as JSON and rendered by the page's script with textContent, so
    # transcript text never becomes markup. "</" is escaped to keep the
    # script element from closing early.
    return REVIEW_PAGE.read_text().replace("/*DATA*/[]", json.dumps(data).replace("</", "<\\/"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/Volumes/Space/fluidity-data")
    test = Path(ap.parse_args().out) / "test"
    rows = []
    for line in (test / "clips.jsonl").open():
        clip = json.loads(line)
        paths = {m: test / "transcripts" / m / f"{clip['id']}.txt" for m in MODELS}
        missing = [m for m, p in paths.items() if not p.exists()]
        if missing:
            # transcribe.sh skips a clip the CLI failed on; rerun it to fill the gap.
            print(f"skipped {clip['id']}: no {', '.join(missing)} transcript")
            continue
        paths.update((m, p) for m in OPTIONAL if (p := test / "transcripts" / m / f"{clip['id']}.txt").exists())
        hyps = {m: words(p.read_text()) for m, p in paths.items()}
        wispr = words(clip["wispr_asr"])
        text, segments = draft(wispr, hyps)
        disputes = [s for s in segments if not isinstance(s, str)]
        starts = word_starts(test / "transcripts" / "v2" / f"{clip['id']}.json")
        confs = word_confidences(test / "transcripts" / "aai" / f"{clip['id']}.json") if "aai" in hyps else None
        for d in disputes:
            d["t"] = starts[min(d["at"]["v2"], len(starts) - 1)] if starts else None
            if confs:
                # AssemblyAI's least sure word in the spot; None where it heard nothing there.
                span = confs[d["at"]["aai"]:d["to"]["aai"]]
                d["aai_conf"] = round(min(span), 2) if span else None
        rows.append({"id": clip["id"], "wav": clip["wav"], "draft": " ".join(text),
                     "disputes": disputes, "segments": segments,
                     "times": segment_times(wispr, hyps["v2"], segments, starts)})
    with (test / "references.draft.jsonl").open("w") as f:
        for r in rows:
            f.write(json.dumps({k: r[k] for k in ("id", "wav", "draft", "disputes")}) + "\n")
    (test / "review.html").write_text(review_html(rows))
    total = sum(len(r["disputes"]) for r in rows)
    nomaj = sum(not d["majority"] for r in rows for d in r["disputes"])
    clean = sum(not r["disputes"] for r in rows)
    print(f"{len(rows)} clips: {clean} with no disagreement, {total} marked spots ({nomaj} with no majority)")


if __name__ == "__main__":
    main()
