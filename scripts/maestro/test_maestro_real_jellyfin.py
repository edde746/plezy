#!/usr/bin/env python3

import hashlib
import io

from pathlib import Path
import sys
import tempfile
from unittest.mock import patch
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parent))

from maestro_fixtures import MEDIA_FIXTURE_SPECS, MediaFixtureSpec  # noqa: E402
import maestro_real_jellyfin as real_jellyfin  # noqa: E402
from maestro_real_jellyfin import (  # noqa: E402
    ALPHABET_TITLES,
    BASE_TITLE,
    EPISODE_TITLES,
    GUEST_TITLE,
    download_codec_media,
    prepare_media,
)


class PrepareMediaTests(unittest.TestCase):
    def test_base_media_is_deterministic_and_repeatable(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "media"

            titles = prepare_media(output, None, False)
            self.assertEqual(titles[0], BASE_TITLE)
            self.assertEqual(len(titles), 1 + len(ALPHABET_TITLES) * 4)
            movie = output / "movies" / "maestro-movie" / f"{BASE_TITLE}.mp4"
            nfo = movie.with_suffix(".nfo")
            first_payload = movie.read_bytes()
            self.assertGreater(len(first_payload), 0)
            self.assertEqual(ET.parse(nfo).findtext("title"), BASE_TITLE)
            self.assertEqual(
                ET.parse(output / "guest-movies" / "guest-galaxy" / f"{GUEST_TITLE}.nfo").findtext("title"),
                GUEST_TITLE,
            )
            episode_nfo = output / "shows" / "Maestro Show" / "Season 01" / (
                f"Maestro Show S01E01 - {EPISODE_TITLES[0]}.nfo"
            )
            self.assertEqual(ET.parse(episode_nfo).findtext("title"), EPISODE_TITLES[0])

            (output / "obsolete").mkdir()
            self.assertEqual(prepare_media(output, None, False), titles)
            self.assertEqual(movie.read_bytes(), first_payload)
            self.assertFalse((output / "obsolete").exists())

    def test_codec_media_uses_hard_links_and_exact_titles(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "source"
            source.mkdir()
            for spec in MEDIA_FIXTURE_SPECS:
                (source / spec.filename).write_bytes(spec.id.encode("utf-8"))

            output = root / "media"
            titles = prepare_media(output, source, True)

            self.assertEqual(titles[0], BASE_TITLE)
            self.assertEqual(titles[-len(MEDIA_FIXTURE_SPECS) :], [spec.title for spec in MEDIA_FIXTURE_SPECS])
            for spec in MEDIA_FIXTURE_SPECS:
                staged = output / "movies" / spec.id / f"{spec.title}.mkv"
                self.assertTrue(staged.samefile(source / spec.filename))
                self.assertEqual(ET.parse(staged.with_suffix(".nfo")).findtext("title"), spec.title)

    def test_codec_download_verifies_size_and_sha256_then_reuses_file(self) -> None:
        payload = b"deterministic codec payload"
        spec = MediaFixtureSpec(
            id="codec-test",
            title="Codec Test",
            filename="codec-test.mkv",
            overview="Test fixture.",
            video_codec="h264",
            width=320,
            height=180,
            size_bytes=len(payload),
            sha256=hashlib.sha256(payload).hexdigest(),
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir)
            response = io.BytesIO(payload)
            response.headers = {"Content-Length": str(len(payload))}
            with (
                patch.object(real_jellyfin, "MEDIA_FIXTURE_SPECS", (spec,)),
                patch.object(real_jellyfin.urllib.request, "urlopen", return_value=response) as urlopen,
            ):
                self.assertEqual(download_codec_media(output, "https://media.example/"), [spec.filename])
                self.assertEqual((output / spec.filename).read_bytes(), payload)
                self.assertEqual(urlopen.call_count, 1)

            with (
                patch.object(real_jellyfin, "MEDIA_FIXTURE_SPECS", (spec,)),
                patch.object(
                    real_jellyfin.urllib.request,
                    "urlopen",
                    side_effect=AssertionError("valid cached fixture must not be downloaded"),
                ),
            ):
                self.assertEqual(download_codec_media(output, "https://media.example/"), [spec.filename])

    def test_codec_download_rejects_corrupt_payload_without_leaving_partial_file(self) -> None:
        payload = b"corrupt"
        spec = MediaFixtureSpec(
            id="codec-test",
            title="Codec Test",
            filename="codec-test.mkv",
            overview="Test fixture.",
            video_codec="h264",
            width=320,
            height=180,
            size_bytes=len(payload),
            sha256=hashlib.sha256(b"expected").hexdigest(),
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir)
            response = io.BytesIO(payload)
            response.headers = {"Content-Length": str(len(payload))}
            with (
                patch.object(real_jellyfin, "MEDIA_FIXTURE_SPECS", (spec,)),
                patch.object(real_jellyfin.urllib.request, "urlopen", return_value=response),
            ):
                with self.assertRaisesRegex(ValueError, "failed SHA-256 verification"):
                    download_codec_media(output, "https://media.example/")

            self.assertFalse((output / spec.filename).exists())
            self.assertFalse((output / f"{spec.filename}.part").exists())


    def test_existing_empty_directory_can_become_managed(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "media"
            output.mkdir()

            self.assertEqual(prepare_media(output, None, False)[0], BASE_TITLE)
            self.assertTrue((output / "movies" / "maestro-movie" / f"{BASE_TITLE}.mp4").is_file())

    def test_existing_unmanaged_directory_is_never_cleared(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "media"
            output.mkdir()
            sentinel = output / "keep.txt"
            sentinel.write_text("user data", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "unmanaged media staging directory"):
                prepare_media(output, None, False)

            self.assertEqual(sentinel.read_text(encoding="utf-8"), "user data")


if __name__ == "__main__":
    unittest.main()
