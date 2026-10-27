import math
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

from output_target import playback_arguments, render_options
import run


class OutputTargetTest(unittest.TestCase):
    def test_auto_uses_context_instead_of_assuming_hdr(self):
        options = render_options("auto")
        self.assertIn("--vo=gpu-next", options)
        self.assertIn("--target-colorspace-hint=auto", options)
        self.assertIn("--target-trc=auto", options)
        self.assertNotIn("--target-trc=pq", options)

    def test_sdr_sets_surface_transfer_gamut_and_both_peak_controls(self):
        options = render_options("sdr")
        for value in ("--target-colorspace-hint=no", "--target-trc=srgb",
                      "--target-prim=bt.709", "--target-peak=100", "--sdr-peak=100"):
            self.assertIn(value, options)
        self.assertIn("--sdr-peak=203", render_options("sdr", peak_nits=203))

    def test_hdr_keeps_sink_mapping_unless_peak_is_known(self):
        self.assertIn("--target-peak=auto", render_options("hdr10"))
        options = render_options("hdr10", peak_nits=600)
        for value in ("--target-trc=pq", "--target-prim=bt.2020", "--target-peak=600"):
            self.assertIn(value, options)

    def test_output_conversion_preserves_source_and_dv_metadata(self):
        for target in ("auto", "sdr", "hdr10"):
            options = render_options(target)
            self.assertFalse(any(value.startswith(("--vf", "--vd-lavc-o", "--lavfi-complex")) for value in options))

    def test_rejects_nonfinite_or_unsupported_peak(self):
        for value in (True, "100", math.nan, math.inf, -math.inf, 0, 9, 10001):
            with self.assertRaises(ValueError):
                render_options("sdr", peak_nits=value)
        with self.assertRaises(ValueError):
            render_options("auto", peak_nits=100)
        with self.assertRaises(ValueError):
            render_options("dolby-vision")

    def test_arguments_are_passed_as_data_and_configs_cannot_override_target(self):
        media = "/media/title with spaces;$(touch nope).mkv"
        options = playback_arguments(["--pause", "--", media], "sdr")
        self.assertEqual(options[-3:], ["--pause", "--", media])
        self.assertEqual(options[0], "--no-config")
        for value in ("--vo=gpu", "--vf-add=format:dolbyvision=no", "--profile=fast",
                      "--target-trc=pq", "--config=yes", "--include=other.conf",
                      "--no-hdr-compute-peak", "--sdr-peak=1000"):
            with self.assertRaises(ValueError):
                playback_arguments([value, media], "sdr")
        self.assertEqual(playback_arguments(["--vo=gpu", media], None), ["--vo=gpu", media])

    def test_cli_rejects_app_and_nonplayer_targets_before_engine_access(self):
        for args in (("--app", "/missing", "--target", "sdr"),
                     ("--tool", "ffmpeg", "--target", "hdr10"),
                     ("--peak-nits", "100")):
            with patch.object(sys, "argv", ["run.py", *args]):
                with self.assertRaises(SystemExit) as error:
                    run.main()
                self.assertEqual(error.exception.code, 2)

    def test_launcher_help_works_without_an_engine(self):
        result = subprocess.run([sys.executable, str(Path(run.__file__)), "--help"],
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0)
        self.assertIn("--target", result.stdout)


if __name__ == "__main__":
    unittest.main()
