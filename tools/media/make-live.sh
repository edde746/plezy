#!/usr/bin/env bash
# Builds the live channels' source (serve.py's /<path>.live.m3u8, the test addon's --live): h264-sdr.mkv (20 s, H.264
# with a 2-s GOP, AAC) copied as it is into a VOD HLS of 2-s segments in one MPEG-TS file, out/matrix/h264-sdr.m3u8 (byte
# ranges) and out/matrix/h264-sdr.ts, which serve.py loops into a live playlist. Run tools/media/make-matrix.sh first
# (it makes h264-sdr.mkv). Output under tools/media/out/matrix/ (gitignored). Needs ffmpeg.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
out="${PLEZY_MATRIX_OUT:-$here/out/matrix}"
[[ -f $out/h264-sdr.mkv ]] || { echo "no $out/h264-sdr.mkv: run tools/media/make-matrix.sh first" >&2; exit 1; }
ffmpeg -hide_banner -loglevel error -y -i "$out/h264-sdr.mkv" -map 0:v -map 0:a -c copy \
  -f hls -hls_time 2 -hls_playlist_type vod -hls_flags single_file -hls_segment_filename "$out/h264-sdr.ts" \
  "$out/h264-sdr.m3u8"
echo "$out/h264-sdr.ts: $(grep -c '^#EXTINF' "$out/h264-sdr.m3u8") segments"
