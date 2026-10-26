"""Sort the user's corrections into AA-304's nine categories and build training data.

Usage: python3 -I eval/sort_corrections.py [DATA] --out DIR [--thresholds FILE]

Reads the app's daily YYYY-MM-DD.jsonl files in DATA (default
/Volumes/Space/fluidity-data). For each dictation it compares the raw
transcript (R), cleaned text (C), pasted text (P) and final text (F) word by
word, sorts every changed span into a category, and writes
speech_to_text.jsonl, cleanup.jsonl and corrections.jsonl to DIR. Prints only
counts: transcript text never reaches stdout, stderr or an exception.
"""
import argparse
import difflib
import json
import re
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))  # python3 -I leaves this folder off the path
from draft_refs import boundary_map  # noqa: E402

DEFAULT_DATA = "/Volumes/Space/fluidity-data"
DEFAULT_THRESHOLDS = Path(__file__).with_name("correction_thresholds.json")
TOKEN = re.compile(r"(?P<w>[^\W_]+(?:['-][^\W_]+)*)|[^\w\s]|_")
# Category 1 in version 1: the known app rewrites, normalised away before comparing.
REWRITES = str.maketrans({
    " ": " ", " ": " ", " ": " ",
    "​": None, "‌": None, "‍": None, "⁠": None, "﻿": None,
    "‘": "'", "’": "'", "‚": "'", "‛": "'",
    "“": '"', "”": '"', "„": '"', "‟": '"',
    "‐": "-", "‑": "-", "‒": "-", "–": "-", "—": "-", "―": "-",
})
COUNT_KEYS = [f"category {k}" for k in range(1, 10)] + [
    "not_pasted", "not_watched", "no_change", "speech_to_text_rows", "cleanup_rows"]


def normalise(s):
    s = unicodedata.normalize("NFC", s).replace("\r\n", "\n").replace("\r", "\n")
    return s.translate(REWRITES)


class Text:
    """A normalised text split into tokens, with its word layer."""

    def __init__(self, s):
        self.s = s
        matches = list(TOKEN.finditer(s))
        self.toks = [(m.group(), m.start(), m.end()) for m in matches]
        self.wpos = [k for k, m in enumerate(matches) if m.group("w")]
        self.words = [self.toks[k][0].lower() for k in self.wpos]

    def start(self, w):
        return self.toks[self.wpos[w]][1]

    def end(self, w):
        return self.toks[self.wpos[w]][2]

    def _unit_stop(self, w):
        return self.wpos[w + 1] if w + 1 < len(self.wpos) else len(self.toks)

    def unit_end(self, w):
        """End of word w plus the punctuation that follows it."""
        return self.toks[self._unit_stop(w) - 1][2]

    def unit(self, w):
        """Surface layer of word w: original case plus the punctuation after it."""
        return tuple(t[0] for t in self.toks[self.wpos[w]:self._unit_stop(w)])

    def between(self, w1, w2):
        return self.s[self.start(w1):self.end(w2 - 1)] if w1 < w2 else ""


def load_thresholds(path):
    th = json.loads(Path(path).read_text())
    th["fillers"] = {tuple(Text(f).words) for f in th["fillers"]}
    return th


def levenshtein(a, b):
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def similarity(old, new):
    a, b = " ".join(old), " ".join(new)
    return 1 - levenshtein(a, b) / max(len(a), len(b), 1)


def squash(words):
    return "".join(words).replace("'", "").replace("-", "")


def is_filler(words, fillers):
    if not words:
        return True
    return any(tuple(words[:len(f)]) == f and is_filler(words[len(f):], fillers) for f in fillers)


def repeats(old, p, i1, i2):
    # A stutter repeats the words beside it; a false start runs into a phrase starting the same way.
    return p[i2:i2 + len(old)] == old or p[max(0, i1 - len(old)):i1] == old or p[i2:i2 + 1] == old[:1]


def classify(old, new, rw, cw, p, i1, i2, th):
    """Category 4-9 for one P->F word span; rw and cw are the R and C words at the same place."""
    if squash(old) == squash(new):
        return 4
    if len(old) > th["max_span_words"] or len(new) > th["max_span_words"]:
        return 9
    if not new and old == cw and all(w in rw for w in old) and (
            is_filler(old, th["fillers"]) or repeats(old, p, i1, i2)):
        return 5
    if new and all(w in rw for w in new) and not any(w in cw for w in new):
        return 6
    # razor: character similarity only; add a phonetic code (Double Metaphone) to catch respellings.
    alike = bool(old and new) and similarity(old, new) >= th["min_similarity"]
    if old and not any(w in rw for w in old) and not alike:
        return 7
    if alike and old == rw == cw and not any(w in rw or w in cw for w in new):
        return 8
    return 9


def edit(t, w1, w2, new):
    """(start, end, replacement) that swaps t's words [w1, w2) for the text new."""
    n = len(t.words)
    if w1 == w2:
        if w1 < n:
            return t.start(w1), t.start(w1), new + " "
        return (t.unit_end(n - 1), t.unit_end(n - 1), " " + new) if n else (0, len(t.s), new)
    if new:
        return t.start(w1), t.end(w2 - 1), new
    if w2 < n:
        return t.start(w1), t.start(w2), ""
    return (t.unit_end(w1 - 1), t.unit_end(w2 - 1), "") if w1 else (0, len(t.s), "")


def apply(s, edits):
    last = len(s) + 1
    for a, b, new in sorted(edits, reverse=True):
        if b <= last:  # skip an edit that overlaps one already applied
            s, last = s[:a] + new + s[b:], a
    return s


def timing_map(r_words, timings):
    """R word index -> wordTimings index, for the words both agree on."""
    flat = [(w, k) for k, t in enumerate(timings) for w in Text(normalise(t["word"])).words]
    m = {}
    ops = difflib.SequenceMatcher(None, r_words, [w for w, _ in flat], autojunk=False).get_opcodes()
    for tag, a1, a2, b1, _ in ops:
        if tag == "equal":
            m.update((a1 + d, flat[b1 + d][1]) for d in range(a2 - a1))
    return m


def sort_dictation(rec, th):
    """Sort one dictation. None when the paste never landed."""
    if not rec.get("pasteLanded") or rec.get("pastedText") is None:
        return None
    fallback = rec.get("fallbackReason") is not None
    r = Text(normalise(rec["rawTranscript"]))
    cleaned = rec.get("cleanedText")
    c = Text(normalise(cleaned)) if cleaned is not None and not fallback else r
    p = Text(normalise(rec["pastedText"]))
    res = {"fallback": fallback, "watched": rec.get("finalText") is not None,
           "spans": [], "changedShare": None, "speech": r.s, "cleanup": None}
    if not res["watched"]:
        return res
    res["changedShare"] = 0.0
    f = Text(normalise(rec["finalText"]))
    pc, cr = boundary_map(p.words, c.words), boundary_map(c.words, r.words)
    timings = rec.get("wordTimings") or []
    tmap = timing_map(r.words, timings)
    off = 0
    spans = []

    def span(cat, i1, i2, j1, j2, surface=False):
        c1, c2 = pc[0][i1], pc[1][i2]
        r1, r2 = cr[0][c1], cr[1][c2]
        old, new = p.words[i1:i2], f.words[j1:j2]
        audio = r1 < r2 and r1 in tmap and r2 - 1 in tmap
        spans.append({
            "category": cat, "oldWords": old, "newWords": new,
            "similarity": round(similarity(old, new), 3) if old and new else None,
            "positions": {"R": [r1, r2], "C": [c1, c2], "P": [i1, i2], "F": [j1 + off, j2 + off]},
            "audioStart": timings[tmap[r1]]["start"] if audio else None,
            "audioEnd": timings[tmap[r2 - 1]]["end"] if audio else None,
            "_local": (i1, i2, j1, j2, surface), "_rw": r.words[r1:r2], "_cw": c.words[c1:c2],
        })
        return spans[-1]

    def finish():
        for s in spans:
            del s["_local"], s["_rw"], s["_cw"]
        res["spans"] = spans
        return res

    if p.s == f.s:
        if rec["pastedText"] != rec["finalText"]:
            span(1, 0, len(p.words), 0, len(f.words))
        return finish()

    n = len(p.words)
    if 0 < n < len(f.words):
        a = next((a for a in range(len(f.words) - n + 1) if f.words[a:a + n] == p.words), None)
        if a is not None:
            if a:
                span(2, 0, 0, 0, a)
            if a + n < len(f.words):
                span(2, n, n, a + n, len(f.words))
            f, off = Text(f.s[f.start(a):f.unit_end(a + n - 1)]), a

    ops = difflib.SequenceMatcher(None, p.words, f.words, autojunk=False).get_opcodes()
    kept = sum(i2 - i1 for tag, i1, i2, _, _ in ops if tag == "equal")
    if not f.words or (n and kept / n < th["min_survive_share"]):
        span(3, 0, n, 0, len(f.words))
        return finish()

    first = len(spans)
    changed = counted = 0
    for tag, i1, i2, j1, j2 in ops:
        if tag != "equal":
            s = span(0, i1, i2, j1, j2)
            s["category"] = classify(s["oldWords"], s["newWords"], s["_rw"], s["_cw"], p.words, i1, i2, th)
            if s["category"] != 4:
                changed, counted = changed + max(i2 - i1, j2 - j1), counted + 1
            continue
        k = 0
        while k < i2 - i1:
            if p.unit(i1 + k) == f.unit(j1 + k):
                k += 1
                continue
            e = k
            while e < i2 - i1 and p.unit(i1 + e) != f.unit(j1 + e):
                e += 1
            span(4, i1 + k, i1 + e, j1 + k, j1 + e, surface=True)
            k = e
    res["changedShare"] = round(changed / n, 3) if n else 0.0
    if res["changedShare"] > th["max_changed_share"] or counted > th["max_spans"]:
        for s in spans[first:]:
            s["category"] = 9
    spans[first:] = sorted(spans[first:], key=lambda s: s["positions"]["P"])

    cats = {s["category"] for s in spans}
    res["speech"] = None if 9 in cats else apply(r.s, [
        (r.start(s["positions"]["R"][0]), r.end(s["positions"]["R"][1] - 1),
         f.between(s["_local"][2], s["_local"][3]))
        for s in spans if s["category"] == 8])
    if cats & {4, 5, 6, 7}:
        edits = []
        for s in spans:
            if s["category"] not in (4, 5, 6, 7):
                continue
            i1, i2, j1, j2, surface = s["_local"]
            c1, c2 = s["positions"]["C"]
            if not surface:
                edits.append(edit(c, c1, c2, f.between(j1, j2)))
                continue
            for d in range(i2 - i1):
                cc = pc[0][i1 + d]
                if cc < len(c.words) and c.unit(cc) == p.unit(i1 + d):
                    edits.append((c.start(cc), c.unit_end(cc),
                                  f.s[f.start(j1 + d):f.unit_end(j1 + d)]))
        res["cleanup"] = apply(c.s, edits)
    return finish()


def find_audio(data, rid):
    hits = sorted(data.glob(f"*_{rid.replace('-', '')[:8].upper()}.flac"))
    return str(hits[0]) if hits else None


def run(data, out, th):
    """Sort every dictation in data, write the three outputs to out, return the counts."""
    counts = dict.fromkeys(COUNT_KEYS, 0)
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "speech_to_text.jsonl", "w") as speech, \
            open(out / "cleanup.jsonl", "w") as cleanup, \
            open(out / "corrections.jsonl", "w") as corrections:
        def write(fh, row):
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")

        for path in sorted(data.glob("*.jsonl")):
            for lineno, line in enumerate(path.read_text().splitlines(), 1):
                if not line.strip():
                    continue
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    raise SystemExit(f"{path.name}:{lineno}: not valid JSON") from None
                res = sort_dictation(rec, th)
                if res is None:
                    counts["not_pasted"] += 1
                    continue
                spans = res["spans"]
                if not res["watched"]:
                    counts["not_watched"] += 1
                elif not spans:
                    counts["no_change"] += 1
                for s in spans:
                    counts[f"category {s['category']}"] += 1
                write(corrections, {
                    "id": rec["id"], "app": rec.get("app"), "startedAt": rec["startedAt"],
                    "fallback": res["fallback"], "changedShare": res["changedShare"],
                    "spanCount": len(spans), "spans": spans})
                if res["speech"] is not None:
                    counts["speech_to_text_rows"] += 1
                    write(speech, {"id": rec["id"], "audio": find_audio(data, rec["id"]),
                                   "text": res["speech"], "watched": res["watched"]})
                if res["cleanup"] is not None:
                    counts["cleanup_rows"] += 1
                    write(cleanup, {"id": rec["id"], "input": normalise(rec["rawTranscript"]),
                                    "target": res["cleanup"]})
    return counts


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("data", nargs="?", default=DEFAULT_DATA)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--thresholds", default=DEFAULT_THRESHOLDS, type=Path)
    args = ap.parse_args(argv)
    data = Path(args.data)
    if not data.is_dir():
        raise SystemExit(f"no data folder at {data}")
    counts = run(data, args.out, load_thresholds(args.thresholds))
    for key in COUNT_KEYS:
        print(f"{key:<20} {counts[key]}")


if __name__ == "__main__":
    main()
