import 'dart:async';

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
    required ProfileRegistry registry,
    required PlexHomeService plexHome,
    required ConnectionRegistry connections,
    StorageService? storage,
  }) : _registry = registry,
       _plexHome = plexHome,
       _connections = connections,
       _storage = storage;

  final ProfileRegistry _registry;
  final PlexHomeService _plexHome;
  final ConnectionRegistry _connections;
  StorageService? _storage;

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

  Profile? get active => _active;
  String? get activeId => _active?.id;
  List<Profile> get profiles => _profiles;
  bool get hasMultipleProfiles => _profiles.length > 1;
  bool get isInitialized => _initialized;

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

  Future<void> _initialize() async {
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

    _localSub = _registry.watchProfiles().listen((list) {
      _localProfiles = list;
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });
    _connSub = _connections.watchConnections().listen((list) {
      _connectionsById = {for (final c in list) c.id: c};
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });
    _plexHomeSub = _plexHome.stream.listen((cache) {
      _plexHomeUsers = cache;
      _recomputeProfiles();
      _resolveActive();
      safeNotifyListeners();
    });

    _initialized = true;
    safeNotifyListeners();
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
    // Saved id no longer matches anything (e.g. Plex admin removed the
    // home user). Clear it so storage-scoped settings do not keep reading
    // and writing under the removed profile's user scope, and let the UI
    // force an explicit profile choice.
    _active = null;
    final storage = _storage;
    if (storage != null) {
      unawaited(storage.clearActiveProfileId());
    }
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
    await storage.setActiveProfileId(profile.id);
    final now = DateTime.now();
    await storage.markProfileUsed(profile.id, now);
    _active = profile.copyWith(lastUsedAt: now);
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
  }

  /// Clear the selected profile in both storage and memory so the picker
  /// can force an explicit choice on the next screen.
  Future<void> clearActiveProfile() async {
    final storage = _storage ??= await StorageService.getInstance();
    await storage.clearActiveProfileId();
    _active = null;
    safeNotifyListeners();
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
  }

  @override
  void dispose() {
    // Settle anyone awaiting binding before the listeners go away — leaving
    // them pending traps callers in a forever-await on app teardown.
    for (final c in _bindingSettleWaiters) {
      if (!c.isCompleted) c.complete(_lastBindingSucceeded);
    }
    _bindingSettleWaiters.clear();
    _initializeFuture = null;
    _localSub?.cancel();
    _connSub?.cancel();
    _plexHomeSub?.cancel();
    super.dispose();
  }
}
