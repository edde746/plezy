import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main_gkui.dart';

void main() {
  test('no-frame timeout follows the full compatibility ladder', () {
    expect(playbackFallback(PlaybackMode.direct, 'startup_timeout'),
        PlaybackMode.transcode720);
    expect(playbackFallback(PlaybackMode.transcode720, 'startup_timeout'),
        PlaybackMode.transcode480);
    expect(
        playbackFallback(PlaybackMode.transcode480, 'startup_timeout'), isNull);
  });

  test('real connection failures do not request another video profile', () {
    for (final kind in <String>['network', 'http', 'initialization']) {
      expect(playbackFallback(PlaybackMode.direct, kind), isNull);
    }
  });

  test('decoder and source failures also use compatibility playback', () {
    expect(playbackFallback(PlaybackMode.direct, 'decoder'),
        PlaybackMode.transcode720);
    expect(playbackFallback(PlaybackMode.transcode720, 'source'),
        PlaybackMode.transcode480);
  });

  test('mobile startup ceilings allow slower transcodes', () {
    expect(playbackStartupHardTimeoutMs(PlaybackMode.direct), 90000);
    expect(playbackStartupHardTimeoutMs(PlaybackMode.transcode720), 120000);
    expect(playbackStartupHardTimeoutMs(PlaybackMode.transcode480), 120000);
  });
}
