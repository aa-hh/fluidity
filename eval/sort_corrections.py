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


def gap(t, w1, w2, first=False, last=False):
    """Character range of words [w1, w2) plus the spaces and punctuation between them and their
    neighbours. With first it starts at word w1; with last, or at the end of t, it stops after
    the punctuation of word w2 - 1. Either way it leaves out the spaces outside."""
    a = t.start(w1) if first and w1 < len(t.words) else (t.end(w1 - 1) if w1 else 0)
    if w2 < len(t.words) and not last:
        return a, t.start(w2)
    return a, (t.unit_end(w2 - 1) if w2 else 0)


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
    spans = []

    def span(cat, i1, i2, j1, j2, surface=False):
        c1, c2 = pc[0][i1], pc[1][i2]
        # A boundary inside a replaced stretch of C has no R match; widen to the stretch's edges.
        a, b = c1, c2
        while cr[0][a] > cr[1][a]:
            a -= 1
        while cr[0][b] > cr[1][b]:
            b += 1
        # Inner boundaries, so words the cleanup dropped beside the span stay out of it.
        r1, r2 = (cr[1][a], cr[0][b]) if a < b else (cr[0][a], cr[1][b])
        old, new = p.words[i1:i2], f.words[j1:j2]
        audio = r1 < r2 and r1 in tmap and r2 - 1 in tmap
        spans.append({
            "category": cat, "oldWords": old, "newWords": new,
            "similarity": round(similarity(old, new), 3) if old and new else None,
            "positions": {"R": [r1, r2], "C": [c1, c2], "P": [i1, i2], "F": [j1, j2]},
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
    ops = []
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, p.words, f.words, autojunk=False).get_opcodes():
        extra = (j2 - j1) - (i2 - i1)
        # The matcher merges a fix at either end with words typed beside it; split the typed words
        # off, unless they are R's own words (then the whole replace is the user restoring R).
        if tag == "replace" and extra > 0 and i1 == 0 and not set(f.words[:extra]) & set(r.words):
            ops += [("insert", 0, 0, 0, extra), ("replace", 0, i2, extra, j2)]
        elif tag == "replace" and extra > 0 and i2 == n and not set(f.words[j2 - extra:j2]) & set(r.words):
            ops += [("replace", i1, i2, j1, j2 - extra), ("insert", n, n, j2 - extra, j2)]
        else:
            ops.append((tag, i1, i2, j1, j2))
    kept = sum(i2 - i1 for tag, i1, i2, _, _ in ops if tag == "equal")
    if not f.words or (n and kept / n < th["min_survive_share"]):
        res["changedShare"] = round(1 - kept / n, 3) if n else 1.0
        span(3, 0, n, 0, len(f.words))
        res["speech"] = None  # the user rejected this transcript, so nothing confirms it
        return finish()

    changed = counted = 0
    word_spans = {}
    for idx, (tag, i1, i2, j1, j2) in enumerate(ops):
        if tag == "equal":
            continue
        s = word_spans[idx] = span(0, i1, i2, j1, j2)
        # Words added before or after the pasted text, unless they are R's words the cleanup dropped there.
        if tag == "insert" and i1 in (0, n) and s["newWords"] != s["_rw"]:
            s["category"] = 2
            continue
        s["category"] = classify(s["oldWords"], s["newWords"], s["_rw"], s["_cw"], p.words, i1, i2, th)
        if s["category"] != 4:
            changed, counted = changed + max(i2 - i1, j2 - j1), counted + 1
    res["changedShare"] = round(changed / n, 3) if n else 0.0
    rewrite = res["changedShare"] > th["max_changed_share"] or counted > th["max_spans"]
    if rewrite:
        for s in spans:
            if s["category"] != 2:
                s["category"] = 9

    for idx, (tag, i1, i2, j1, j2) in enumerate(ops):
        if tag != "equal":
            continue
        # When the next span is applied as a cleanup edit, that edit carries the punctuation after
        # this block's last word; otherwise the punctuation is checked here.
        nxt = word_spans.get(idx + 1)
        trim = nxt is not None and nxt["category"] in (4, 5, 6, 7)

        def differs(d):
            if trim and d == i2 - i1 - 1:
                return p.toks[p.wpos[i1 + d]][0] != f.toks[f.wpos[j1 + d]][0]
            return p.unit(i1 + d) != f.unit(j1 + d)

        k = 0
        while k < i2 - i1:
            if not differs(k):
                k += 1
                continue
            e = k
            while e < i2 - i1 and differs(e):
                e += 1
            span(9 if rewrite else 4, i1 + k, i1 + e, j1 + k, j1 + e,
                 surface="trim" if trim and e == i2 - i1 else "units")
            k = e
    spans.sort(key=lambda s: s["positions"]["P"])

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
                (a, b), (fa, fb) = gap(c, c1, c2), gap(f, j1, j2, c1 == 0, c2 == len(c.words))
                edits.append((a, b, f.s[fa:fb]))
                continue
            for d in range(i2 - i1):
                cc = pc[0][i1 + d]
                if cc >= len(c.words):
                    continue
                if surface == "trim" and d == i2 - i1 - 1:  # the word only; its punctuation is the next span's
                    if c.toks[c.wpos[cc]][0] == p.toks[p.wpos[i1 + d]][0]:
                        edits.append((c.start(cc), c.end(cc), f.toks[f.wpos[j1 + d]][0]))
                elif c.unit(cc) == p.unit(i1 + d):
                    edits.append((c.start(cc), c.unit_end(cc), f.s[f.start(j1 + d):f.unit_end(j1 + d)]))
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
