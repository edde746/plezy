import 'dart:async';

import '../media/account_preferences.dart';
import '../media/account_preferences_source.dart';
import '../media/account_ref.dart';
import '../media/media_backend.dart';

/// Thrown when an account's preferences cannot be reached: its server client is
/// offline, its Plex token has not been minted yet, or the connection is gone.
/// Distinct from a transport failure so the UI can say "unavailable" instead of
/// "request failed".
class AccountPreferencesUnavailableException implements Exception {
  const AccountPreferencesUnavailableException(this.ref);

  final AccountRef ref;

  @override
  String toString() => 'AccountPreferencesUnavailableException(${ref.key})';
}

/// The single cache of server-stored account preferences.
///
/// One instance, app-lifetime: the Account preferences screens and playback
/// ([AccountPreferencesController.activePreferences]) read the same values, or
/// a write made in settings would leave playback on the stale value until
/// restart.
///
/// No disk cache and no periodic refresh by design — these values are read when
/// a settings screen opens or a profile binds, and a stale value is worse than
/// a missing one. Failures propagate; callers decide whether to show cached
/// values read-only or an error state.
///
/// Sources are resolved per call rather than held: a Plex Home token is minted
/// lazily by the binder and a MediaBrowser client appears only once the server
/// is online, so a snapshot taken at construction would strand the first read
/// after launch.
class AccountPreferencesRepository {
  AccountPreferencesRepository({required this._sourceFor});

  final Future<AccountPreferencesSource?> Function(AccountRef ref) _sourceFor;

  final Map<AccountRef, AccountPreferences> _cache = {};
  final Map<AccountRef, ({Object token, Future<AccountPreferences> future})> _inFlight = {};
  // Account lifetimes change only on invalidation, not on successful writes.
  // Queued writers retain the lifetime captured before waiting.
  final Map<AccountRef, Object> _revisions = {};
  // Keep live tails across invalidation so replacement identities cannot
  // overlap a write that has already reached the server.
  final Map<AccountRef, Future<void>> _writeTails = {};
  final Set<AccountRef> _unreachable = {};
  final StreamController<AccountRef> _changes = StreamController<AccountRef>.broadcast();
  bool _disposed = false;

  /// Emits the account whose cached values just changed (load, write, or
  /// invalidation).
  Stream<AccountRef> get changes => _changes.stream;

  /// Last known values for [ref], or null when never loaded.
  AccountPreferences? cached(AccountRef ref) => _cache[ref];

  /// What [ref]'s backend can store. A pure function of the backend, so UI can
  /// build its rows before the first request resolves.
  AccountPreferencesCapabilities capabilitiesFor(AccountRef ref) => switch (ref.backend) {
    MediaBackend.jellyfin => AccountPreferencesCapabilities.jellyfin,
    MediaBackend.emby => AccountPreferencesCapabilities.emby,
    MediaBackend.plex => AccountPreferencesCapabilities.plex,
  };

  /// Last known reachability of [ref] — false once a read failed to resolve a
  /// source. Optimistic before the first attempt; the authoritative answer is
  /// whether [load] completes.
  bool isAvailable(AccountRef ref) => !_unreachable.contains(ref);

  /// Read [ref]'s preferences, serving the cache unless [forceRefresh].
  ///
  /// Concurrent calls for the same account share one request — the detail
  /// screen and a profile bind routinely land together.
  Future<AccountPreferences> load(AccountRef ref, {bool forceRefresh = false}) {
    final cachedValue = _cache[ref];
    if (!forceRefresh && cachedValue != null) return Future.value(cachedValue);

    final pending = _inFlight[ref];
    if (pending != null) return pending.future;

    final revision = _revisions.putIfAbsent(ref, Object.new);
    final token = Object();
    final future = _read(ref, revision, token);
    _inFlight[ref] = (token: token, future: future);
    return future.whenComplete(() {
      if (identical(_inFlight[ref]?.token, token)) _inFlight.remove(ref);
    });
  }

  Future<AccountPreferences> _read(AccountRef ref, Object revision, Object token) async {
    final source = await _requireSource(ref, revision, readToken: token);
    final prefs = await source.read();
    if (!_isCurrent(ref, revision) || !identical(_inFlight[ref]?.token, token)) return prefs;
    _cache[ref] = prefs;
    _emit(ref);
    return prefs;
  }

  /// Apply [patch] to [ref] and cache the authoritative result.
  ///
  /// Unsupported keys and values fail before any backend writes. Callers may
  /// additionally fence the request to a captured profile/account identity.
  /// Writes serialize per account before resolving a source: MediaBrowser
  /// replaces its full Configuration, so concurrent read/merge/write cycles
  /// would otherwise lose unrelated changes.
  Future<AccountPreferences> update(
    AccountRef ref,
    AccountPreferencesPatch patch, {
    void Function()? checkCurrent,
  }) async {
    capabilitiesFor(ref).validate(patch);
    final revision = _revisions.putIfAbsent(ref, Object.new);
    void guard() {
      checkCurrent?.call();
      if (!_isCurrent(ref, revision)) throw AccountPreferencesUnavailableException(ref);
    }

    guard();
    final previous = _writeTails[ref];
    final completion = Completer<void>();
    _writeTails[ref] = completion.future;
    try {
      if (previous != null) await previous;
      guard();
      final source = await _requireSource(ref, revision);
      guard();
      source.capabilities.validate(patch);
      if (patch.isEmpty) {
        final prefs = await load(ref);
        guard();
        return prefs;
      }
      final updated = await source.write(patch, checkCurrent: guard);
      guard();
      // Reads are allowed during a write. Revoke only their publication
      // ownership, leaving the account lifetime valid for queued writers.
      _inFlight.remove(ref);
      _cache[ref] = updated;
      _emit(ref);
      return updated;
    } finally {
      completion.complete();
      if (identical(_writeTails[ref], completion.future)) {
        unawaited(_writeTails.remove(ref));
      }
    }
  }

  /// Drop [ref]'s cached values, e.g. after the account's token is re-minted.
  void invalidate(AccountRef ref) {
    final hadState = _revisions.remove(ref) != null;
    _inFlight.remove(ref);
    _unreachable.remove(ref);
    _cache.remove(ref);
    if (hadState) _emit(ref);
  }

  /// Drop everything. Called on profile switch and sign-out so one user's
  /// preferences never answer for another.
  void clear() {
    final refs = _revisions.keys.toList();
    _revisions.clear();
    _inFlight.clear();
    _unreachable.clear();
    _cache.clear();
    for (final ref in refs) {
      _emit(ref);
    }
  }

  bool _isCurrent(AccountRef ref, Object revision) => !_disposed && identical(_revisions[ref], revision);

  Future<AccountPreferencesSource> _requireSource(AccountRef ref, Object revision, {Object? readToken}) async {
    final source = await _sourceFor(ref);
    final current = _isCurrent(ref, revision) && (readToken == null || identical(_inFlight[ref]?.token, readToken));
    if (source == null) {
      if (current) _unreachable.add(ref);
      throw AccountPreferencesUnavailableException(ref);
    }
    if (current) _unreachable.remove(ref);
    return source;
  }

  void _emit(AccountRef ref) {
    if (_disposed || _changes.isClosed) return;
    _changes.add(ref);
  }

  void dispose() {
    _disposed = true;
    _cache.clear();
    _inFlight.clear();
    _revisions.clear();
    _unreachable.clear();
    _changes.close();
  }
}
