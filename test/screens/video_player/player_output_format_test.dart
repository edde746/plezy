import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/player_output_format.dart';

import '../../test_helpers/watch_together_fakes.dart';

/// A player whose mpv properties are exactly the given map; anything else
/// is unavailable, as a backend without the property (ExoPlayer) or a chain
/// that has not configured yet reports it.
class _PropertyPlayer extends FakeSyncPlayer {
  _PropertyPlayer(this._properties);

  final Map<String, String> _properties;

  @override
  Future<String?> getProperty(String name) async => _properties[name];
}

void main() {
  test('an interlaced stream is presented at field rate while mpv deinterlaces it', () async {
    // #2322: bwdif send_field turns 29.97i into 59.94p, so an exact 29.97 Hz
    // mode would drop every other frame.
    final output = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '29.970030', 'deinterlace-active': 'yes', 'width': '720', 'height': '480'}),
    );

    expect(output.fps, closeTo(59.94006, 1e-5));
    expect(output.width, 720);
    expect(output.height, 480);
  });

  test('a progressive stream keeps the container rate', () async {
    final progressive = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '23.976', 'deinterlace-active': 'no'}),
    );
    final withoutDeinterlacer = await PlayerOutputFormat.read(_PropertyPlayer({'container-fps': '23.976'}));

    expect(progressive.fps, closeTo(23.976, 1e-9));
    expect(withoutDeinterlacer.fps, closeTo(23.976, 1e-9));
    expect(progressive.hasDimensions, isFalse);
  });

  test('no usable container rate yields no rate target', () async {
    for (final raw in [null, '0', '-1', 'nan-ish']) {
      final output = await PlayerOutputFormat.read(
        _PropertyPlayer({'container-fps': ?raw, 'deinterlace-active': 'yes'}),
      );

      expect(output.hasFrameRate, isFalse, reason: 'container-fps=$raw');
      expect(output.fps, isNull, reason: 'container-fps=$raw');
    }
  });
}
