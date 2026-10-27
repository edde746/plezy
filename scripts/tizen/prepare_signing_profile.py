#!/usr/bin/env python3
"""Materialize one Samsung Tizen signing profile from a protected job secret."""
from __future__ import annotations

import argparse
import base64
import binascii
import io
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import tarfile
import xml.etree.ElementTree as ET

MAX_ENCODED_BYTES = 64 * 1024
MAX_ARCHIVE_BYTES = 48 * 1024
MAX_EXPANDED_BYTES = 8 * 1024 * 1024
MAX_MEMBERS = 128
PROFILE_NAME = re.compile(r"^[A-Za-z0-9_.-]{1,80}$")
ALLOWED_SUFFIXES = {".p12", ".pwd", ".cer", ".crt", ".pem", ".der"}


class ProfileError(ValueError):
    pass


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def safe_relative_name(raw: str) -> PurePosixPath:
    if not raw or "\\" in raw or any(ord(ch) < 32 for ch in raw):
        raise ProfileError("profile bundle contains an unsafe path")
    if raw.startswith("/") or re.match(r"^[A-Za-z]:", raw):
        raise ProfileError("profile bundle paths must be relative")
    if any(part in {"..", ""} for part in raw.split("/")):
        raise ProfileError("profile bundle contains an unsafe path")
    path = PurePosixPath(raw)
    if path.is_absolute() or not path.parts or path.as_posix() in {".", ".."}:
        raise ProfileError("profile bundle contains an unsafe path")
    return path


def write_bundle(encoded: str, destination: Path) -> dict[str, Path]:
    compact = "".join(encoded.split())
    if not compact:
        raise ProfileError("Actions secret SAMSUNG_TIZEN_PROFILE_ARCHIVE_B64 is empty")
    if len(compact) > MAX_ENCODED_BYTES:
        raise ProfileError("encoded signing profile exceeds the supported secret size")
    try:
        compressed = base64.b64decode(compact, validate=True)
    except (binascii.Error, ValueError) as error:
        raise ProfileError("Actions secret is not valid base64") from error
    if len(compressed) > MAX_ARCHIVE_BYTES:
        raise ProfileError("compressed signing profile exceeds the supported secret size")

    files: dict[str, Path] = {}
    total_size = 0
    count = 0
    try:
        archive = tarfile.open(fileobj=io.BytesIO(compressed), mode="r|gz")
        with archive:
            for member in archive:
                count += 1
                if count > MAX_MEMBERS:
                    raise ProfileError("profile bundle contains too many entries")
                relative = safe_relative_name(member.name)
                if member.isdir():
                    continue
                if not member.isfile():
                    raise ProfileError("profile bundle may contain only directories and regular files")
                suffix = relative.suffix.lower()
                if relative.name.lower() != "profiles.xml" and suffix not in ALLOWED_SUFFIXES:
                    raise ProfileError("profile bundle contains an unsupported file type")
                if relative.as_posix() in files:
                    raise ProfileError("profile bundle contains duplicate paths")
                if member.size < 0 or member.size > MAX_EXPANDED_BYTES:
                    raise ProfileError("profile bundle contains an oversized file")
                total_size += member.size
                if total_size > MAX_EXPANDED_BYTES:
                    raise ProfileError("expanded profile bundle exceeds the supported size")
                source = archive.extractfile(member)
                if source is None:
                    raise ProfileError("profile bundle contains an unreadable file")
                target = destination.joinpath(*relative.parts)
                target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                with source, target.open("xb") as output:
                    shutil.copyfileobj(source, output, length=64 * 1024)
                target.chmod(0o600)
                files[relative.as_posix()] = target
    except (tarfile.TarError, OSError) as error:
        raise ProfileError("cannot read the protected signing profile bundle") from error
    profiles = [path for rel, path in files.items() if PurePosixPath(rel).name.lower() == "profiles.xml"]
    if len(profiles) != 1:
        raise ProfileError("bundle must contain exactly one profiles.xml")
    return files


def looks_like_certificate_path(value: str, attribute: str) -> bool:
    suffix = PurePosixPath(value.replace("\\", "/")).suffix.lower()
    if attribute == "password":
        return suffix == ".pwd"
    return suffix in ALLOWED_SUFFIXES


def resolve_bundled_file(value: str, files: dict[str, Path]) -> Path | None:
    normalized = value.strip().replace("\\", "/")
    parts = tuple(part for part in normalized.split("/") if part not in {"", ".", ".."})
    if not parts:
        return None
    relatives = [PurePosixPath(item).parts for item in files]
    for width in range(min(len(parts), 8), 0, -1):
        suffix = parts[-width:]
        matches = [
            files[item]
            for item, candidate_parts in zip(files, relatives)
            if len(candidate_parts) >= width and candidate_parts[-width:] == suffix
        ]
        if matches:
            if len(matches) != 1:
                raise ProfileError("certificate path is ambiguous in the protected bundle")
            return matches[0]
    return None


def prepare_profile(profile_name: str, destination: Path) -> Path:
    if not PROFILE_NAME.fullmatch(profile_name):
        raise ProfileError("invalid Samsung security profile name")
    encoded = os.environ.get("SAMSUNG_TIZEN_PROFILE_ARCHIVE_B64", "")
    runner_temp = os.environ.get("RUNNER_TEMP")
    if not runner_temp:
        raise ProfileError("RUNNER_TEMP is unavailable; signing material must stay in the ephemeral job")
    destination = destination.absolute()
    temp_root = Path(runner_temp).resolve()
    if not destination.resolve().is_relative_to(temp_root):
        raise ProfileError("signing material destination must be inside RUNNER_TEMP")
    if destination.exists() or destination.is_symlink():
        raise ProfileError("temporary signing directory already exists")
    destination.mkdir(parents=True, mode=0o700)
    try:
        files = write_bundle(encoded, destination)
        source_xml = next(path for rel, path in files.items() if PurePosixPath(rel).name.lower() == "profiles.xml")
        xml_bytes = source_xml.read_bytes()
        if len(xml_bytes) > 256 * 1024 or b"<!DOCTYPE" in xml_bytes.upper() or b"<!ENTITY" in xml_bytes.upper():
            raise ProfileError("profiles.xml is too large or contains unsafe XML declarations")
        try:
            root = ET.fromstring(xml_bytes)
        except ET.ParseError as error:
            raise ProfileError("profiles.xml is not valid XML") from error
        profile_nodes = [node for node in root.iter() if local_name(node.tag) == "profile"]
        selected = [node for node in profile_nodes if node.get("name") == profile_name]
        if len(selected) != 1:
            raise ProfileError("selected Samsung profile is missing or duplicated")
        chosen = selected[0]
        parent_map = {child: parent for parent in root.iter() for child in parent}
        if chosen not in parent_map:
            raise ProfileError("profiles.xml has an unexpected profile layout")
        for node in profile_nodes:
            if node is not chosen:
                parent = parent_map.get(node)
                if parent is not None:
                    parent.remove(node)
        if "active" in root.attrib:
            root.set("active", profile_name)

        items = [node for node in chosen.iter() if local_name(node.tag) == "profileitem"]
        distributors = {node.get("distributor") for node in items}
        if not items or "0" not in distributors or not (distributors - {"0", None, ""}):
            raise ProfileError("selected profile must include author and distributor certificates")
        for item in items:
            key = item.get("key", "")
            key_file = resolve_bundled_file(key, files)
            if not key_file or key_file.suffix.lower() != ".p12":
                raise ProfileError("selected profile's author/distributor certificate is missing")
            item.set("key", str(key_file))
            for attribute in ("password", "ca", "rootca"):
                value = item.get(attribute, "")
                if not value or not looks_like_certificate_path(value, attribute):
                    continue
                bundled = resolve_bundled_file(value, files)
                if bundled is None:
                    raise ProfileError("selected profile references a certificate file missing from the bundle")
                item.set(attribute, str(bundled))

        output_xml = destination / "profiles.xml"
        tree = ET.ElementTree(root)
        tree.write(output_xml, encoding="utf-8", xml_declaration=True)
        output_xml.chmod(0o600)
        if source_xml != output_xml:
            source_xml.unlink()
        return output_xml
    except Exception:
        shutil.rmtree(destination, ignore_errors=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True, help="selected Tizen security profile name")
    parser.add_argument("--destination", required=True, type=Path, help="private ephemeral output directory")
    args = parser.parse_args()
    try:
        prepare_profile(args.profile, args.destination)
    except (ProfileError, OSError, ET.ParseError) as error:
        parser.exit(1, f"Samsung profile preparation failed: {error}\n")
    print(f"Prepared Samsung Tizen signing profile {args.profile} in the ephemeral job workspace.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
