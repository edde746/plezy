import 'package:shared_preferences/shared_preferences.dart';

import 'trakt_constants.dart';
import 'trakt_session.dart';

/// Per-Plex-profile persistence of Trakt OAuth sessions.
///
/// Each Plex Home user can link a different Trakt account. Pass an empty
/// `userUuid` to fall back to a single global slot (used before the user has
/// selected a profile).
class TraktAccountStore {
  static const String _baseKey = 'trakt_session';

  TraktAccountStore._();
  static final TraktAccountStore instance = TraktAccountStore._();

  Future<TraktSession?> load(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(traktUserKey(userUuid, _baseKey));
    if (raw == null) return null;
    try {
      return TraktSession.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, TraktSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(traktUserKey(userUuid, _baseKey), session.encode());
  }

  Future<void> clear(String userUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(traktUserKey(userUuid, _baseKey));
  }
}
