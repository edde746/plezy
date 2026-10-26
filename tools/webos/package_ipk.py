#!/usr/bin/env python3
"""Create a minimal, deterministic webOS IPK for the Flutter webOS SDK."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import json
import os
import re
import stat
import struct
import sys
import tarfile
import tempfile
from pathlib import Path, PurePosixPath
from typing import Iterator


APP_ID_PATTERN = re.compile(r"^[a-z0-9.+-]+$")
VERSION_PATTERN = re.compile(r"^(?:[1-9][0-9]{0,8}|0)\.(?:[1-9][0-9]{0,8}|0)\.(?:[1-9][0-9]{0,8}|0)$")
AR_MAGIC = b"!<arch>\n"
AR_BLOCK = 60
PACKAGER_VERSION = "1"
MAINTAINER = "SnapeTech <noreply@github.com>"
DESCRIPTION = "Plex media client for LG webOS TVs."


class PackageError(ValueError):
    pass


def _safe_relative_path(root: Path, path: Path) -> PurePosixPath:
    relative = path.relative_to(root)
    if not relative.parts or any(part in ("", ".", "..") for part in relative.parts):
        raise PackageError(f"unsafe package path: {relative!s}")
    if not relative.as_posix().isascii():
        raise PackageError(f"webOS IPK paths must use ASCII names: {relative!s}")
    if len(relative.as_posix().encode("ascii")) > 255:
        raise PackageError(f"webOS IPK path exceeds the USTAR limit: {relative!s}")
    if len(relative.name.encode("ascii")) > 100:
        raise PackageError(f"webOS IPK filename exceeds the USTAR limit: {relative!s}")
    return PurePosixPath(relative.as_posix())


def _iter_tree(root: Path) -> Iterator[tuple[PurePosixPath, Path, os.stat_result]]:
    if root.is_symlink() or not root.is_dir():
        raise PackageError(f"package tree is not a regular directory: {root}")
    entries: list[Path] = []

    def fail_walk(error: OSError) -> None:
        raise error

    for current, directories, files in os.walk(root, topdown=True, followlinks=False, onerror=fail_walk):
        current_path = Path(current)
        directories.sort()
        files.sort()
        for name in directories + files:
            entry = current_path / name
            info = entry.lstat()
            if stat.S_ISLNK(info.st_mode):
                raise PackageError(f"symbolic links are forbidden in the package tree: {entry}")
            if not (stat.S_ISDIR(info.st_mode) or stat.S_ISREG(info.st_mode)):
                raise PackageError(f"special files are forbidden in the package tree: {entry}")
            entries.append(entry)
            if len(entries) > 100_000:
                raise PackageError("package tree exceeds the 100,000-entry safety limit")
    for path in sorted(entries, key=lambda entry: entry.relative_to(root).as_posix()):
        yield _safe_relative_path(root, path), path, path.lstat()


def _add_tree_to_tar(root: Path, archive: tarfile.TarFile, epoch: int, app_id: str) -> int:
    total_file_bytes = 0
    appdata_path = PurePosixPath("usr/palm/applications") / app_id / "appdata"
    for relative, path, info in _iter_tree(root):
        item = tarfile.TarInfo(relative.as_posix())
        item.uid = 0
        item.gid = 0
        item.uname = ""
        item.gname = ""
        item.mtime = epoch
        item.pax_headers = {}
        if stat.S_ISDIR(info.st_mode):
            # The Flutter webOS runner writes only under appdata. Keep that
            # SDK-created directory writable while all bundled paths stay
            # read-only to other users.
            item.type = tarfile.DIRTYPE
            item.mode = 0o777 if relative == appdata_path else 0o755
            item.size = 0
            archive.addfile(item)
        else:
            item.type = tarfile.REGTYPE
            item.mode = 0o755 if info.st_mode & 0o111 else 0o644
            item.size = info.st_size
            total_file_bytes += info.st_size
            flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
            descriptor = os.open(path, flags)
            with os.fdopen(descriptor, "rb") as contents:
                opened = os.fstat(contents.fileno())
                if not stat.S_ISREG(opened.st_mode) or (opened.st_dev, opened.st_ino, opened.st_size) != (
                    info.st_dev,
                    info.st_ino,
                    info.st_size,
                ):
                    raise PackageError(f"package file changed while being read: {path}")
                archive.addfile(item, contents)
    return total_file_bytes


def _write_tar_gz(root: Path, destination: Path, epoch: int, app_id: str) -> int:
    with destination.open("wb") as output:
        with gzip.GzipFile(filename="", mode="wb", fileobj=output, compresslevel=9, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.USTAR_FORMAT) as archive:
                return _add_tree_to_tar(root, archive, epoch, app_id)


def _elf_machine(path: Path) -> int:
    with path.open("rb") as binary:
        header = binary.read(20)
    if len(header) < 20 or header[:4] != b"\x7fELF":
        raise PackageError(f"app main is not an ELF executable: {path}")
    if header[4] != 1 or header[5] != 1:
        raise PackageError("webOS ARM package requires a little-endian ELF32 executable")
    return struct.unpack_from("<H", header, 18)[0]


def _validate_app(app_dir: Path, output_dir: Path) -> tuple[dict[str, object], str]:
    if app_dir.is_symlink() or output_dir.is_symlink():
        raise PackageError("symlinked package input and output directories are forbidden")
    try:
        app_real = app_dir.resolve(strict=True)
        output_real = output_dir.resolve(strict=True)
    except OSError as exc:
        raise PackageError(f"cannot resolve package input path: {exc}") from exc
    expected_parent = (output_real / "data/usr/palm/applications").resolve(strict=True)
    if app_real.parent != expected_parent:
        raise PackageError("app directory must be directly under this IPK's data/usr/palm/applications")
    if app_real.is_symlink() or not app_real.is_dir():
        raise PackageError("app input must be a regular directory")

    appinfo_path = app_real / "appinfo.json"
    if appinfo_path.is_symlink() or not appinfo_path.is_file():
        raise PackageError("appinfo.json must be a regular file")
    try:
        if appinfo_path.stat().st_size > 1024 * 1024:
            raise PackageError("appinfo.json exceeds the size limit")
        appinfo = json.loads(appinfo_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PackageError(f"cannot read appinfo.json: {exc}") from exc
    app_id = appinfo.get("id")
    version = appinfo.get("version")
    main = appinfo.get("main")
    if not isinstance(app_id, str) or not APP_ID_PATTERN.fullmatch(app_id):
        raise PackageError("appinfo.json contains an invalid package ID")
    if app_real.name != app_id:
        raise PackageError("app directory name does not match appinfo.json ID")
    if not isinstance(version, str) or not VERSION_PATTERN.fullmatch(version):
        raise PackageError("appinfo.json contains an invalid package version")
    if appinfo.get("type") != "native":
        raise PackageError("only native Flutter webOS applications can be packaged")
    if not isinstance(main, str) or Path(main).name != main or main in ("", ".", ".."):
        raise PackageError("appinfo.json contains an unsafe main executable name")
    main_path = app_real / main
    if main_path.is_symlink() or not main_path.is_file():
        raise PackageError("app main executable must be a regular file")
    machine = _elf_machine(main_path)
    if machine != 40:
        raise PackageError(f"this release lane only supports ARM ELF machine 40; got {machine}")
    return appinfo, app_id


def _tree_size(root: Path) -> int:
    """Return the stable installed byte count used in the IPK control field."""
    total = 0
    for path in [root, *root.rglob("*")]:
        info = path.lstat()
        if stat.S_ISLNK(info.st_mode):
            raise PackageError(f"symbolic links are forbidden in the package tree: {path}")
        if stat.S_ISDIR(info.st_mode):
            continue
        if stat.S_ISREG(info.st_mode):
            total += info.st_size
        else:
            raise PackageError(f"special files are forbidden in the package tree: {path}")
    return total


def _write_control_tar(destination: Path, package_id: str, version: str, installed_size: int, epoch: int) -> None:
    control = (
        f"Package: {package_id}\n"
        f"Version: {version}\n"
        "Section: misc\n"
        "Priority: optional\n"
        "Architecture: arm\n"
        f"Installed-Size: {installed_size}\n"
        f"Maintainer: {MAINTAINER}\n"
        f"Description: {DESCRIPTION}\n"
        "webOS-Package-Format-Version: 2\n"
        "webOS-Packager-Version: plezyng-python-1\n"
        "\n"
    ).encode("utf-8")
    with destination.open("wb") as output:
        with gzip.GzipFile(filename="", mode="wb", fileobj=output, compresslevel=9, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.USTAR_FORMAT) as archive:
                item = tarfile.TarInfo("control")
                item.mode = 0o644
                item.uid = 0
                item.gid = 0
                item.uname = ""
                item.gname = ""
                item.mtime = epoch
                item.size = len(control)
                archive.addfile(item, io.BytesIO(control))


def _ar_header(name: str, size: int) -> bytes:
    if len(name.encode("ascii")) > 15 or "/" in name:
        raise PackageError(f"invalid IPK archive member name: {name!r}")
    fields = (
        f"{name:<16}"
        f"{0:<12}"
        f"{0:<6}"
        f"{0:<6}"
        f"{0o100644:<8o}"
        f"{size:<10}"
        "`\n"
    )
    header = fields.encode("ascii")
    if len(header) != AR_BLOCK:
        raise PackageError("internal ar header size error")
    return header


def _write_ipk(destination: Path, control_tar: Path, data_tar: Path) -> None:
    members: tuple[tuple[str, bytes | Path], ...] = (
        ("debian-binary", b"2.0\n"),
        ("control.tar.gz", control_tar),
        ("data.tar.gz", data_tar),
    )
    temporary = destination.with_name(f".{destination.name}.tmp-{os.getpid()}")
    try:
        with temporary.open("xb") as output:
            output.write(AR_MAGIC)
            for name, value in members:
                if isinstance(value, bytes):
                    size = len(value)
                else:
                    size = value.stat().st_size
                output.write(_ar_header(name, size))
                if isinstance(value, bytes):
                    output.write(value)
                else:
                    with value.open("rb") as contents:
                        while chunk := contents.read(1024 * 1024):
                            output.write(chunk)
                if size % 2:
                    output.write(b"\n")
            output.flush()
            os.fsync(output.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, destination)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def package(app_dir: Path, output_dir: Path) -> Path:
    if output_dir.is_symlink() or not output_dir.is_dir():
        raise PackageError("IPK output directory must be a regular directory")
    output_real = output_dir.resolve(strict=True)
    appinfo, app_id = _validate_app(app_dir, output_real)
    version = str(appinfo["version"])
    app_real = app_dir.resolve(strict=True)
    expected_data_root = output_real / "data"
    if not (app_real == expected_data_root / "usr/palm/applications" / app_id):
        raise PackageError("app directory is not the expected IPK staging tree")
    if sorted(path.name for path in expected_data_root.iterdir()) != ["usr"]:
        raise PackageError("IPK staging data tree must contain only usr/")
    list(_iter_tree(expected_data_root))

    applications_dir = expected_data_root / "usr/palm/applications"
    packages_dir = expected_data_root / "usr/palm/packages"
    if sorted(path.name for path in applications_dir.iterdir()) != [app_id]:
        raise PackageError("IPK staging tree must contain only the expected application")
    package_dir = packages_dir / app_id
    packageinfo = {"id": app_id, "version": version, "app": app_id}
    packageinfo_path = package_dir / "packageinfo.json"
    if packages_dir.exists():
        if packages_dir.is_symlink() or not packages_dir.is_dir():
            raise PackageError("IPK package metadata path must be a regular directory")
        if sorted(path.name for path in packages_dir.iterdir()) != [app_id]:
            raise PackageError("IPK staging tree must contain only the expected package metadata")
        if package_dir.is_symlink() or not package_dir.is_dir():
            raise PackageError("IPK package metadata path must be a regular directory")
        if sorted(path.name for path in package_dir.iterdir()) != ["packageinfo.json"]:
            raise PackageError("IPK package metadata directory contains unexpected files")
        if packageinfo_path.is_symlink() or not packageinfo_path.is_file():
            raise PackageError("IPK packageinfo.json must be a regular file")
        if json.loads(packageinfo_path.read_text(encoding="utf-8")) != packageinfo:
            raise PackageError("IPK packageinfo.json does not match this application")
    else:
        packages_dir.mkdir(parents=True, mode=0o755)
        package_dir.mkdir(mode=0o755)
        with packageinfo_path.open("x", encoding="utf-8") as packageinfo_file:
            packageinfo_file.write(json.dumps(packageinfo, indent=2) + "\n")
        packageinfo_path.chmod(0o644)
    installed_size = _tree_size(expected_data_root)

    epoch_text = os.environ.get("SOURCE_DATE_EPOCH", "0")
    try:
        epoch = int(epoch_text)
    except ValueError as exc:
        raise PackageError("SOURCE_DATE_EPOCH must be a non-negative integer") from exc
    if epoch < 0:
        raise PackageError("SOURCE_DATE_EPOCH must be a non-negative integer")

    final_path = output_real / f"{app_id}_{version}_arm.ipk"
    temporary_paths: list[Path] = []
    try:
        for suffix in ("control.tar.gz", "data.tar.gz"):
            fd, name = tempfile.mkstemp(prefix=f".{suffix}.", dir=output_real)
            os.close(fd)
            temporary_paths.append(Path(name))
        control_tar, data_tar = temporary_paths
        _write_control_tar(control_tar, app_id, version, installed_size, epoch)
        _write_tar_gz(expected_data_root, data_tar, epoch, app_id)
        _write_ipk(final_path, control_tar, data_tar)
    finally:
        for path in temporary_paths:
            try:
                path.unlink()
            except FileNotFoundError:
                pass
    return final_path


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-minify", action="store_true", required=True)
    parser.add_argument("app_dir", type=Path)
    parser.add_argument("-o", "--outdir", type=Path, required=True)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = sys.argv[1:] if argv is None else argv
    if arguments == ["--version"]:
        print(f"plezyng-ipk-packager {PACKAGER_VERSION}")
        return 0
    try:
        args = _parse_args(arguments)
        result = package(args.app_dir, args.outdir)
        digest = hashlib.sha256()
        with result.open("rb") as packaged:
            while chunk := packaged.read(1024 * 1024):
                digest.update(chunk)
        print(f"Created {result} (sha256={digest.hexdigest()})")
        return 0
    except (OSError, PackageError, json.JSONDecodeError, tarfile.TarError) as exc:
        print(f"webOS IPK packaging failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
