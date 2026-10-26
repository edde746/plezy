import struct
import unittest

from generate_synthetic_p7 import (
    EL_NEUTRAL,
    EL_RESIDUAL,
    FRAME_RATE,
    make_bl_frame,
    make_el_frame,
    validate_mp4_packets,
    validate_mp4_probe,
    validate_rpu_access_units,
)


class SyntheticP7PatternTest(unittest.TestCase):
    @staticmethod
    def _annex_b_nal(nal_type, prefix=b"\x00\x00\x01"):
        return prefix + bytes((nal_type << 1, 1))

    def test_base_layer_contains_four_static_luma_bars(self):
        width, height = 8, 4
        frame = make_bl_frame(width, height)
        self.assertEqual(len(frame), width * height * 3)
        y_values = [struct.unpack_from("<H", frame, column * 2)[0] for column in (0, 2, 4, 6)]
        self.assertEqual(y_values, [256, 384, 512, 640])

    def test_el_residual_only_changes_the_center_patch(self):
        width, height = 8, 8
        neutral = make_el_frame(width, height, residual=False)
        active = make_el_frame(width, height, residual=True)
        center = ((height // 2) * width + (width // 2)) * 2
        outside = ((height // 8) * width + (width // 8)) * 2
        self.assertEqual(struct.unpack_from("<H", neutral, center)[0], EL_NEUTRAL)
        self.assertEqual(struct.unpack_from("<H", active, center)[0], EL_RESIDUAL)
        self.assertEqual(struct.unpack_from("<H", active, outside)[0], EL_NEUTRAL)

    def test_rejects_unusable_plane_geometry(self):
        with self.assertRaises(ValueError):
            make_bl_frame(7, 4)
        with self.assertRaises(ValueError):
            make_el_frame(3, 8, residual=True)

    def test_mp4_annex_b_requires_one_rpu_per_access_unit(self):
        stream = b"".join((
            self._annex_b_nal(32, b"\x00\x00\x00\x01"),
            self._annex_b_nal(35),
            self._annex_b_nal(62),
            self._annex_b_nal(1),
            self._annex_b_nal(35, b"\x00\x00\x00\x01"),
            self._annex_b_nal(62),
            self._annex_b_nal(1),
        ))

        report = validate_rpu_access_units(stream, 2)

        self.assertEqual(report["access_units"], 2)
        self.assertEqual(report["rpu_nals"], 2)
        self.assertEqual(report["rpu_nals_per_access_unit"], {"min": 1, "max": 1})
        self.assertTrue(report["exactly_one_rpu_per_access_unit"])

    def test_rpu_access_unit_check_rejects_missing_duplicate_and_unframed_rpus(self):
        missing = b"".join((
            self._annex_b_nal(35),
            self._annex_b_nal(62),
            self._annex_b_nal(1),
            self._annex_b_nal(35),
            self._annex_b_nal(1),
        ))
        with self.assertRaises(RuntimeError):
            validate_rpu_access_units(missing, 2)

        duplicate = b"".join((
            self._annex_b_nal(35),
            self._annex_b_nal(62),
            self._annex_b_nal(62),
        ))
        with self.assertRaises(RuntimeError):
            validate_rpu_access_units(duplicate, 1)

        unframed = self._annex_b_nal(62) + self._annex_b_nal(35)
        with self.assertRaises(ValueError):
            validate_rpu_access_units(unframed, 1)

        two_access_units = b"".join((
            self._annex_b_nal(35),
            self._annex_b_nal(62),
            self._annex_b_nal(1),
            self._annex_b_nal(35),
            self._annex_b_nal(62),
            self._annex_b_nal(1),
        ))
        with self.assertRaises(RuntimeError):
            validate_rpu_access_units(two_access_units, 1)

    def test_mp4_probe_requires_timestamped_profile7_with_both_layers(self):
        probe = {
            "streams": [{
                "codec_name": "hevc",
                "codec_tag_string": "hvc1",
                "r_frame_rate": FRAME_RATE,
                "avg_frame_rate": FRAME_RATE,
                "nb_frames": "48",
                "start_time": "0.000000",
                "duration": "2.000000",
                "time_base": "1/24000",
                "side_data_list": [
                    {
                        "side_data_type": "DOVI configuration record",
                        "dv_profile": 7,
                        "rpu_present_flag": 1,
                        "el_present_flag": 1,
                        "bl_present_flag": 1,
                    },
                    {"side_data_type": "HEVC enhancement-layer decoder configuration"},
                ],
            }],
        }
        report = validate_mp4_probe(probe, 48)
        self.assertEqual(report["profile"], 7)
        self.assertTrue(report["enhancement_layer_decoder_config"])
        self.assertEqual(report["frame_rate"], FRAME_RATE)

    def test_mp4_probe_rejects_missing_el_flag(self):
        probe = {
            "streams": [{
                "codec_name": "hevc",
                "codec_tag_string": "hvc1",
                "r_frame_rate": FRAME_RATE,
                "avg_frame_rate": FRAME_RATE,
                "nb_frames": "24",
                "start_time": "0",
                "duration": "1",
                "time_base": "1/24000",
                "side_data_list": [{
                    "side_data_type": "DOVI configuration record",
                    "dv_profile": 7,
                    "rpu_present_flag": 1,
                    "el_present_flag": 0,
                    "bl_present_flag": 1,
                }],
            }],
        }
        with self.assertRaises(RuntimeError):
            validate_mp4_probe(probe, 24)

    def test_mp4_packet_probe_requires_complete_pts_and_monotonic_dts(self):
        probe = {
            "packets": [
                {"pts": 0, "dts": -2002, "duration": 1001},
                {"pts": 4004, "dts": -1001, "duration": 1001},
                {"pts": 2002, "dts": 0, "duration": 1001},
                {"pts": 1001, "dts": 1001, "duration": 1001},
                {"pts": 3003, "dts": 2002, "duration": 1001},
            ],
        }
        report = validate_mp4_packets(probe, 5)
        self.assertTrue(report["presentation_timestamps_unique_and_complete"])
        self.assertTrue(report["decode_timestamps_monotonic"])

    def test_mp4_packet_probe_rejects_missing_or_duplicate_pts(self):
        probe = {"packets": [
            {"pts": 0, "dts": 0, "duration": 1001},
            {"pts": 0, "dts": 1001, "duration": 1001},
        ]}
        with self.assertRaises(RuntimeError):
            validate_mp4_packets(probe, 2)


if __name__ == "__main__":
    unittest.main()
