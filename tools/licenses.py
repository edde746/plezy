#!/usr/bin/env python3
"""Check or update the vendored licence texts in licenses/ against their upstream sources.

licenses/sources.json maps every folder `<group>/<folder>` to the notices it covers, the shipped version and its
files: each file's path in the folder and where its bytes come from, an immutable URL (a tag or commit, never a
branch) in one of three forms, or the repository itself:

- "<url>": the whole file; a googlesource.com `?format=TEXT` URL is base64 and is decoded;
- {"url": "<url>", "lines": [first, last]}: those lines of the file, 1-based and inclusive, each with its newline
  (`sed -n 'first,lastp'`);
- {"url": "<archive url>", "member": "<path>"}: one file of a zip, a tar (gzip, xz, bzip2) or a .deb (its
  data.tar.*);
- {"local": true}: a file no upstream publishes, kept only here (a licensor's written permission): `check` only
  needs it present, `update` leaves it as it is.

  tools/licenses.py [check]                     fetch every file and compare it with the vendored one
  tools/licenses.py update [<group>/<folder>...]  fetch the files of those folders (all without one) and write them

`check` exits 1 and lists each vendored file whose bytes differ from its source, each file sources.json names that is
missing, and each file under a group folder that sources.json doesn't name. The builds never run this script: they
stay offline and ship licenses/ as it is.

Needs Python 3.14 or later (compression.zstd, for the Ubuntu packages' data.tar.zst) and nothing beyond its standard
library.
"""

import base64
import concurrent.futures
import io
import json
import sys
import tarfile
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

if sys.version_info < (3, 14):
    sys.exit("tools/licenses.py needs Python 3.14 or later (compression.zstd)")

from compression import zstd  # noqa: E402

LICENSES = Path(__file__).resolve().parent.parent / "licenses"
ROOT_FILES = {"apps.json", "README.md", "sources.json"}


def download(url):
    request = urllib.request.Request(url, headers={"User-Agent": "plezy-licenses"})
    with urllib.request.urlopen(request, timeout=120) as response:
        data = response.read()
    parts = urllib.parse.urlsplit(url)
    if parts.hostname.endswith(".googlesource.com") and "format=TEXT" in parts.query.split("&"):
        data = base64.b64decode(data)
    return data


def archive_member(archive, member):
    if archive.startswith(b"PK\x03\x04"):
        with zipfile.ZipFile(io.BytesIO(archive)) as zf:
            return zf.read(member)
    if archive.startswith(b"!<arch>\n"):
        archive = deb_data_tar(archive)
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:*") as tf:
        for info in tf:
            if info.name.removeprefix("./") == member:
                if not info.isfile():
                    raise ValueError(f"{member} is not a regular file in the archive")
                return tf.extractfile(info).read()
    raise KeyError(f"no {member} in the archive")


def deb_data_tar(deb):
    """The data.tar of a .deb (an ar archive), decompressed when it is zstd (tarfile reads the others)."""
    offset = 8
    while offset < len(deb):
        header = deb[offset:offset + 60]
        name = header[:16].decode().strip().rstrip("/")
        size = int(header[48:58])
        body = deb[offset + 60:offset + 60 + size]
        if name.startswith("data.tar"):
            return zstd.decompress(body) if name.endswith(".zst") else body
        offset += 60 + size + size % 2
    raise KeyError("no data.tar in the .deb")


def extract(source, downloads, vendored):
    if isinstance(source, str):
        return downloads[source]
    if source.get("local"):
        return vendored.read_bytes()
    data = downloads[source["url"]]
    if "lines" in source:
        first, last = source["lines"]
        return b"".join(io.BytesIO(data).readlines()[first - 1:last])
    return archive_member(data, source["member"])


def fetch_all(entries):
    """Every file of `entries` as {(folder, path): bytes or the exception that fetching it raised}."""
    sources = {(folder, path): source for folder, entry in entries.items() for path, source in entry["files"].items()}
    urls = {source if isinstance(source, str) else source["url"] for source in sources.values()
            if isinstance(source, str) or not source.get("local")}
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        futures = {url: pool.submit(download, url) for url in urls}
    downloads, failed = {}, {}
    for url, future in futures.items():
        try:
            downloads[url] = future.result()
        except Exception as e:
            failed[url] = e
    files = {}
    for key, source in sources.items():
        url = source if isinstance(source, str) else source.get("url")
        try:
            files[key] = failed[url] if url in failed else extract(source, downloads, LICENSES / key[0] / key[1])
        except Exception as e:
            files[key] = e
    return files


def check(entries):
    problems = []
    for (folder, path), data in sorted(fetch_all(entries).items()):
        vendored = LICENSES / folder / path
        if isinstance(data, Exception):
            problems.append(f"{folder}/{path}: fetching its source failed: {data}")
        elif not vendored.is_file():
            problems.append(f"{folder}/{path}: missing (sources.json names it)")
        elif vendored.read_bytes() != data:
            problems.append(f"{folder}/{path}: differs from its source ({vendored.stat().st_size} bytes here, "
                            f"{len(data)} upstream)")
    named = {f"{folder}/{path}" for folder, entry in entries.items() for path in entry["files"]}
    for file in sorted(LICENSES.rglob("*")):
        relative = file.relative_to(LICENSES).as_posix()
        if file.is_file() and relative not in ROOT_FILES and relative not in named:
            problems.append(f"{relative}: not in sources.json")
    for problem in problems:
        print(problem)
    files = sum(len(entry["files"]) for entry in entries.values())
    if problems:
        print(f"FAILED: {len(problems)} problems in {files} files of {len(entries)} folders")
        return 1
    print(f"OK: {files} files of {len(entries)} folders match their sources")
    return 0


def update(entries, folders):
    unknown = [folder for folder in folders if folder not in entries]
    if unknown:
        sys.exit(f"not in sources.json: {', '.join(unknown)}")
    selected = {folder: entries[folder] for folder in folders} if folders else entries
    failed = 0
    for (folder, path), data in sorted(fetch_all(selected).items()):
        if isinstance(data, Exception):
            print(f"{folder}/{path}: fetching its source failed: {data}")
            failed += 1
            continue
        target = LICENSES / folder / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"{folder}/{path}: {len(data)} bytes")
    return 1 if failed else 0


def main(args):
    entries = json.loads((LICENSES / "sources.json").read_text())
    command = args[0] if args else "check"
    if command == "check" and len(args) <= 1:
        return check(entries)
    if command == "update":
        return update(entries, args[1:])
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
