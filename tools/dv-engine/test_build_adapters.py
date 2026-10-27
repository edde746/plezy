import json
from pathlib import Path
import tempfile
import unittest

from build_adapters import pin_map, patch_felbaker_vs_output_key, verify_swift_pins


def pin(identity, revision, *, version="1.0.0", location=None):
    return {
        "identity": identity,
        "kind": "remoteSourceControl",
        "location": location or f"https://example.invalid/{identity}",
        "state": {"revision": revision, "version": version},
    }


LOCKED = [
    pin("ffmpegbuild", "a" * 40, version="3.10.0"),
    pin("libdovi", "b" * 40, version="2.1.0"),
    pin("smbclient", "c" * 40, version="0.3.1"),
    pin("libtruehd", "d" * 40, version="3.1.0"),
]
REQUIRED = ("ffmpegbuild", "libdovi")


class SwiftPinVerificationTest(unittest.TestCase):
    def verify(self, pins):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Package.resolved"
            path.write_text(json.dumps({"pins": pins}))
            verify_swift_pins(path, LOCKED, required=REQUIRED)

    def test_accepts_the_full_upstream_lock(self):
        self.verify(LOCKED)

    def test_accepts_the_actual_swiftpm_host_graph(self):
        # The selected Aether host graph resolves these three pins. LibTrueHD
        # is in Aether's package lock but its optional trait is not selected.
        self.verify([*LOCKED[:2], LOCKED[3]])

    def test_rejects_changed_revision(self):
        changed = [*LOCKED[:2]]
        changed[0] = pin("ffmpegbuild", "e" * 40, version="3.10.0")
        with self.assertRaisesRegex(ValueError, "resolution drifted"):
            self.verify(changed)

    def test_rejects_unexpected_dependency(self):
        with self.assertRaisesRegex(ValueError, "resolution drifted"):
            self.verify([*LOCKED[:2], pin("new-dependency", "f" * 40)])

    def test_rejects_missing_required_dependency(self):
        with self.assertRaisesRegex(ValueError, "resolution drifted"):
            self.verify(LOCKED[1:2])

    def test_rejects_duplicate_pin_identity(self):
        with self.assertRaisesRegex(ValueError, "duplicate pin"):
            pin_map({"pins": [LOCKED[0], LOCKED[0]]})


class FelBakerVapourSynthCompatibilityTest(unittest.TestCase):
    def test_aligns_registered_outputs_with_vapoursynth_clip_key(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            entry = source / "src/VapourSynthEntry.cpp"
            entry.parent.mkdir()
            entry.write_text(
                'registerFunction("Bake", "inputs", "baked:vnode;", bakeFilter);\n'
                'registerFunction("ToRGB", "inputs", "baked_rgb:vnode;", rgbFilter);\n'
            )

            digest = patch_felbaker_vs_output_key(source)

            self.assertEqual(
                entry.read_text(),
                'registerFunction("Bake", "inputs", "clip:vnode;", bakeFilter);\n'
                'registerFunction("ToRGB", "inputs", "clip:vnode;", rgbFilter);\n',
            )
            self.assertEqual(len(digest), 64)

    def test_rejects_upstream_signature_drift(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory)
            entry = source / "src/VapourSynthEntry.cpp"
            entry.parent.mkdir()
            entry.write_text('registerFunction("Bake", "inputs", "baked:vnode;", bakeFilter);\n')

            with self.assertRaisesRegex(ValueError, "signature changed"):
                patch_felbaker_vs_output_key(source)


if __name__ == "__main__":
    unittest.main()
