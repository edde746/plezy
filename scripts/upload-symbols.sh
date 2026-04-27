#!/usr/bin/env bash
# Usage: upload-symbols.sh <platform>
# Env: BUGS_ADMIN_TOKEN (required), BUGS_URL (default https://bugs.plezy.app)
# Platforms: macos | ios | android-apk | android-aab | linux-x64 | linux-arm64
set -euo pipefail

PLATFORM="${1:?platform arg required}"
TOKEN="${BUGS_ADMIN_TOKEN:?BUGS_ADMIN_TOKEN env var required}"
URL="${BUGS_URL:-https://bugs.plezy.app}"
MAX_ATTEMPTS="${BUGS_UPLOAD_ATTEMPTS:-5}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

RELEASE="plezy@$(git rev-parse --short HEAD)"
ENDPOINT="${URL}/api/0/projects/plezy/plezy/files/dsyms/"
FILES=()

add_matches() {
  local path
  while IFS= read -r -d '' path; do
    FILES+=("$path")
  done < <(find "$@" -print0 2>/dev/null || true)
}

add_debug_info() {
  if [ -d "debug-info/${PLATFORM}" ]; then
    add_matches "debug-info/${PLATFORM}" -type f
  fi
}

file_size() {
  wc -c < "$1" | tr -d '[:space:]'
}

curl_fail_arg() {
  if curl --help all 2>/dev/null | grep -q -- '--fail-with-body'; then
    printf '%s\n' '--fail-with-body'
  else
    printf '%s\n' '--fail'
  fi
}

upload_file() {
  local file="$1"
  local index="$2"
  local total="$3"
  local size
  local body
  local attempt
  local delay
  local fail_arg

  size="$(file_size "$file")"
  body="$(mktemp)"
  fail_arg="$(curl_fail_arg)"

  echo "uploading symbols ${index}/${total}: ${file} (${size} bytes)"

  attempt=1
  delay=2
  while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
    if curl "$fail_arg" --silent --show-error \
      --connect-timeout 20 \
      --max-time 600 \
      -o "$body" \
      -X POST \
      -H "Authorization: Bearer ${TOKEN}" \
      -F "file=@${file}" \
      -F "release=${RELEASE}" \
      "$ENDPOINT"; then
      rm -f "$body"
      return 0
    fi

    if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
      echo "symbol upload failed for ${file}; retrying in ${delay}s (${attempt}/${MAX_ATTEMPTS})" >&2
      sleep "$delay"
      delay=$((delay * 2))
    fi
    attempt=$((attempt + 1))
  done

  echo "symbol upload failed after ${MAX_ATTEMPTS} attempts" >&2
  echo "platform=${PLATFORM}" >&2
  echo "release=${RELEASE}" >&2
  echo "file_count=${total}" >&2
  echo "failed_file=${file}" >&2
  echo "failed_file_size=${size}" >&2
  if [ -s "$body" ]; then
    echo "response_body:" >&2
    sed 's/^/  /' "$body" >&2
  fi
  rm -f "$body"
  return 1
}

add_debug_info

case "$PLATFORM" in
  macos)
    add_matches build/macos/Build/Products/Release -path '*.dSYM/Contents/Resources/DWARF/*' -type f
    ;;
  ios)
    add_matches build/ios -path '*.dSYM/Contents/Resources/DWARF/*' -type f
    ;;
  linux-x64|linux-arm64)
    add_matches build/linux -path '*/release/bundle/plezy' -type f
    ;;
  android-apk|android-aab)
    add_matches build/app/intermediates/merged_native_libs -name '*.so' -type f
    ;;
  *)
    echo "unknown platform: $PLATFORM" >&2
    exit 2
    ;;
esac

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "no symbols found for platform ${PLATFORM}" >&2
  exit 3
fi

echo "uploading ${#FILES[@]} symbol file(s) for ${PLATFORM} release ${RELEASE}"

index=1
for file in "${FILES[@]}"; do
  upload_file "$file" "$index" "${#FILES[@]}"
  index=$((index + 1))
done
