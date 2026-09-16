import '../../mpv/models.dart';

// Every line below is quoted verbatim from mpv, where it is the last thing
// logged before `error_on_track` (player/misc.c) deselects the stream:
//
// - player/audio.c: "Could not open/initialize audio device -> no sound."
//   (sets MPV_ERROR_AO_INIT_FAILED), "Audio filter initialized failed!",
//   "Error reinitializing audio."; a failed output conversion on the audio
//   chain deselects the track without any further line of its own.
// - player/video.c: "Could not initialize video chain.", "Error
//   opening/initializing the selected video_out (--vo) device."
// - filters/f_output_chain.c: "Cannot convert decoder/filter output to any
//   format supported by the output." — logged under the chain's own prefix
//   (`af` / `vf`).
// - filters/f_decoder_wrapper.c: "Failed to initialize a decoder for codec
//   '%s'." — after the whole decoder list was tried.
//
// One line is terminal without deselecting anything: filters/f_lavfi.c
// "error on filtering (%d)" — libavfilter refused to run the graph
// (AVERROR code in the parentheses; -12 is ENOMEM). mpv's read_output_pads
// logs it under "Real error - ignore it": the filter is neither failed nor
// bypassed, so the chain simply never produces a frame again. During an
// open that means the stream behind it (audio for loudnorm, video for
// bwdif) never reaches READY and mpv never fires playback-restart — video
// sits on its first frame and only the open deadline ends it, ~26 s after
// the line (Fire TV / Google TV Streamer / Box R, TrueHD 7.1 + loudnorm on
// the pre-pool-fix FFmpeg).
//
// Deliberately absent: "Disabling filter %s because it has failed."
// (f_output_chain.c — the filter is bypassed, the chain continues), "Could
// not open codec." (video/decode/vd_lavc.c — one hwdec probe, the next
// method follows), ffmpeg per-packet errors, and HTTP status lines, which
// `PlayerError.httpStatusFromLog` and the 503 watchdog own.

const String _audioOutputFailedLine = 'Could not open/initialize audio device -> no sound.';
const String _videoChainFailedLine = 'Could not initialize video chain.';
const String _outputConversionFailedLine =
    'Cannot convert decoder/filter output to any format supported by the output.';
const String _decoderInitFailedPrefix = 'Failed to initialize a decoder for codec';
const String _lavfiRunFailedPrefix = 'error on filtering (';
const List<String> _streamInitFailedLines = [
  'Audio filter initialized failed!',
  'Error reinitializing audio.',
  'Error opening/initializing the selected video_out (--vo) device.',
];

/// The [PlayerError] cause an open should fail with because of one mpv log
/// line, or null when the line is not one mpv gives a stream up on.
///
/// mpv's `error_on_track` only ends the file when *both* streams are gone;
/// with the other stream alive it keeps playing (audio-only, or video with no
/// sound) and no `end-file` reaches Dart, so the open sits on its deadline.
/// These lines are the only early signal. Pure and exact-match so it is
/// testable and cannot drift into matching recoverable errors.
///
/// [prefix] is mpv's log prefix. The output-conversion line is terminal only
/// on the audio chain (`af`): on the video chain (`vf`) mpv first forces a
/// software-decode fallback (player/video.c `check_for_hwdec_fallback`) and,
/// if that fails too, logs "Could not initialize video chain." itself.
///
/// [isAndroid]: the Android core consumes "Could not initialize video chain."
/// under vo=mediacodec to fall back to the GL vo and re-select the video
/// track (MpvPlayerCore.kt `collectLogMessages`), so Dart must not pre-empt
/// it there.
String? openFailureCauseFromLog({
  required PlayerLogLevel level,
  required String prefix,
  required String text,
  required bool isAndroid,
}) {
  if (level != PlayerLogLevel.error && level != PlayerLogLevel.fatal) return null;
  final line = text.trim();
  if (line == _audioOutputFailedLine) return PlayerError.audioOutputFailed;
  if (line == _videoChainFailedLine) return isAndroid ? null : PlayerError.streamInitFailed;
  if (line == _outputConversionFailedLine) return prefix == 'af' ? PlayerError.streamInitFailed : null;
  if (_streamInitFailedLines.contains(line) || line.startsWith(_decoderInitFailedPrefix)) {
    return PlayerError.streamInitFailed;
  }
  // The libavfilter wrapper logs under its own prefix whichever chain hosts
  // it; other filters never produce this text.
  if (prefix == 'lavfi' && line.startsWith(_lavfiRunFailedPrefix)) return PlayerError.streamInitFailed;
  return null;
}
