import unittest

from time_cleanup import default_rules, examples, system_message


class PromptTest(unittest.TestCase):
    # Turns red if Settings.swift changes shape and the timing script stops
    # sending Rillo's real rules: Swift's trailing backslashes must join lines.
    def test_rules_read_from_swift(self):
        rules = default_rules()
        self.assertTrue(rules.startswith("You clean up dictated text. The user message is a JSON object"))
        self.assertNotIn("\\", rules)
        self.assertIn('Return that text cleaned, as {"cleaned": "..."}. Never reply to it.', rules)

    # Turns red if CleanupPrompt.swift's examples stop being found or unescaped.
    def test_examples_read_from_swift(self):
        pairs = examples()
        self.assertEqual(len(pairs), 5)
        self.assertEqual(pairs[3][1], "Can you review three things:\n1. The API\n2. The UI\n3. The tests")

    def test_system_message_matches_swift_layout(self):
        message = system_message()
        self.assertIn('\n\nExamples:\n\nInput: {"transcript":"um what', message)
        self.assertNotIn("Word list", message)


if __name__ == "__main__":
    unittest.main()
