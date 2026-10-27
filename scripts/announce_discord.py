#!/usr/bin/env python3
"""Announce a published stable release, including its generated release notes."""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import Request

try:
    from maestro.safe_http import safe_urlopen
except ModuleNotFoundError:
    from scripts.maestro.safe_http import safe_urlopen


MAX_EMBED_DESCRIPTION = 3500


def split_description(text: str) -> list[str]:
    chunks: list[str] = []
    remaining = text
    while len(remaining) > MAX_EMBED_DESCRIPTION:
        boundary = remaining.rfind("\n", 0, MAX_EMBED_DESCRIPTION + 1)
        if boundary >= 0:
            boundary += 1
        else:
            boundary = remaining.rfind(" ", 0, MAX_EMBED_DESCRIPTION + 1)
            if boundary >= 0:
                boundary += 1
        if boundary <= 0:
            boundary = MAX_EMBED_DESCRIPTION
        chunks.append(remaining[:boundary])
        remaining = remaining[boundary:]
    if remaining:
        chunks.append(remaining)
    return chunks


def with_wait_parameter(webhook_url: str) -> str:
    parsed = urlsplit(webhook_url)
    if (
        parsed.scheme != "https"
        or parsed.netloc != "discord.com"
        or not parsed.path.startswith("/api/webhooks/")
    ):
        raise ValueError("DISCORD_RELEASE_WEBHOOK must be a Discord webhook URL.")
    query = [(key, value) for key, value in parse_qsl(parsed.query) if key != "wait"]
    query.append(("wait", "true"))
    return urlunsplit((parsed.scheme, parsed.netloc, parsed.path, urlencode(query), parsed.fragment))


def post(webhook_url: str, title: str, release_url: str, description: str) -> None:
    payload = {
        "username": "PlezyNG Releases",
        "embeds": [
            {
                "title": title,
                "url": release_url,
                "description": description,
                "color": 5793266,
            }
        ],
    }
    request = Request(
        webhook_url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with safe_urlopen(request, timeout=30) as response:
            result = json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        raise RuntimeError(f"Discord webhook returned HTTP {error.code}.") from None
    except URLError:
        raise RuntimeError("Could not reach the Discord webhook.") from None
    except json.JSONDecodeError:
        raise RuntimeError("Discord returned an invalid announcement response.") from None
    if not isinstance(result, dict):
        raise RuntimeError("Discord returned an invalid release announcement response.")
    embeds = result.get("embeds")
    if (
        not result.get("id")
        or not isinstance(embeds, list)
        or not embeds
        or not isinstance(embeds[0], dict)
        or embeds[0].get("description") != description
    ):
        raise RuntimeError("Discord did not confirm the release announcement.")


def main() -> int:
    webhook_value = os.environ.get("DISCORD_RELEASE_WEBHOOK", "")
    if not webhook_value:
        print("DISCORD_RELEASE_WEBHOOK is required to announce a release.", file=sys.stderr)
        return 1
    release_path = os.environ.get("RELEASE_JSON_PATH") or os.environ.get("GITHUB_EVENT_PATH", "")
    if not release_path:
        print("RELEASE_JSON_PATH or GITHUB_EVENT_PATH is required.", file=sys.stderr)
        return 1

    try:
        event = json.loads(Path(release_path).read_text(encoding="utf-8"))
        release = event.get("release", event)
        if not isinstance(release, dict):
            raise ValueError("release event data is invalid")
        if release.get("draft") or release.get("prerelease"):
            raise ValueError("only published stable releases can be announced")
        version = release["tag_name"]
        release_url = release["html_url"]
        body = release.get("body") or "Release assets are available."
        if not isinstance(version, str) or not isinstance(release_url, str) or not isinstance(body, str):
            raise ValueError("release event data is incomplete")
        webhook_url = with_wait_parameter(webhook_value)
    except (OSError, KeyError, TypeError, ValueError) as error:
        print(f"release announcement: {error}", file=sys.stderr)
        return 1

    chunks = split_description(body)
    if not chunks:
        chunks = ["Release assets are available."]
    try:
        for index, description in enumerate(chunks, start=1):
            suffix = f" ({index}/{len(chunks)})" if len(chunks) > 1 else ""
            post(
                webhook_url,
                f"PlezyNG {version} is out{suffix}",
                release_url,
                description,
            )
            if index < len(chunks):
                time.sleep(1)
    except RuntimeError as error:
        print(f"release announcement: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
