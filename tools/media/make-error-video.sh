#!/usr/bin/env bash
# Builds the test addon's error videos: a still slate with a stream host's message, as some hosts send in place of a
# file they refuse ("Wrong IP"), in H.264 and AAC silence, MP4. Two lengths: out/matrix/error-slate.mp4 (120 s, a
# long slate) and out/matrix/error-slate-10s.mp4 (10 s, a short one). Output under tools/media/out/matrix/
# (gitignored; serve.py serves it as /matrix/). Needs ffmpeg (libx264)
# and ImageMagick (`magick`).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${PLEZY_MATRIX_OUT:-$here/out/matrix}"
font="${PLEZY_SLATE_FONT:-/System/Library/Fonts/Supplemental/Arial.ttf}"
mkdir -p "$out"
slate="$(mktemp -t error-slate).png"
trap 'rm -f "$slate"' EXIT
magick -size 1920x1080 xc:'#1d2330' -font "$font" -fill '#f2f2f2' -gravity center \
  -pointsize 84 -annotate +0-220 'Wrong IP' \
  -pointsize 44 -annotate +0-60 'This stream can only be played from the same IP address' \
  -annotate +0+10 'that first requested it.' \
  -fill '#9aa3b5' -pointsize 36 -annotate +0+150 'Expected IP: 192.0.2.1   Current IP: 198.51.100.7' \
  -pointsize 30 -annotate +0+380 'Plezy test slate (made-up service)' \
  "$slate"
for spec in "error-slate.mp4 120" "error-slate-10s.mp4 10"; do
  read -r name seconds <<<"$spec"
  ffmpeg -hide_banner -loglevel error -y \
    -loop 1 -framerate 24 -i "$slate" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -t "$seconds" -map 0:v -map 1:a \
    -c:v libx264 -tune stillimage -preset veryfast -crf 28 -pix_fmt yuv420p -r 24 \
    -c:a aac -b:a 32k -movflags +faststart -shortest \
    "$out/$name"
  ffprobe -v error -show_entries format=duration,size -of compact "$out/$name"
done
