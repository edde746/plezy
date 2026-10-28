#!/usr/bin/env bash
# Upload one verified release package from a private JIT job without snapd/LXD.
set +x
set -Eeuo pipefail

: "${GITHUB_ACTIONS:?Run this publication helper in its private JIT workflow}"
: "${GITHUB_RUN_ID:?The task run ID is required}"
: "${RUNNER_TEMP:?The job temporary directory is required}"
if [[ "$GITHUB_ACTIONS" != true || "${RUNNER_ENVIRONMENT:-}" != self-hosted || ! "$GITHUB_RUN_ID" =~ ^[0-9]+$ ]]; then
  echo 'Snap publication requires the private self-hosted JIT job.' >&2
  exit 1
fi
if [[ "$(uname -s):$(uname -m)" != Linux:x86_64 ]]; then
  echo 'Snap publication requires the private Linux x64 runner.' >&2
  exit 1
fi
if [[ $# != 2 ]]; then
  echo 'Usage: publish_private_snap.sh PACKAGE.snap CHANNEL' >&2
  exit 1
fi
channel="$2"
case "$channel" in edge|beta|candidate|stable) ;; *) echo 'Unsupported Snap Store channel.' >&2; exit 1 ;; esac
if [[ -z "${SNAPCRAFT_STORE_CREDENTIALS:-}" ]]; then
  echo 'Snap Store credentials are required.' >&2
  exit 1
fi
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
proxy="${HTTPS_PROXY:-${https_proxy:-}}"
mapfile -t inputs < <(python3 - "$root/linux/packaging/snap/toolchain.lock.json" "$proxy" "$RUNNER_TEMP" "$1" <<'PY'
import hashlib
import json
from pathlib import Path
import re
import stat
import sys
from urllib.parse import urlsplit

lock = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
raw, temporary, package = sys.argv[2:]
proxy = urlsplit(raw)
if (not raw or any(character.isspace() for character in raw)
        or proxy.scheme != "http" or not proxy.hostname or not proxy.port
        or proxy.username or proxy.password or proxy.path not in ("", "/")
        or proxy.query or proxy.fragment):
    raise SystemExit("An unauthenticated private HTTP proxy with host and port is required")
if (lock["base"] != "core24" or "linux/amd64" not in lock["platforms"]
        or not re.fullmatch(r"ghcr\.io/canonical/snapcraft@sha256:[0-9a-f]{64}", lock["image"])):
    raise SystemExit("The Canonical Snapcraft image must be digest-pinned")
path = Path(package)
if not stat.S_ISREG(path.lstat().st_mode):
    raise SystemExit("The release package must be a regular file, not a symlink")
path = path.resolve(strict=True)
if (path.parent != Path(temporary).resolve(strict=True) / "plezyng-snap"
        or not re.fullmatch(r"plezyng-linux-(x64|arm64)\.snap", path.name)
        or any(character in str(path) for character in "\r\n:\x00")):
    raise SystemExit("Use the exact release package in RUNNER_TEMP/plezyng-snap")
checksums = path.with_name("SHA256SUMS.txt")
if not stat.S_ISREG(checksums.lstat().st_mode):
    raise SystemExit("The release checksum manifest must be a regular file")
matches = []
for line in checksums.read_text(encoding="utf-8").splitlines():
    match = re.fullmatch(r"([0-9a-fA-F]{64}) [ *](.+)", line)
    if match and match[2] == path.name:
        matches.append(match[1].lower())
with path.open("rb") as stream:
    actual = hashlib.file_digest(stream, "sha256").hexdigest()
if len(matches) != 1 or actual != matches[0] or path.stat().st_size == 0:
    raise SystemExit("The exact Snap must match one entry in the release checksum manifest")
print(lock["image"])
print(path)
PY
)
# Process substitutions do not propagate failures to mapfile. Validate the
# complete result before installing tools or performing any network operation.
if [[ ${#inputs[@]} != 2 ]]; then
  echo 'Snap publication input validation failed.' >&2
  exit 1
fi
image="${inputs[0]}"
package="${inputs[1]}"
cid_file="$RUNNER_TEMP/plezyng-snap-publish-$(basename -- "$package").cid"
if [[ -e "$cid_file" || -L "$cid_file" ]]; then
  echo 'Refusing to reuse a Snap publication container receipt.' >&2
  exit 1
fi

sudo -n apt-get update -o Acquire::Retries=3 \
  -o "Acquire::http::Proxy=$proxy" -o "Acquire::https::Proxy=$proxy"
sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  -o Acquire::Retries=3 -o "Acquire::http::Proxy=$proxy" -o "Acquire::https::Proxy=$proxy" podman
sudo -n env HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" http_proxy="$proxy" https_proxy="$proxy" \
  podman pull --platform linux/amd64 "$image"
if [[ "$(sudo -n podman image inspect --format '{{.Architecture}}' "$image")" != amd64 ]]; then
  echo 'The downloaded Snapcraft image has the wrong architecture.' >&2
  exit 1
fi
cleanup() {
  if [[ -f "$cid_file" && ! -L "$cid_file" ]]; then
    local cid
    cid="$(cat -- "$cid_file")"
    if [[ "$cid" =~ ^[0-9a-f]{64}$ ]]; then
      sudo -n podman rm --force --ignore "$cid" >/dev/null || true
    fi
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# Preserve only this named variable across sudo; never construct credential-
# bearing argv, an env file, or a log. Podman removes container metadata on exit.
sudo -n --preserve-env=SNAPCRAFT_STORE_CREDENTIALS \
  podman run --rm --pull=never --network host --cidfile "$cid_file" \
  --platform linux/amd64 --workdir /project \
  --volume "$package:/artifact/package.snap:ro" \
  --env HTTP_PROXY="$proxy" --env HTTPS_PROXY="$proxy" \
  --env http_proxy="$proxy" --env https_proxy="$proxy" \
  --env SNAPCRAFT_STORE_CREDENTIALS \
  "$image" upload /artifact/package.snap --release "$channel"
