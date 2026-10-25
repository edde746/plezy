import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';
import 'base_shared_preferences_service.dart';
import 'plex_auth_service.dart';
import 'settings_service.dart';

/// Keeps the Home layout (row order, which rows show, Hero and Auto-slide per
/// row, per-library row order) the same on every Plezy signed in to the same
/// Plex account.
///
/// The layout is stored as one hidden shared setting on the plex.tv account,
/// the same mechanism Plex Web uses for its own experience settings. Last
/// writer wins: each push stamps the layout with the time it was changed, and
/// a pull only applies a remote layout that is newer than the one this device
/// last applied or pushed. A device with an unpushed local change skips the
/// pull and pushes instead.
///
/// Only the settings are shared. How a device draws them (TV spotlight vs
/// desktop list) stays per platform.
class HomeLayoutSyncService with WidgetsBindingObserver {
  HomeLayoutSyncService._();

  static final HomeLayoutSyncService instance = HomeLayoutSyncService._();

  static const String settingId = 'plezy_home_layout';
  static const String _stateKey = 'home_layout_sync_state';
  static const String _backupKey = 'home_layout_sync_backup';
  static const String _migratedKey = 'home_layout_sync_enabled_migrated';
  static const Duration _pushDelay = Duration(seconds: 2);
  static const Duration _minPullGap = Duration(seconds: 20);
  static const Duration _periodicPull = Duration(minutes: 1);

  static final List<_SyncedPref<dynamic>> _prefs = [
    _SyncedPref.json(SettingsService.homeSections),
    _SyncedPref.json(SettingsService.homeRowOrder),
    _SyncedPref.json(SettingsService.managedHubHeroOverrides),
    _SyncedPref.json(SettingsService.libraryContinueWatchingHidden),
    _SyncedPref.json(SettingsService.libraryManagedRowOrder),
    _SyncedPref.boolean(SettingsService.continueWatchingOnHome),
    _SyncedPref.boolean(SettingsService.showHeroSection),
    _SyncedPref.boolean(SettingsService.hideWatchedInHubs),
  ];

  @visibleForTesting
  static List<String> debugSyncedPrefTypesForTesting() => [for (final synced in _prefs) synced.runtimeType.toString()];

  /// Whether [local] changed since [savedSnapshot] (the JSON snapshot taken at
  /// the last sync). Keys the saved snapshot doesn't have yet are ignored:
  /// a pref added to the synced list in an app update is not a user change,
  /// and counting it would make every device upload its own layout as the
  /// newest one the first time it runs the update.
  @visibleForTesting
  static bool changedSinceSnapshot(String savedSnapshot, Map<String, Object?> local) {
    if (savedSnapshot.isEmpty) return false;
    final Map<String, dynamic> saved;
    try {
      saved = json.decode(savedSnapshot) as Map<String, dynamic>;
    } catch (_) {
      return true;
    }
    for (final entry in saved.entries) {
      if (!local.containsKey(entry.key)) continue;
      if (json.encode(entry.value) != json.encode(local[entry.key])) return true;
    }
    return false;
  }

  /// Whether the account already holds this device's layout. A key the
  /// account doesn't have yet only matches while this device still has that
  /// pref at its default.
  bool _sameAsRemote(SettingsService settings, Map<String, Object?> local, Map<String, Object?> remote) {
    for (final synced in _prefs) {
      final key = synced.pref.key;
      if (!remote.containsKey(key)) {
        if (!synced.isDefault(settings)) return false;
        continue;
      }
      if (json.encode(remote[key]) != json.encode(local[key])) return false;
    }
    return true;
  }

  /// Human-readable last sync result for the Organizer ("Synced ... at 6:41").
  final ValueNotifier<String> status = ValueNotifier('Not synced yet');

  /// Bumped each time a layout from the account is applied, so an open
  /// Organizer can reload its rows.
  final ValueNotifier<int> appliedRevision = ValueNotifier(0);

  String? _token;
  PlexAuthService? _auth;
  bool _listening = false;
  bool _applying = false;
  bool _pulling = false;
  Timer? _pushTimer;
  Timer? _periodicTimer;
  DateTime? _lastPull;

  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Sets [status] and appends one line to `home_layout_sync.log` in the app
  /// support directory, so a sync problem can be diagnosed on any device
  /// (release builds don't keep the app log anywhere readable).
  void _trace(String message, {String? statusText}) {
    final now = DateTime.now();
    if (statusText != null) status.value = '$statusText at ${_clock(now)}';
    unawaited(() async {
      try {
        final file = File(
          '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}home_layout_sync.log',
        );
        if (await file.exists() && await file.length() > 256 * 1024) await file.writeAsString('');
        await file.writeAsString('${now.toIso8601String()} $message\n', mode: FileMode.append, flush: true);
      } catch (_) {}
    }());
  }

  /// Called whenever the active profile's Plex token is known (or gone).
  /// A new token pulls right away; null stops syncing (Jellyfin, signed out).
  /// Whether this device shares its layout ([SettingsService.homeLayoutSyncEnabled]).
  bool get enabled => SettingsService.instance.read(SettingsService.homeLayoutSyncEnabled);

  /// Turn sharing on or off for this device. Turning it on pulls right away:
  /// the account's layout applies if it is newer, otherwise this device's
  /// layout is uploaded.
  Future<void> setEnabled(bool value) async {
    await SettingsService.instance.write(SettingsService.homeLayoutSyncEnabled, value);
    _pushTimer?.cancel();
    _pushTimer = null;
    if (value) {
      await pull(force: true);
    } else {
      status.value = 'Off on this device';
    }
  }

  /// Devices that synced before the on/off switch existed keep syncing.
  void _migrateEnabled(SettingsService settings) {
    if (settings.readNullableString(_migratedKey) != null) return;
    unawaited(settings.writeString(_migratedKey, '1'));
    if (_readState(settings).appliedAt > 0) {
      unawaited(settings.write(SettingsService.homeLayoutSyncEnabled, true));
    }
  }

  void bind(String? token) {
    _migrateEnabled(SettingsService.instance);
    if (!enabled) status.value = 'Off on this device';
    if (token == null || token.isEmpty) {
      if (_token != null) appLogger.i('HomeLayoutSync: no Plex account, sync off');
      _token = null;
      _periodicTimer?.cancel();
      _periodicTimer = null;
      return;
    }
    final changed = token != _token;
    _token = token;
    if (changed) {
      appLogger.i('HomeLayoutSync: bound to active Plex account');
      _trace('bound');
    }
    _startListening();
    _periodicTimer ??= Timer.periodic(_periodicPull, (_) => unawaited(pull()));
    if (changed) unawaited(pull(force: true));
  }

  void _startListening() {
    if (_listening) return;
    _listening = true;
    final settings = SettingsService.instance;
    for (final synced in _prefs) {
      settings.listenableOf(synced.pref).addListener(_onLocalChange);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(pull());
  }

  void _onLocalChange() {
    if (_applying || _token == null || !enabled) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDelay, () {
      _pushTimer = null;
      unawaited(push());
    });
  }

  Map<String, Object?> _snapshot(SettingsService settings) => {
    for (final synced in _prefs) synced.pref.key: synced.encode(settings),
  };

  ({int appliedAt, String snapshot}) _readState(SettingsService settings) {
    final raw = settings.readNullableString(_stateKey);
    if (raw == null) return (appliedAt: 0, snapshot: '');
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      return (appliedAt: (map['appliedAt'] as num?)?.toInt() ?? 0, snapshot: map['snapshot'] as String? ?? '');
    } catch (_) {
      return (appliedAt: 0, snapshot: '');
    }
  }

  Future<void> _writeState(SettingsService settings, int appliedAt, String snapshot) =>
      settings.writeString(_stateKey, json.encode({'appliedAt': appliedAt, 'snapshot': snapshot}));

  bool _isAllDefault(SettingsService settings) => _prefs.every((synced) => synced.isDefault(settings));

  Future<PlexAuthService> _authService() async => _auth ??= await PlexAuthService.create();

  /// Fetch the account's layout and apply it if it is newer than this
  /// device's. Throttled unless [force].
  Future<void> pull({bool force = false}) async {
    final token = _token;
    if (!enabled) return;
    if (token == null || _pulling) {
      _trace('pull skipped (token=${token != null}, pulling=$_pulling)');
      if (force && token == null) status.value = 'Not signed in to a Plex account';
      return;
    }
    final now = DateTime.now();
    if (!force && _lastPull != null && now.difference(_lastPull!) < _minPullGap) return;
    _lastPull = now;
    _pulling = true;
    try {
      final settings = SettingsService.instance;
      final entries = await (await _authService()).getUserSettings(token);
      final entry = entries.firstWhere((e) => e['id'] == settingId, orElse: () => const {});
      final rawValue = entry['value'];

      if (rawValue is! String || rawValue.isEmpty) {
        // Nothing on the account yet: seed it from this device, but never
        // from an untouched default layout (that would wipe a configured
        // device the next time it pulls).
        final allDefault = _isAllDefault(settings);
        appLogger.i(
          'HomeLayoutSync: no layout on account yet',
          error: {
            'entries': entries.length,
            'seeding': !allDefault,
            'nonDefault': [
              for (final synced in _prefs)
                if (!synced.isDefault(settings)) synced.pref.key,
            ],
          },
        );
        if (!allDefault) {
          // Keep this device's own last-change time so a device that changed
          // something more recently still wins when it pulls next.
          final state = _readState(settings);
          await push(force: true, modifiedAt: state.appliedAt > 0 ? state.appliedAt : null);
        }
        return;
      }

      final remote = json.decode(rawValue) as Map<String, dynamic>;
      final remoteModifiedAt = (remote['modifiedAt'] as num?)?.toInt() ?? 0;
      final remotePrefs = Map<String, Object?>.from(remote['prefs'] as Map? ?? const {});
      final state = _readState(settings);

      final local = _snapshot(settings);
      // Changed here but never uploaded (offline, or app closed first).
      final localDirty = state.appliedAt > 0 && changedSinceSnapshot(state.snapshot, local);
      final same = _sameAsRemote(settings, local, remotePrefs);
      _trace(
        'pull: remote=$remoteModifiedAt applied=${state.appliedAt} dirty=$localDirty '
        'pushPending=${_pushTimer != null} same=$same',
      );
      if (_pushTimer != null) return; // a newer local change is about to push
      if (remoteModifiedAt <= state.appliedAt || localDirty) {
        // This device's layout is the newer one: send it unless the account
        // already holds the same thing.
        if (!same) {
          await push(force: true, modifiedAt: localDirty ? null : state.appliedAt);
        } else {
          _trace('up to date', statusText: 'Up to date with your Plex account');
        }
        return;
      }

      if (state.appliedAt == 0 && settings.readNullableString(_backupKey) == null) {
        // First sync on this device: keep its own layout recoverable.
        await settings.writeString(_backupKey, json.encode(local));
      }

      _applying = true;
      try {
        for (final synced in _prefs) {
          if (!remotePrefs.containsKey(synced.pref.key)) continue;
          final value = remotePrefs[synced.pref.key];
          if (json.encode(value) == json.encode(local[synced.pref.key])) continue;
          await synced.apply(settings, value);
        }
      } finally {
        _applying = false;
      }
      await _writeState(settings, remoteModifiedAt, json.encode(_snapshot(settings)));
      appLogger.i('HomeLayoutSync: applied layout from Plex account', error: {'modifiedAt': remoteModifiedAt});
      _trace('applied $remoteModifiedAt', statusText: 'Got the latest layout from your Plex account');
      appliedRevision.value++;
    } catch (e) {
      appLogger.w('HomeLayoutSync: pull failed', error: e);
      _trace('pull failed: $e', statusText: 'Sync failed ($e)');
    } finally {
      _pulling = false;
    }
  }

  /// Upload this device's layout if it differs from what was last synced
  /// ([force] skips that check). [modifiedAt] defaults to now.
  Future<void> push({bool force = false, int? modifiedAt}) async {
    final token = _token;
    if (token == null || !enabled) return;
    try {
      final settings = SettingsService.instance;
      final snapshot = _snapshot(settings);
      final encodedSnapshot = json.encode(snapshot);
      final state = _readState(settings);
      if (!force && encodedSnapshot == state.snapshot) return;
      final stamp = modifiedAt ?? DateTime.now().millisecondsSinceEpoch;
      final value = json.encode({'v': 1, 'modifiedAt': stamp, 'prefs': snapshot});
      await (await _authService()).putUserSetting(token, settingId, value);
      await _writeState(settings, stamp, encodedSnapshot);
      appLogger.i('HomeLayoutSync: pushed layout to Plex account', error: {'modifiedAt': stamp});
      _trace('pushed $stamp', statusText: 'Saved your layout to your Plex account');
    } catch (e) {
      appLogger.w('HomeLayoutSync: push failed', error: e);
      _trace('push failed: $e', statusText: 'Sync failed ($e)');
    }
  }
}

/// One synced pref with its JSON round trip.
class _SyncedPref<T> {
  _SyncedPref._(this.pref, this._toJson, this._fromJson, this._defaultJson);

  // Non-generic return type on purpose: a `_SyncedPref<V>` return lets the
  // list's `_SyncedPref<dynamic>` context infer V = dynamic, which erases the
  // pref's real type and fails the runtime check on `JsonPref.encode`.
  static _SyncedPref<dynamic> json<V>(JsonPref<V> pref) => _SyncedPref<V>._(
    pref,
    (v) => jsonDecode(pref.encode(v)),
    (raw) => pref.decode(raw),
    jsonDecode(pref.encode(pref.defaultValue)),
  );

  static _SyncedPref<dynamic> boolean(BoolPref pref) =>
      _SyncedPref<bool>._(pref, (v) => v, (raw) => raw as bool? ?? pref.defaultValue, pref.defaultValue);

  final Pref<T> pref;
  final Object? Function(T) _toJson;
  final T Function(Object?) _fromJson;
  final Object? _defaultJson;

  Object? encode(BaseSharedPreferencesService settings) => _toJson(settings.read(pref));

  bool isDefault(BaseSharedPreferencesService settings) => jsonEncode(encode(settings)) == jsonEncode(_defaultJson);

  Future<void> apply(BaseSharedPreferencesService settings, Object? raw) => settings.write(pref, _fromJson(raw));
}
