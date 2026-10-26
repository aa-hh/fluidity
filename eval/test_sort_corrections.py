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

    # Turns red if additions before and after the pasted words stop being cut off before sorting the rest,
    # or if punctuation typed with an addition counts as a fix.
    def test_2_additions_cut_then_rest_sorted(self):
        self.assertEqual(cats(rec("Purple walrus", "Hi there. Purple walrus, thanks")), [2, 2])
        self.assertEqual(cats(rec("Purple walrus", "Hi there. purple walrus thanks")), [2, 2, 4])

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



LONG = "meet me at the pier then walk to the bear den and feed the deer near the boat"
TWENTY = "meet me at the pier then walk to the bear den and feed the deer near the sail boat now"
# Every dictation a pull-request review found mishandled. raw, final, cleaned (None: same as raw), pasted,
# the sorted categories, then optional checks: speech or cleanup output (None: no row),
# share_above (changedShare must exceed it), raw_in_range (every span's R positions ordered and in R).
REVIEW_CASES = [
    # a filler the cleanup dropped beside the fixed word stays out of its raw words
    dict(raw="um meet me at the pier", cleaned="meet me at the pier", final="meat me at the pier",
         cats=[8], speech="um meat me at the pier"),
    dict(raw="meet me at the pier um", cleaned="meet me at the pier", final="meet me at the peer",
         cats=[8], speech="meet me at the peer um"),
    # a span inside a phrase the cleanup rewrote reads its R positions from that phrase's edges
    dict(raw="I'm gonna feed the walrus after lunch", cleaned="I'm going to feed the walrus after lunch",
         final="I'm going two feed the walrus after lunch", cats=[9], speech=None, raw_in_range=True),
    # a wiped dictation is rejected and records the share of words lost
    dict(raw="purple walrus dances", final="", cats=[3], speech=None, share_above=0.5),
    # over 30% of the words changed, and over 4 spans changed
    dict(raw="meet me at the pier", final="meat me at the peer", cats=[9, 9], speech=None),
    dict(raw=TWENTY, final=TWENTY.replace("meet", "meat").replace("pier", "peer").replace("bear", "bare")
         .replace("deer", "dear").replace("sail", "sale"), cats=[9] * 5, speech=None),
    # the user puts back a raw word the cleanup dropped at either end, punctuation included
    dict(raw="send the walrus file now.", cleaned="send the walrus file.", final="send the walrus file now.",
         cats=[6], cleanup="send the walrus file now."),
    dict(raw="so send the walrus file.", cleaned="send the walrus file.", final="so send the walrus file.",
         cats=[6], cleanup="so send the walrus file."),
    # words typed after a misheard fix are an addition, and the fix still trains speech-to-text
    dict(raw="meet me at the pier", final="meet me at the peer thanks a lot", cats=[2, 8],
         speech="meet me at the peer"),
    # R's own words restored at either end are not split off as typed additions
    dict(raw="please send the walrus file to the team before lunch right now.",
         cleaned="please send the walrus file to the team before lunch soon.",
         final="please send the walrus file to the team before lunch right now.", cats=[6],
         cleanup="please send the walrus file to the team before lunch right now."),
    dict(raw="so yeah send the walrus file to the team before lunch on friday.",
         cleaned="sent the walrus file to the team before lunch on friday.",
         final="so yeah send the walrus file to the team before lunch on friday.", cats=[6],
         cleanup="so yeah send the walrus file to the team before lunch on friday."),
    # a cleanup fix right after a typed addition gets no leading space
    dict(raw="gonna feed the walrus after lunch on friday", cleaned="will feed the walrus after lunch on friday",
         final="hey gonna feed the walrus after lunch on friday", cats=[2, 6],
         cleanup="gonna feed the walrus after lunch on friday"),
    # punctuation before a span that no cleanup edit applies is still its own category-4 fix
    dict(raw="call me later. pier side at noon", final="call me later, peer side at noon", cats=[4, 8],
         cleanup="call me later, pier side at noon", speech="call me later. peer side at noon"),
    # additions stay category 2 when the rest of the dictation is over a limit
    dict(raw="meet me at the pier", final="hello there meat me at the peer", cats=[2, 9, 9], speech=None),
    # typed words are an addition unless the cleanup dropped them, even when R uses them elsewhere
    dict(raw=LONG, final="the plan is meat " + LONG[5:], cats=[2, 8], speech="meat " + LONG[5:]),
    # the exact R words dropped at an edge, restored beside a fix, sort 6 while the fix sorts 8
    dict(raw="so meet me at the pier then walk to the den", cleaned="meet me at the pier then walk to the den",
         final="so meat me at the pier then walk to the den", cats=[6, 8],
         speech="so meat me at the pier then walk to the den", cleanup="so meet me at the pier then walk to the den"),
    dict(raw="meet me at the pier then walk to the den now", cleaned="meet me at the pier then walk to the den",
         final="meet me at the pier then walk to the din now", cats=[6, 8],
         speech="meet me at the pier then walk to the din now", cleanup="meet me at the pier then walk to the den now"),
    # restoring some of the R words dropped at an edge is still the cleanup's fault
    dict(raw="so yeah send the walrus file to the team", cleaned="send the walrus file to the team",
         final="yeah send the walrus file to the team", cats=[6], cleanup="yeah send the walrus file to the team"),
    # a misheard word owns the punctuation after it, and a change there is a cleanup fix
    dict(raw="meet me at the pier. then go home", final="meet me at the peer, then go home", cats=[4, 8],
         speech="meet me at the peer. then go home", cleanup="meet me at the pier, then go home"),
    # punctuation typed with an end addition is not a fix
    dict(raw="its walrus time now", final="it's walrus time now, ok", cats=[2, 4], cleanup="it's walrus time now"),
    # a fix to text the finisher changed, which C does not hold, writes no cleanup row
    dict(raw="hello world", pasted="Hello world.", final="Hello world!", cats=[4], cleanup=None),
    # hyphen-only changes keep their words, so the dictation is not taken as replaced
    dict(raw="the on device model runs on device", final="the on-device model runs on-device", cats=[4, 4],
         speech="the on device model runs on device", cleanup="the on-device model runs on-device"),
    # an empty cleanup output: R typed back is the cleanup's fault, anything else is rejected
    dict(raw="send the walrus file", cleaned="", final="send the walrus file", cats=[6],
         cleanup="send the walrus file"),
    dict(raw="send the walrus file", cleaned="", final="hello", cats=[3], speech=None),
    # no speech-to-text row without raw words
    dict(raw="...", final="...", cats=[], speech=None),
    # a fixed word keeps R's lower case in the speech-to-text target
    dict(raw="meet me at the pier then go home", final="meet me at the Peer then go home", cats=[8],
         speech="meet me at the peer then go home"),
    # the modifier-letter apostrophe is an app rewrite
    dict(raw="we'll meet at the pier today", final="we\u02bcll meet at the pier today", cats=[1]),
]


class ReviewCasesTest(unittest.TestCase):
    # Turns red if any fix a review asked for regresses: each row is a case a reviewer found mishandled.
    def test_review_cases(self):
        for case in REVIEW_CASES:
            with self.subTest(raw=case["raw"], final=case["final"]):
                res = sort_dictation(rec(case["raw"], case["final"], case.get("cleaned"), case.get("pasted")), TH)
                self.assertEqual(sorted(s["category"] for s in res["spans"]), case["cats"])
                for key in ("speech", "cleanup"):
                    if key in case:
                        self.assertEqual(res[key], case[key])
                if "share_above" in case:
                    self.assertGreater(res["changedShare"], case["share_above"])
                if case.get("raw_in_range"):
                    for span in res["spans"]:
                        r1, r2 = span["positions"]["R"]
                        self.assertTrue(0 <= r1 <= r2 <= len(case["raw"].split()))


class DictationTest(unittest.TestCase):
    # Turns red if a rewrite span lets the dictation into speech-to-text, or blocks its cleanup fixes.
    def test_rewrite_keeps_dictation_out_of_speech_but_not_cleanup(self):
        raw = "so um I want to book the pier for the walrus lunch on friday afternoon please"
        _, rows = run_folder([rec(raw, raw.replace("um ", "").replace("pier", "office"))])
        self.assertEqual(rows["speech_to_text"], [])
        self.assertEqual(rows["cleanup"][0]["target"], raw.replace("um ", ""))
        self.assertEqual([s["category"] for s in rows["corrections"][0]["spans"]], [5, 9])

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
