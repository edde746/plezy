#!/usr/bin/env bash
# Builds the sample the mpv-android device tests play: 60 s of 1080p HEVC 10-bit, AAC stereo and an embedded, styled
# ASS subtitle track, in Matroska. Output: tools/media/out/sample.mkv (gitignored). Needs ffmpeg with libx265.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
cat > out/sample.ass <<'EOF'
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,64,&H00D6F1FF,&H000000FF,&H00000000,&H64000000,0,0,0,0,100,100,0,0,1,4,1,8,40,40,60,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.50,0:00:15.00,Default,,0,0,0,,Plezy sample · ASS subtitle, top centre
Dialogue: 0,0:00:15.00,0:00:30.00,Default,,0,0,0,,{\c&H00FFFF&}Styled line: yellow, still top centre
Dialogue: 0,0:00:30.00,0:00:45.00,Default,,0,0,0,,{\an2}Bottom centre, above the player overlay?
Dialogue: 0,0:00:45.00,0:01:00.00,Default,,0,0,0,,{\fad(500,500)}Fading line · end of sample
EOF
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "testsrc2=size=1920x1080:rate=24000/1001:duration=60" \
  -f lavfi -i "sine=frequency=440:sample_rate=48000:duration=60" \
  -i out/sample.ass \
  -map 0:v -map 1:a -map 2:s \
  -c:v libx265 -pix_fmt yuv420p10le -preset fast -crf 28 -x265-params log-level=error \
  -c:a aac -b:a 128k -ac 2 \
  -c:s ass -metadata:s:s:0 language=eng -metadata:s:s:0 title="ASS" \
  -metadata title="Plezy sample" \
  out/sample.mkv
ffprobe -v error -show_entries stream=codec_name,profile,pix_fmt,codec_type -of compact out/sample.mkv
ls -l out/sample.mkv
