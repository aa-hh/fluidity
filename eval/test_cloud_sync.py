import json
import tempfile
import unittest
from pathlib import Path

from cloud_sync import changed_rows, read_records, recordings, sql_text


class CloudSyncTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.data = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def write_day(self, name, *lines):
        (self.data / name).write_text("\n".join(lines), encoding="utf-8")

    # Turns red if a half-written last line (the app mid-save) crashes the run or gets sent.
    def test_line_still_being_written_is_skipped(self):
        self.write_day("2026-11-02.jsonl", json.dumps({"id": "AAAA1111-x"}), '{"id": "BBBB2222-x", "fin')
        self.assertEqual(list(read_records(self.data)), ["AAAA1111-x"])

    # Turns red if a record rewritten later (final text added) stops replacing the earlier line.
    def test_later_line_for_same_id_wins(self):
        self.write_day("2026-11-02.jsonl", json.dumps({"id": "A", "finalText": ""}),
                       json.dumps({"id": "A", "finalText": "done"}))
        self.assertEqual(read_records(self.data)["A"]["finalText"], "done")

    # Turns red if recordings stop matching records by the clip id after the last `_`.
    def test_recordings_keyed_by_clip_id(self):
        (self.data / "2026-11-01T00-37-49Z_4309048B.flac").touch()
        self.assertEqual(recordings(self.data), {"4309048B": "2026-11-01T00-37-49Z_4309048B.flac"})

    # Turns red if an unchanged record is sent again, or a changed one is not.
    def test_only_changed_records_are_sent(self):
        records = {"4309048B-9EA2": {"id": "4309048B-9EA2", "finalText": "a"}}
        first = changed_rows(records, {}, {})
        self.assertEqual(len(first), 1)
        sent = {rid: digest for rid, digest, _ in first}
        self.assertEqual(changed_rows(records, {}, sent), [])
        records["4309048B-9EA2"]["finalText"] = "b"
        self.assertEqual(len(changed_rows(records, {}, sent)), 1)

    # Turns red if a recording that arrives after its record never reaches the row.
    def test_late_recording_resends_row(self):
        records = {"4309048B-9EA2": {"id": "4309048B-9EA2"}}
        sent = {rid: digest for rid, digest, _ in changed_rows(records, {}, {})}
        self.assertEqual(len(changed_rows(records, {"4309048B": "x_4309048B.flac"}, sent)), 1)

    # Turns red if a quote in dictated text can break out of the SQL string.
    def test_quotes_are_escaped(self):
        self.assertEqual(sql_text("it's '); DROP TABLE dictations; --"),
                         "'it''s ''); DROP TABLE dictations; --'")


if __name__ == "__main__":
    unittest.main()
