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

  test('a decoder that deinterlaces by itself is caught by the measured cadence', () async {
    // MediaCodec on Tegra/Amlogic emits 59.94 frames for 29.97i with no mpv
    // filter to report it; only estimated-vf-fps shows the doubled cadence.
    final output = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '29.970030', 'deinterlace-active': 'no', 'estimated-vf-fps': '58.823529'}),
    );

    expect(output.fps, closeTo(59.94006, 1e-5));
  });

  test('a frame step that advanced media time at field rate doubles even while mpv has no estimate', () async {
    // Tegra's plane: ten stepped frames advanced time-pos by ten field
    // durations while estimated-vf-fps still reads unavailable.
    const step = (frames: 10, advanced: Duration(microseconds: 166833));
    final stepped = PlayerOutputFormat.steppedRate(frames: step.frames, advanced: step.advanced);
    final output = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '29.970030', 'deinterlace-active': 'no'}),
      step: step,
    );

    expect(stepped, closeTo(59.94, 0.01));
    expect(output.fps, closeTo(59.94006, 1e-5));

    // MediaTek: the first field pair shares a timestamp, so ten frames
    // advance nine field durations.
    final withDuplicate = PlayerOutputFormat.steppedRate(frames: 10, advanced: const Duration(microseconds: 150150));
    expect(PlayerOutputFormat.presentsFields(container: 29.97003, presented: withDuplicate!), isTrue);

    // Progressive: ten frames advance ten frame durations; a stalled step
    // measures nothing.
    final progressive = PlayerOutputFormat.steppedRate(frames: 10, advanced: const Duration(microseconds: 417083));
    expect(PlayerOutputFormat.presentsFields(container: 23.976, presented: progressive!), isFalse);
    expect(PlayerOutputFormat.steppedRate(frames: 10, advanced: Duration.zero), isNull);
  });

  test('only a doubled cadence counts as field output', () {
    // Matroska rounds the first field duration to 16 or 17 ms.
    expect(PlayerOutputFormat.presentsFields(container: 29.97003, presented: 1000 / 16), isTrue);
    expect(PlayerOutputFormat.presentsFields(container: 29.97003, presented: 1000 / 17), isTrue);
    expect(PlayerOutputFormat.presentsFields(container: 25, presented: 50), isTrue);
    // Telecine (1.25x), a duplicated first frame (3x), a dropped one (0.5x).
    expect(PlayerOutputFormat.presentsFields(container: 23.976, presented: 29.97), isFalse);
    expect(PlayerOutputFormat.presentsFields(container: 29.97003, presented: 89.91), isFalse);
    expect(PlayerOutputFormat.presentsFields(container: 29.97003, presented: 14.985), isFalse);
  });

  test('a progressive stream keeps the container rate', () async {
    final progressive = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '23.976', 'deinterlace-active': 'no', 'estimated-vf-fps': '23.976'}),
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

  test('a track without a container rate takes the standard rate its frame step identifies', () async {
    // #2607: a Matroska track with no DefaultDuration gives mpv no rate.
    // Millisecond timestamps make ten 23.976 fps frames span 417 or 418 ms.
    Future<double?> fpsFor(Duration advanced) async =>
        (await PlayerOutputFormat.read(_PropertyPlayer(const {}), step: (frames: 10, advanced: advanced))).fps;

    expect(await fpsFor(const Duration(milliseconds: 417)), closeTo(24000 / 1001, 1e-9));
    expect(await fpsFor(const Duration(milliseconds: 418)), closeTo(24000 / 1001, 1e-9));
    expect(await fpsFor(const Duration(milliseconds: 416)), 24);
    expect(await fpsFor(const Duration(milliseconds: 400)), 25);
    // Field output needs no doubling: the step already counts presented frames.
    expect(await fpsFor(const Duration(milliseconds: 167)), closeTo(60000 / 1001, 1e-9));
  });

  test('a frame step that matches no standard rate yields no rate', () async {
    for (final advanced in const [
      Duration(microseconds: 409556), // 24.417 fps, the rate Plex misdetected in #2607
      Duration(milliseconds: 375), // a duplicated timestamp inside a 23.976 fps step
      Duration.zero, // a stalled step
    ]) {
      final output = await PlayerOutputFormat.read(_PropertyPlayer(const {}), step: (frames: 10, advanced: advanced));

      expect(output.fps, isNull, reason: 'advanced=$advanced');
    }
  });

  test('a container rate wins over the frame step', () async {
    final output = await PlayerOutputFormat.read(
      _PropertyPlayer({'container-fps': '25.000000'}),
      step: (frames: 10, advanced: const Duration(milliseconds: 417)),
    );

    expect(output.fps, 25);
  });
}
