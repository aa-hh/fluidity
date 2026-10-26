import tempfile
import unittest
from pathlib import Path

from build_testset import load_or_draw_split, route

DRIVE = "/Volumes/Space/wispr-flow-teardown/audio"


def routed(wispr_wavs, fluid_wavs, wispr, fluid, test_ids):
    return {row["id"]: (name, row) for name, _, row in route(wispr_wavs, fluid_wavs, wispr, fluid, test_ids)}


class RouteTest(unittest.TestCase):
    wispr = {"AAAA0001": {"asr": "hi", "duration_s": 1.0}, "AAAA0002": {"asr": "yo", "duration_s": 2.0}}
    fluid = {"BBBB0001": "hey"}

    # Turns red if a clip's source is read from its path again: every
    # FluidVoice clip on the drive sits under a folder named wispr-flow-teardown.
    def test_fluidvoice_clip_on_the_drive_is_labelled_fluidvoice(self):
        out = routed([], [f"{DRIVE}/fluidvoice-local/2026-10-22T05-28-01Z_BBBB0001.wav"],
                     self.wispr, self.fluid, set())
        self.assertEqual(out["BBBB0001"], ("train", {"id": "BBBB0001", "source": "fluidvoice", "model_transcript": "hey"}))

    # Turns red if a test-set Wispr clip stops going to test or loses its transcript.
    def test_wispr_clip_in_the_split_goes_to_test(self):
        out = routed([f"{DRIVE}/wispr-local/2026-10-20-20-43-56_AAAA0001.wav"], [], self.wispr, self.fluid, {"AAAA0001"})
        self.assertEqual(out["AAAA0001"], ("test", {"id": "AAAA0001", "wispr_asr": "hi", "duration_s": 1.0}))

    # Turns red if a clip outside the split, such as a new recording, can reach test.
    def test_clips_outside_the_split_go_to_training(self):
        out = routed([f"{DRIVE}/wispr-local/x_AAAA0002.wav"], [f"{DRIVE}/fluidvoice-local/y_BBBB0001.wav"],
                     self.wispr, self.fluid, {"AAAA0001"})
        self.assertEqual({k: v[0] for k, v in out.items()}, {"AAAA0002": "train", "BBBB0001": "train"})


class SplitTest(unittest.TestCase):
    # Turns red if a second run redraws the split instead of reading split.json:
    # any model trained on the old training pool would then have seen test clips.
    def test_split_is_drawn_once_and_reused(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "split.json"
            first = load_or_draw_split(path, [f"ID{i:06d}" for i in range(10)])
            second = load_or_draw_split(path, [f"ID{i:06d}" for i in range(10, 30)])
            self.assertEqual(len(first), 5)
            self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
