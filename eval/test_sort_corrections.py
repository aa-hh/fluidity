import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path

from sort_corrections import DEFAULT_THRESHOLDS, load_thresholds, main, sort_dictation

TH = load_thresholds(DEFAULT_THRESHOLDS)
UUID = "a1b2c3d4-0000-4000-8000-{:012d}"


def rec(raw, final, cleaned=None, pasted=None, n=0):
    cleaned = raw if cleaned is None else cleaned
    return {"id": UUID.format(n), "startedAt": "2026-10-26T09:00:00Z", "app": "com.example.notes",
            "rawTranscript": raw, "cleanedText": cleaned,
            "pastedText": cleaned if pasted is None else pasted, "finalText": final,
            "wordTimings": [], "pasteLanded": True, "fallbackReason": None}


def cats(r, th=TH):
    return sorted(s["category"] for s in sort_dictation(r, th)["spans"])


def run_folder(records, thresholds=DEFAULT_THRESHOLDS):
    tmp = Path(tempfile.mkdtemp())
    (tmp / "data").mkdir()
    (tmp / "data" / "split.json").write_text("{}")
    (tmp / "data" / "train").mkdir()
    if records:
        (tmp / "data" / "2026-10-26.jsonl").write_text("".join(json.dumps(r) + "\n" for r in records))
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        main([str(tmp / "data"), "--out", str(tmp / "out"), "--thresholds", str(thresholds)])
    rows = {name: [json.loads(line) for line in (tmp / "out" / f"{name}.jsonl").read_text().splitlines()]
            for name in ("speech_to_text", "cleanup", "corrections")}
    return buf.getvalue(), rows


class CategoryTest(unittest.TestCase):
    # Turns red if smart quotes stop being normalised away as the app's own rewrite.
    def test_1_app_rewrite(self):
        self.assertEqual(cats(rec("the zebra’s fine", "the zebra's fine")), [1])

    # Turns red if additions before and after the pasted words stop being cut off before sorting the rest.
    def test_2_additions_cut_then_rest_sorted(self):
        self.assertEqual(cats(rec("Purple walrus", "Hi there. Purple walrus, thanks")), [2, 2, 4])

    # Turns red if a wiped or mostly replaced dictation stops counting as rejected.
    def test_3_wipe_and_replacement(self):
        self.assertEqual(cats(rec("purple walrus dances", "")), [3])
        self.assertEqual(cats(rec("purple walrus dances slowly", "green otter sings slowly")), [3])

    # Turns red if punctuation, case or an apostrophe stops being checked before the sound-alike rule.
    def test_4_punctuation_case_and_its(self):
        self.assertEqual(cats(rec("the walrus naps today", "The walrus naps, today.")), [4, 4])
        self.assertEqual(cats(rec("its walrus time now", "it's walrus time now")), [4])

    # Turns red if removing a filler the cleanup left in is sorted as a rewrite.
    def test_5_filler_and_stutter(self):
        self.assertEqual(cats(rec("so um we can start", "so we can start")), [5])
        self.assertEqual(cats(rec("the the walrus naps", "the walrus naps")), [5])

    # Turns red if restoring a word the cleanup changed stops being blamed on the cleanup.
    def test_6_user_restores_raw_word(self):
        r = rec("I'm gonna feed the walrus after lunch", "I'm gonna feed the walrus after lunch",
                cleaned="I'm going to feed the walrus after lunch")
        self.assertEqual(cats(r), [6])

    # Turns red if a word the cleanup invented and the user deleted is not blamed on the cleanup.
    def test_7_user_removes_cleanup_word(self):
        r = rec("send the walrus file", "send the walrus file", cleaned="send the final walrus file")
        self.assertEqual(cats(r), [7])

    # Turns red if a sound-alike swap of a speech-to-text word stops counting as misheard.
    def test_8_sound_alike_swap(self):
        self.assertEqual(cats(rec("meet me at the pier", "meet me at the peer")), [8])

    # Turns red if a swap that does not sound alike is let through as a misheard word.
    def test_9_non_sound_alike_swap(self):
        self.assertEqual(cats(rec("meet me at the pier", "meet me at the office")), [9])

    # Turns red if changing over 30% of the words stops marking the dictation as a rewrite.
    def test_9_too_much_changed(self):
        self.assertEqual(cats(rec("meet the walrus at noon", "meet the walrus at pier sometime soon")), [9])


class DictationTest(unittest.TestCase):
    # Turns red if a rewrite span lets the dictation into speech-to-text, or blocks its cleanup fixes.
    def test_rewrite_keeps_dictation_out_of_speech_but_not_cleanup(self):
        raw = "so um I want to book the pier for the walrus lunch on friday afternoon please"
        _, rows = run_folder([rec(raw, raw.replace("um ", "").replace("pier", "office"))])
        self.assertEqual(rows["speech_to_text"], [])
        self.assertEqual(rows["cleanup"][0]["target"], raw.replace("um ", ""))
        self.assertEqual([s["category"] for s in rows["corrections"][0]["spans"]], [5, 9])

    # Turns red if a wiped dictation's raw transcript goes into the speech-to-text set.
    def test_wiped_dictation_stays_out_of_speech(self):
        _, rows = run_folder([rec("purple walrus dances", "")])
        self.assertEqual(rows["speech_to_text"], [])
        self.assertEqual(rows["corrections"][0]["spans"][0]["category"], 3)

    # Turns red if the category-8 fix stops reaching the speech-to-text target.
    def test_misheard_fix_reaches_speech_target(self):
        _, rows = run_folder([rec("meet me at the pier", "meet me at the peer")])
        self.assertEqual(rows["speech_to_text"][0]["text"], "meet me at the peer")
        self.assertEqual(rows["cleanup"], [])

    # Turns red if the span-length threshold is read from code instead of the JSON file.
    def test_thresholds_file_drives_the_sort(self):
        r = rec("please send the draft to jon smith before noon tomorrow",
                "please send the draft to jan smyth before noon tomorrow")
        self.assertEqual(cats(r), [8])
        th = json.loads(DEFAULT_THRESHOLDS.read_text())
        th["max_span_words"] = 1
        path = Path(tempfile.mkdtemp()) / "th.json"
        path.write_text(json.dumps(th))
        self.assertEqual(cats(r, load_thresholds(path)), [9])

    # Turns red if a folder with no jsonl files errors or prints a non-zero count.
    def test_empty_folder_writes_empty_outputs(self):
        out, rows = run_folder([])
        self.assertEqual(rows, {"speech_to_text": [], "cleanup": [], "corrections": []})
        self.assertEqual({line.split()[-1] for line in out.splitlines()}, {"0"})

    # Turns red if any transcript text reaches the printed summary.
    def test_summary_holds_no_transcript_text(self):
        raw = "so um the zebra wants marmalade near the pier"
        out, _ = run_folder([rec(raw, raw.replace("pier", "peer"))])
        for word in raw.replace("um ", "").split() + ["peer"]:
            if len(word) > 3:
                self.assertNotIn(word, out.lower())


if __name__ == "__main__":
    unittest.main()
