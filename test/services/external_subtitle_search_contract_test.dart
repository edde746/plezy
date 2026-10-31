import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';

/// What the player reads from each client to run a subtitle download, so the
/// player itself never branches on the backend.
void main() {
  setUp(() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    PlexApiCache.initialize(db);
  });

  List<MediaKind> searchable(ExternalSubtitleSearchClient client) => [
    for (final kind in MediaKind.values)
      if (client.canSearchSubtitlesFor(kind)) kind,
  ];

  test('Plex: the 15 s wait Plex-web uses, stable stream ids, any item', () {
    final client = testPlexClient();
    addTearDown(client.close);

    expect(client.subtitleDownloadTimeout, const Duration(seconds: 15));
    expect(client.subtitleDownloadKeepsStreamIds, isTrue);
    expect(searchable(client), MediaKind.values);
  });

  test('Jellyfin: a longer wait, renumbered streams, films and episodes only', () {
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(),
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    addTearDown(client.close);

    expect(client.subtitleDownloadTimeout, const Duration(seconds: 30));
    expect(client.subtitleDownloadKeepsStreamIds, isFalse);
    expect(searchable(client), [MediaKind.movie, MediaKind.episode]);
  });
}
