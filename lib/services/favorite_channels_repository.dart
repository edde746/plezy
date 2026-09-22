import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/livetv_channel.dart';
import 'base_shared_preferences_service.dart';

/// Persistence boundary for the per-connection favorite-channel list shown
/// in the Live TV picker. Pulled out of `_JellyfinLiveTvSupport` so the
/// favorites round-trip can be exercised with an in-memory fake instead of
/// the platform `SharedPreferences` plugin.
///
/// The repo owns the *serialisation*; the call site owns the *key naming*
/// (which depends on connection id + machineId — backend-specific concerns
/// the repo shouldn't have to know about).
abstract class FavoriteChannelsRepository {
  /// Reads channels for [key]. If absent, falls back to [legacyKey] one
  /// time, migrating the value into [key] and clearing the legacy slot.
  Future<List<FavoriteChannel>> read({
    required String key,
    required String legacyKey,
    bool migrate = true,
    void Function()? checkCurrent,
  });

  /// Replaces the channel list under [key].
  Future<void> write(String key, List<FavoriteChannel> channels, {void Function()? checkCurrent});
}

/// Production implementation. Holds no state; reads and writes go through
/// the app-wide [BaseSharedPreferencesService.sharedCache] so favorites are
/// covered by logout wipe, export and store salvage like every other pref.
///
/// Earlier builds wrote favorites with `SharedPreferences.getInstance()` —
/// the legacy store, which the one-shot legacy→async migration had already
/// left behind. Those lists are adopted into the shared cache on first read.
class SharedPreferencesFavoriteChannelsRepository implements FavoriteChannelsRepository {
  const SharedPreferencesFavoriteChannelsRepository();

  @override
  Future<List<FavoriteChannel>> read({
    required String key,
    required String legacyKey,
    bool migrate = true,
    void Function()? checkCurrent,
  }) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    var raw = readTolerantString(prefs, key);
    if (raw == null) {
      // Older slots, most recent first: the bare-machineId key in the shared
      // cache, then either key in the legacy store. Only the first user to
      // read inherits a bare-machineId value; the rest start empty
      // (favorites were always user-scoped semantically — the legacy key
      // just couldn't express it).
      final legacyStore = await SharedPreferences.getInstance();
      final sources = <(String?, Future<void> Function())>[
        (readTolerantString(prefs, legacyKey), () => prefs.remove(legacyKey)),
        (legacyStore.getString(key), () => _removeLegacy(legacyStore, key)),
        (legacyStore.getString(legacyKey), () => _removeLegacy(legacyStore, legacyKey)),
      ];
      for (final (value, clear) in sources) {
        if (value == null) continue;
        if (migrate) {
          checkCurrent?.call();
          await prefs.setString(key, value);
          checkCurrent?.call();
          await clear();
        }
        raw = value;
        break;
      }
    }
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((row) => row is! Map<String, dynamic>)) {
      throw const FormatException('Invalid favorite channel list');
    }
    return decoded.cast<Map<String, dynamic>>().map(FavoriteChannel.fromJson).toList();
  }

  @override
  Future<void> write(String key, List<FavoriteChannel> channels, {void Function()? checkCurrent}) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    checkCurrent?.call();
    await prefs.setString(key, jsonEncode(channels.map((c) => c.toJson()).toList()));
  }

  static Future<void> _removeLegacy(SharedPreferences legacyStore, String key) async {
    if (!await legacyStore.remove(key)) throw StateError('Favorite migration cleanup failed');
  }
}
