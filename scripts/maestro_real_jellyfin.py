#!/usr/bin/env python3
"""Prepare and bootstrap a disposable real Jellyfin server for Maestro."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import time
from typing import Any
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

from maestro_fixtures import MEDIA_FIXTURE_SPECS, _AUDIO, _VIDEO

USERNAME = "maestro"
PASSWORD = "maestro"
GUEST_USERNAME = "guest"
GUEST_PASSWORD = "guest"
SERVER_NAME = "Maestro Jellyfin"
BASE_TITLE = "Maestro Movie"
BASE_OVERVIEW = "A deterministic movie used to verify Plezy's end-to-end flows."
GUEST_TITLE = "Guest Galaxy"
SHOW_TITLE = "Maestro Show"
EPISODE_TITLES = ("Maestro Episode 1", "Maestro Episode 2")
MUSIC_ARTIST = "Maestro Artist"
MUSIC_ALBUM = "Regression Album"
MUSIC_TRACK = "Resilient Track"
ALPHABET_TITLES = (
    "Alpha Archive",
    "Bravo Beacon",
    "Charlie Circuit",
    "Delta Drive",
    "Echo Engine",
    "Foxtrot Frame",
    "Gamma Garden",
    "Hotel Horizon",
    "India Index",
    "Juliet Junction",
    "Kilo Key",
    "Lima Loop",
    "Mike Matrix",
    "November Node",
    "Oscar Orbit",
    "Papa Pipeline",
    "Quebec Queue",
    "Romeo Relay",
    "Sierra Signal",
    "Tango Track",
    "Uniform Update",
    "Victor View",
    "Whiskey Widget",
    "Xray XML",
    "Yankee Yield",
    "Zulu Zone",
)
_MANAGED_MARKER = ".plezy-jellyfin-e2e-media"
DEFAULT_CODEC_BASE_URL = "https://demo-files.plezy.app/media-samples/"
_DOWNLOAD_CHUNK_SIZE = 1024 * 1024



def _write_nfo(path: Path, *, item_id: str, title: str, overview: str, genre: str) -> None:
    movie = ET.Element("movie")
    values = {
        "title": title,
        "originaltitle": title,
        "sorttitle": title,
        "year": "2026",
        "premiered": "2026-01-01",
        "dateadded": "2026-01-01 00:00:00",
        "plot": overview,
        "outline": overview,
        "studio": "Plezy E2E",
        "genre": genre,
        "tag": "E2E",
        "mpaa": "E2E",
        "rating": "8.0",
        "lockdata": "true",
    }
    for key, value in values.items():
        ET.SubElement(movie, key).text = value
    unique_id = ET.SubElement(movie, "uniqueid", {"type": "plezy", "default": "true"})
    unique_id.text = item_id
    ET.indent(movie, space="  ")
    ET.ElementTree(movie).write(path, encoding="utf-8", xml_declaration=True)

def _write_show_nfo(path: Path) -> None:
    show = ET.Element("tvshow")
    for key, value in {
        "title": SHOW_TITLE,
        "sorttitle": SHOW_TITLE,
        "year": "2026",
        "premiered": "2026-01-01",
        "plot": "A deterministic show used to verify episode playback and queue behavior.",
        "studio": "Plezy E2E",
        "genre": "Test",
        "lockdata": "true",
    }.items():
        ET.SubElement(show, key).text = value
    unique_id = ET.SubElement(show, "uniqueid", {"type": "plezy", "default": "true"})
    unique_id.text = "maestro-show"
    ET.indent(show, space="  ")
    ET.ElementTree(show).write(path, encoding="utf-8", xml_declaration=True)


def _write_episode_nfo(path: Path, number: int) -> None:
    episode = ET.Element("episodedetails")
    title = EPISODE_TITLES[number - 1]
    for key, value in {
        "title": title,
        "showtitle": SHOW_TITLE,
        "season": "1",
        "episode": str(number),
        "aired": f"2026-01-0{number}",
        "plot": f"Deterministic episode {number} for player queue coverage.",
        "lockdata": "true",
    }.items():
        ET.SubElement(episode, key).text = value
    unique_id = ET.SubElement(episode, "uniqueid", {"type": "plezy", "default": "true"})
    unique_id.text = f"maestro-episode-{number}"
    ET.indent(episode, space="  ")
    ET.ElementTree(episode).write(path, encoding="utf-8", xml_declaration=True)


def _write_music_nfo(path: Path, root_name: str, values: dict[str, str]) -> None:
    root = ET.Element(root_name)
    for key, value in values.items():
        ET.SubElement(root, key).text = value
    ET.indent(root, space="  ")
    ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=True)


def _reset_managed_directory(path: Path) -> None:
    marker = path / _MANAGED_MARKER
    if not path.exists():
        path.mkdir(parents=True)
        marker.write_text("Managed by scripts/maestro_real_jellyfin.py\n", encoding="utf-8")
        return
    if not marker.is_file():
        if any(path.iterdir()):
            raise ValueError(f"Refusing to clear unmanaged media staging directory: {path}")
        marker.write_text("Managed by scripts/maestro_real_jellyfin.py\n", encoding="utf-8")
        return
    for child in path.iterdir():
        if child == marker:
            continue
        if child.is_dir() and not child.is_symlink():
            shutil.rmtree(child)
        else:
            child.unlink()


def _hard_link(source: Path, destination: Path) -> None:
    try:
        os.link(source, destination)
    except OSError as error:
        raise ValueError(
            f"Could not hard-link {source} into the staging directory; keep both paths on the same filesystem"
        ) from error


def _codec_digest(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(_DOWNLOAD_CHUNK_SIZE):
            digest.update(chunk)
    return digest.hexdigest()


def _valid_codec_file(path: Path, expected_size: int, expected_sha256: str) -> bool:
    return path.is_file() and path.stat().st_size == expected_size and _codec_digest(path) == expected_sha256


def download_codec_media(output_dir: Path, base_url: str = DEFAULT_CODEC_BASE_URL) -> list[str]:
    output = output_dir.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    normalized_base_url = base_url.rstrip("/") + "/"
    filenames: list[str] = []

    for spec in MEDIA_FIXTURE_SPECS:
        destination = output / spec.filename
        filenames.append(spec.filename)
        if _valid_codec_file(destination, spec.size_bytes, spec.sha256):
            continue

        partial = destination.with_suffix(f"{destination.suffix}.part")
        partial.unlink(missing_ok=True)
        request = urllib.request.Request(
            urllib.parse.urljoin(normalized_base_url, urllib.parse.quote(spec.filename)),
            headers={"User-Agent": "plezy-jellyfin-demo-builder"},
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw_length = response.headers.get("Content-Length")
                if raw_length is not None and int(raw_length) != spec.size_bytes:
                    raise ValueError(
                        f"{spec.filename} download is {raw_length} bytes, expected {spec.size_bytes}"
                    )
                total = 0
                digest = hashlib.sha256()
                with partial.open("wb") as target:
                    while chunk := response.read(_DOWNLOAD_CHUNK_SIZE):
                        total += len(chunk)
                        if total > spec.size_bytes:
                            raise ValueError(f"{spec.filename} download exceeds {spec.size_bytes} bytes")
                        digest.update(chunk)
                        target.write(chunk)
            if total != spec.size_bytes:
                raise ValueError(f"{spec.filename} download is {total} bytes, expected {spec.size_bytes}")
            if digest.hexdigest() != spec.sha256:
                raise ValueError(f"{spec.filename} download failed SHA-256 verification")
            partial.replace(destination)
        except (OSError, ValueError, urllib.error.URLError):
            partial.unlink(missing_ok=True)
            raise

    return filenames


def prepare_media(output_dir: Path, codec_source_dir: Path | None, include_codecs: bool) -> list[str]:
    output = output_dir.expanduser().resolve()
    _reset_managed_directory(output)

    base_dir = output / "movies" / "maestro-movie"
    base_dir.mkdir(parents=True)
    (base_dir / f"{BASE_TITLE}.mp4").write_bytes(_VIDEO)
    _write_nfo(
        base_dir / f"{BASE_TITLE}.nfo",
        item_id="maestro-movie",
        title=BASE_TITLE,
        overview=BASE_OVERVIEW,
        genre="Test",
    )
    titles = [BASE_TITLE]

    for alphabet_title in ALPHABET_TITLES:
        for copy in range(1, 5):
            title = alphabet_title if copy == 1 else f"{alphabet_title} {copy}"
            item_id = f"alpha-{title.lower().replace(' ', '-')}"
            item_dir = output / "movies" / item_id
            item_dir.mkdir()
            media_path = item_dir / f"{title}.mp4"
            media_path.write_bytes(_VIDEO)
            _write_nfo(
                media_path.with_suffix(".nfo"),
                item_id=item_id,
                title=title,
                overview="A deterministic title for TV alphabet focus coverage.",
                genre="E2E Alphabet",
            )
            titles.append(title)

    guest_dir = output / "guest-movies" / "guest-galaxy"
    guest_dir.mkdir(parents=True)
    guest_media = guest_dir / f"{GUEST_TITLE}.mp4"
    guest_media.write_bytes(_VIDEO)
    _write_nfo(
        guest_media.with_suffix(".nfo"),
        item_id="guest-galaxy",
        title=GUEST_TITLE,
        overview="Content visible only to the Maestro Guest profile.",
        genre="E2E Guest",
    )

    show_dir = output / "shows" / SHOW_TITLE
    season_dir = show_dir / "Season 01"
    season_dir.mkdir(parents=True)
    _write_show_nfo(show_dir / "tvshow.nfo")
    for number, title in enumerate(EPISODE_TITLES, start=1):
        episode_path = season_dir / f"{SHOW_TITLE} S01E{number:02d} - {title}.mp4"
        episode_path.write_bytes(_VIDEO)
        _write_episode_nfo(episode_path.with_suffix(".nfo"), number)

    album_dir = output / "music" / MUSIC_ARTIST / MUSIC_ALBUM
    album_dir.mkdir(parents=True)
    (album_dir / f"{MUSIC_TRACK}.wav").write_bytes(_AUDIO)
    _write_music_nfo(
        album_dir.parent / "artist.nfo",
        "artist",
        {"name": MUSIC_ARTIST, "sortname": MUSIC_ARTIST, "overview": "Deterministic E2E music artist."},
    )
    _write_music_nfo(
        album_dir / "album.nfo",
        "album",
        {
            "title": MUSIC_ALBUM,
            "artist": MUSIC_ARTIST,
            "albumartist": MUSIC_ARTIST,
            "year": "2026",
            "review": "Deterministic E2E music album.",
        },
    )

    if not include_codecs:
        return titles
    if codec_source_dir is None:
        raise ValueError("--codec-source-dir is required with --include-codecs")

    source_dir = codec_source_dir.expanduser().resolve()
    missing = [spec.filename for spec in MEDIA_FIXTURE_SPECS if not (source_dir / spec.filename).is_file()]
    if missing:
        raise ValueError(f"Codec fixture directory is missing: {', '.join(missing)}")

    for spec in MEDIA_FIXTURE_SPECS:
        item_dir = output / "movies" / spec.id
        item_dir.mkdir()
        media_path = item_dir / f"{spec.title}.mkv"
        _hard_link(source_dir / spec.filename, media_path)
        _write_nfo(
            media_path.with_suffix(".nfo"),
            item_id=spec.id,
            title=spec.title,
            overview=spec.overview,
            genre="E2E Codec",
        )
        titles.append(spec.title)
    return titles


class JellyfinApi:
    def __init__(self, base_url: str) -> None:
        self.base_url = base_url.rstrip("/")

    def request(
        self,
        method: str,
        path: str,
        *,
        payload: Any | None = None,
        token: str | None = None,
        headers: dict[str, str] | None = None,
        timeout: float = 30,
    ) -> tuple[int, bytes]:
        request_headers = {"Accept": "application/json", **(headers or {})}
        data: bytes | None = None
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            request_headers["Content-Type"] = "application/json"
        elif method == "POST":
            data = b""
        if token is not None:
            request_headers["X-Emby-Token"] = token
        request = urllib.request.Request(self.base_url + path, data=data, method=method, headers=request_headers)
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            return error.code, error.read()

    def json(self, method: str, path: str, **kwargs: Any) -> Any:
        status, body = self.request(method, path, **kwargs)
        if status < 200 or status >= 300:
            detail = body.decode("utf-8", errors="replace")[:500]
            raise RuntimeError(f"Jellyfin {method} {path} returned HTTP {status}: {detail}")
        return json.loads(body) if body else None


def _wait_until(deadline: float, description: str, operation: Any) -> Any:
    last_error: Exception | None = None
    while time.monotonic() < deadline:
        try:
            result = operation()
            if result is not None:
                return result
        except (OSError, RuntimeError, urllib.error.URLError) as error:
            last_error = error
        time.sleep(1)
    suffix = f": {last_error}" if last_error is not None else ""
    raise TimeoutError(f"Timed out waiting for {description}{suffix}")


def bootstrap_server(
    base_url: str,
    expected_titles: set[str],
    timeout_seconds: int,
    expected_music_titles: set[str] | None = None,
) -> dict[str, Any]:
    api = JellyfinApi(base_url)
    deadline = time.monotonic() + timeout_seconds

    def public_info() -> dict[str, Any] | None:
        status, body = api.request("GET", "/System/Info/Public", timeout=3)
        if status != 200:
            return None
        return json.loads(body)

    info = _wait_until(deadline, "Jellyfin startup", public_info)
    version = info.get("Version") or info.get("version")
    if version != "10.11.11":
        raise RuntimeError(f"Expected Jellyfin 10.11.11, got {version}")

    startup_complete = info.get("StartupWizardCompleted", info.get("startupWizardCompleted", False))
    if not startup_complete:

        def configure_startup() -> bool | None:
            status, body = api.request(
                "POST",
                "/Startup/Configuration",
                payload={
                    "UICulture": "en-US",
                    "MetadataCountryCode": "US",
                    "PreferredMetadataLanguage": "en",
                },
            )
            if status == 204:
                return True
            if status == 503:
                return None
            detail = body.decode("utf-8", errors="replace")[:500]
            raise RuntimeError(f"Jellyfin startup configuration returned HTTP {status}: {detail}")

        _wait_until(deadline, "Jellyfin startup API", configure_startup)

        def startup_user() -> dict[str, Any] | None:
            status, body = api.request("GET", "/Startup/User", timeout=3)
            if status != 200:
                return None
            return json.loads(body)

        _wait_until(deadline, "Jellyfin startup user", startup_user)
        api.json("POST", "/Startup/User", payload={"Name": USERNAME, "Password": PASSWORD})
        api.json("POST", "/Startup/Complete")

    authorization = (
        'MediaBrowser Client="Plezy E2E Bootstrap", Device="Host", '
        'DeviceId="plezy-e2e-bootstrap", Version="1.0"'
    )

    def authenticate(username: str, password: str) -> dict[str, Any] | None:
        status, body = api.request(
            "POST",
            "/Users/AuthenticateByName",
            payload={"Username": username, "Pw": password},
            headers={"Authorization": authorization},
            timeout=5,
        )
        if status != 200:
            return None
        return json.loads(body)

    authentication = _wait_until(deadline, "Jellyfin authentication", lambda: authenticate(USERNAME, PASSWORD))
    token = authentication["AccessToken"]
    user_id = authentication["User"]["Id"]

    configuration = api.json("GET", "/System/Configuration", token=token)
    if configuration.get("ServerName") != SERVER_NAME:
        configuration["ServerName"] = SERVER_NAME
        api.json("POST", "/System/Configuration", payload=configuration, token=token)

    required_folders = (
        ("Maestro Movies", "movies", "/media/movies"),
        ("Guest Movies", "movies", "/media/guest-movies"),
        ("Maestro Shows", "tvshows", "/media/shows"),
        ("Maestro Music", "music", "/media/music"),
    )
    virtual_folders = api.json("GET", "/Library/VirtualFolders", token=token)
    existing_folder_names = {folder.get("Name") for folder in virtual_folders}
    for name, collection_type, path in required_folders:
        if name in existing_folder_names:
            continue
        query = urllib.parse.urlencode(
            {
                "name": name,
                "collectionType": collection_type,
                "paths": path,
                "refreshLibrary": "false",
            }
        )
        api.json("POST", f"/Library/VirtualFolders?{query}", token=token)

    users = api.json("GET", "/Users", token=token)
    main_user = next(user for user in users if user["Id"] == user_id)
    guest_user = next((user for user in users if user.get("Name") == GUEST_USERNAME), None)
    if guest_user is None:
        guest_user = api.json(
            "POST",
            "/Users/New",
            payload={"Name": GUEST_USERNAME, "Password": GUEST_PASSWORD},
            token=token,
        )
    if not guest_user.get("HasPassword", guest_user.get("HasConfiguredPassword", False)):
        api.json(
            "POST",
            f"/Users/{guest_user['Id']}/Password",
            payload={"CurrentPw": "", "NewPw": GUEST_PASSWORD},
            token=token,
        )

    unrestricted_policy = dict(main_user["Policy"])
    unrestricted_policy["EnableAllFolders"] = True
    unrestricted_policy["EnabledFolders"] = []
    api.json("POST", f"/Users/{user_id}/Policy", payload=unrestricted_policy, token=token)

    views = api.json("GET", f"/Users/{user_id}/Views", token=token).get("Items", [])
    views_by_name = {view.get("Name"): view.get("Id") for view in views}
    missing_views = [name for name, _, _ in required_folders if not views_by_name.get(name)]
    if missing_views:
        raise RuntimeError(f"Jellyfin did not create library views: {', '.join(missing_views)}")

    main_policy = dict(main_user["Policy"])
    main_policy["EnableAllFolders"] = False
    main_policy["EnabledFolders"] = [
        views_by_name["Maestro Movies"],
        views_by_name["Maestro Shows"],
        views_by_name["Maestro Music"],
    ]
    api.json("POST", f"/Users/{user_id}/Policy", payload=main_policy, token=token)

    guest_policy = dict(guest_user["Policy"])
    guest_policy["EnableAllFolders"] = False
    guest_policy["EnabledFolders"] = [views_by_name["Guest Movies"]]
    api.json("POST", f"/Users/{guest_user['Id']}/Policy", payload=guest_policy, token=token)

    api.json("POST", "/Library/Refresh", token=token)

    def scanned_items() -> list[dict[str, Any]] | None:
        query = urllib.parse.urlencode(
            {
                "Recursive": "true",
                "IncludeItemTypes": "Movie",
                "Fields": "MediaSources,MediaStreams",
                "Limit": "500",
            }
        )
        result = api.json("GET", f"/Users/{user_id}/Items?{query}", token=token)
        items = result.get("Items", [])
        by_title = {item.get("Name"): item for item in items}
        if not expected_titles.issubset(by_title):
            return None
        if any(not by_title[title].get("MediaSources") for title in expected_titles):
            return None
        if GUEST_TITLE in by_title:
            raise RuntimeError("Main Jellyfin user can see the guest-only library")
        return items

    items = _wait_until(deadline, "Jellyfin media scan", scanned_items)
    required_music = expected_music_titles or {MUSIC_TRACK}

    def scanned_music() -> list[dict[str, Any]] | None:
        query = urllib.parse.urlencode(
            {
                "Recursive": "true",
                "IncludeItemTypes": "Audio",
                "Fields": "MediaSources,MediaStreams,Album,AlbumId,AlbumArtist,AlbumArtists",
                "Limit": "100",
            }
        )
        result = api.json("GET", f"/Users/{user_id}/Items?{query}", token=token)
        music_items = result.get("Items", [])
        by_title = {item.get("Name"): item for item in music_items}
        if not required_music.issubset(by_title):
            return None
        if any(not by_title[title].get("MediaSources") for title in required_music):
            return None
        return music_items

    music_items = _wait_until(deadline, "Jellyfin music scan", scanned_music)

    def scanned_artists() -> list[dict[str, Any]] | None:
        query = urllib.parse.urlencode({"UserId": user_id, "Limit": "100"})
        result = api.json("GET", f"/Artists/AlbumArtists?{query}", token=token)
        artists = result.get("Items", [])
        if MUSIC_ARTIST not in {artist.get("Name") for artist in artists}:
            return None
        return artists

    artist_items = _wait_until(deadline, "Jellyfin music artist scan", scanned_artists)

    def scanned_episodes() -> list[dict[str, Any]] | None:
        query = urllib.parse.urlencode(
            {
                "Recursive": "true",
                "IncludeItemTypes": "Episode",
                "Fields": "MediaSources,MediaStreams,SeriesId,ParentId,IndexNumber",
                "Limit": "100",
            }
        )
        result = api.json("GET", f"/Users/{user_id}/Items?{query}", token=token)
        episodes = result.get("Items", [])
        by_title = {item.get("Name"): item for item in episodes}
        if not set(EPISODE_TITLES).issubset(by_title):
            return None
        if any(not by_title[title].get("MediaSources") for title in EPISODE_TITLES):
            return None
        return episodes

    episode_items = _wait_until(deadline, "Jellyfin episode scan", scanned_episodes)
    guest_authentication = _wait_until(
        deadline,
        "Jellyfin guest authentication",
        lambda: authenticate(GUEST_USERNAME, GUEST_PASSWORD),
    )
    guest_token = guest_authentication["AccessToken"]

    def scanned_guest_items() -> list[dict[str, Any]] | None:
        query = urllib.parse.urlencode(
            {
                "Recursive": "true",
                "IncludeItemTypes": "Movie",
                "Fields": "MediaSources,MediaStreams",
                "Limit": "100",
            }
        )
        result = api.json("GET", f"/Users/{guest_user['Id']}/Items?{query}", token=guest_token)
        guest_items = result.get("Items", [])
        by_title = {item.get("Name"): item for item in guest_items}
        if GUEST_TITLE not in by_title or not by_title[GUEST_TITLE].get("MediaSources"):
            return None
        if BASE_TITLE in by_title:
            raise RuntimeError("Guest Jellyfin user can see the main library")
        return guest_items

    guest_items = _wait_until(deadline, "Jellyfin guest media scan", scanned_guest_items)
    return {
        "server": SERVER_NAME,
        "version": "10.11.11",
        "userId": user_id,
        "guestUserId": guest_user["Id"],
        "titles": sorted(item["Name"] for item in items if item.get("Name") in expected_titles),
        "musicTitles": sorted(item["Name"] for item in music_items if item.get("Name") in required_music),
        "artistTitles": sorted(item["Name"] for item in artist_items if item.get("Name") == MUSIC_ARTIST),
        "episodeTitles": sorted(item["Name"] for item in episode_items if item.get("Name") in EPISODE_TITLES),
        "guestTitles": sorted(item["Name"] for item in guest_items if item.get("Name") == GUEST_TITLE),
    }


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    prepare = subparsers.add_parser("prepare", help="Create the deterministic media staging tree")
    prepare.add_argument("--output-dir", type=Path, required=True)
    prepare.add_argument("--codec-source-dir", type=Path)
    prepare.add_argument("--include-codecs", action="store_true")

    download = subparsers.add_parser("download-codecs", help="Download and verify the hosted codec fixtures")
    download.add_argument("--output-dir", type=Path, required=True)
    download.add_argument(
        "--base-url",
        default=os.environ.get("PLEZY_DEMO_MEDIA_BASE_URL", DEFAULT_CODEC_BASE_URL),
    )

    bootstrap = subparsers.add_parser("bootstrap", help="Configure and verify a fresh Jellyfin server")
    bootstrap.add_argument("--url", required=True)
    bootstrap.add_argument("--expected-title", action="append", default=[])
    bootstrap.add_argument("--expected-music-title", action="append", default=[])
    bootstrap.add_argument("--timeout", type=int, default=600)
    bootstrap.add_argument("--include-codecs", action="store_true")
    return parser


def main() -> int:
    args = _build_parser().parse_args()
    try:
        if args.command == "download-codecs":
            filenames = download_codec_media(args.output_dir, args.base_url)
            print(json.dumps({"codecDir": str(args.output_dir.resolve()), "files": filenames}, sort_keys=True))
        elif args.command == "prepare":
            titles = prepare_media(args.output_dir, args.codec_source_dir, args.include_codecs)
            print(json.dumps({"mediaDir": str(args.output_dir.resolve()), "titles": titles}, sort_keys=True))
        else:
            expected = {BASE_TITLE, *args.expected_title}
            expected.update(
                title if copy == 1 else f"{title} {copy}"
                for title in ALPHABET_TITLES
                for copy in range(1, 5)
            )
            if args.include_codecs:
                expected.update(spec.title for spec in MEDIA_FIXTURE_SPECS)
            expected_music = set(args.expected_music_title) or {MUSIC_TRACK}
            result = bootstrap_server(args.url, expected, args.timeout, expected_music)
            print(json.dumps(result, sort_keys=True))
        return 0
    except (OSError, RuntimeError, TimeoutError, ValueError) as error:
        print(f"Real Jellyfin E2E setup failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
