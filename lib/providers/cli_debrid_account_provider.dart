import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/cli_debrid/cli_debrid_session.dart';
import '../services/cli_debrid/cli_debrid_client.dart';
import '../services/cli_debrid/cli_debrid_session_store.dart';
import '../utils/app_logger.dart';

/// Owns the active cli_debrid session for the currently-selected profile,
/// mirroring [SeerrAccountProvider]'s rebind shape but without re-auth: the
/// API token is a long-lived credential, so there's no cookie/session-
/// invalidated callback plumbing to wire up.
class CliDebridAccountProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  CliDebridAccountProvider({CliDebridSessionStore? store}) : _store = store ?? const CliDebridSessionStore();

  final CliDebridSessionStore _store;

  /// Store writes go through one queue: save() awaits an AES-GCM protect
  /// step, so two rapid unawaited writes could otherwise persist
  /// last-started-first (mirrors SeerrAccountProvider's same guard).
  Future<void> _pendingPersistence = Future<void>.value();

  Future<void> _enqueuePersistence(Future<void> Function() op) {
    final run = _pendingPersistence.then((_) => op());
    _pendingPersistence = run.then<void>(
      (_) {},
      onError: (Object e) => appLogger.w('cli_debrid: session persistence failed', error: e),
    );
    return run;
  }

  CliDebridSession? _session;
  String _activeUserUuid = '';
  int _bindingGeneration = 0;
  CliDebridClient? _client;

  /// Completes once the first [onActiveProfileChanged] call for this
  /// provider instance has loaded (or failed to load) a session from disk.
  /// [isConnected] is only meaningful once this has completed — before that,
  /// it reads `false` regardless of whether a session is actually stored,
  /// because the async disk read + credential decrypt hasn't finished yet.
  /// Callers that need to distinguish "definitely disconnected" from
  /// "still loading" (e.g. deciding whether to offer a re-request action
  /// right after app launch) should await this first.
  Future<void> get initialLoadComplete => _initialLoadComplete.future;
  final Completer<void> _initialLoadComplete = Completer<void>();

  CliDebridSession? get session => _session;
  bool get isConnected => _session != null;
  String? get displayName => _session?.displayName;

  /// Client for rescrape/request calls; null when disconnected.
  CliDebridClient? get client => _client;

  /// Called whenever the active profile changes (or on initial load).
  Future<void> onActiveProfileChanged(String? newUserUuid) async {
    if (isDisposed) return;
    final userUuid = newUserUuid ?? '';
    final generation = ++_bindingGeneration;
    _activeUserUuid = userUuid;
    try {
      final loaded = await _store.load(userUuid);
      _setSessionAndRebind(userUuid, generation, loaded);
    } finally {
      if (!_initialLoadComplete.isCompleted) _initialLoadComplete.complete();
    }
  }

  /// Persist and bind a session the connect screen established.
  Future<void> adoptSession(CliDebridSession session) async {
    final userUuid = _activeUserUuid;
    await _enqueuePersistence(() => _store.save(userUuid, session));
    _setSessionAndRebind(userUuid, ++_bindingGeneration, session);
  }

  /// Clear the local session. No server-side sign-out call exists for a
  /// static-token connection — this just forgets the token locally.
  Future<void> disconnect() async {
    final userUuid = _activeUserUuid;
    _setSessionAndRebind(userUuid, ++_bindingGeneration, null);
    await _enqueuePersistence(() => _store.clear(userUuid));
  }

  void _setSessionAndRebind(String userUuid, int generation, CliDebridSession? session) {
    if (!_isCurrentBinding(userUuid, generation)) return;
    _session = session;
    _client?.dispose();
    _client = session == null ? null : CliDebridClient(session);
    safeNotifyListeners();
  }

  bool _isCurrentBinding(String userUuid, int generation) {
    return !isDisposed && userUuid == _activeUserUuid && generation == _bindingGeneration;
  }

  @override
  void dispose() {
    _client?.dispose();
    _client = null;
    super.dispose();
  }
}
