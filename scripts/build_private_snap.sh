#!/usr/bin/env bash
# Run Canonical's core24 build environment inside the existing private JIT VM.
set -Eeuo pipefail

: "${GITHUB_ACTIONS:?Run this packaging helper in its private JIT workflow}"
: "${GITHUB_RUN_ID:?The task run ID is required}"
: "${RUNNER_TEMP:?The job temporary directory is required}"
: "${GITHUB_OUTPUT:?The workflow step output file is required}"
if [[ "$GITHUB_ACTIONS" != true || "${RUNNER_ENVIRONMENT:-}" != self-hosted || ! "$GITHUB_RUN_ID" =~ ^[0-9]+$ ]]; then
  echo 'Snap packaging requires the private self-hosted JIT job.' >&2
  exit 1
fi
arch="${1:?Pass the native Snap architecture: amd64 or arm64}"
case "$(uname -s):$(uname -m):$arch" in
  Linux:x86_64:amd64|Linux:aarch64:arm64) ;;
  *) echo 'The Snap target must match this Linux runner architecture.' >&2; exit 1 ;;
esac
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
project="$root/linux/packaging/snap"
proxy="${HTTPS_PROXY:-${https_proxy:-}}"
image="$(python3 - "$project/toolchain.lock.json" "$proxy" "$arch" <<'PY'
import json
import re
import sys
from urllib.parse import urlsplit

lock = json.load(open(sys.argv[1], encoding="utf-8"))
raw, arch = sys.argv[2:]
proxy = urlsplit(raw)
if (not raw or any(character.isspace() for character in raw)
        or proxy.scheme != "http" or not proxy.hostname or not proxy.port
        or proxy.username or proxy.password or proxy.path not in ("", "/")
        or proxy.query or proxy.fragment):
    raise SystemExit("An unauthenticated private HTTP proxy with host and port is required")
if (lock["base"] != "core24" or f"linux/{arch}" not in lock["platforms"]
        or not re.fullmatch(r"ghcr\.io/canonical/snapcraft@sha256:[0-9a-f]{64}", lock["image"])):
    raise SystemExit("The Canonical multi-platform Snapcraft image must be digest-pinned")
print(lock["image"])
PY
)"
cid_file="$RUNNER_TEMP/plezyng-snap-${arch}.cid"
if [[ -e "$cid_file" || -L "$cid_file" ]]; then
  echo 'Refusing to reuse a Snap container receipt.' >&2
  exit 1
fi
shopt -s nullglob
previous=("$project"/*.snap)
if (( ${#previous[@]} != 0 )); then
  echo 'Refusing to confuse a previous Snap with this build.' >&2
  exit 1
fi

sudo -n apt-get update -o Acquire::Retries=3
sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  -o Acquire::Retries=3 podman squashfs-tools
# Podman's image download runs in this process, so the proxy applies without
# restarting a Docker, snapd, or LXD daemon. The image supplies Ubuntu 24.04.
sudo -n env HTTP_PROXY="$proxy" HTTPS_PROXY="$proxy" http_proxy="$proxy" https_proxy="$proxy" \
  podman pull --platform "linux/$arch" "$image"
actual_arch="$(sudo -n podman image inspect --format '{{.Architecture}}' "$image")"
if [[ "$actual_arch" != "$arch" ]]; then
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
sudo -n podman run --rm --pull=never --network host --cidfile "$cid_file" \
  --platform "linux/$arch" --workdir /project \
  --volume "$project:/project" \
  --env HTTP_PROXY="$proxy" --env HTTPS_PROXY="$proxy" \
  --env http_proxy="$proxy" --env https_proxy="$proxy" \
  --env SNAPCRAFT_BUILD_INFO=1 \
  "$image" pack --destructive-mode --build-for="$arch"
snaps=("$project"/*.snap)
if (( ${#snaps[@]} != 1 )); then
  echo 'Expected one completed Snap package.' >&2
  exit 1
fi
unsquashfs -s "${snaps[0]}"
printf 'snap=%s\n' "${snaps[0]}" >> "$GITHUB_OUTPUT"
