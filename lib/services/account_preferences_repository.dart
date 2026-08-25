import 'dart:async';

import '../media/account_preferences.dart';
import '../media/account_preferences_source.dart';
import '../media/account_ref.dart';
import '../media/media_backend.dart';
import '../utils/app_logger.dart';

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
/// One instance, app-lifetime: the Account preferences screens and
/// [UserProfileProvider] must not keep separate copies, or a write made in
/// settings would leave playback on the stale value until restart.
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
  final Map<AccountRef, Future<AccountPreferences>> _inFlight = {};
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
    MediaBackend.jellyfin || MediaBackend.emby => AccountPreferencesCapabilities.mediaBrowser,
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
    if (pending != null) return pending;

    final future = _read(ref);
    _inFlight[ref] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[ref], future)) _inFlight.remove(ref);
    });
  }

  Future<AccountPreferences> _read(AccountRef ref) async {
    final source = await _requireSource(ref);
    final prefs = await source.read();
    if (_disposed) return prefs;
    _cache[ref] = prefs;
    _emit(ref);
    return prefs;
  }

  /// Apply [patch] to [ref] and cache the authoritative result.
  ///
  /// Keys the backend does not support are dropped rather than sent: the UI
  /// hides those rows, so reaching here with one means a caller built a patch
  /// generically, and sending it would either 4xx or silently no-op.
  Future<AccountPreferences> update(AccountRef ref, AccountPreferencesPatch patch) async {
    final source = await _requireSource(ref);
    final capabilities = source.capabilities;

    for (final key in patch.keys) {
      if (!capabilities.supports(key)) {
        appLogger.w('AccountPreferencesRepository: dropping unsupported key', error: {'key': key.name, 'ref': ref.key});
      }
    }

    final supported = AccountPreferencesPatch({
      for (final entry in patch.values.entries)
        if (capabilities.supports(entry.key)) entry.key: entry.value,
    });
    if (supported.isEmpty) return _cache[ref] ?? AccountPreferences.empty;

    final updated = await source.write(supported);
    if (_disposed) return updated;
    _cache[ref] = updated;
    _emit(ref);
    return updated;
  }

  /// Drop [ref]'s cached values, e.g. after the account's token is re-minted.
  void invalidate(AccountRef ref) {
    _unreachable.remove(ref);
    if (_cache.remove(ref) != null) _emit(ref);
  }

  /// Drop everything. Called on profile switch and sign-out so one user's
  /// preferences never answer for another.
  void clear() {
    _unreachable.clear();
    if (_cache.isEmpty) return;
    final refs = _cache.keys.toList();
    _cache.clear();
    for (final ref in refs) {
      _emit(ref);
    }
  }

  Future<AccountPreferencesSource> _requireSource(AccountRef ref) async {
    final source = await _sourceFor(ref);
    if (source == null) {
      _unreachable.add(ref);
      throw AccountPreferencesUnavailableException(ref);
    }
    _unreachable.remove(ref);
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
    _unreachable.clear();
    _changes.close();
  }
}
