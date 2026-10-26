#!/usr/bin/env python3
"""DV research lab tests. Does not assert hardware playback qualification."""

import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import dv_lab


def fixture(profile=7, compatibility=6, el=1, codec="hevc"):
    return {"streams": [{"index": 0, "codec_type": "video", "codec_name": codec,
        "side_data_list": [{"side_data_type": "DOVI configuration record",
            "dv_profile": profile, "dv_level": 6, "dv_version_major": 1,
            "dv_version_minor": 0, "rpu_present_flag": 1, "el_present_flag": el,
            "bl_present_flag": 1, "dv_bl_signal_compatibility_id": compatibility}]}]}


class DvLabTest(unittest.TestCase):
    def first(self, probe):
        return dv_lab.inspect_probe(probe)["video_streams"][0]

    def test_p7_presence_does_not_claim_fel(self):
        report = dv_lab.inspect_probe(fixture())
        self.assertEqual(report["video_streams"][0]["enhancement_layer"], "present_mel_or_fel_unclassified")
        self.assertEqual(set(report["qualification"].values()), {"not_tested"})

    def test_profile_fallbacks(self):
        cases = [(5, 0, "hevc", "none"), (7, 6, "hevc", "hdr10"),
                 (8, 1, "hevc", "hdr10"), (8, 4, "hevc", "hlg"),
                 (9, 2, "h264", "sdr"), (10, 0, "av1", "none"),
                 (10, 1, "av1", "hdr10"), (10, 4, "av1", "hlg"),
                 (20, 0, "hevc", "none"), (20, 4, "hevc", "hlg")]
        for profile, compatibility, codec, expected in cases:
            with self.subTest(profile=profile, compatibility=compatibility):
                item = self.first(fixture(profile, compatibility, int(profile == 7), codec))
                self.assertEqual(item["base_layer_compatibility"], expected)

    def test_p5_cannot_be_relabelled_hdr10(self):
        item = self.first(fixture(5, 1, 0))
        self.assertEqual(item["base_layer_compatibility"], "unknown")
        self.assertIn("unrecognized_profile_compatibility_combination", item["issues"])

    def test_missing_config_is_unknown(self):
        probe = fixture()
        probe["streams"][0]["side_data_list"] = []
        self.assertEqual(self.first(probe)["dv_configuration"], "not_reported")

    def test_conflicting_records_cannot_select_fallback(self):
        probe = fixture()
        records = probe["streams"][0]["side_data_list"]
        other = copy.deepcopy(records[0])
        other["el_present_flag"] = 0
        records.append(other)
        item = self.first(probe)
        self.assertEqual(item["base_layer_compatibility"], "unknown")
        self.assertEqual(item["enhancement_layer"], "unknown")

    def test_string_flags_are_parsed_but_bool_is_not(self):
        probe = fixture()
        record = probe["streams"][0]["side_data_list"][0]
        record["el_present_flag"] = "1"
        self.assertEqual(self.first(probe)["enhancement_layer"], "present_mel_or_fel_unclassified")
        record["el_present_flag"] = True
        self.assertIn("missing_or_invalid_el_present_flag", self.first(probe)["issues"])

    def test_historical_and_legacy_are_not_qualified(self):
        self.assertEqual(self.first(fixture(8, 2, 0))["base_layer_compatibility"], "unknown")
        self.assertEqual(self.first(fixture(4, 2, 1))["base_layer_compatibility"], "unknown")

    def test_missing_and_out_of_range_fields(self):
        for field, value in (("dv_profile", None), ("dv_level", 64),
                             ("bl_present_flag", 0), ("rpu_present_flag", 0),
                             ("dv_md_compression", 1)):
            with self.subTest(field=field):
                probe = fixture()
                probe["streams"][0]["side_data_list"][0][field] = value
                self.assertEqual(self.first(probe)["base_layer_compatibility"], "unknown")

    def test_codec_mismatch(self):
        self.assertIn("profile_codec_mismatch", self.first(fixture(10, 1, 0))["issues"])

    def test_multiple_streams_are_not_assumed_to_be_a_layer_pair(self):
        probe = fixture()
        second = copy.deepcopy(probe["streams"][0])
        second["index"] = 3
        probe["streams"].append(second)
        self.assertEqual(len(dv_lab.inspect_probe(probe)["video_streams"]), 2)
        second["disposition"] = {"attached_pic": 1}
        self.assertEqual(len(dv_lab.inspect_probe(probe)["video_streams"]), 1)

    def test_input_shape_and_budget(self):
        for data in ([], {}, {"streams": None}):
            with self.assertRaises(ValueError):
                dv_lab.inspect_probe(data)
        with tempfile.TemporaryDirectory() as folder:
            report = Path(folder) / "probe.json"
            report.write_text(json.dumps(fixture()), encoding="utf-8")
            with patch.object(dv_lab, "MAX_REPORT_BYTES", 8):
                with self.assertRaises(ValueError):
                    dv_lab.read_json(report)

    def test_trial_is_bounded_and_does_not_strip_rpu(self):
        source = Path("/tmp/--strange $(filename).mkv")
        args = dv_lab.trial_command(source, "mpv", "auto", 15)
        self.assertEqual(args[-2:], ["--", str(source)])
        self.assertIn("--vo=gpu-next", args)
        self.assertIn("--no-config", args)
        self.assertFalse(any("dovi=no" in arg for arg in args))
        self.assertIn("--target-trc=bt.1886", dv_lab.trial_command(source, "mpv", "sdr", 15))
        for seconds in (0, 61, float("inf"), float("nan")):
            with self.assertRaises(ValueError):
                dv_lab.trial_command(source, "mpv", "auto", seconds)

    def test_absent_executable_is_reported(self):
        self.assertFalse(dv_lab.capture(["/nonexistent/plezyng-dv-test-mpv"])["available"])


if __name__ == "__main__":
    unittest.main()
