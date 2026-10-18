import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/screens/video_player/open_failure_log.dart';

// mpv's error_on_track deselects a stream whose chain failed to initialize
// and, with the other stream alive, keeps the file going: no end-file
// follows, and the open would otherwise sit on its 30 s deadline for an error
// mpv logged in the first seconds. The classifier is the only thing turning
// those lines into a failure, so it must hit the terminal lines exactly and
// nothing mpv recovers from on its own.
String? classify(String text, {PlayerLogLevel level = PlayerLogLevel.error, String prefix = 'cplayer'}) {
  return openFailureCauseFromLog(level: level, prefix: prefix, text: text);
}

void main() {
  test('an audio device that would not open is the audio-output failure', () {
    // Same cause the native cores emit for a dead AO, so it inherits that
    // cause's localized copy and its always-fatal policy.
    expect(classify('Could not open/initialize audio device -> no sound.\n'), PlayerError.audioOutputFailed);
  });

  test('a decoder that could not be initialized for the codec fails the stream', () {
    // The line carries the codec name, so only its head is stable.
    expect(classify("Failed to initialize a decoder for codec 'hevc'.", prefix: 'vd'), PlayerError.streamInitFailed);
  });

  test('a failed video chain is terminal', () {
    // Android included: the plane's format rejection holds the chain for the
    // core's GL vo switch and never logs this line.
    expect(classify('Could not initialize video chain.', level: PlayerLogLevel.fatal), PlayerError.streamInitFailed);
  });

  test('a failed output conversion is terminal on the audio chain only', () {
    // audio.c deselects the track straight away with no further line.
    expect(
      classify('Cannot convert decoder/filter output to any format supported by the output.', prefix: 'af'),
      PlayerError.streamInitFailed,
    );
    // video.c first forces a software-decode fallback, and when that fails
    // too it logs "Could not initialize video chain." itself — or, on
    // Android's video plane, holds the chain for the core's GL vo switch.
    expect(
      classify('Cannot convert decoder/filter output to any format supported by the output.', prefix: 'vf'),
      isNull,
    );
  });

  test('a filter mpv bypassed is not a failure', () {
    // f_output_chain.c drops the filter and the chain keeps running; Plezy
    // inserts loudnorm, so this line is reachable on a working open.
    expect(classify('Disabling filter loudnorm because it has failed.', prefix: 'af'), isNull);
  });

  test('a libavfilter graph that refused to run leaves its chain stuck', () {
    // f_lavfi.c logs the AVERROR and ignores it: the filter is neither
    // failed nor bypassed, so the stream behind it never produces a frame
    // and no playback-restart follows (loudnorm ENOMEM on 32-bit Android).
    expect(classify('error on filtering (-12)', prefix: 'lavfi'), PlayerError.streamInitFailed);
    // Only the wrapper's own prefix: the text is not mpv's elsewhere.
    expect(classify('error on filtering (-12)', prefix: 'af'), isNull);
  });

  test('one failed hwdec probe is not a failure', () {
    // vd_lavc.c logs this per attempted hwdec method before the next one
    // (or software decoding) takes over.
    expect(classify('Could not open codec.', prefix: 'vd'), isNull);
  });

  test('only error and fatal levels count', () {
    expect(classify('Could not open/initialize audio device -> no sound.', level: PlayerLogLevel.warn), isNull);
  });

  test('HTTP status lines stay with the status parser and the 503 watchdog', () {
    expect(classify('https: HTTP error 503 Service Unavailable', prefix: 'ffmpeg'), isNull);
  });
}
