"""Score each speech model's test transcripts against a reference.

Usage: python3 -I eval/score.py [--out DIR] [--ref MODEL|reviewed] [models...]

The reference is another model's transcripts (default aai, AssemblyAI) or
"reviewed", Alec's checked text in test/references.reviewed.jsonl. Wispr's text
from clips.jsonl scores as "wispr". Only misheard real words count: fillers,
words repeated back to back and American/British spelling differences are
removed from both sides first, because cleanup handles those.
"""
import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))  # python3 -I leaves this folder off the path
from draft_refs import words  # noqa: E402

FILLERS = {"um", "uh", "uhm", "erm", "er", "ah", "hmm", "mm", "mhm"}
# British -> American for words the -ise rule below can't catch.
SPELLING = {"colour": "color", "colours": "colors", "favour": "favor", "favourite": "favorite",
            "behaviour": "behavior", "honour": "honor", "labour": "labor", "neighbour": "neighbor",
            "centre": "center", "centres": "centers", "metre": "meter", "litre": "liter",
            "theatre": "theater", "fibre": "fiber", "catalogue": "catalog", "dialogue": "dialog",
            "travelled": "traveled", "travelling": "traveling", "cancelled": "canceled",
            "cancelling": "canceling", "modelling": "modeling", "labelled": "labeled",
            "labelling": "labeling", "licence": "license", "defence": "defense", "grey": "gray",
            "programme": "program", "programmes": "programs", "judgement": "judgment"}
# Words that end in -ise in American English too.
ISE_WORDS = {"advertise", "advise", "arise", "chastise", "comprise", "compromise", "concise",
             "demise", "despise", "devise", "disguise", "enterprise", "exercise", "expertise",
             "franchise", "improvise", "likewise", "merchandise", "noise", "otherwise", "praise",
             "precise", "premise", "promise", "raise", "revise", "rise", "supervise", "surprise",
             "televise", "wise", "cruise", "bruise", "poise", "paradise", "treatise"}
ISE = re.compile(r"^(\w{2,})(is|ys)(e|es|ed|ing|ation|ations)$")


def american(w):
    if w in SPELLING:
        return SPELLING[w]
    m = ISE.match(w)
    if m and not any(w.startswith(x[:-1]) for x in ISE_WORDS):
        return m[1] + ("iz" if m[2] == "is" else "yz") + m[3]
    return w


def normalise(text):
    out = []
    for w in (american(w) for w in words(text) if w not in FILLERS):
        if not out or out[-1] != w:
            out.append(w)
    return out


def errors(ref, hyp):
    """Word edit distance: substituted, dropped and added words."""
    prev = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, 1):
        cur = [i]
        for j, h in enumerate(hyp, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (r != h)))
        prev = cur
    return prev[-1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="/Volumes/Space/fluidity-data")
    ap.add_argument("--ref", default="aai")
    ap.add_argument("models", nargs="*",
                    default=["wispr", "v2", "v3", "ultra", "nemotron-en", "nemotron-ml", "whisper-turbo"])
    args = ap.parse_args()
    test = Path(args.out) / "test"
    clips = [json.loads(line) for line in (test / "clips.jsonl").open()]

    def text(model, clip):
        if model == "wispr":
            return clip["wispr_asr"]
        p = test / "transcripts" / model / f"{clip['id']}.txt"
        return p.read_text() if p.exists() else None

    if args.ref == "reviewed":
        reviewed = {json.loads(line)["id"]: json.loads(line)["reference"]
                    for line in (test / "references.reviewed.jsonl").open()}
        refs = {c["id"]: reviewed.get(c["id"]) for c in clips}
    else:
        refs = {c["id"]: text(args.ref, c) for c in clips}
    refs = {k: normalise(v) for k, v in refs.items() if v}
    # Score every model on the same clips: those with a reference and every model's text.
    shared = [c for c in clips if c["id"] in refs and all(text(m, c) is not None for m in args.models)]
    total = sum(len(refs[c["id"]]) for c in shared)
    print(f"reference {args.ref}: {len(shared)} clips, {total} words")
    rows = []
    for m in args.models:
        e = sum(errors(refs[c["id"]], normalise(text(m, c))) for c in shared)
        rows.append((e / total if total else 0, e, m))
    for rate, e, m in sorted(rows):
        print(f"{m:15} {rate:6.1%}  ({e} errors)")


if __name__ == "__main__":
    main()
