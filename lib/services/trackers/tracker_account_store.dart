import 'package:shared_preferences/shared_preferences.dart';

/// Per-Plex-profile session persistence for any tracker service.
///
/// Keyed by `user_{uuid}_{baseKey}` so each Plex Home profile gets its own
/// stored session. Generic over the session type [T] — callers supply
/// encode/decode functions.
///
/// Pass an empty `userUuid` to fall back to a single global slot (used
/// before a profile has been selected).
class TrackerAccountStore<T> {
  final String _baseKey;
  final T Function(String raw) _decode;
  final String Function(T session) _encode;

  const TrackerAccountStore({
    required String baseKey,
    required T Function(String raw) decode,
    required String Function(T session) encode,
  }) : _baseKey = baseKey,
       _decode = decode,
       _encode = encode;

  String _scopedKey(String userUuid) => userUuid.isEmpty ? _baseKey : 'user_${userUuid}_$_baseKey';

  Future<T?> load(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scopedKey(userUuid));
    if (raw == null) return null;
    try {
      return _decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, T session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scopedKey(userUuid), _encode(session));
  }

  Future<void> clear(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedKey(userUuid));
  }
}
