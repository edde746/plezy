import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/plex_home_cache_codec.dart';

void main() {
  final user = PlexHomeUser(
    id: 1,
    uuid: 'user-1',
    title: 'Owner',
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: true,
    guest: false,
    protected: false,
  );

  test('round-trips the persisted Plex Home users format', () {
    final decoded = decodePlexHomeUsersCache(encodePlexHomeUsersCacheJson([user]));

    expect(decoded.map((entry) => entry.toJson()), [user.toJson()]);
  });

  test('rejects cache payloads that are not lists', () {
    expect(() => decodePlexHomeUsersCache('{"uuid":"user-1"}'), throwsFormatException);
  });

  test('ignores non-object entries for compatibility with existing caches', () {
    final decoded = decodePlexHomeUsersCache('[null, 1, "bad", ${encodePlexHomeUsersCacheJson([user]).substring(1)}');

    expect(decoded.map((entry) => entry.toJson()), [user.toJson()]);
  });
}
