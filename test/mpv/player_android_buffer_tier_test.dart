import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// Drives the Playback Buffer contract between Dart and `ExoPlayerPlugin` (#1816).
///
/// `exo-buffer-tier` is a synthetic property, not an mpv one: mpv's read-ahead belongs to
/// the mpv.conf editor, so the tier is cached in Dart and only ever crosses the channel as
/// the `bufferTier` argument of `initialize`, where `ExoPlayerCore` resolves it into
/// `LoadControlPolicy.bufferDurations`. It is init-only — losing it is silent, because the
/// native side then keeps the Auto tier and simply never applies the user's choice.
Future<MethodCall> _captureInitialize({required Future<void> Function(PlayerAndroid player) configure}) async {
  late MethodCall initialize;
  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/exo_player',
    eventChannelName: 'com.plezy/exo_player/events',
    methodHandler: (call) async {
      if (call.method == 'initialize') initialize = call;
      return call.method == 'initialize' ? true : null;
    },
    testBody: () async {
      final player = PlayerAndroid();
      try {
        await configure(player);
        // requestAudioFocus is what actually triggers native initialize; the screen relies
        // on that ordering so every setProperty above is cached first.
        await player.requestAudioFocus();
      } finally {
        await player.dispose();
      }
    },
  );
  return initialize;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('an explicit Playback Buffer tier reaches native initialization', () async {
    final initialize = await _captureInitialize(
      configure: (player) => player.setProperty('exo-buffer-tier', PlaybackBufferTier.extraLarge.nativeValue),
    );

    final args = initialize.arguments as Map<Object?, Object?>;
    expect(args['bufferTier'], 'extra_large');
  });

  test('no tier write still sends an explicit Auto wire value', () async {
    // Native reads the argument with a `?: "auto"` default, but the wire value must be
    // present and explicit: a missing key would make a genuine Auto session
    // indistinguishable from a tier that was dropped on the way down.
    final initialize = await _captureInitialize(configure: (_) async {});

    final args = initialize.arguments as Map<Object?, Object?>;
    expect(args['bufferTier'], 'auto');
  });
}
