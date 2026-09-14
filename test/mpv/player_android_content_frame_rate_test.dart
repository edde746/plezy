import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// Drives the content frame-rate contract between Dart and `ExoPlayerPlugin` (#1802).
///
/// The native side gates video tunneling on this rate: a Fire TV Stick 4K judders through
/// tunneled 23.976p, so `DeviceQuirks.hasUnreliableTunneledPlayback` withdraws tunneling
/// below 30fps and leaves the 4K60 workload tunneling alone. Neither the Matroska nor the
/// MP4 extractor populates `Format.frameRate`, and a tunneled session renders no frames
/// back for the native FPS detector, so this channel argument is the only source.
///
/// Losing it is silent — the native default is "unknown", which keeps stock behaviour and
/// simply never applies the fix.
Future<MethodCall> _captureOpen({required Future<void> Function(PlayerAndroid player) configure}) async {
  late MethodCall open;
  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/exo_player',
    eventChannelName: 'com.plezy/exo_player/events',
    methodHandler: (call) async {
      if (call.method == 'open') open = call;
      return call.method == 'initialize' ? true : null;
    },
    testBody: () async {
      final player = PlayerAndroid();
      try {
        await configure(player);
        await player.open(const Media('https://example.test/a.mkv'), play: false);
      } finally {
        await player.dispose();
      }
    },
  );
  return open;
}

Map<Object?, Object?> _args(MethodCall call) => call.arguments as Map<Object?, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('the metadata frame rate reaches the native open call', () async {
    final open = await _captureOpen(configure: (player) => player.setProperty('content-frame-rate', '23.976'));

    expect(_args(open)['contentFrameRate'], closeTo(23.976, 1e-6));
  });

  test('a high frame rate is forwarded unchanged so tunneling survives', () async {
    // The quirk must be able to tell 4K60 apart from 24p; clamping or rounding here
    // would withdraw tunneling from the workload it exists for.
    final open = await _captureOpen(configure: (player) => player.setProperty('content-frame-rate', '59.94'));

    expect(_args(open)['contentFrameRate'], closeTo(59.94, 1e-6));
  });

  test('unknown metadata sends no rate rather than a bogus one', () async {
    // video_player_screen writes "0" when the server gave no frame rate. Forwarding 0 as a
    // real value would be indistinguishable from a measured rate on the native side.
    final open = await _captureOpen(configure: (player) => player.setProperty('content-frame-rate', '0'));

    expect(_args(open).containsKey('contentFrameRate'), isFalse);
  });

  test('an item without a rate clears the previous item\'s rate', () async {
    // Episode-to-episode reuse keeps the same PlayerAndroid, so a stale 24p rate would
    // keep tunneling withdrawn for a following 60fps item.
    final open = await _captureOpen(
      configure: (player) async {
        await player.setProperty('content-frame-rate', '23.976');
        await player.setProperty('content-frame-rate', '0');
      },
    );

    expect(_args(open).containsKey('contentFrameRate'), isFalse);
  });

  test('an unparseable rate is dropped instead of forwarded', () async {
    final open = await _captureOpen(configure: (player) => player.setProperty('content-frame-rate', 'nonsense'));

    expect(_args(open).containsKey('contentFrameRate'), isFalse);
  });
}
