#!/usr/bin/env python3
"""Prepare a pinned, app-private Moonlight library; never download a binary APK."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ANDROID = "{http://schemas.android.com/apk/res/android}"


def run(*args: str, cwd: Path | None = None) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def private_manifest(source: Path, destination: Path) -> None:
    ET.register_namespace("android", ANDROID[1:-1])
    tree = ET.parse(source)
    app = tree.getroot().find("application")
    if app is None:
        raise ValueError("Upstream manifest has no application")
    # Host application owns icons, backup, network policy and theme.
    app.attrib.clear()
    for child in list(app):
        if child.tag not in {"activity", "service"}:
            app.remove(child)
            continue
        name = child.get(ANDROID + "name", "")
        if name.startswith("."):
            child.set(ANDROID + "name", "com.limelight" + name)
        child.set(ANDROID + "exported", "false")
        if child.tag == "activity" and ANDROID + "theme" not in child.attrib:
            child.set(ANDROID + "theme", "@style/AppTheme")
        # Embedded streaming belongs to Plezy's task and returns to Games.
        child.attrib.pop(ANDROID + "launchMode", None)
        for intent in list(child.findall("intent-filter")):
            child.remove(intent)
    for permission in list(tree.getroot().findall("uses-permission")):
        if "providers.tv" in permission.get(ANDROID + "name", ""):
            tree.getroot().remove(permission)
        elif permission.get(ANDROID + "name") == "android.permission.CHANGE_WIFI_MULTICAST_STATE":
            permission.attrib.pop(ANDROID + "maxSdkVersion", None)
    ET.indent(tree)
    tree.write(destination, encoding="utf-8", xml_declaration=True)


def patch_http(path: Path) -> None:
    source = path.read_text()
    anchor = "public class NvHTTP {"
    if source.count(anchor) != 1:
        raise ValueError("NvHTTP changed; review cancellation patch")
    source = source.replace(anchor, anchor + """
    // PlezyNG: cancellation stops a pending PIN request without unpairing the host.
    public void cancelPendingRequests() {
        httpClientLongConnectTimeout.dispatcher().cancelAll();
        httpClientLongConnectNoReadTimeout.dispatcher().cancelAll();
        httpClientShortConnectTimeout.dispatcher().cancelAll();
    }
""", 1)
    anchor = ".readTimeout(0, TimeUnit.MILLISECONDS)"
    if source.count(anchor) != 1:
        raise ValueError("NvHTTP changed; review pairing deadline")
    source = source.replace(anchor, anchor + "\n                .callTimeout(90, TimeUnit.SECONDS)", 1)
    path.write_text(source)


def prepare(destination: Path) -> None:
    lock = json.loads((ROOT / "games-native.lock.json").read_text())["moonlightAndroid"]
    recipe = hashlib.sha256(Path(__file__).read_bytes() + json.dumps(lock, sort_keys=True).encode()).hexdigest()
    marker = destination / ".plezy-recipe"
    if marker.exists() and marker.read_text() == recipe:
        return
    # Never replace someone's checkout or edits. Regeneration requires an explicit clean.
    if destination.exists():
        raise SystemExit(f"Stale prepared sources: remove {destination} and rerun after reviewing the lock/recipe change")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="moonlight-", dir=destination.parent) as staging:
        checkout = Path(staging) / "source"
        run("git", "init", "--quiet", str(checkout))
        run("git", "remote", "add", "origin", lock["repository"], cwd=checkout)
        run("git", "fetch", "--quiet", "--depth=1", "origin", lock["revision"], cwd=checkout)
        run("git", "checkout", "--quiet", "--detach", "FETCH_HEAD", cwd=checkout)
        if run("git", "rev-parse", "HEAD", cwd=checkout) != lock["revision"]:
            raise ValueError("Unexpected Moonlight revision")
        run("git", "submodule", "update", "--init", "--recursive", "--depth=1", cwd=checkout)
        common = checkout / "app/src/main/jni/moonlight-core/moonlight-common-c"
        if run("git", "rev-parse", "HEAD", cwd=common) != lock["commonRevision"]:
            raise ValueError("Unexpected Moonlight common revision")
        private_manifest(checkout / "app/src/main/AndroidManifest.xml", checkout / "EmbeddedManifest.xml")
        patch_http(checkout / "app/src/main/java/com/limelight/nvstream/http/NvHTTP.java")
        (checkout / ".plezy-recipe").write_text(recipe)
        shutil.move(str(checkout), destination)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / ".dart_tool/games/moonlight-android")
    prepare(parser.parse_args().output.resolve())
