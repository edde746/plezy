#!/usr/bin/env python3
"""Verify pinned webOS runtime inputs and inspect a produced PlezyNG IPK."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import struct
import sys
import tarfile
import zipfile
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[2]
LOCK_PATH = ROOT / "tools" / "webos" / "compatibility.json"
APP_ID = "org.snapetech.plezyng"
EXPECTED_MAINTAINER = "SnapeTech <noreply@github.com>"
EXPECTED_DESCRIPTION = "Plex media client for LG webOS TVs."
APP_ROOT = PurePosixPath("usr/palm/applications") / APP_ID
GEN_SNAPSHOT = "linux-x64/gen_snapshot"
RUNTIME_LIBRARIES = (
    "libflutter_engine.so",
    "libflutter_common.so",
    "libflutter_webos_media.so",
)
REQUIRED_NATIVE_LIBRARIES = (
    "libapp.so",
    "libplezy_torrent.so",
    "libflutter_secure_storage_webos_plugin.so",
    "libshared_preferences_webos_plugin.so",
    "libvideo_player_drm_plugin.so",
)
LICENSE_ASSET = ROOT / "assets" / "licenses" / "LGFlutterWebOSRuntimeNotice.txt"
MAX_IPK_BYTES = 512 * 1024 * 1024
MAX_UNCOMPRESSED_BYTES = 512 * 1024 * 1024
MAX_TAR_ENTRIES = 100_000


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_zip_member(path: Path, name: str) -> bytes:
    try:
        with zipfile.ZipFile(path) as archive:
            return archive.read(name)
    except (OSError, KeyError, zipfile.BadZipFile) as exc:
        raise ValueError(f"cannot read {name} from {path}: {exc}") from exc


def read_ar_archive(path: Path) -> dict[str, bytes]:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"IPK input must be a regular, non-symlink file: {path}")
    try:
        if path.stat().st_size > MAX_IPK_BYTES:
            raise ValueError(f"IPK exceeds the {MAX_IPK_BYTES}-byte safety limit")
        contents = path.read_bytes()
    except OSError as exc:
        raise ValueError(f"cannot read IPK {path}: {exc}") from exc
    if not contents.startswith(b"!<arch>\n"):
        raise ValueError("file does not have the IPK/ar archive header")
    members: dict[str, bytes] = {}
    offset = 8
    while offset < len(contents):
        header = contents[offset : offset + 60]
        if len(header) != 60 or header[58:60] != b"`\n":
            raise ValueError("malformed IPK ar member header")
        try:
            name = header[:16].decode("ascii").strip()
            size = int(header[48:58].decode("ascii").strip())
        except (UnicodeDecodeError, ValueError) as exc:
            raise ValueError("malformed IPK ar member name or size") from exc
        if name.endswith("/"):
            name = name[:-1]
        if not name or name in members or name.startswith("#"):
            raise ValueError(f"invalid or duplicate IPK ar member: {name!r}")
        if size < 0:
            raise ValueError(f"negative IPK ar member size: {name}")
        start = offset + 60
        end = start + size
        if end > len(contents):
            raise ValueError(f"truncated IPK ar member: {name}")
        members[name] = contents[start:end]
        if size & 1:
            if end >= len(contents) or contents[end : end + 1] != b"\n":
                raise ValueError(f"invalid IPK ar padding after {name}")
            offset = end + 1
        else:
            offset = end
    expected = ["debian-binary", "control.tar.gz", "data.tar.gz"]
    if list(members) != expected:
        raise ValueError(f"unexpected IPK ar member order or contents: {list(members)!r}")
    if members["debian-binary"] not in (b"2.0", b"2.0\n"):
        raise ValueError("unsupported webOS IPK format version")
    return members


def read_tar_member(archive_bytes: bytes, member_name: str) -> bytes:
    return read_tar_members(
        archive_bytes,
        {member_name},
        validate_app_layout=False,
        expected_names={member_name},
    )[member_name]


def parse_control_fields(control_bytes: bytes) -> dict[str, str]:
    try:
        control = control_bytes.decode("utf-8", errors="strict")
    except UnicodeDecodeError as exc:
        raise ValueError("IPK control metadata is not valid UTF-8") from exc
    if "\r" in control or not control.endswith("\n\n"):
        raise ValueError("IPK control metadata must use LF lines and end with one paragraph separator")

    lines = control[:-2].split("\n")
    fields: dict[str, str] = {}
    for line in lines:
        if not line or line[0].isspace():
            raise ValueError("IPK control metadata contains an empty or folded field")
        key, separator, value = line.partition(":")
        if not separator or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*", key):
            raise ValueError("IPK control metadata contains a malformed field")
        if key in fields:
            raise ValueError(f"IPK control metadata repeats field {key!r}")
        fields[key] = value.lstrip(" ")
    return fields


def read_tar_members(
    archive_bytes: bytes,
    required: set[str],
    *,
    validate_app_layout: bool = True,
    expected_names: set[str] | None = None,
) -> dict[str, bytes]:
    try:
        with tarfile.open(fileobj=io.BytesIO(archive_bytes), mode="r|gz") as archive:
            found: dict[str, bytes] = {}
            names: set[str] = set()
            unpacked_bytes = 0
            app_prefix = f"{APP_ROOT.as_posix()}/"
            package_prefix = f"usr/palm/packages/{APP_ID}/"
            allowed_directories = {
                "usr",
                "usr/palm",
                "usr/palm/applications",
                str(APP_ROOT),
                "usr/palm/packages",
                f"usr/palm/packages/{APP_ID}",
            }
            appdata_name = f"{APP_ROOT}/appdata"
            for member in archive:
                name = member.name
                path = PurePosixPath(name)
                if (
                    path.is_absolute()
                    or path.as_posix() != name
                    or "\\" in name
                    or not name.isascii()
                    or len(name.encode("ascii")) > 255
                    or any(part in ("", ".", "..") for part in path.parts)
                ):
                    raise ValueError(f"unsafe path in IPK tar member: {name!r}")
                if name in names:
                    raise ValueError(f"duplicate path in IPK tar archive: {name!r}")
                names.add(name)
                if expected_names is not None and name not in expected_names:
                    raise ValueError(f"unexpected path in IPK tar archive: {name!r}")
                if len(names) > MAX_TAR_ENTRIES:
                    raise ValueError("IPK tar archive exceeds the 100,000-entry safety limit")
                if member.size < 0:
                    raise ValueError(f"negative tar member size: {name!r}")
                unpacked_bytes += member.size
                if unpacked_bytes > MAX_UNCOMPRESSED_BYTES:
                    raise ValueError("IPK data exceeds the 512 MiB uncompressed safety limit")
                if not (member.isdir() or member.isfile()):
                    raise ValueError(f"unsupported special file in IPK tar archive: {name!r}")
                if validate_app_layout:
                    if not (name in allowed_directories or name.startswith(app_prefix) or name.startswith(package_prefix)):
                        raise ValueError(f"unexpected path in PlezyNG IPK: {name!r}")
                    if member.isdir():
                        expected_mode = 0o777 if name == appdata_name else 0o755
                        if member.mode != expected_mode:
                            raise ValueError(f"unexpected directory permissions {member.mode:o} on {name!r}")
                    elif member.mode not in (0o644, 0o755):
                        raise ValueError(f"unexpected file permissions {member.mode:o} on {name!r}")
                if member.isfile() and name in required:
                    stream = archive.extractfile(member)
                    if stream is None:
                        raise ValueError(f"{name} is not a regular file")
                    found[name] = stream.read()
                elif name in required:
                    raise ValueError(f"{name} is not a regular file")
            missing = required - found.keys()
            if missing:
                raise ValueError(f"IPK tar archive is missing required files: {sorted(missing)!r}")
            return found
    except (KeyError, tarfile.TarError) as exc:
        raise ValueError(f"cannot read required files from IPK tar archive: {exc}") from exc


def verify_arm_elf(data: bytes, name: str) -> None:
    if len(data) < 20 or data[:4] != b"\x7fELF":
        raise ValueError(f"{name} is not an ELF binary")
    if data[4] != 1 or data[5] != 1:
        raise ValueError(f"{name} must be little-endian ELF32 for the LG ARM target")
    machine = struct.unpack_from("<H", data, 18)[0]
    if machine != 40:
        raise ValueError(f"{name} has ELF machine {machine}; expected ARM (40)")


def load_lock() -> dict[str, object]:
    try:
        return json.loads(LOCK_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read {LOCK_PATH}: {exc}") from exc


def verify_runtime_archives(engine_archive: Path | None, common_archive: Path | None, lock: dict[str, object]) -> None:
    artifacts = lock["lgArtifacts"]
    assert isinstance(artifacts, dict)
    expected_engine_archive = artifacts["engineArchiveSha256"]
    expected_common_archive = artifacts["commonArchiveSha256"]
    expected_libraries = artifacts["runtimeLibraries"]
    assert isinstance(expected_libraries, dict)

    if engine_archive is not None:
        actual = sha256(engine_archive.read_bytes())
        if actual != expected_engine_archive:
            raise ValueError(f"engine archive SHA-256 mismatch: {actual}")
        for name in RUNTIME_LIBRARIES:
            actual_library = sha256(read_zip_member(engine_archive, name))
            if actual_library != expected_libraries[name]:
                raise ValueError(f"{name} in engine archive has SHA-256 {actual_library}")
        expected_snapshot = artifacts["genSnapshotSha256"]
        actual_snapshot = sha256(read_zip_member(engine_archive, GEN_SNAPSHOT))
        if actual_snapshot != expected_snapshot:
            raise ValueError(f"{GEN_SNAPSHOT} in engine archive has SHA-256 {actual_snapshot}")

    if common_archive is not None:
        actual = sha256(common_archive.read_bytes())
        if actual != expected_common_archive:
            raise ValueError(f"common archive SHA-256 mismatch: {actual}")


def expected_package_version() -> str:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"(?m)^version:\s*([^\s]+)\s*$", text)
    if match is None:
        raise ValueError("pubspec.yaml has no simple top-level version field")
    return match.group(1).split("+", maxsplit=1)[0]


def verify_ipk(path: Path, lock: dict[str, object]) -> dict[str, object]:
    source_appinfo = json.loads((ROOT / "webos" / "meta" / "appinfo.json").read_text(encoding="utf-8"))
    app_specific = set(lock["appSpecificACG"])
    if source_appinfo.get("id") != APP_ID or source_appinfo.get("type") != "native":
        raise ValueError("webos/meta/appinfo.json is not the expected native PlezyNG package")
    source_acg = source_appinfo.get("requiredACG")
    if not isinstance(source_acg, list) or len(source_acg) != len(set(source_acg)) or set(source_acg) != app_specific:
        raise ValueError(f"unexpected app-specific requiredACG set: {source_acg!r}")

    ar_members = read_ar_archive(path)
    data_tar = ar_members["data.tar.gz"]
    control = read_tar_member(ar_members["control.tar.gz"], "control")
    control_fields = parse_control_fields(control)
    expected_control_fields = {
        "Package",
        "Version",
        "Section",
        "Priority",
        "Architecture",
        "Installed-Size",
        "Maintainer",
        "Description",
        "webOS-Package-Format-Version",
        "webOS-Packager-Version",
    }
    if set(control_fields) != expected_control_fields:
        raise ValueError("IPK control metadata has missing or unexpected fields")
    if control_fields.get("Package") != APP_ID:
        raise ValueError("IPK control package ID is incorrect")
    if control_fields.get("Section") != "misc" or control_fields.get("Priority") != "optional":
        raise ValueError("IPK control section or priority is incorrect")
    if control_fields.get("Architecture") != "arm":
        raise ValueError("IPK control architecture is not ARM")
    installed_size = control_fields.get("Installed-Size", "")
    if not installed_size.isdecimal() or not (0 < int(installed_size) <= MAX_UNCOMPRESSED_BYTES):
        raise ValueError("IPK control installed size is invalid")
    if control_fields.get("webOS-Package-Format-Version") != "2":
        raise ValueError("IPK control metadata has an unsupported webOS package format")
    if control_fields.get("webOS-Packager-Version") != "plezyng-python-1":
        raise ValueError("IPK was not produced by the pinned PlezyNG packager")
    if control_fields.get("Maintainer") != EXPECTED_MAINTAINER:
        raise ValueError("IPK control metadata does not identify the PlezyNG maintainer")
    if control_fields.get("Description") != EXPECTED_DESCRIPTION:
        raise ValueError("IPK control metadata does not describe the PlezyNG webOS client")

    appinfo_path = str(APP_ROOT / "appinfo.json")
    executable_path = str(APP_ROOT / "plezyng")
    package_info_path = f"usr/palm/packages/{APP_ID}/packageinfo.json"
    notice_path = str(APP_ROOT / "data/flutter_assets/assets/licenses/LGFlutterWebOSRuntimeNotice.txt")
    library_paths = [str(APP_ROOT / "lib" / name) for name in (*RUNTIME_LIBRARIES, *REQUIRED_NATIVE_LIBRARIES)]
    selected = read_tar_members(data_tar, {appinfo_path, executable_path, package_info_path, notice_path, *library_paths})
    appinfo = json.loads(selected[appinfo_path])
    if appinfo.get("id") != APP_ID:
        raise ValueError(f"IPK app ID is {appinfo.get('id')!r}; expected {APP_ID!r}")
    if appinfo.get("type") != "native" or appinfo.get("main") != "plezyng":
        raise ValueError("IPK is not the expected native PlezyNG application")

    version = appinfo.get("version")
    if version != expected_package_version():
        raise ValueError(f"IPK version {version!r} does not match pubspec {expected_package_version()!r}")
    if control_fields.get("Version") != version:
        raise ValueError("IPK control version does not match appinfo.json")

    package_info = json.loads(selected[package_info_path])
    if package_info != {"id": APP_ID, "version": version, "app": APP_ID}:
        raise ValueError("IPK packageinfo.json does not match the PlezyNG application")

    packager = set(lock["packagerACG"])
    required_acg = appinfo.get("requiredACG")
    if (
        not isinstance(required_acg, list)
        or len(required_acg) != len(set(required_acg))
        or set(required_acg) != app_specific | packager
    ):
        raise ValueError(f"unexpected requiredACG set: {required_acg!r}")
    if "*" in required_acg:
        raise ValueError("wildcard ACG permissions are forbidden")

    verify_arm_elf(selected[executable_path], "plezyng")

    for name in (*RUNTIME_LIBRARIES, *REQUIRED_NATIVE_LIBRARIES):
        library_path = str(APP_ROOT / "lib" / name)
        contents = selected[library_path]
        verify_arm_elf(contents, name)
        expected_libraries = lock["lgArtifacts"]["runtimeLibraries"]
        if name in expected_libraries and sha256(contents) != expected_libraries[name]:
            raise ValueError(f"{name} differs from the pinned runtime library")

    packaged_notice = selected[notice_path]
    if packaged_notice != LICENSE_ASSET.read_bytes():
        raise ValueError("IPK is missing the exact LG runtime OSS notice asset")

    return {
        "appId": APP_ID,
        "version": version,
        "target": lock["target"],
        "packageSha256": sha256(path.read_bytes()),
        "packageBytes": path.stat().st_size,
        "requiredACG": sorted(required_acg),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine-archive", type=Path, help="pinned webos-arm-release.zip")
    parser.add_argument("--common-archive", type=Path, help="pinned webos-common.zip")
    parser.add_argument("--ipk", type=Path, help="built PlezyNG webOS IPK to inspect")
    args = parser.parse_args()

    try:
        lock = load_lock()
        if args.engine_archive is not None:
            verify_runtime_archives(args.engine_archive, None, lock)
        if args.common_archive is not None:
            verify_runtime_archives(None, args.common_archive, lock)
        if args.ipk is not None:
            print(json.dumps(verify_ipk(args.ipk, lock), indent=2))
        if args.engine_archive is None and args.common_archive is None and args.ipk is None:
            parser.error("provide at least one archive or --ipk")
    except (OSError, ValueError, KeyError, TypeError, AssertionError) as exc:
        print(f"webOS package verification failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
