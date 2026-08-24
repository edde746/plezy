import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/playback_rate.dart';
import '../models/player_setting_scope.dart';
import '../utils/global_key_utils.dart';
import 'settings_service.dart';

/// One player-sheet property whose persistence is scope-configurable.
///
/// [id] discriminates the property inside
/// [SettingsService.scopedPlayerPrefValues]; [scope] is the user-configured
/// [PlayerSettingScope]; [global] is the pre-existing global pref every scope
/// falls back to (and the write target for [PlayerSettingScope.global]).
final class ScopedPlayerPref<T> {
  final String id;
  final EnumPref<PlayerSettingScope> scope;
  final Pref<T> global;

  /// Decodes a JSON-decoded stored value back to [T]; null rejects the entry
  /// (falls back to the global pref). Values round-trip through JSON, so ints
  /// and doubles need tolerant numeric handling.
  final T? Function(Object? raw) _decode;

  const ScopedPlayerPref._(this.id, this.scope, this.global, this._decode);
}

/// Scope-aware persistence for values changed in the player's settings sheet.
///
/// Writes go to the configured scope: `off` writes nothing, `global` writes
/// the property's pre-existing global pref, `library`/`title` write an entry
/// keyed by the item's library/title identity. Items without the required
/// identity (live TV placeholders, Jellyfin/Emby downloads without a stamped
/// library, search rows) fall back to the global pref so a change never
/// silently vanishes.
///
/// Resolution consults only the configured scope's entry, then the global
/// pref — never entries saved under another scope — so switching scopes makes
/// old entries inert instead of shadowing the new regime, and switching back
/// resurrects them.
abstract final class ScopedPlayerPrefs {
  static final playbackSpeed = ScopedPlayerPref<double>._(
    'playback_speed',
    SettingsService.playbackSpeedScope,
    SettingsService.defaultPlaybackSpeed,
    _decodeSpeed,
  );

  /// Stored value is the [ShaderPreset] id, matching
  /// [SettingsService.globalShaderPreset].
  static final shaderPreset = ScopedPlayerPref<String>._(
    'shader_preset',
    SettingsService.shaderPresetScope,
    SettingsService.globalShaderPreset,
    _decodeString,
  );

  static final boxFitMode = ScopedPlayerPref<int>._(
    'box_fit_mode',
    SettingsService.boxFitScope,
    SettingsService.defaultBoxFitMode,
    _decodeBoxFit,
  );

  static final audioSyncOffset = ScopedPlayerPref<int>._(
    'audio_sync_offset',
    SettingsService.syncOffsetScope,
    SettingsService.audioSyncOffset,
    _decodeInt,
  );

  static final subtitleSyncOffset = ScopedPlayerPref<int>._(
    'subtitle_sync_offset',
    SettingsService.syncOffsetScope,
    SettingsService.subtitleSyncOffset,
    _decodeInt,
  );

  /// Entry cap per property; oldest entries by write time are evicted past it.
  static const int maxEntriesPerProperty = 300;

  /// The value to apply for [item], honoring the property's configured scope.
  static T resolve<T>(ScopedPlayerPref<T> pref, MediaItem? item) {
    final svc = SettingsService.instance;
    final key = scopeKeyFor(svc.read(pref.scope), item);
    if (key != null) {
      final entry = _entriesFor(svc, pref.id)[key];
      if (entry is Map) {
        final value = pref._decode(entry['v']);
        if (value != null) return value;
      }
    }
    return svc.read(pref.global);
  }

  /// Persist [value] for [item] at the property's configured scope.
  static Future<void> write<T>(ScopedPlayerPref<T> pref, MediaItem? item, T value) async {
    final svc = SettingsService.instance;
    final scope = svc.read(pref.scope);
    if (scope == PlayerSettingScope.off) return;
    final key = scopeKeyFor(scope, item);
    if (key == null) {
      await svc.write(pref.global, value);
      return;
    }
    final entries = Map<String, dynamic>.from(_entriesFor(svc, pref.id));
    entries[key] = <String, dynamic>{'v': value, 't': DateTime.now().millisecondsSinceEpoch};
    final store = Map<String, dynamic>.from(svc.read(SettingsService.scopedPlayerPrefValues));
    store[pref.id] = _prune(entries);
    await svc.write(SettingsService.scopedPlayerPrefValues, store);
  }

  /// The storage key for [item] under [scope], or null when the scope keys
  /// globally or the item lacks the required identity.
  static String? scopeKeyFor(PlayerSettingScope scope, MediaItem? item) {
    if (item == null) return null;
    switch (scope) {
      case PlayerSettingScope.off:
      case PlayerSettingScope.global:
        return null;
      case PlayerSettingScope.library:
        // Null for Jellyfin/Emby items whose library was never stamped
        // (notably downloads) and for shared/search rows.
        final libraryKey = item.libraryGlobalKey;
        return libraryKey == null ? null : 'library:$libraryKey';
      case PlayerSettingScope.title:
        // Series key for episodes, own key for movies — the same rule as
        // media-version preferences. Server-scoped because raw Plex rating
        // keys are small integers that collide across servers; without a
        // server id (live TV placeholders) fall back to global.
        final serverId = serverIdOrNull(item.serverId);
        if (serverId == null) return null;
        return 'title:${buildGlobalKey(serverId, item.grandparentId ?? item.id)}';
    }
  }

  static Map<String, dynamic> _entriesFor(SettingsService svc, String propertyId) {
    final raw = svc.read(SettingsService.scopedPlayerPrefValues)[propertyId];
    return raw is Map ? Map<String, dynamic>.from(raw) : const {};
  }

  static Map<String, dynamic> _prune(Map<String, dynamic> entries) {
    if (entries.length <= maxEntriesPerProperty) return entries;
    final sorted = entries.entries.toList()..sort((a, b) => _timestampOf(b.value).compareTo(_timestampOf(a.value)));
    return Map.fromEntries(sorted.take(maxEntriesPerProperty));
  }

  static int _timestampOf(Object? entry) => entry is Map && entry['t'] is int ? entry['t'] as int : 0;

  static double? _decodeSpeed(Object? raw) =>
      raw is num ? raw.toDouble().clamp(minimumPlaybackRate, maximumPlaybackRate) : null;

  static int? _decodeInt(Object? raw) => raw is int ? raw : null;

  static int? _decodeBoxFit(Object? raw) => raw is int ? raw.clamp(0, 2) : null;

  static String? _decodeString(Object? raw) => raw is String ? raw : null;
}
