import json
import tempfile
import unittest
from pathlib import Path

from draft_refs import draft, word_confidences, words


def disputes(wispr, v2, v3, aai=None):
    hyps = {"v2": words(v2), "v3": words(v3)}
    if aai is not None:
        hyps["aai"] = words(aai)
    _, segments = draft(words(wispr), hyps)
    return [s for s in segments if not isinstance(s, str)]


class DraftTest(unittest.TestCase):
    # Turns red if boundary_map stops keeping the latest edge at an insertion:
    # a word only one model heard would then vanish instead of being marked.
    def test_word_only_one_model_heard_is_marked(self):
        (d,) = disputes("hello world", "hello there world", "hello world")
        self.assertEqual((d["wispr"], d["v2"], d["v3"]), ("", "there", ""))

    # Turns red if the draft stops taking the two-of-three answer.
    def test_majority_wins_and_is_marked(self):
        text, _ = draft(words("on Tuesday"), {"v2": words("on Tuesday"), "v3": words("on Wednesday")})
        self.assertEqual(text, ["on", "tuesday"])
        self.assertEqual(len(disputes("on Tuesday", "on Tuesday", "on Wednesday")), 1)

    # Turns red if a three-way split stops being flagged as having no majority.
    def test_three_way_split_has_no_majority(self):
        (d,) = disputes("at four", "at for", "at fore")
        self.assertFalse(d["majority"])
        self.assertEqual(d["chosen"], "four")

    # Turns red if AssemblyAI stops breaking a two-two tie.
    def test_assemblyai_breaks_a_tie(self):
        (d,) = disputes("at four", "at four", "at for", "at for")
        self.assertEqual((d["chosen"], d["majority"]), ("for", True))

    # Turns red if a four-way split stops taking AssemblyAI's version.
    def test_four_way_split_takes_assemblyai(self):
        (d,) = disputes("at four", "at for", "at fore", "at 4")
        self.assertEqual((d["chosen"], d["majority"]), ("4", False))


class ConfidenceTest(unittest.TestCase):
    # Turns red if one AssemblyAI word that normalises to several stops giving
    # each its confidence: every later word would take its neighbour's.
    def test_split_word_keeps_alignment(self):
        resp = {"text": "Version 3.5 now", "words": [
            {"text": "Version", "confidence": 0.9},
            {"text": "3.5", "confidence": 0.4},
            {"text": "now", "confidence": 0.8}]}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "t.json"
            path.write_text(json.dumps(resp))
            self.assertEqual(word_confidences(path), [0.9, 0.4, 0.4, 0.8])


if __name__ == "__main__":
    unittest.main()
