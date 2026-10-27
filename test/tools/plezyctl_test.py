import importlib.util
import json
import tempfile
import unittest
from importlib.machinery import SourceFileLoader
from pathlib import Path
from urllib.parse import parse_qs, urlsplit


ROOT = Path(__file__).resolve().parents[2]
LOADER = SourceFileLoader("plezyctl", str(ROOT / "tools" / "plezyctl"))
SPEC = importlib.util.spec_from_loader("plezyctl", LOADER)
assert SPEC is not None and SPEC.loader is not None
plezyctl = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(plezyctl)


class PlezyCtlTests(unittest.TestCase):
    def test_example_manifest_validates_without_network_access(self):
        manifest = plezyctl.load_manifest(ROOT / "examples" / "extensions" / "search.example.json")

        self.assertEqual(manifest["id"], "community-search-example")
        self.assertEqual(urlsplit(str(manifest["endpoint"])).hostname, "catalog.example.invalid")

    def test_query_is_encoded_as_one_parameter(self):
        manifest = plezyctl.load_manifest(ROOT / "examples" / "extensions" / "search.example.json")
        parsed = urlsplit(plezyctl.request_url(manifest, "ambient jazz & rain"))

        self.assertEqual(parse_qs(parsed.query), {"q": ["ambient jazz & rain"]})

    def test_app_link_accepts_safe_urls_and_rejects_credentials_or_signatures(self):
        link = plezyctl.safe_open_link("https://media.example/live.m3u8?quality=high", "Kids")
        self.assertEqual(urlsplit(link).scheme, "plezy")
        self.assertEqual(parse_qs(urlsplit(link).query)["profile"], ["Kids"])

        for url in [
            "http://media.example/live.m3u8",
            "https://user:pass@media.example/live.m3u8",
            "https://media.example/live.m3u8?signature=secret",
            "https://media.example/live.m3u8#chapter",
            "https://media.example/live.m3u8\nhttps://attacker.example",
        ]:
            with self.subTest(url=url):
                with self.assertRaises(plezyctl.CliError):
                    plezyctl.safe_open_link(url)

    def test_manifest_rejects_code_and_insecure_endpoints(self):
        example = json.loads((ROOT / "examples" / "extensions" / "search.example.json").read_text())
        for changes in ({"script": "alert(1)"}, {"endpoint": "http://catalog.example/search"}):
            manifest = {**example, **changes}
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "manifest.json"
                path.write_text(json.dumps(manifest))
                with self.subTest(changes=changes):
                    with self.assertRaises(plezyctl.CliError):
                        plezyctl.load_manifest(path)


if __name__ == "__main__":
    unittest.main()
