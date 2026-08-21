import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

/// Drives the Buffer Size contract between Dart and `ExoPlayerPlugin` (#1618).
///
/// Auto still sends `demuxer-max-bytes`, because mpv's demuxer shares the property and the
/// plugin's mpv fallback replays it. Only `bufferSizeAuto` tells the native side that the
/// value was derived for the demuxer and that `LoadControlPolicy` should size ExoPlayer's
/// allocator instead. Getting that flag wrong is silent: playback still works, just with the
/// 64MB cap that starves a high-bitrate passthrough track.
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

  test('Auto tells the native side to size its own LoadControl target', () async {
    final initialize = await _captureInitialize(
      configure: (player) async {
        // What video_player_screen sends on Auto for a 512MB-heap device.
        await player.setProperty('demuxer-max-bytes', '${64 * 1024 * 1024}');
        await player.setProperty('demuxer-max-bytes-auto', 'yes');
      },
    );

    final args = initialize.arguments as Map<Object?, Object?>;
    expect(args['bufferSizeAuto'], isTrue);
    // Still forwarded: the plugin's mpv fallback replays it as a real demuxer property.
    expect(args['bufferSizeBytes'], 64 * 1024 * 1024);
  });

  test('an explicit Buffer Size choice is never overridden by Auto sizing', () async {
    final initialize = await _captureInitialize(
      configure: (player) async {
        await player.setProperty('demuxer-max-bytes', '${128 * 1024 * 1024}');
      },
    );

    final args = initialize.arguments as Map<Object?, Object?>;
    expect(args['bufferSizeAuto'], isFalse);
    expect(args['bufferSizeBytes'], 128 * 1024 * 1024);
  });

  test('an unknown heap leaves no byte cap, so the native side still picks Auto', () async {
    // video_player_screen skips the whole tier block when getHeapSize() fails, so neither
    // property is ever set. bufferSizeBytes must stay null rather than defaulting to a
    // number the native side would treat as a deliberate choice.
    final initialize = await _captureInitialize(configure: (_) async {});

    final args = initialize.arguments as Map<Object?, Object?>;
    expect(args['bufferSizeAuto'], isFalse);
    expect(args['bufferSizeBytes'], isNull);
    // Playback Buffer is also init-only: when absent, native must receive an explicit Auto wire value.
    expect(args['bufferTier'], 'auto');
  });

  test('an explicit Playback Buffer tier reaches native initialization', () async {
    final initialize = await _captureInitialize(
      configure: (player) async {
        await player.setProperty('exo-buffer-tier', PlaybackBufferTier.extraLarge.nativeValue);
      },
    );

    final args = initialize.arguments as Map<Object?, Object?>;
    // The synthetic property is init-only; losing it would silently restore the native Auto tier.
    expect(args['bufferTier'], 'extra_large');
  });
}
