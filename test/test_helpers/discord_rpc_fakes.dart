import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';

/// Fake [DiscordRPC] mirroring the lifecycle contract the service depends on:
/// a disposed client rejects re-initialization, so recovery requires a fresh
/// instance. Only the surface the service touches is implemented.
class FakeDiscordRPC implements DiscordRPC {
  final _ready = StreamController<DiscordReadyEvent>.broadcast(sync: true);
  final _disconnected = StreamController<DiscordDisconnectedEvent>.broadcast(sync: true);
  final _errors = StreamController<DiscordErrorEvent>.broadcast(sync: true);

  int initializeCalls = 0;
  int disposeCalls = 0;
  int clearPresenceCalls = 0;
  final List<DiscordPresence> presences = [];
  bool _disposed = false;

  /// When set, [initialize] awaits this after recording the call, so tests
  /// can fail (or complete) an in-flight initialize on demand.
  Completer<void>? initializeGate;

  @override
  Stream<DiscordReadyEvent> get onReady => _ready.stream;

  @override
  Stream<DiscordDisconnectedEvent> get onDisconnected => _disconnected.stream;

  @override
  Stream<DiscordErrorEvent> get onError => _errors.stream;

  @override
  Future<void> initialize(String applicationId) async {
    if (_disposed) throw StateError('Cannot initialize a disposed DiscordRPC');
    if (initializeCalls > 0) throw StateError('Already initialized');
    initializeCalls++;
    final gate = initializeGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    disposeCalls++;
    await _ready.close();
    await _disconnected.close();
    await _errors.close();
  }

  @override
  Future<void> clearPresence() async {
    clearPresenceCalls++;
  }

  @override
  Future<void> setPresence(DiscordPresence presence) async {
    presences.add(presence);
  }

  void emitReady() {
    _ready.add(
      const DiscordReadyEvent(
        user: DiscordUser(userId: '1', username: 'tester'),
      ),
    );
  }

  void emitDisconnected() {
    _disconnected.add(const DiscordDisconnectedEvent(errorCode: 1006, message: 'connection lost'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
