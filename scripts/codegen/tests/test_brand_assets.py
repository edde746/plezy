"""Properties that protect the approved logo across native icon formats."""

import json
import math
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from generate_brand_assets import BrandRenderer, CONFIG, ROOT


class BrandAssetsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads(CONFIG.read_text())
        cls.renderer = BrandRenderer(cls.config)

    def test_source_change_requires_explicit_approval(self):
        with self.assertRaisesRegex(ValueError, 'checksum changed'):
            BrandRenderer({**self.config, 'source_sha256': '0' * 64})

    def test_dark_centre_survives_colour_export(self):
        image = self.renderer.frame((512, 512), 1)
        red, green, blue, alpha = image.getpixel((256, 256))
        self.assertGreaterEqual(alpha, 250)
        self.assertLess(max(red, green, blue), 70)
        self.assertGreater(blue, red)

    def test_monochrome_retains_hollow_triangles_and_ng(self):
        image = self.renderer.frame((512, 512), 1, mono=True)
        self.assertEqual(image.getpixel((256, 256))[3], 0)
        self.assertGreater(image.crop((240, 360, 470, 490)).getchannel('A').getextrema()[1], 240)
        visible = [pixel for pixel in image.get_flattened_data() if pixel[3] > 200]
        self.assertGreater(len(visible), 15000)
        self.assertTrue(all(pixel[:3] == (255, 255, 255) for pixel in visible))

    def test_entire_adaptive_mark_stays_inside_safe_circle(self):
        size = 432
        image = self.renderer.frame((size, size), self.renderer.adaptive_fit)
        alpha = image.getchannel('A')
        visible = [(x, y) for y in range(size) for x in range(size) if alpha.getpixel((x, y)) > 16]
        self.assertGreater(len(visible), 1000)
        furthest = max(math.hypot(x - size / 2, y - size / 2) for x, y in visible)
        self.assertLessEqual(furthest, size * (33 / 108))

    def test_every_ios_alternate_is_opaque(self):
        for path in (ROOT / 'ios/Runner/AlternateAppIcons.xcassets').glob('*.appiconset/icon.png'):
            with self.subTest(path=path):
                with Image.open(path) as image:
                    self.assertEqual(image.mode, 'RGB')

    def test_windows_ico_has_all_required_frames(self):
        with Image.open(ROOT / 'windows/runner/resources/app_icon.ico') as image:
            self.assertEqual(image.ico.sizes(), {(n, n) for n in (16, 24, 32, 48, 64, 128, 256)})


if __name__ == '__main__':
    unittest.main()
