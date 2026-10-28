#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${PLEZY_LITERT_SOURCE_ROOT:-}" ]]; then
  echo "Set PLEZY_LITERT_SOURCE_ROOT to a LiteRT v2.3.0 checkout." >&2
  exit 2
fi
if [[ -z "${EXYNOS_AI_LITECORE_ROOT:-}" ]]; then
  echo "Set EXYNOS_AI_LITECORE_ROOT to the LiteCore SDK obtained through Samsung's authorized download flow." >&2
  exit 2
fi
if [[ -z "${PLEZY_LITERT_SAMSUNG_RUNTIME_OUTPUT:-}" ]]; then
  echo "Set PLEZY_LITERT_SAMSUNG_RUNTIME_OUTPUT to a new output directory." >&2
  exit 2
fi
for tool in bazel git grep mktemp readelf realpath sha256sum sort xargs; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required tool is missing from PATH: $tool" >&2
    exit 2
  fi
done

source_root="$(realpath "$PLEZY_LITERT_SOURCE_ROOT")"
litecore_root="$(realpath "$EXYNOS_AI_LITECORE_ROOT")"
output_parent="$(mkdir -p "$(dirname "$PLEZY_LITERT_SAMSUNG_RUNTIME_OUTPUT")" && cd "$(dirname "$PLEZY_LITERT_SAMSUNG_RUNTIME_OUTPUT")" && pwd)"
output_dir="$output_parent/$(basename "$PLEZY_LITERT_SAMSUNG_RUNTIME_OUTPUT")"

if [[ "$(git -C "$source_root" describe --tags --exact-match 2>/dev/null || true)" != "v2.3.0" ]]; then
  echo "PLEZY_LITERT_SOURCE_ROOT must be checked out at the v2.3.0 tag." >&2
  exit 2
fi
if [[ -e "$output_dir" ]]; then
  echo "Output already exists; choose a new path so stale LiteCore files cannot be mixed: $output_dir" >&2
  exit 2
fi
for required in \
  "$litecore_root/include/graph_wrapper_api.h" \
  "$litecore_root/include/graphgen_c.h" \
  "$litecore_root/lib/arm64-v8a/libgraph_wrapper.so" \
  "$litecore_root/lib/arm64-v8a/libgraphgen_api.so" \
  "$litecore_root/lib/x86_64-linux/libgraph_wrapper.so" \
  "$litecore_root/lib/x86_64-linux/libgraphgen_api.so"; do
  if [[ ! -f "$required" ]]; then
    echo "LiteCore SDK is missing $required" >&2
    exit 2
  fi
done

staging_dir="$(mktemp -d "$output_parent/.plezy-litert-samsung.XXXXXX")"
cleanup_staging() {
  if [[ -n "${staging_dir:-}" && -d "$staging_dir" ]]; then
    rm -rf -- "$staging_dir"
  fi
}
trap cleanup_staging EXIT

(
  cd "$source_root"
  EXYNOS_AI_LITECORE_ROOT="$litecore_root" \
    bazel build --config=android_arm64 \
      //litert/vendors/samsung/compiler:compiler_plugin_so \
      //litert/vendors/samsung/dispatch:dispatch_api_so
)

bazel_bin="$(cd "$source_root" && realpath "$(bazel info bazel-bin)")"
find_android_library() {
  local search_root="$1"
  local library_name="$2"
  local candidate
  while IFS= read -r -d '' candidate; do
    if readelf -h "$candidate" 2>/dev/null | grep -q 'Machine:.*AArch64'; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(find -L "$search_root" -type f -name "$library_name" -print0)
  return 1
}

compiler_plugin="$(find_android_library \
  "$bazel_bin/litert/vendors/samsung/compiler" \
  "libLiteRtCompilerPlugin_Samsung.so")" || {
  echo "Could not find the Android arm64 Samsung compiler plugin in Bazel outputs." >&2
  exit 1
}
dispatch_plugin="$(find_android_library \
  "$bazel_bin/litert/vendors/samsung/dispatch" \
  "libLiteRtDispatch_Samsung.so")" || {
  echo "Could not find the Android arm64 Samsung dispatch library in Bazel outputs." >&2
  exit 1
}

mkdir -p "$staging_dir/arm64-v8a" "$staging_dir/litecore/lib/arm64-v8a"
cp "$compiler_plugin" "$staging_dir/arm64-v8a/libLiteRtCompilerPlugin_Samsung.so"
cp "$dispatch_plugin" "$staging_dir/arm64-v8a/libLiteRtDispatch_Samsung.so"
shopt -s nullglob
litecore_android_libraries=("$litecore_root"/lib/arm64-v8a/*.so)
if (( ${#litecore_android_libraries[@]} < 2 )); then
  echo "LiteCore SDK contains fewer than two Android shared libraries." >&2
  exit 2
fi
cp "${litecore_android_libraries[@]}" "$staging_dir/litecore/lib/arm64-v8a/"
[[ -f "$staging_dir/litecore/lib/arm64-v8a/libgraph_wrapper.so" ]]
[[ -f "$staging_dir/litecore/lib/arm64-v8a/libgraphgen_api.so" ]]

{
  printf 'LiteRT source tag: v2.3.0\n'
  printf 'LiteRT source commit: %s\n' "$(git -C "$source_root" rev-parse HEAD)"
  printf 'LiteCore host and Android libraries are copied from the supplied SDK root.\n'
} > "$staging_dir/BUILD_INFO.txt"
(cd "$staging_dir" && find . -type f -name '*.so' -print0 | sort -z | xargs -0 sha256sum) \
  > "$staging_dir/SHA256SUMS"

mv "$staging_dir" "$output_dir"
staging_dir=""
trap - EXIT
echo "Samsung LiteRT runtime staged at $output_dir"
