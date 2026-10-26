import tempfile
import unittest
from pathlib import Path

from verify_synthetic_render import capture_seconds, compare_pixels, read_ppm


class SyntheticRenderVerificationTest(unittest.TestCase):
    def test_reads_binary_ppm_and_rejects_size_mismatch(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "frame.ppm"
            path.write_bytes(b"P6\n2 1\n255\n" + bytes((0, 1, 2, 3, 4, 5)))
            self.assertEqual(read_ppm(path), (2, 1, bytes((0, 1, 2, 3, 4, 5))))
            path.write_bytes(b"P6\n2 1\n255\n\x00")
            with self.assertRaises(ValueError):
                read_ppm(path)

    def test_parses_reported_capture_time(self):
        self.assertEqual(capture_seconds("Embedded opengl-next rendered and read back at 0.542208 s"), 0.542208)
        with self.assertRaises(RuntimeError):
            capture_seconds("render failed")

    def test_requires_the_center_fel_patch_to_dominate_the_delta(self):
        width = height = 8
        neutral = bytes([32] * (width * height * 3))
        residual = bytearray(neutral)
        for y in range(height // 4, 3 * height // 4):
            for x in range(width // 4, 3 * width // 4):
                offset = (y * width + x) * 3
                residual[offset:offset + 3] = bytes((80, 80, 80))
        result = compare_pixels(width, height, neutral, bytes(residual))
        self.assertTrue(result["fel_patch_dominates"])
        self.assertEqual(result["center_patch_pixels_changed"], 16)
        self.assertEqual(result["outside_patch_pixels_changed"], 0)

    def test_rejects_framewide_changes_without_a_dominant_fel_patch(self):
        width = height = 8
        neutral = bytes([32] * (width * height * 3))
        residual = bytes([80] * (width * height * 3))
        result = compare_pixels(width, height, neutral, residual)
        self.assertFalse(result["fel_patch_dominates"])


if __name__ == "__main__":
    unittest.main()
