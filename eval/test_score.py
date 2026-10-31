import unittest

from score import errors, normalise


class ScoreTest(unittest.TestCase):
    # Turns red if a dropped filler or stutter starts counting against a model.
    def test_fillers_and_repeats_are_free(self):
        self.assertEqual(errors(normalise("um so the the order uh shipped"), normalise("So the order shipped.")), 0)

    # Turns red if British spelling stops matching the models' American spelling.
    def test_british_spelling_matches_american(self):
        self.assertEqual(normalise("the colour was analysed, organisation-wide"),
                         normalise("the color was analyzed, organization-wide"))

    # Turns red if the -ise rule starts rewriting words that end in -ise in American English too.
    def test_real_ise_words_are_left_alone(self):
        self.assertEqual(normalise("otherwise a surprise exercise"), ["otherwise", "a", "surprise", "exercise"])

    # Turns red if a misheard, dropped or added real word stops counting.
    def test_real_word_errors_count(self):
        self.assertEqual(errors(normalise("ship it on tuesday"), normalise("ship it on wednesday thank you")), 3)


if __name__ == "__main__":
    unittest.main()
