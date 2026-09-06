import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/services/library_events/library_event_service.dart';
import 'package:plezy/services/library_events/library_event_socket.dart';
import 'package:plezy/services/library_events/plex_library_event_socket.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/library_content_notifier.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeChannel implements LibraryEventChannel {
  final _controller = StreamController<LibraryChangeEvent>.broadcast();
  int starts = 0;
  int stops = 0;
  bool disposed = false;

  @override
  Stream<LibraryChangeEvent> get events => _controller.stream;

  @override
  void start() => starts++;

  @override
  void stop() => stops++;

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }

  void emit(LibraryChangeEvent event) => _controller.add(event);
}

class _FakeClient implements MediaServerClient {
  _FakeClient(this.serverIdValue, {this.supportsEvents = true});

  final String serverIdValue;
  final bool supportsEvents;
  final List<_FakeChannel> channels = [];

  @override
  final Object authenticationSessionId = Object();

  @override
  ServerId get serverId => ServerId(serverIdValue);

  @override
  String? get serverName => serverIdValue;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities =>
      supportsEvents ? ServerCapabilities.plex : const ServerCapabilities(libraryChangeEvents: false);

  @override
  LibraryEventChannel? createLibraryEventChannel() {
    final channel = _FakeChannel();
    channels.add(channel);
    return channel;
  }

  /// Reached by `MultiServerManager.dispose()` during teardown.
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MultiServerManager manager;
  late LibraryEventService service;

  setUp(() {
    manager = MultiServerManager();
  });

  tearDown(() {
    service.dispose();
    manager.dispose();
  });

  test('starts one channel per online server and forwards its events', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);

    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    expect(client.channels, hasLength(1));
    expect(client.channels.single.starts, 1);
    expect(service.activeServerIds, {'server_1'});

    final received = <LibraryChangeEvent>[];
    final subscription = LibraryContentNotifier().stream.listen(received.add);
    addTearDown(subscription.cancel);
    client.channels.single.emit(LibraryChangeEvent(serverId: ServerId('server_1'), itemsAdded: true));
    await pumpEventQueue();

    expect(received, hasLength(1));
    expect(received.single.serverId, 'server_1');
  });

  for (final foregroundResume in [false, true]) {
    test(
      '${foregroundResume ? 'foreground resume without suspension' : 'a status emission'} recovers exhausted push',
      () {
        fakeAsync((async) {
          final transport = _PushTransport();
          var available = false;
          var connections = 0;
          final channel = PlexLibraryEventSocket(
            serverId: ServerId('server_1'),
            baseUrl: () => 'http://server.invalid',
            token: () => 'token',
            debounce: Duration.zero,
            retryBaseDelay: const Duration(seconds: 5),
            maxConnectAttempts: 2,
            channelFactory: (_) {
              connections++;
              return (
                channel: available
                    ? Future<WebSocketChannel>.value(transport)
                    : Future<WebSocketChannel>.error(const SocketException('push unavailable')),
                cancel: () {},
              );
            },
          );
          manager.debugRegisterClientForTesting(_SocketClient(channel));
          service = LibraryEventService(manager);
          final received = <LibraryChangeEvent>[];
          final subscription = LibraryContentNotifier().stream.listen(received.add);
          service.sync();
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 15));
          expect(channel.isRunning, isFalse);
          expect(connections, 3);
          async.elapse(const Duration(minutes: 5));
          expect(connections, 3, reason: 'the retry budget really is exhausted');

          available = true;
          if (foregroundResume) {
            // Desktop foreground does not require suspend or an HTTP status
            // transition: the manager still considers this server online.
            service.resume();
          } else {
            manager.debugEmitStatusForTesting();
          }
          async.flushMicrotasks();
          transport.addChange('recovered');
          async.flushMicrotasks();
          expect(received.single.libraryIds, {'recovered'});

          service.resume();
          service.resume();
          async.flushMicrotasks();
          transport.addChange('still-live');
          async.flushMicrotasks();
          expect(received.last.libraryIds, {'still-live'});
          expect(connections, 4, reason: 'foreground must not restart an active transport');
          service.dispose();
          unawaited(transport.close());
          unawaited(subscription.cancel());
          async.flushMicrotasks();
        });
      },
    );
  }

  test('foreground resume preserves an in-progress reconnect backoff', () {
    fakeAsync((async) {
      final transport = _PushTransport();
      var connections = 0;
      final channel = PlexLibraryEventSocket(
        serverId: ServerId('server_1'),
        baseUrl: () => 'http://server.invalid',
        token: () => 'token',
        debounce: Duration.zero,
        retryBaseDelay: const Duration(seconds: 5),
        channelFactory: (_) => (
          channel: ++connections == 1
              ? Future<WebSocketChannel>.error(const SocketException('push unavailable'))
              : Future<WebSocketChannel>.value(transport),
          cancel: () {},
        ),
      );
      manager.debugRegisterClientForTesting(_SocketClient(channel));
      service = LibraryEventService(manager);
      final received = <LibraryChangeEvent>[];
      final subscription = LibraryContentNotifier().stream.listen(received.add);
      service.sync();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));

      service.resume();
      async.flushMicrotasks();
      expect(connections, 1, reason: 'resume must not bypass the existing backoff');
      async.elapse(const Duration(seconds: 3));
      transport.addChange('retry');
      async.flushMicrotasks();

      expect(received.single.libraryIds, {'retry'});
      expect(connections, 2, reason: 'resume must not postpone the existing retry either');
      service.dispose();
      unawaited(transport.close());
      unawaited(subscription.cancel());
      async.flushMicrotasks();
    });
  });

  test('removed item ids fan out as in-place deletion events', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    final deletions = <DeletionEvent>[];
    final subscription = DeletionNotifier().stream.listen(deletions.add);
    addTearDown(subscription.cancel);
    final forwarded = <LibraryChangeEvent>[];
    final contentSubscription = LibraryContentNotifier().stream.listen(forwarded.add);
    addTearDown(contentSubscription.cancel);

    client.channels.single.emit(
      LibraryChangeEvent(serverId: ServerId('server_1'), itemsRemoved: true, removedItemIds: const {'m1', 'm2'}),
    );
    await pumpEventQueue();

    expect(deletions.map((e) => e.itemId).toSet(), {'m1', 'm2'});
    expect(deletions.every((e) => e.serverId == 'server_1'), isTrue);
    expect(deletions.every((e) => !e.isDownloadOnly), isTrue, reason: 'a server removal is not a download deletion');
    expect(deletions.every((e) => e.origin == DeletionOrigin.serverPush), isTrue);
    expect(forwarded, hasLength(1), reason: 'the coarse event still reaches the notifier');
  });

  test('bulk removals skip per-item deletion events and rely on the refetch', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    final deletions = <DeletionEvent>[];
    final subscription = DeletionNotifier().stream.listen(deletions.add);
    addTearDown(subscription.cancel);
    final forwarded = <LibraryChangeEvent>[];
    final contentSubscription = LibraryContentNotifier().stream.listen(forwarded.add);
    addTearDown(contentSubscription.cancel);

    client.channels.single.emit(
      LibraryChangeEvent(
        serverId: ServerId('server_1'),
        itemsRemoved: true,
        removedItemIds: {for (var i = 0; i < 30; i++) 'bulk-$i'},
      ),
    );
    await pumpEventQueue();

    expect(deletions, isEmpty, reason: 'past the cap the coarse refetch owns the update');
    expect(forwarded, hasLength(1));
  });

  test('skips servers without the capability or without a channel', () async {
    final incapable = _FakeClient('server_nocap', supportsEvents: false);
    manager.debugRegisterClientForTesting(incapable);
    service = LibraryEventService(manager);

    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    expect(incapable.channels, isEmpty);
    expect(service.activeServerIds, isEmpty);
  });

  test('an offline transition disposes the channel; back online recreates it', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();
    expect(client.channels, hasLength(1));

    manager.debugMarkAuthErrorForTesting(ServerId('server_1'));
    await pumpEventQueue();
    expect(client.channels.single.disposed, isTrue);
    expect(service.activeServerIds, isEmpty);

    manager.debugRegisterClientForTesting(client);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();
    expect(client.channels, hasLength(2));
    expect(client.channels.last.starts, 1);
  });

  test('a replaced client tears down the old channel and starts a fresh one', () async {
    final original = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(original);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    final replacement = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(replacement);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    expect(original.channels.single.disposed, isTrue);
    expect(replacement.channels, hasLength(1));
    expect(replacement.channels.single.starts, 1);
  });

  test('suspend stops channels; resume rebuilds them', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    service.suspend();
    expect(client.channels.single.disposed, isTrue);
    expect(service.activeServerIds, isEmpty);

    // Status emissions while suspended must not resurrect channels.
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();
    expect(client.channels, hasLength(1));

    service.resume();
    expect(client.channels, hasLength(2));
    expect(client.channels.last.starts, 1);
  });

  test('dispose tears everything down and ignores later status emissions', () async {
    final client = _FakeClient('server_1');
    manager.debugRegisterClientForTesting(client);
    service = LibraryEventService(manager);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();

    service.dispose();
    expect(client.channels.single.disposed, isTrue);

    manager.debugEmitStatusForTesting();
    service.resume();
    await pumpEventQueue();
    expect(client.channels, hasLength(1));
  });
}

class _SocketClient extends _FakeClient {
  _SocketClient(this.channel) : super('server_1');

  final LibraryEventSocket channel;

  @override
  LibraryEventChannel createLibraryEventChannel() => channel;
}

class _PushTransport implements WebSocketChannel, WebSocketSink {
  final _frames = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _frames.stream;

  @override
  WebSocketSink get sink => this;

  void addChange(String libraryId) {
    _frames.add(
      jsonEncode({
        'NotificationContainer': {
          'type': 'timeline',
          'TimelineEntry': [
            {'identifier': 'com.plexapp.plugins.library', 'sectionID': libraryId, 'state': 5, 'type': 1},
          ],
        },
      }),
    );
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) => _frames.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
