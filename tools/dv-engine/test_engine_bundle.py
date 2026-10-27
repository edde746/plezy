import json
from pathlib import Path
import struct
import tempfile
import unittest

from build_windows import collect_runtime_dlls, compiler_architecture, imported_dlls
from engine_bundle import ENGINE_ID, MACHINES, bundle_manifest, validate_bundle
from run_windows import arguments


def image(path, architecture="x86_64"):
    data = bytearray(70)
    data[:2] = b"MZ"
    struct.pack_into("<I", data, 60, 64)
    data[64:68] = b"PE\0\0"
    struct.pack_into("<H", data, 68, MACHINES[architecture])
    path.write_bytes(data)


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "include/mpv").mkdir(parents=True)
        for name in ("libmpv.dll.a", "include/mpv/client.h", "include/mpv/render.h"):
            (self.root / name).write_text("fixture")
        image(self.root / "libmpv-2.dll")
        self.report = dict(engine_id=ENGINE_ID, render_backend="d3d11",
                           dovi_split=True, paired_frame_api=True, fel_nlq_api=True)
        self.write_report()
        self.seal()

    def write_report(self):
        (self.root / "feature-report.json").write_text(json.dumps(self.report))

    def seal(self):
        manifest = bundle_manifest(self.root, "x86_64", {"mpv": {"commit": "fixture"}})
        (self.root / "engine-manifest.json").write_text(json.dumps(manifest))

    def test_round_trip_remains_unqualified(self):
        self.assertEqual(validate_bundle(self.root, "x86_64")["qualification"], "unverified")

    def test_modified_header_rejected(self):
        (self.root / "include/mpv/client.h").write_text("changed")
        with self.assertRaisesRegex(ValueError, "digest"):
            validate_bundle(self.root, "x86_64")

    def test_unlisted_runtime_rejected(self):
        image(self.root / "extra.dll")
        with self.assertRaisesRegex(ValueError, "file set"):
            validate_bundle(self.root, "x86_64")

    def test_wrong_architecture_rejected(self):
        image(self.root / "libmpv-2.dll", "aarch64")
        with self.assertRaisesRegex(ValueError, "architecture"):
            self.seal()

    def test_feature_probe_is_not_optional(self):
        self.report["fel_nlq_api"] = False
        self.write_report()
        with self.assertRaisesRegex(ValueError, "fel_nlq_api"):
            self.seal()

    def test_runtime_marker_required(self):
        del self.report["engine_id"]
        self.write_report()
        with self.assertRaisesRegex(ValueError, "runtime identity"):
            self.seal()

    def test_backend_required(self):
        self.report["render_backend"] = "opengl"
        self.write_report()
        with self.assertRaisesRegex(ValueError, "render backend"):
            self.seal()

    def test_malformed_pe_rejected(self):
        (self.root / "libmpv-2.dll").write_bytes(b"not executable")
        with self.assertRaisesRegex(ValueError, "PE"):
            self.seal()

    def test_nested_manifest_is_hashed(self):
        (self.root / "include/engine-manifest.json").write_text("first")
        self.seal()
        (self.root / "include/engine-manifest.json").write_text("changed")
        with self.assertRaisesRegex(ValueError, "digest"):
            validate_bundle(self.root, "x86_64")

    def test_missing_development_file_rejected(self):
        (self.root / "libmpv.dll.a").unlink()
        with self.assertRaisesRegex(ValueError, "missing"):
            validate_bundle(self.root, "x86_64")


class DependencyTests(unittest.TestCase):
    def test_compiler_targets(self):
        self.assertEqual(compiler_architecture("aarch64-w64-mingw32"), "aarch64")
        self.assertEqual(compiler_architecture("x86_64-w64-mingw32"), "x86_64")
        self.assertEqual(compiler_architecture("aarch64-w64-windows-gnu"), "aarch64")
        with self.assertRaises(ValueError):
            compiler_architecture("x86_64-linux-gnu")

    def test_launcher_preserves_sdr_and_software_decode(self):
        command = arguments(["--", "movie with spaces.mkv"], "sdr")
        self.assertIn("--gpu-api=d3d11", command)
        self.assertIn("--hwdec=no", command)
        self.assertIn("--target-trc=srgb", command)
        self.assertEqual(command[-1], "movie with spaces.mkv")
        for option in ("--hwdec=auto", "--gpu-api=vulkan", "--gpu-context=winvk"):
            with self.assertRaises(ValueError):
                arguments([option, "movie.mkv"], "auto")

    def test_import_parser(self):
        self.assertEqual(imported_dlls("  DLL Name: KERNEL32.dll\n  DLL Name: libfoo-1.dll\n"),
                         ["KERNEL32.dll", "libfoo-1.dll"])
        with self.assertRaises(ValueError):
            imported_dlls("DLL Name: ../escape.dll\n")

    def test_executable_imports_and_transitive_dependencies_collected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bundle, search, system = (root / name for name in ("bundle", "search", "system"))
            for path in (bundle, search, system):
                path.mkdir()
            image(bundle / "mpv.exe")
            image(search / "first.dll")
            image(search / "second.dll")
            imports = {"mpv.exe": "first.dll", "first.dll": "second.dll",
                       "second.dll": "api-ms-win-core-file-l1-1-0.dll"}
            collect_runtime_dlls(bundle, [search], system, "x86_64",
                                 lambda path: "DLL Name: " + imports[path.name])
            self.assertEqual({p.name for p in bundle.iterdir()}, {"mpv.exe", "first.dll", "second.dll"})

    def test_unresolved_import_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            image(root / "mpv.exe")
            with self.assertRaisesRegex(ValueError, "Unresolved"):
                collect_runtime_dlls(root, [], root / "system", "x86_64",
                                     lambda path: "DLL Name: missing.dll")

    def test_wrong_architecture_dependency_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bundle, search = root / "bundle", root / "search"
            bundle.mkdir()
            search.mkdir()
            image(bundle / "mpv.exe")
            image(search / "wrong.dll", "aarch64")
            with self.assertRaisesRegex(ValueError, "architecture"):
                collect_runtime_dlls(bundle, [search], root / "system", "x86_64",
                                     lambda path: "DLL Name: wrong.dll")


if __name__ == "__main__":
    unittest.main()
