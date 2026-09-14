import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';

import '../test_helpers/mock_player_channels.dart';

/// The device heap is immutable per process, so [PlayerNative.getHeapSize]
/// memoizes the first successful result: the second read on the playback-open
/// hot path (`_applyNetworkStreamTuning`) must not pay a channel round trip.
/// Failures keep the documented `0` sentinel and must never be pinned.
///
/// Served by the mpv plugin channel, which is registered regardless of the
/// selected backend, so the stream ring cache tier works on both.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PlayerNative.debugResetHeapSizeCache);

  Future<void> withHeapSizeHandler({
    required Future<Object?> Function(MethodCall call) methodHandler,
    required Future<void> Function() testBody,
  }) {
    return withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: methodHandler,
      testBody: testBody,
    );
  }

  test('a successful heap read is served from cache on subsequent calls', () async {
    var channelCalls = 0;
    await withHeapSizeHandler(
      methodHandler: (call) async {
        if (call.method != 'getHeapSize') return null;
        channelCalls++;
        return 512;
      },
      testBody: () async {
        expect(await PlayerNative.getHeapSize(), 512);
        expect(await PlayerNative.getHeapSize(), 512);
      },
    );
    expect(channelCalls, 1);
  });

  test('a failed heap read returns 0 and is not cached', () async {
    await withHeapSizeHandler(
      methodHandler: (call) async => throw PlatformException(code: 'unavailable'),
      testBody: () async {
        expect(await PlayerNative.getHeapSize(), 0);
      },
    );
    // The channel recovers: the earlier failure must not have pinned the 0
    // sentinel, or the stream ring cap would stay degraded for the whole run.
    await withHeapSizeHandler(
      methodHandler: (call) async => call.method == 'getHeapSize' ? 256 : null,
      testBody: () async {
        expect(await PlayerNative.getHeapSize(), 256);
      },
    );
  });

  test('a null heap report keeps the 0 sentinel without caching it', () async {
    var channelCalls = 0;
    await withHeapSizeHandler(
      methodHandler: (call) async {
        if (call.method != 'getHeapSize') return null;
        channelCalls++;
        return null;
      },
      testBody: () async {
        expect(await PlayerNative.getHeapSize(), 0);
        expect(await PlayerNative.getHeapSize(), 0);
      },
    );
    // Unavailable is re-asked, never memoized.
    expect(channelCalls, 2);
  });
}
