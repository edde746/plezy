import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/services/system_shelf_background.dart';
import 'package:plezy/services/system_shelf_service.dart';

import '../test_helpers/media_items.dart';

class _BackgroundClient implements MediaServerClient {
  @override
  ServerId get serverId => ServerId('server-a');

  @override
  String get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) =>
      'https://media.invalid$path?token=transient';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/system_shelf_background');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('no active profile completes false without opening a session or touching the shelf', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    final reported = <bool>[];
    var opened = false;

    final result = await runSystemShelfBackgroundSync(
      readActiveProfileId: () async => null,
      openSession: (_) async {
        opened = true;
        return null;
      },
      reportCompletion: (success) async => reported.add(success),
      shelfService: service,
    );

    expect(result, isFalse);
    expect(reported, [false]);
    expect(opened, isFalse);
    expect(nativeCalls, 0);
    expect(service.debugActiveOwner, isNull);
  });

  test('an unopenable session (offline / no connections / failed bind) completes false without shelf calls', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    final reported = <bool>[];

    final result = await runSystemShelfBackgroundSync(
      readActiveProfileId: () async => 'profile-1',
      openSession: (_) async => null,
      reportCompletion: (success) async => reported.add(success),
      shelfService: service,
    );

    expect(result, isFalse);
    expect(reported, [false]);
    expect(nativeCalls, 0);
    expect(service.debugActiveOwner, isNull);
  });

  test('happy path begins the owner session and syncs only client-backed items', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    final client = _BackgroundClient();
    final reported = <bool>[];
    var disposed = false;
    final item = testMediaItem(id: 'movie-1', serverId: 'server-a', title: 'Movie');
    // No owning client — must be filtered out, mirroring DiscoverProvider.
    final orphan = testMediaItem(id: 'movie-2', serverId: 'server-gone', title: 'Orphan');

    final result = await runSystemShelfBackgroundSync(
      readActiveProfileId: () async => 'profile-1',
      openSession: (profileId) async {
        expect(profileId, 'profile-1');
        return SystemShelfBackgroundSession(
          profileId: 'profile-1',
          fetchContinueWatching: () async => [item, orphan],
          clientForServer: (serverId) => serverId == 'server-a' ? client : null,
          hideSpoilers: false,
          dispose: () async {
            disposed = true;
          },
        );
      },
      reportCompletion: (success) async => reported.add(success),
      shelfService: service,
    );

    expect(result, isTrue);
    expect(reported, [true]);
    expect(disposed, isTrue);
    expect(service.debugActiveOwner, 'profile-1');
    final sync = calls.singleWhere((call) => call.method == 'sync');
    final envelope = sync.arguments as Map;
    expect(envelope['ownerId'], 'profile-1');
    final items = envelope['items'] as List;
    expect(items, hasLength(1));
    expect((items.single as Map)['contentId'], 'plezy_server-a_movie-1');
  });

  test('a failure inside the fetch completes false and still disposes the session', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeCalls++;
      return true;
    });
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    final reported = <bool>[];
    var disposed = false;

    final result = await runSystemShelfBackgroundSync(
      readActiveProfileId: () async => 'profile-1',
      openSession: (_) async => SystemShelfBackgroundSession(
        profileId: 'profile-1',
        fetchContinueWatching: () async => throw StateError('server exploded'),
        clientForServer: (_) => null,
        hideSpoilers: false,
        dispose: () async {
          disposed = true;
        },
      ),
      reportCompletion: (success) async => reported.add(success),
      shelfService: service,
    );

    expect(result, isFalse);
    expect(reported, [false]);
    expect(disposed, isTrue);
    expect(nativeCalls, 0);
  });

  test('completion is still reported when session teardown itself throws', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);
    final service = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
    final reported = <bool>[];

    final result = await runSystemShelfBackgroundSync(
      readActiveProfileId: () async => 'profile-1',
      openSession: (_) async => SystemShelfBackgroundSession(
        profileId: 'profile-1',
        fetchContinueWatching: () async => [],
        clientForServer: (_) => null,
        hideSpoilers: false,
        dispose: () async => throw StateError('teardown failed'),
      ),
      reportCompletion: (success) async => reported.add(success),
      shelfService: service,
    );

    expect(result, isTrue);
    expect(reported, [true]);
  });
}
