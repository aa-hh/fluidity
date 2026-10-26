import unittest

from draft_refs import draft, words


def disputes(wispr, v2, v3):
    _, segments = draft(words(wispr), {"v2": words(v2), "v3": words(v3)})
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


if __name__ == "__main__":
    unittest.main()
