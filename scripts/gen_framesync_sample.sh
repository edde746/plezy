#!/usr/bin/env bash
# Generates MKV test assets that prove (or disprove) frame-perfect ASS rendering:
# the video has a per-frame counter burned in (top) and the MKV carries an ASS
# track flipping the same counter (bottom) on exactly the same frame boundaries.
# Any captured frame showing video number N with subtitle number != N is a sync
# failure.
#
# Outputs (in scripts/framesync/):
#   framesync-2397.mkv    23.976 fps, plain per-frame counter events
#   framesync-60.mkv      60 fps variant
#   framesync-stress.mkv  23.976 fps + heavy animated typesetting (blur/scale/
#                         rotation re-rendered every frame) to stress libass
#
# The burn-in uses, in order of preference: ffmpeg drawtext, ffmpeg subtitles
# filter, or mpv's encoding mode (mpv always bundles libass) — all three
# evaluate the counter at each frame's exact PTS, so the burned reference is
# frame-exact by construction.
#
# Verification procedure (Android, ExoPlayer path):
#   1. Play the file with the ASS track selected (SDR content and the
#      ASS-tunneling block mean the layers are screen-recordable).
#   2. adb shell screenrecord /sdcard/sync.mp4   (record ~30 s, pull it)
#   3. Step through frames (e.g. ffmpeg -i sync.mp4 frames/%05d.png, or mpv with
#      '.' frame-step): top (video) and bottom (player-rendered ASS) counters
#      must match on EVERY captured frame. Desktop mpv is the reference player.
#   4. Cross-check at the compositor: while playing,
#        adb shell dumpsys SurfaceFlinger --latency
#      lists per-layer (desired, actual) present times for the video SurfaceView
#      and the ASS overlay layer — matched content must share vsync timestamps.
#   5. Cheap regression: the in-app stats overlay should show subLateSwaps ≈ 0,
#      subOverflows == 0, subMinLeadMs ≥ 0 and a >95% subSpecHits ratio.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p framesync
cd framesync

DURATION_S=${DURATION_S:-60}
# drawtext resolves the family via fontconfig; override with FONT if needed.
FONT=${FONT:-Sans}

have_filter() { ffmpeg -hide_banner -filters 2>/dev/null | grep -q " $1 "; }

# Emits an ASS file with one Dialogue event per frame. Frame i starts at
# i*den/num seconds; timestamps are floored to ASS centisecond precision, which
# is safe because the floor error (<10 ms) is smaller than any frame interval
# generated here (16.7 / 41.7 ms) — an event can never leak onto the previous
# frame. burn=1 emits the top-aligned white reference style (for burn-in),
# burn=0 the bottom-aligned yellow player style; heavy=1 adds per-frame
# animated blur/scale/rotation events.
gen_ass() { # $1=fps_num $2=fps_den $3=frames $4=burn(0/1) $5=heavy(0/1) $6=outfile
  awk -v num="$1" -v den="$2" -v frames="$3" -v burn="$4" -v heavy="$5" '
    function ts(cs,  h, m, s) {
      h = int(cs / 360000); cs -= h * 360000
      m = int(cs / 6000);  cs -= m * 6000
      s = int(cs / 100);   cs -= s * 100
      return sprintf("%d:%02d:%02d.%02d", h, m, s, cs)
    }
    BEGIN {
      print "[Script Info]"
      print "ScriptType: v4.00+"
      print "PlayResX: 1280"
      print "PlayResY: 720"
      print ""
      print "[V4+ Styles]"
      print "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"
      if (burn)
        print "Style: Counter,Arial,150,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,8,10,10,30,1"
      else
        print "Style: Counter,Arial,150,&H0000FFFF,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,10,10,30,1"
      print "Style: Stress,Arial,80,&H40FF8800,&H000000FF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,2,0,5,10,10,10,1"
      print ""
      print "[Events]"
      print "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
      for (i = 0; i < frames; i++) {
        start = int(i * den * 100 / num)
        end = int((i + 1) * den * 100 / num)
        if (end <= start) end = start + 1
        printf "Dialogue: 0,%s,%s,Counter,,0,0,0,,%d\n", ts(start), ts(end), i
        if (heavy) {
          # Re-emitted every frame with a frame-dependent rotation/blur so libass
          # reports changed content and re-rasterizes large blurred glyphs —
          # approximates typesetting storms (the measured 100-400 ms frames).
          printf "Dialogue: 1,%s,%s,Stress,,0,0,0,,{\\an5\\pos(640,260)\\blur12\\fscx320\\fscy320\\frz%d}#\n", ts(start), ts(end), (i * 7) % 360
          printf "Dialogue: 1,%s,%s,Stress,,0,0,0,,{\\an5\\pos(640,500)\\blur18\\fscx500\\fscy220\\frz%d\\alpha&H80&}@\n", ts(start), ts(end), 359 - (i * 11) % 360
        }
      }
    }
  ' /dev/null > "$6"
}

# Produces the reference video: gray frames with the frame counter burned in at
# the top. Tries drawtext, then the subtitles filter, then mpv encoding.
gen_video() { # $1=rate $2=burn_ass $3=outfile
  if have_filter drawtext; then
    ffmpeg -y -v error -f lavfi -i "color=c=0x202020:s=1280x720:r=$1" \
      -vf "drawtext=font='${FONT}':text='%{n}':fontsize=150:fontcolor=white:borderw=5:bordercolor=black:x=(w-text_w)/2:y=30" \
      -t "$DURATION_S" -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$3"
  elif have_filter subtitles; then
    ffmpeg -y -v error -f lavfi -i "color=c=0x202020:s=1280x720:r=$1" \
      -vf "subtitles=$2" \
      -t "$DURATION_S" -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$3"
  elif command -v mpv > /dev/null; then
    ffmpeg -y -v error -f lavfi -i "color=c=0x202020:s=1280x720:r=$1" \
      -t "$DURATION_S" -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p blank.mp4
    mpv blank.mp4 --sub-files="$2" --vf=sub --no-audio \
      --o="$3" --of=mp4 --ovc=libx264 --ovcopts=preset=veryfast,crf=18 \
      --msg-level=all=error
    rm -f blank.mp4
  else
    echo "error: need ffmpeg with drawtext or subtitles filter, or mpv (for the burn-in)" >&2
    exit 1
  fi
}

# Muxes the burned video + silent audio + the player-rendered ASS track.
mux() { # $1=video $2=ass $3=outfile
  ffmpeg -y -v error -i "$1" -f lavfi -i "anullsrc=r=48000:cl=stereo" -i "$2" \
    -map 0:v -map 1:a -map 2 -c:v copy -c:a aac -b:a 64k -c:s copy -shortest \
    -metadata:s:s:0 language=eng -disposition:s:0 default "$3"
}

frames_2397=$(awk -v d="$DURATION_S" 'BEGIN { print int(d * 24000 / 1001) }')
frames_60=$(awk -v d="$DURATION_S" 'BEGIN { print d * 60 }')

echo "Generating ${DURATION_S}s assets..."
gen_ass 24000 1001 "$frames_2397" 1 0 burn-2397.ass
gen_ass 60 1 "$frames_60" 1 0 burn-60.ass
gen_ass 24000 1001 "$frames_2397" 0 0 counter-2397.ass
gen_ass 60 1 "$frames_60" 0 0 counter-60.ass
gen_ass 24000 1001 "$frames_2397" 0 1 counter-stress.ass
gen_video "24000/1001" burn-2397.ass video-2397.mp4
gen_video "60" burn-60.ass video-60.mp4
mux video-2397.mp4 counter-2397.ass framesync-2397.mkv
mux video-60.mp4 counter-60.ass framesync-60.mkv
mux video-2397.mp4 counter-stress.ass framesync-stress.mkv
rm -f video-2397.mp4 video-60.mp4 burn-2397.ass burn-60.ass

echo "Done:"
ls -la framesync-*.mkv
echo
echo "Reference check: open framesync-2397.mkv in mpv, frame-step with '.' —"
echo "top (video) and bottom (subtitle) counters must match on every frame."
echo "Then repeat in Plezy on-device and screenrecord (see header comments)."
