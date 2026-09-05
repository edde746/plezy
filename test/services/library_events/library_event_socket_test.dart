import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/services/library_events/media_browser_library_event_socket.dart';
import 'package:plezy/services/library_events/plex_library_event_socket.dart';

/// Ephemeral loopback websocket server standing in for a media server's
/// notification endpoint. Real protocol boundary, torn down unconditionally.
class _NotificationServer {
  _NotificationServer._(this._server);

  final HttpServer _server;
  final List<WebSocket> sockets = [];
  final List<Uri> requestUris = [];
  final List<Map<String, dynamic>> received = [];
  final _connections = StreamController<WebSocket>.broadcast();

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_NotificationServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final notification = _NotificationServer._(server);
    server.listen((request) async {
      notification.requestUris.add(request.uri);
      final socket = await WebSocketTransformer.upgrade(request);
      notification.sockets.add(socket);
      socket.listen((data) {
        notification.received.add((jsonDecode(data as String) as Map).cast<String, dynamic>());
      });
      notification._connections.add(socket);
    });
    return notification;
  }

  /// The next socket to connect (or an already-connected one).
  Future<WebSocket> nextConnection() async {
    if (sockets.isNotEmpty) return sockets.last;
    return _connections.stream.first;
  }

  void send(WebSocket socket, Map<String, dynamic> message) => socket.add(jsonEncode(message));

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await _server.close(force: true);
    await _connections.close();
  }
}

/// Frames captured live from Plex 1.43 during one library scan (2026-08-31).
Map<String, dynamic> _plexTimeline(List<Map<String, dynamic>> entries) => {
  'NotificationContainer': {'type': 'timeline', 'size': entries.length, 'TimelineEntry': entries},
};

Map<String, dynamic> _plexTimelineEntry({
  required int state,
  int type = 1,
  String sectionId = '1',
  String? metadataState,
}) => {
  'identifier': 'com.plexapp.plugins.library',
  'sectionID': sectionId,
  'itemID': '10141',
  'type': type,
  'title': 'Prefix Test (2024)',
  'state': state,
  'metadataState': ?metadataState,
  'updatedAt': 1788180088,
};

const _plexPlayingFrame = {
  'NotificationContainer': {
    'type': 'playing',
    'size': 1,
    'PlaySessionStateNotification': [
      {'sessionKey': '3', 'ratingKey': '9940', 'key': '/library/metadata/9940', 'state': 'paused'},
    ],
  },
};

/// LibraryChanged as captured from Jellyfin 10.11 / Emby 4.9.5.
const _libraryChangedFrame = {
  'MessageType': 'LibraryChanged',
  'Data': {
    'FoldersAddedTo': ['ba9c5cad4ccd875366bf54fd50e04928'],
    'FoldersRemovedFrom': <String>[],
    'ItemsAdded': ['6f91bbba468dfbb00984986c4e5d0a74'],
    'ItemsRemoved': <String>[],
    'ItemsUpdated': <String>[],
    'CollectionFolders': ['f137a2dd21bbc1b99aa5c0f6bf02a805', '1071671e7bffa0532e930debee501d2e'],
    'IsEmpty': false,
  },
};

void main() {
  final servers = <_NotificationServer>[];
  final channels = <LibraryEventChannel>[];

  Future<_NotificationServer> startServer() async {
    final server = await _NotificationServer.start();
    servers.add(server);
    return server;
  }

  T track<T extends LibraryEventChannel>(T channel) {
    channels.add(channel);
    return channel;
  }

  tearDown(() async {
    for (final channel in channels) {
      channel.dispose();
    }
    channels.clear();
    for (final server in servers) {
      await server.close();
    }
    servers.clear();
  });

  PlexLibraryEventSocket plexSocket(
    _NotificationServer server, {
    Duration debounce = const Duration(milliseconds: 100),
  }) => track(
    PlexLibraryEventSocket(
      serverId: ServerId('plex_1'),
      baseUrl: () => server.baseUrl,
      token: () => 'token-1',
      debounce: debounce,
      retryBaseDelay: const Duration(milliseconds: 50),
    ),
  );

  MediaBrowserLibraryEventSocket mediaBrowserSocket(
    _NotificationServer server, {
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
    Future<void> Function()? registerCapabilities,
  }) => track(
    MediaBrowserLibraryEventSocket(
      serverId: ServerId('mb_1'),
      dialect: dialect,
      baseUrl: () => server.baseUrl,
      accessToken: 'access-1',
      deviceId: 'device-1',
      registerCapabilities: registerCapabilities,
      debounce: const Duration(milliseconds: 100),
      retryBaseDelay: const Duration(milliseconds: 50),
    ),
  );

  test('websocket URIs preserve a reverse-proxy path prefix', () {
    final plex = track(
      PlexLibraryEventSocket(
        serverId: ServerId('plex_1'),
        baseUrl: () => 'https://proxy.example/plex',
        token: () => 'token-1',
        debounce: Duration.zero,
      ),
    );
    expect(plex.buildUri().path, '/plex/:/websockets/notifications');
    expect(plex.buildUri().scheme, 'wss');

    final mb = track(
      MediaBrowserLibraryEventSocket(
        serverId: ServerId('mb_1'),
        dialect: MediaBrowserDialect.jellyfin,
        baseUrl: () => 'https://proxy.example/jellyfin',
        accessToken: 'access-1',
        deviceId: 'device-1',
      ),
    );
    expect(mb.buildUri().path, '/jellyfin/socket');
  });

  group('PlexLibraryEventSocket', () {
    test('first settled entry emits immediately; the rest of the flood coalesces', () async {
      final server = await startServer();
      final channel = plexSocket(server);
      final events = <LibraryChangeEvent>[];
      channel.events.listen(events.add);
      channel.start();
      final socket = await server.nextConnection();

      expect(server.requestUris.single.path, '/:/websockets/notifications');
      expect(server.requestUris.single.queryParameters['X-Plex-Token'], 'token-1');

      // The measured state walk for one new item, plus unrelated session
      // noise: only the settled state-5 entries may schedule the event.
      server.send(socket, _plexPlayingFrame);
      for (final state in [0, 1, 2, 3, 4]) {
        server.send(socket, _plexTimeline([_plexTimelineEntry(state: state, metadataState: 'created')]));
      }
      server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5)]));
      server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5)]));
      server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5, sectionId: '2')]));

      // Leading edge (Plex Web parity): the first settled entry surfaces
      // without waiting out the debounce.
      final first = await channel.events.first.timeout(const Duration(milliseconds: 500));
      expect(first.serverId, 'plex_1');
      expect(first.libraryIds, {'1'});
      expect(first.itemsAdded, isTrue);
      expect(first.itemsUpdated, isTrue);
      expect(first.itemsRemoved, isFalse);

      // The remaining settled entries merge into exactly one trailing event.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(events, hasLength(2));
      expect(events[1].libraryIds, {'1', '2'});
    });

    test('a sustained stream emits once per window instead of starving', () async {
      final server = await startServer();
      final channel = plexSocket(server, debounce: const Duration(milliseconds: 150));
      final events = <LibraryChangeEvent>[];
      channel.events.listen(events.add);
      channel.start();
      final socket = await server.nextConnection();

      // Frames every 80 ms for ~1.2 s. A trailing-reset debounce would emit
      // nothing until the stream stops; the min-interval throttle emits a
      // leading event plus one per elapsed window.
      for (var i = 0; i < 15; i++) {
        server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5)]));
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }

      expect(events.length, greaterThanOrEqualTo(2), reason: 'must not starve while frames keep arriving');
      expect(events.length, lessThanOrEqualTo(10), reason: 'at most one event per 150 ms window, not per frame');
    });

    test('settled deletion entry reports itemsRemoved', () async {
      final server = await startServer();
      final channel = plexSocket(server);
      channel.start();
      final socket = await server.nextConnection();

      server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5, type: -1)]));

      final event = await channel.events.first.timeout(const Duration(seconds: 5));
      expect(event.itemsRemoved, isTrue);
      expect(event.itemsAdded, isFalse);
      expect(event.removedItemIds, {'10141'}, reason: 'deletion ids ride along for in-place drops');
    });

    test('a malformed frame does not kill the channel', () async {
      final server = await startServer();
      final channel = plexSocket(server);
      channel.start();
      final socket = await server.nextConnection();

      socket.add('this is not json');
      socket.add('[1,2,3]');
      server.send(socket, _plexTimeline([_plexTimelineEntry(state: 5)]));

      final event = await channel.events.first.timeout(const Duration(seconds: 5));
      expect(event.itemsAdded, isTrue);
    });

    test('reconnects after the server drops the connection', () async {
      final server = await startServer();
      final channel = plexSocket(server);
      channel.start();
      final first = await server.nextConnection();

      await first.close();
      // Backoff is 50ms; the second connection must arrive on its own.
      await _waitFor(() => server.sockets.length >= 2);

      server.send(server.sockets[1], _plexTimeline([_plexTimelineEntry(state: 5)]));
      final event = await channel.events.first.timeout(const Duration(seconds: 5));
      expect(event.itemsAdded, isTrue);
    });

    test('stop() prevents reconnecting', () async {
      final server = await startServer();
      final channel = plexSocket(server);
      channel.start();
      await server.nextConnection();

      channel.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(server.sockets, hasLength(1), reason: 'no reconnect after stop');
      expect(channel.isRunning, isFalse);
    });
  });

  group('MediaBrowserLibraryEventSocket', () {
    test('connects to the dialect path and answers ForceKeepAlive', () async {
      final server = await startServer();
      final channel = mediaBrowserSocket(server);
      channel.start();
      final socket = await server.nextConnection();

      expect(server.requestUris.single.path, '/socket');
      expect(server.requestUris.single.queryParameters, containsPair('ApiKey', 'access-1'));
      expect(server.requestUris.single.queryParameters.containsKey('api_key'), isFalse);
      expect(server.requestUris.single.queryParameters, containsPair('deviceId', 'device-1'));

      server.send(socket, {'MessageId': 'x', 'Data': 60, 'MessageType': 'ForceKeepAlive'});
      await _waitFor(() => server.received.any((m) => m['MessageType'] == 'KeepAlive'));
    });

    test('maps LibraryChanged to a coalesced event', () async {
      final server = await startServer();
      final channel = mediaBrowserSocket(server);
      channel.start();
      final socket = await server.nextConnection();

      server.send(socket, _libraryChangedFrame);

      final event = await channel.events.first.timeout(const Duration(seconds: 5));
      expect(event.serverId, 'mb_1');
      expect(event.itemsAdded, isTrue);
      expect(event.itemsRemoved, isFalse);
      expect(event.itemsUpdated, isFalse);
      expect(event.libraryIds, {'f137a2dd21bbc1b99aa5c0f6bf02a805', '1071671e7bffa0532e930debee501d2e'});
    });

    test('LibraryChanged removals carry the removed item ids', () async {
      final server = await startServer();
      final channel = mediaBrowserSocket(server);
      channel.start();
      final socket = await server.nextConnection();

      server.send(socket, {
        'MessageType': 'LibraryChanged',
        'Data': {
          'FoldersAddedTo': <String>[],
          'FoldersRemovedFrom': <String>[],
          'ItemsAdded': <String>[],
          'ItemsRemoved': ['b44f297fb12dbc4dad50bb49f8475520', '6f91bbba468dfbb00984986c4e5d0a74'],
          'ItemsUpdated': <String>[],
          'CollectionFolders': ['f137a2dd21bbc1b99aa5c0f6bf02a805'],
          'IsEmpty': false,
        },
      });

      final event = await channel.events.first.timeout(const Duration(seconds: 5));
      expect(event.itemsRemoved, isTrue);
      expect(event.removedItemIds, {'b44f297fb12dbc4dad50bb49f8475520', '6f91bbba468dfbb00984986c4e5d0a74'});
    });

    test('an empty LibraryChanged emits nothing', () async {
      final server = await startServer();
      final channel = mediaBrowserSocket(server);
      final events = <LibraryChangeEvent>[];
      channel.events.listen(events.add);
      channel.start();
      final socket = await server.nextConnection();

      server.send(socket, {
        'MessageType': 'LibraryChanged',
        'Data': {
          'FoldersAddedTo': <String>[],
          'FoldersRemovedFrom': <String>[],
          'ItemsAdded': <String>[],
          'ItemsRemoved': <String>[],
          'ItemsUpdated': <String>[],
          'CollectionFolders': <String>[],
          'IsEmpty': true,
        },
      });

      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(events, isEmpty);
    });

    test('Emby registers capabilities before every connect; Jellyfin never does', () async {
      final server = await startServer();
      var registrations = 0;
      final emby = mediaBrowserSocket(
        server,
        dialect: MediaBrowserDialect.emby,
        registerCapabilities: () async => registrations++,
      );
      emby.start();
      final first = await server.nextConnection();
      expect(registrations, 1);
      expect(server.requestUris.single.path, '/embywebsocket');
      expect(server.requestUris.single.queryParameters, containsPair('api_key', 'access-1'));
      expect(server.requestUris.single.queryParameters.containsKey('ApiKey'), isFalse);

      // A drop re-registers on the reconnect attempt.
      await first.close();
      await _waitFor(() => registrations >= 2);
      emby.dispose();

      final jellyfinServer = await startServer();
      var jellyfinRegistrations = 0;
      final jellyfin = mediaBrowserSocket(jellyfinServer, registerCapabilities: () async => jellyfinRegistrations++);
      jellyfin.start();
      await jellyfinServer.nextConnection();
      expect(jellyfinRegistrations, 0);
    });

    test('a failing capabilities registration retries and then connects', () async {
      final server = await startServer();
      var registrations = 0;
      final channel = mediaBrowserSocket(
        server,
        dialect: MediaBrowserDialect.emby,
        registerCapabilities: () async {
          registrations++;
          if (registrations == 1) throw Exception('server busy');
        },
      );
      channel.start();
      await server.nextConnection();
      expect(registrations, 2, reason: 'first attempt failed, retry connected');
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not reached within 5s');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
