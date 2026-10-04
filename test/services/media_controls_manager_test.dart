import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/media_controls_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.edde746.os_media_controls/methods');
  final calls = <MethodCall>[];
  TargetPlatform? previousPlatformOverride;

  setUp(() {
    previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = previousPlatformOverride;
  });

  test('guest, anyone, and host capability snapshots advertise exact authority', () async {
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);

    await manager.setControlsEnabled(
      canPlayPause: false,
      canGoNext: false,
      canGoPrevious: false,
      canSeek: false,
      canStop: true,
      canSkip: false,
      canSetSpeed: false,
    );

    _expectControlTransition(
      calls,
      enabled: const ['stop'],
      disabled: const ['play', 'pause', 'previous', 'next', 'seek', 'skipForward', 'skipBackward', 'changeSpeed'],
    );

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: false,
      canGoPrevious: false,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    _expectControlTransition(
      calls,
      enabled: const ['play', 'pause', 'seek', 'skipForward', 'skipBackward', 'changeSpeed'],
    );

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    _expectControlTransition(calls, enabled: const ['previous', 'next']);

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    expect(calls, isEmpty);
  });

  test('video-style sync advertises skip with intervals on iOS and resends only on change', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);

    Future<void> syncVideoStyle(Duration interval) => manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
      preferSkipOverTrackButtons: true,
      skipInterval: interval,
    );

    await syncVideoStyle(const Duration(seconds: 10));
    expect(calls.map((c) => c.method), ['setSkipIntervals', 'enableControls']);
    expect(calls[0].arguments, {'forward': 10, 'backward': 10});
    expect(calls[1].arguments, containsAll(['skipForward', 'skipBackward']));

    // Unchanged snapshot: nothing crosses the channel again.
    calls.clear();
    await syncVideoStyle(const Duration(seconds: 10));
    expect(calls, isEmpty);

    // An interval change alone re-advertises the new step.
    await syncVideoStyle(const Duration(seconds: 30));
    expect(calls.map((c) => c.method), ['setSkipIntervals']);
    expect(calls[0].arguments, {'forward': 30, 'backward': 30});

    // clear() drops the cached interval; the next session re-sends it.
    await manager.clear();
    calls.clear();
    await syncVideoStyle(const Duration(seconds: 30));
    expect(calls.map((c) => c.method), ['setSkipIntervals', 'enableControls']);
  });

  test('music-style sync keeps skip un-advertised on iOS so next/previous hold the lock screen', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);

    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      skipInterval: const Duration(seconds: 10),
    );

    _expectControlTransition(
      calls,
      enabled: const ['play', 'pause', 'previous', 'next', 'seek', 'stop'],
      disabled: const ['skipForward', 'skipBackward', 'changeSpeed'],
    );
  });

  test('skip intervals never cross the channel on Android', () async {
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);

    await manager.setControlsEnabled(
      canPlayPause: true,
      canStop: true,
      canSkip: true,
      preferSkipOverTrackButtons: true,
      skipInterval: const Duration(seconds: 10),
    );

    expect(calls.map((c) => c.method), isNot(contains('setSkipIntervals')));
    expect(calls.map((c) => c.method), ['enableControls', 'disableControls']);
    expect(calls[0].arguments, containsAll(['skipForward', 'skipBackward']));
  });

  group('artwork', () {
    late AppDatabase db;
    late PlexClient client;
    setUpAll(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      client = testPlexClient(token: 'secret-token');
    });
    tearDownAll(() async {
      client.close();
      await db.close();
    });
    final movie = testMediaItem(title: 'Movie', thumbPath: '/library/metadata/1/thumb/2');

    List<Map<Object?, Object?>> metadataCalls() => [
      for (final call in calls)
        if (call.method == 'setMetadata') call.arguments as Map<Object?, Object?>,
    ];

    test('Linux publishes artwork bytes instead of the token-bearing URL', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final requested = <String>[];
      final manager = MediaControlsManager(
        artworkBytesLoader: (url) async {
          requested.add(url);
          return Uint8List.fromList([1, 2, 3]);
        },
      );
      addTearDown(manager.dispose);

      await manager.updateMetadata(metadata: movie, client: client);
      await pumpEventQueue();

      expect(requested.single, contains('secret-token'));
      final published = metadataCalls();
      expect(published, hasLength(2));
      expect(published.first['title'], 'Movie');
      expect(published.map((m) => m['artworkUrl']), everyElement(isNull));
      expect(published.last['artwork'], [1, 2, 3]);
    });

    test('late Linux artwork never lands on a newer item or a cleared session', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final pending = <Completer<Uint8List?>>[];
      final manager = MediaControlsManager(
        artworkBytesLoader: (_) {
          final completer = Completer<Uint8List?>();
          pending.add(completer);
          return completer.future;
        },
      );
      addTearDown(manager.dispose);

      await manager.updateMetadata(metadata: movie, client: client);
      await manager.updateMetadata(
        metadata: testMediaItem(id: 'item-2', title: 'Next', thumbPath: '/library/metadata/2/thumb/3'),
        client: client,
      );
      pending.first.complete(Uint8List.fromList([1]));
      await pumpEventQueue();
      expect(metadataCalls().map((m) => m['title']), ['Movie', 'Next']);

      await manager.clear();
      pending.last.complete(Uint8List.fromList([2]));
      await pumpEventQueue();
      expect(metadataCalls().map((m) => m['title']), ['Movie', 'Next']);
    });

    test('other platforms keep handing the artwork URL to the plugin', () async {
      final manager = MediaControlsManager(artworkBytesLoader: (_) async => fail('no download expected'));
      addTearDown(manager.dispose);

      await manager.updateMetadata(metadata: movie, client: client);
      await pumpEventQueue();

      final published = metadataCalls();
      expect(published, hasLength(1));
      expect(published.single['artworkUrl'], contains('/library/metadata/1/thumb/2'));
    });
  });
}

void _expectControlTransition(
  List<MethodCall> calls, {
  List<String> enabled = const [],
  List<String> disabled = const [],
}) {
  final expectedCalls = <({String method, List<String> controls})>[
    if (enabled.isNotEmpty) (method: 'enableControls', controls: enabled),
    if (disabled.isNotEmpty) (method: 'disableControls', controls: disabled),
  ];

  expect(calls, hasLength(expectedCalls.length));
  for (var index = 0; index < expectedCalls.length; index++) {
    expect(calls[index].method, expectedCalls[index].method);
    expect(calls[index].arguments, expectedCalls[index].controls);
  }
}
