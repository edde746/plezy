import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/plex/plex_home_user.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'plex_home_service.dart';
import 'profile.dart';
import 'profile_merge.dart';
import 'profile_registry.dart';

/// Holds the currently active [Profile] and a merged list of all available
/// profiles — local rows from [ProfileRegistry] plus virtual Plex Home
/// profiles built from [PlexHomeService]'s live cache.
///
/// The active id (in storage) can reference either a local row or a Plex
/// Home virtual id like `plex-home-{connId}-{uuid}`. Resolution checks
/// local profiles first, then live home users; if neither matches we fall
/// back to the first profile in the merged list.
class ActiveProfileProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  ActiveProfileProvider({
    required this._registry,
    required this._plexHome,
    required this._connections,
    this._storage,
    this._activeProfileIdWriter,
  });

  final ProfileRegistry _registry;
  final PlexHomeService _plexHome;
  final ConnectionRegistry _connections;
  StorageService? _storage;
  final Future<void> Function(String profileId)? _activeProfileIdWriter;

  Profile? _active;
  List<Profile> _profiles = const [];
  List<Profile> _localProfiles = const [];
  Map<String, List<PlexHomeUser>> _plexHomeUsers = const {};
  Map<String, Connection> _connectionsById = const {};

  StreamSubscription<List<Profile>>? _localSub;
  StreamSubscription<List<Connection>>? _connSub;
  StreamSubscription<Map<String, List<PlexHomeUser>>>? _plexHomeSub;
  Future<void>? _initializeFuture;
  bool _initialized = false;

  bool _isBinding = false;
  bool _lastBindingSucceeded = true;
  final List<Completer<bool>> _bindingSettleWaiters = [];
  Future<void>? _identityMutationQueue;
  int _identityMutationGeneration = 0;
  int _committedIdentityGeneration = 0;
  int _pendingIdentityMutations = 0;
  final Map<int, Completer<void>> _identityMutationReservations = {};

  Profile? get active => _active;
  String? get activeId => _active?.id;
  List<Profile> get profiles => _profiles;
  bool get hasMultipleProfiles => _profiles.length > 1;
  bool get isInitialized => _initialized;

  /// Monotonically identifies the last active-profile identity that
  /// successfully committed. Failed and cancelled activation attempts do not
  /// advance it.
  int get committedIdentityGeneration => _committedIdentityGeneration;

  int get identityMutationGeneration => _identityMutationGeneration;

  /// True while [ActiveProfileBinder] is wiring servers/tokens for the
  /// active profile. The picker reads this so it can stay open (and stay
  /// behind any PIN dialog the binder pops) until binding settles.
  bool get isBinding => _isBinding;

  /// Outcome of the most recent settled bind. False after a PIN cancel,
  /// failed `/home/users/{uuid}/switch`, or any error inside the binder.
  bool get lastBindingSucceeded => _lastBindingSucceeded;

  /// Called by [ActiveProfileBinder] at the start of a rebind cycle.
  /// Re-entrant — no-ops if already in [isBinding].
  void markBindingStarted() {
    if (_isBinding) return;
    _isBinding = true;
    _lastBindingSucceeded = true;
    safeNotifyListeners();
  }

  /// Called by [ActiveProfileBinder] when the rebind settles. [success]
  /// means the active profile was applied successfully. A local profile with
  /// no connections is successful and intentionally exposes no servers; false
  /// covers the "user cancelled the PIN" path and real binding errors.
  void markBindingFinished({required bool success}) {
    if (!_isBinding && _lastBindingSucceeded == success) return;
    _isBinding = false;
    _lastBindingSucceeded = success;
    safeNotifyListeners();
  }

  /// Resolves once the binder reports done. Returns immediately when no
  /// rebind is in flight. The boolean reflects [lastBindingSucceeded] at
  /// the moment binding settles, so the picker can decide whether to
  /// dismiss or surface an error.
  ///
  /// Pending completers are tracked so [dispose] can settle them — without
  /// that, awaiters (picker, user-profile refresh, post-bind hooks) hang
  /// indefinitely when the provider is torn down mid-rebind.
  Future<bool> awaitBindingSettle() {
    if (!_isBinding) return Future.value(_lastBindingSucceeded);
    final completer = Completer<bool>();
    _bindingSettleWaiters.add(completer);
    void listener() {
      if (_isBinding) return;
      removeListener(listener);
      if (_bindingSettleWaiters.remove(completer) && !completer.isCompleted) {
        completer.complete(_lastBindingSucceeded);
      }
    }

    addListener(listener);
    return completer.future;
  }

  Future<void> initialize() {
    if (_initialized) return Future.value();
    final pending = _initializeFuture;
    if (pending != null) return pending;

    final future = _initialize().catchError((Object error, StackTrace stackTrace) {
      _initializeFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _initializeFuture = future;
    return future;
  }

  /// Re-read connections, Plex Home cache, local profiles, and active id.
  ///
  /// Provider initialization starts before boot-time migration, so the first
  /// snapshot can legitimately miss the migrated connection/profile state.
  Future<void> reloadFromStorage() async {
    await initialize();
    await _plexHome.reloadFromStorage();
    await _reloadSnapshot();
    safeNotifyListeners();
  }

  Future<void> _initialize() async {
    await _reloadSnapshot();

    // Every listener diffs its snapshot first: drift re-emits on any table
    // write (including no-op upserts like the binder's server refresh), and
    // each unchecked pass rebuilds every Profile and notifies the whole
    // listener tree (binder, MainScreen, pickers).
    _localSub = _registry.watchProfiles().listen((list) {
      if (listEquals(list, _localProfiles)) return;
      _localProfiles = list;
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });
    _connSub = _connections.watchConnections().listen((list) {
      final byId = {for (final c in list) c.id: c};
      if (_sameConnections(byId, _connectionsById)) return;
      _connectionsById = byId;
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });
    _plexHomeSub = _plexHome.stream.listen((cache) {
      if (_samePlexHomeUsers(cache, _plexHomeUsers)) return;
      _plexHomeUsers = cache;
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });

    _initialized = true;
    safeNotifyListeners();
  }

  Future<void> _reloadSnapshot() async {
    _storage ??= await StorageService.getInstance();
    // Hydrate the Plex Home cache before we read it — `_plexHome.current`
    // is only populated after start() finishes its disk-cache load.
    await _plexHome.start();

    _localProfiles = await _registry.list();
    final initialConns = await _connections.list();
    _connectionsById = {for (final c in initialConns) c.id: c};
    _plexHomeUsers = _plexHome.current;
    _recomputeProfiles();
    _resolveActive();
  }

  /// [Connection] has no value equality; its persisted config is the
  /// cheapest faithful comparison key for the handful of rows involved.
  static bool _sameConnections(Map<String, Connection> a, Map<String, Connection> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if (identical(entry.value, other)) continue;
      if (jsonEncode(entry.value.toConfigJson()) != jsonEncode(other.toConfigJson())) return false;
    }
    return true;
  }

  static bool _samePlexHomeUsers(Map<String, List<PlexHomeUser>> a, Map<String, List<PlexHomeUser>> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || !listEquals(entry.value, other)) return false;
    }
    return true;
  }

  void _recomputeProfiles() {
    _profiles = mergeLocalWithPlexHome(
      locals: _localProfiles,
      plexHomeByConnectionId: _plexHomeUsers,
      connectionsById: _connectionsById,
      storage: _storage,
    );
  }

  void _resolveActive() {
    if (_pendingIdentityMutations > 0) return;
    if (_profiles.isEmpty) {
      _active = null;
      return;
    }
    final id = _storage?.getActiveProfileId();
    // No saved id means "fresh state" — leave the active profile null so
    // MainScreen prompts the user via the picker. Auto-falling back to
    // `_profiles.first` would let the binder bind (and possibly PIN-prompt)
    // a profile the user never picked.
    if (id == null) {
      _active = null;
      return;
    }
    for (final p in _profiles) {
      if (p.id == id) {
        _active = p;
        return;
      }
    }
    // Saved id no longer matches anything. Keep the persisted id: this
    // resolver runs on every stream emission, and early/partial snapshots
    // (boot before migration, a Plex Home cache that hasn't hydrated yet)
    // must not irreversibly wipe the user's selection. Genuinely
    // unresolvable states clear the id at their decision points — the boot
    // guard and the post-removal settle flow.
    _active = null;
  }

  /// Claims ownership for an identity change that must perform asynchronous
  /// preparation before it can enter the serialized mutation queue.
  ///
  /// The claim is synchronous so a newer user request can invalidate older
  /// preparation immediately. Callers must always pair this with
  /// [finishIdentityMutationRequest].
  int beginIdentityMutationRequest() {
    final generation = ++_identityMutationGeneration;
    _identityMutationReservations[generation] = Completer<void>();
    return generation;
  }

  bool isIdentityMutationRequestCurrent(int generation) => generation == _identityMutationGeneration;

  void finishIdentityMutationRequest(int generation) {
    final reservation = _identityMutationReservations.remove(generation);
    if (reservation != null && !reservation.isCompleted) reservation.complete();
  }

  /// Activate [profile]. PIN-protected local profiles must supply a matching
  /// PIN; for Plex Home profiles the binder enforces the PIN via
  /// `/home/users/{uuid}/switch` after activation.
  Future<bool> activate(Profile profile, {String? pin}) async {
    if (profile.isLocal && profile.isPinProtected) {
      final hash = profile.pinHash;
      if (pin == null || hash == null || !verifyPin(pin, hash)) {
        return false;
      }
    }
    final storage = _storage;
    if (storage == null) return false;
    return _serializeIdentityMutation<bool>((generation) async {
      if (generation != _identityMutationGeneration) return false;
      final now = DateTime.now();
      await storage.markProfileUsed(profile.id, now);
      if (generation != _identityMutationGeneration) return false;
      final previousActiveProfileId = storage.getActiveProfileId();
      try {
        await _writeActiveProfileId(storage, profile.id);
      } catch (_) {
        await _restoreActiveProfileId(storage, previousActiveProfileId);
        rethrow;
      }
      if (generation != _identityMutationGeneration) {
        await _restoreActiveProfileId(storage, previousActiveProfileId);
        return false;
      }

      final activated = profile.copyWith(lastUsedAt: now);
      _active = activated;
      _committedIdentityGeneration = generation;
      _profiles = sortProfilesByLastUsed([for (final p in _profiles) p.id == profile.id ? activated : p]);
      safeNotifyListeners();
      appLogger.i('ActiveProfileProvider: activated ${profile.displayName} (${profile.id})');
      if (profile.isLocal) {
        // Local rows also bump the DB's lastUsedAt so the in-DB sortable column
        // stays accurate — the in-memory mark above keeps the picker snappy.
        unawaited(
          _registry.markUsed(profile.id, now).catchError((Object e, StackTrace s) {
            appLogger.w('markUsed failed for ${profile.id}', error: e, stackTrace: s);
          }),
        );
      }
      return true;
    });
  }

  /// Restore the profile that owned the current authenticated session when a
  /// later activation fails. The caller must supply the profile captured
  /// before that activation; no PIN prompt is repeated for the session that
  /// was already unlocked.
  Future<int?> restoreAfterFailedActivation(
    Profile profile, {
    required String expectedActiveId,
    required int expectedCommittedGeneration,
    int? requestGeneration,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError('ActiveProfileProvider is not initialized');
    }

    var generation = requestGeneration;
    while (_active?.id == expectedActiveId && _committedIdentityGeneration == expectedCommittedGeneration) {
      if (generation != null && generation != _identityMutationGeneration) {
        // A newer request may still be preparing before it enters the queue
        // (for example, clearing its former shelf owner). Do not reclaim
        // ownership until that request has finished. If it fails without
        // committing, the genuinely current failed identity can still be
        // restored on the next pass.
        await _awaitIdentityWorkAfter(generation);
        if (_active?.id != expectedActiveId || _committedIdentityGeneration != expectedCommittedGeneration) {
          return null;
        }
        generation = null;
      }

      late int attemptedGeneration;
      Future<int?> restore(int ownedGeneration) {
        attemptedGeneration = ownedGeneration;
        return _restoreFailedActivation(
          storage,
          profile,
          expectedActiveId,
          expectedCommittedGeneration,
          ownedGeneration,
        );
      }

      final restoredGeneration = generation == null
          ? await _serializeIdentityMutation<int?>(restore)
          : await _queueIdentityMutation<int?>(generation, restore);
      if (restoredGeneration != null) return restoredGeneration;
      if (_active?.id != expectedActiveId || _committedIdentityGeneration != expectedCommittedGeneration) {
        return null;
      }

      await _awaitIdentityWorkAfter(attemptedGeneration);
      generation = null;
    }
    return null;
  }

  Future<int?> _restoreFailedActivation(
    StorageService storage,
    Profile profile,
    String expectedActiveId,
    int expectedCommittedGeneration,
    int generation,
  ) async {
    if (_active?.id != expectedActiveId ||
        _committedIdentityGeneration != expectedCommittedGeneration ||
        generation != _identityMutationGeneration) {
      return null;
    }
    final previousActiveProfileId = storage.getActiveProfileId();
    try {
      await _writeActiveProfileId(storage, profile.id);
    } catch (_) {
      await _restoreActiveProfileId(storage, previousActiveProfileId);
      rethrow;
    }
    if (generation != _identityMutationGeneration) {
      await _restoreActiveProfileId(storage, previousActiveProfileId);
      return null;
    }

    _committedIdentityGeneration = generation;
    _active = profile;
    _profiles = sortProfilesByLastUsed([
      for (final candidate in _profiles) candidate.id == profile.id ? profile : candidate,
    ]);
    safeNotifyListeners();
    appLogger.i('ActiveProfileProvider: restored ${profile.displayName} (${profile.id}) after failed activation');
    return generation;
  }

  /// Clear the selected profile in both storage and memory so the picker
  /// can force an explicit choice on the next screen.
  Future<void> clearActiveProfile() async {
    final generation = beginIdentityMutationRequest();
    try {
      final storage = _storage ??= await StorageService.getInstance();
      if (!isIdentityMutationRequestCurrent(generation)) return;
      await _queueIdentityMutation<void>(generation, (ownedGeneration) async {
        if (ownedGeneration != _identityMutationGeneration) return;
        final previousActiveProfileId = storage.getActiveProfileId();
        await storage.clearActiveProfileId();
        if (ownedGeneration != _identityMutationGeneration) {
          await _restoreActiveProfileId(storage, previousActiveProfileId);
          return;
        }
        _committedIdentityGeneration = ownedGeneration;
        _active = null;
        safeNotifyListeners();
      });
    } finally {
      finishIdentityMutationRequest(generation);
    }
  }

  Future<void> _writeActiveProfileId(StorageService storage, String profileId) {
    return _activeProfileIdWriter?.call(profileId) ?? storage.setActiveProfileId(profileId);
  }

  Future<void> _restoreActiveProfileId(StorageService storage, String? profileId) {
    if (profileId == null) return storage.clearActiveProfileId();
    return _writeActiveProfileId(storage, profileId);
  }

  Future<T> _serializeIdentityMutation<T>(Future<T> Function(int generation) mutation) {
    final generation = ++_identityMutationGeneration;
    return _queueIdentityMutation(generation, mutation);
  }

  Future<T> _queueIdentityMutation<T>(int generation, Future<T> Function(int generation) mutation) {
    final previous = _identityMutationQueue;
    _pendingIdentityMutations++;
    final operation = () async {
      if (previous != null) await previous;
      try {
        return await mutation(generation);
      } finally {
        _pendingIdentityMutations--;
      }
    }();
    _identityMutationQueue = operation.then<void>((_) {}).catchError((Object _, StackTrace _) {});
    return operation;
  }

  Future<void> _awaitIdentityWorkAfter(int generation) async {
    while (true) {
      final reservations = [
        for (final entry in _identityMutationReservations.entries)
          if (entry.key > generation) entry.value.future,
      ];
      final queue = _identityMutationQueue;
      if (reservations.isNotEmpty) await Future.wait(reservations);
      if (queue != null) await queue;

      final hasNewerReservation = _identityMutationReservations.keys.any((candidate) => candidate > generation);
      if (!hasNewerReservation && identical(queue, _identityMutationQueue)) return;
    }
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    await _localSub?.cancel();
    await _connSub?.cancel();
    await _plexHomeSub?.cancel();
    _localSub = null;
    _connSub = null;
    _plexHomeSub = null;
    _profiles = const [];
    _localProfiles = const [];
    _plexHomeUsers = const {};
    _connectionsById = const {};
    _active = null;
    _initializeFuture = null;
    _initialized = false;
    _isBinding = false;
    _lastBindingSucceeded = true;
    for (final c in _bindingSettleWaiters) {
      if (!c.isCompleted) c.complete(_lastBindingSucceeded);
    }
    _bindingSettleWaiters.clear();
    for (final reservation in _identityMutationReservations.values) {
      if (!reservation.isCompleted) reservation.complete();
    }
    _identityMutationReservations.clear();
  }

  @override
  void dispose() {
    // Settle anyone awaiting binding before the listeners go away — leaving
    // them pending traps callers in a forever-await on app teardown.
    for (final c in _bindingSettleWaiters) {
      if (!c.isCompleted) c.complete(_lastBindingSucceeded);
    }
    _bindingSettleWaiters.clear();
    for (final reservation in _identityMutationReservations.values) {
      if (!reservation.isCompleted) reservation.complete();
    }
    _identityMutationReservations.clear();
    _initializeFuture = null;
    _localSub?.cancel();
    _connSub?.cancel();
    _plexHomeSub?.cancel();
    super.dispose();
  }
}
