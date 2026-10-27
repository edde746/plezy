import unittest

from verify_felbaker_synthetic import validate_synthetic_control


class SyntheticFelControlTest(unittest.TestCase):
    def validate(self, **changes):
        controls = {
            "bl_rate": (24000, 1001),
            "el_rate": (24000, 1001),
            "neutral_rpu": b"same-rpu",
            "residual_rpu": b"same-rpu",
            "base_layer_identical": True,
            "center_codes": (512, 640),
            "outside_codes": (512, 512),
            "el_luma_pattern_exact": True,
            "el_chroma_identical": True,
            "bl_dimensions": (3840, 2160),
            "el_dimensions": (1920, 1080),
            "bl_frames": 48,
            "el_frames": 48,
        }
        controls.update(changes)
        return validate_synthetic_control(**controls)

    def test_accepts_el_only_control(self):
        report = self.validate()
        self.assertTrue(report["passed"])
        self.assertTrue(report["sampled_bl_frames_identical"])
        self.assertTrue(report["sampled_rpu_properties_identical"])
        self.assertTrue(report["el_luma_pattern_matches_authored_patch"])
        self.assertTrue(report["el_chroma_unchanged"])
        self.assertEqual(
            report["el_luma_control_codes"],
            {
                "center_neutral": 512,
                "center_residual": 640,
                "outside_neutral": 512,
                "outside_residual": 512,
            },
        )

    def test_rejects_rate_rpu_and_base_layer_changes(self):
        invalid = (
            {"bl_rate": (24, 1)},
            {"el_rate": (24000, 1000)},
            {"residual_rpu": b"different-rpu"},
            {"residual_rpu": None},
            {"base_layer_identical": False},
        )
        for changes in invalid:
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                self.validate(**changes)

    def test_rejects_wrong_or_missing_el_patch_samples(self):
        invalid = (
            {"center_codes": (512, 512)},
            {"outside_codes": (512, 640)},
            {"neutral_rpu": b""},
            {"el_luma_pattern_exact": False},
            {"el_chroma_identical": False},
            {"bl_dimensions": (1920, 1080)},
            {"el_dimensions": (3840, 2160)},
            {"el_frames": 47},
        )
        for changes in invalid:
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                self.validate(**changes)


if __name__ == "__main__":
    unittest.main()
