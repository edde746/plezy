import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/services/system_shelf_service.dart';

import '../test_helpers/media_items.dart';

class _ShelfClient implements MediaServerClient {
  _ShelfClient({this.throwOnThumbnail = false});

  final bool throwOnThumbnail;

  @override
  ServerId get serverId => ServerId('server-a');

  @override
  String get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  String thumbnailUrl(String? path, {int? width, int? height}) {
    if (throwOnThumbnail) throw StateError('conversion failed');
    expect(width, 640);
    expect(height, 360);
    return 'https://media.invalid/poster.jpg?token=transient';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/system_shelf');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('live shelf tap acknowledges only an attached consumer', () async {
    final service = SystemShelfService.forTesting(channel: channel);
    const call = MethodCall('onShelfItemTap', {'contentId': 'server:item'});

    expect(await service.handleMethodCallForTesting(call), isFalse);

    final received = <String>[];
    service.onShelfItemTap = received.add;
    expect(await service.handleMethodCallForTesting(call), isTrue);
    expect(received, ['server:item']);
  });

  test('delayed support result is dropped after synchronous owner invalidation', () async {
    final support = Completer<bool>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () => support.future);
    service.beginProfileSession('owner-a');

    final delayed = service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient());
    final ended = service.endProfileSession('owner-a');
    support.complete(true);

    expect(await delayed, isFalse);
    await ended;
    expect(calls.map((call) => call.method), ['clear']);
    expect(calls.single.arguments, {
      'schemaVersion': SystemShelfService.schemaVersion,
      'ownerId': 'owner-a',
      'generation': 2,
    });
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
  });

  test('dispatched old sync settles before clear and new owner sync', () async {
    final syncDispatched = Completer<void>();
    final releaseOldSync = Completer<void>();
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'sync' && !syncDispatched.isCompleted) {
        syncDispatched.complete();
        await releaseOldSync.future;
      }
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');
    final oldSync = service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient());
    await syncDispatched.future;

    final oldEnd = service.endProfileSession('owner-a');
    service.beginProfileSession('owner-b');
    final newSync = service.syncFromContinueWatching('owner-b', const [], (_) => _ShelfClient());
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((call) => call.method), ['sync']);

    releaseOldSync.complete();
    expect(await oldSync, isTrue);
    await oldEnd;
    expect(await newSync, isTrue);
    expect(calls.map((call) => call.method), ['sync', 'clear', 'sync']);
    expect((calls.last.arguments as Map)['ownerId'], 'owner-b');
  });

  test('native failure is contained and the ordered tail accepts a later sync', () async {
    var syncCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'sync' && syncCount++ == 0) {
        throw PlatformException(code: 'first-failed');
      }
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');

    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isTrue);
    expect(syncCount, 2);
  });

  test('versioned payload carries transient source only and conversion failure keeps metadata', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    service.beginProfileSession('owner-a');
    final item = testMediaItem(
      id: 'item-a',
      backend: MediaBackend.plex,
      title: 'Private title',
      summary: 'Private summary',
      thumbPath: '/poster',
      serverId: 'server-a',
      serverName: 'Server',
    );

    expect(await service.syncFromContinueWatching('owner-a', [item], (_) => _ShelfClient()), isTrue);
    final envelope = calls.single.arguments as Map;
    expect(envelope['schemaVersion'], SystemShelfService.schemaVersion);
    expect(envelope['ownerId'], 'owner-a');
    final sent = (envelope['items'] as List).single as Map;
    expect(sent['posterSourceUri'], startsWith('https://media.invalid/'));
    expect(sent, isNot(contains('posterUri')));

    calls.clear();
    expect(
      await service.syncFromContinueWatching('owner-a', [item], (_) => _ShelfClient(throwOnThumbnail: true)),
      isTrue,
    );
    final fallback = (((calls.single.arguments as Map)['items'] as List).single as Map);
    expect(fallback['title'], 'Private title');
    expect(fallback['posterSourceUri'], isNull);
  });

  test('unsupported integration completes without native mutation', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => false);
    service.beginProfileSession('owner-a');
    expect(await service.syncFromContinueWatching('owner-a', const [], (_) => _ShelfClient()), isFalse);
    expect(nativeCalls, 0);
  });
}
