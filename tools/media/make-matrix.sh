#!/usr/bin/env bash
# Builds the playback matrix: H.264, HEVC HDR10, AV1 HDR10, AV1 at about 30 Mb/s of film grain, MPEG-2, Dolby Vision
# profiles 5 and 8.1,
# DTS-HD MA, TrueHD, ASS, PGS, a 4:3 picture, named chapters (intro, recap and credits skipping), a REMUX-style file
# with many tracks and its next episode with the same languages in another order (tracks carried across episodes).
# The entries live in matrix/spec.py; every file is verified with ffprobe (and dovi_tool) after muxing, and
# tools/media/matrix.json is rewritten from them.
#
# Output: tools/media/out/matrix/ (gitignored; serve.py serves it as /matrix/). Scratch space and downloads:
# tools/media/out/matrix-work/. Override with PLEZY_MATRIX_OUT / PLEZY_MATRIX_WORK.
# Options: --force rebuilds everything (unchanged files are otherwise only re-verified); --only ID... limits the run.
#
# Needs ffmpeg (libx264, libx265, libsvtav1), mkvmerge (MKVToolNix), dovi_tool and uv (which fetches the pinned
# numpy and Pillow). Nothing is played.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${PLEZY_MATRIX_OUT:-$here/out/matrix}"
work="${PLEZY_MATRIX_WORK:-$here/out/matrix-work}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "make-matrix: '$1' not found; $2" >&2; exit 1; }
}
need ffmpeg "brew install ffmpeg"
need ffprobe "brew install ffmpeg"
need mkvmerge "brew install mkvtoolnix"
need dovi_tool "brew install dovi_tool"
need uv "brew install uv"
encoders="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
for enc in libx264 libx265 libsvtav1 aac ac3 truehd; do
  grep -qE "^ [A-Z.]{6} $enc " <<<"$encoders" || { echo "make-matrix: ffmpeg lacks the $enc encoder" >&2; exit 1; }
done

export PYTHONDONTWRITEBYTECODE=1
exec uv run --quiet --script "$here/matrix/build.py" --out "$out" --work "$work" "$@"
