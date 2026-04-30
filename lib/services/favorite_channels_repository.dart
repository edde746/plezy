import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/livetv_channel.dart';

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
  Future<List<FavoriteChannel>> read({required String key, required String legacyKey});

  /// Replaces the channel list under [key].
  Future<void> write(String key, List<FavoriteChannel> channels);
}

/// Production implementation. Holds no state; the platform plugin has its
/// own caching layer behind `SharedPreferences.getInstance()`.
class SharedPreferencesFavoriteChannelsRepository implements FavoriteChannelsRepository {
  const SharedPreferencesFavoriteChannelsRepository();

  @override
  Future<List<FavoriteChannel>> read({required String key, required String legacyKey}) async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(key);
    if (raw == null) {
      // Migrate from the legacy bare-machineId slot. Only the first user to
      // read inherits it; the rest start empty (favorites were always
      // user-scoped semantically — the legacy key just couldn't express it).
      final legacy = prefs.getString(legacyKey);
      if (legacy != null) {
        await prefs.setString(key, legacy);
        await prefs.remove(legacyKey);
        raw = legacy;
      }
    }
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().map(FavoriteChannel.fromJson).toList();
  }

  @override
  Future<void> write(String key, List<FavoriteChannel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(channels.map((c) => c.toJson()).toList()));
  }
}
