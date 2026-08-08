import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player_screen.dart';

void main() {
  test('transcode opens tune the demuxer and clear subtitle events on seek (#1738)', () {
    final props = networkStreamTuningProperties(isNetworkVod: true, isTranscoding: true);

    // Segment retries belong to ffmpeg's hls demuxer; the HTTP layer must not
    // second-guess a finished segment (Plex sends WebVTT with no
    // Content-Length, so a retry turns every clean EOF into a 416 loop).
    expect(props['demuxer-lavf-o'], 'reconnect=0,reconnect_streamed=0,reconnect_on_network_error=0');
    // Seeks re-deliver WebVTT cues with restarted ReadOrder; without this the
    // same cue renders stacked on top of itself.
    expect(props['sub-clear-on-seek'], 'yes');
    // The #1520 playlist-level reconnect protection must survive unchanged.
    expect(
      props['stream-lavf-o'],
      'reconnect=1,reconnect_on_network_error=1,reconnect_on_http_error=503,'
      'reconnect_streamed=1,reconnect_delay_max=600',
    );
  });

  test('non-transcode opens reset the transcode tuning so a reused player carries nothing over', () {
    final networkDirectPlay = networkStreamTuningProperties(isNetworkVod: true, isTranscoding: false);
    expect(networkDirectPlay['demuxer-lavf-o'], '');
    expect(networkDirectPlay['sub-clear-on-seek'], 'no');
    expect(networkDirectPlay['stream-lavf-o'], isNotEmpty);

    final localFile = networkStreamTuningProperties(isNetworkVod: false, isTranscoding: false);
    expect(localFile['stream-lavf-o'], '');
    expect(localFile['demuxer-lavf-o'], '');
    expect(localFile['sub-clear-on-seek'], 'no');
  });

  test('every mpv option-string entry is a complete key=value (no multi-code values needing quoting)', () {
    for (final transcoding in [true, false]) {
      final props = networkStreamTuningProperties(isNetworkVod: true, isTranscoding: transcoding);
      for (final optionList in ['stream-lavf-o', 'demuxer-lavf-o']) {
        final value = props[optionList]!;
        if (value.isEmpty) continue;
        // mpv splits key-value-list options on commas; a value containing a
        // comma (e.g. reconnect_on_http_error=404,503) needs %len% quoting and
        // must not appear here unquoted.
        for (final entry in value.split(',')) {
          expect(RegExp(r'^[a-z_]+=[0-9]+$').hasMatch(entry), isTrue, reason: '"$entry" in $optionList');
        }
      }
    }
  });
}
