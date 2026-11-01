import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/media/subtitle_search_result.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

/// Jellyfin searches and downloads subtitles through whichever subtitle
/// plugin the server has loaded (`/Items/{id}/RemoteSearch/Subtitles`). The
/// client only offers it when the server can actually answer: a Jellyfin
/// server, a user allowed to manage subtitles (admins always are), and the
/// Open Subtitles plugin loaded, as any signed-in user can read it.
void main() {
  ({JellyfinClient client, List<http.Request> requests}) clientAnswering(
    Map<String, Object? Function(http.Request request)> routes, {
    bool isAdministrator = false,
    MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
  }) {
    final requests = <http.Request>[];
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(isAdministrator: isAdministrator, dialect: dialect),
      httpClient: MockClient((request) async {
        requests.add(request);
        final route = routes[request.url.path];
        if (route == null) return http.Response('', 404);
        final body = route(request);
        if (body is http.Response) return body;
        return jsonResponse(body ?? const {});
      }),
    );
    addTearDown(client.close);
    return (client: client, requests: requests);
  }

  Map<String, Object? Function(http.Request)> serverWithPlugin({
    bool isAdministrator = false,
    bool enableSubtitleManagement = true,
    List<String> fetchers = const ['Open Subtitles'],
  }) => {
    '/Users/Me': (_) => {
      'Policy': {'IsAdministrator': isAdministrator, 'EnableSubtitleManagement': enableSubtitleManagement},
    },
    '/Libraries/AvailableOptions': (_) => {
      'SubtitleFetchers': [
        for (final name in fetchers) {'Name': name, 'DefaultEnabled': true},
      ],
    },
  };

  group('JellyfinClient.probeRemoteSubtitleSearch', () {
    test('is off until probed, then on for a permitted user with the plugin loaded', () async {
      final fake = clientAnswering(serverWithPlugin());

      expect(fake.client.capabilities.externalSubtitleSearch, isFalse);
      expect(await fake.client.probeRemoteSubtitleSearch(), isTrue);
      expect(fake.client.capabilities.externalSubtitleSearch, isTrue);
      // A non-admin is judged on the loaded fetchers alone: /Plugins is admin-only.
      expect(fake.requests.map((r) => r.url.path), isNot(contains('/Plugins')));
    });

    test('an admin is judged exactly like everyone else, without the admin-only /Plugins', () async {
      final admin = clientAnswering(serverWithPlugin(isAdministrator: true), isAdministrator: true);

      expect(await admin.client.probeRemoteSubtitleSearch(), isTrue);
      expect(admin.requests.map((r) => r.url.path), isNot(contains('/Plugins')));
    });

    test('stays off without subtitle-management permission, unless the user is an admin', () async {
      // The routes' SubtitleManagement policy runs through Jellyfin's
      // DefaultAuthorizationHandler too, where admins pass whatever the flag
      // (measured on 12.3: an admin with the flag off gets 200 from the search).
      final user = clientAnswering(serverWithPlugin(enableSubtitleManagement: false));
      final admin = clientAnswering(
        serverWithPlugin(isAdministrator: true, enableSubtitleManagement: false),
        isAdministrator: true,
      );

      expect(await user.client.probeRemoteSubtitleSearch(), isFalse);
      expect(user.client.capabilities.externalSubtitleSearch, isFalse);
      expect(await admin.client.probeRemoteSubtitleSearch(), isTrue);
    });

    test('stays off when the Open Subtitles fetcher is not loaded', () async {
      final none = clientAnswering(serverWithPlugin(fetchers: const []));
      final other = clientAnswering(serverWithPlugin(fetchers: const ['Some Other Fetcher']));

      expect(await none.client.probeRemoteSubtitleSearch(), isFalse);
      expect(await other.client.probeRemoteSubtitleSearch(), isFalse);
    });

    test('degrades to off on any server error', () async {
      final fake = clientAnswering({
        ...serverWithPlugin(),
        '/Libraries/AvailableOptions': (_) => http.Response('boom', 500),
      });

      expect(await fake.client.probeRemoteSubtitleSearch(), isFalse);
      expect(fake.client.capabilities.externalSubtitleSearch, isFalse);
    });

    test('a probe that fails keeps the last answer', () async {
      var userFails = false;
      final routes = serverWithPlugin();
      final fake = clientAnswering({
        ...routes,
        '/Users/Me': (r) => userFails ? http.Response('down', 503) : routes['/Users/Me']!(r),
      });

      expect(await fake.client.probeRemoteSubtitleSearch(), isTrue);
      userFails = true;
      expect(await fake.client.probeRemoteSubtitleSearch(), isTrue);
      expect(fake.client.capabilities.externalSubtitleSearch, isTrue);
    });

    test('follows permission changes at each health check', () async {
      var allowed = true;
      final routes = serverWithPlugin();
      final fake = clientAnswering({
        ...routes,
        '/Users/Me': (_) => {
          'Policy': {'IsAdministrator': false, 'EnableSubtitleManagement': allowed},
        },
      });

      await fake.client.checkHealth();
      await pumpEventQueue();
      expect(fake.client.capabilities.externalSubtitleSearch, isTrue);

      allowed = false;
      await fake.client.checkHealth();
      await pumpEventQueue();
      expect(fake.client.capabilities.externalSubtitleSearch, isFalse);

      allowed = true;
      await fake.client.checkHealth();
      await pumpEventQueue();
      expect(fake.client.capabilities.externalSubtitleSearch, isTrue);
    });

    test('never probes an Emby server', () async {
      final fake = clientAnswering(serverWithPlugin(), dialect: MediaBrowserDialect.emby);

      expect(await fake.client.probeRemoteSubtitleSearch(), isFalse);
      expect(fake.requests, isEmpty);
      expect(fake.client.capabilities.externalSubtitleSearch, isFalse);
    });
  });

  group('JellyfinClient as an ExternalSubtitleSearchClient', () {
    test('searches with the sheet language code and maps plugin rows onto the shared row type', () async {
      final fake = clientAnswering({
        '/Items/item-1/RemoteSearch/Subtitles/en': (_) => [
          {
            'Id': 'sub-1',
            'ProviderName': 'Open Subtitles',
            'Name': 'The Crow (2024) BLURAY',
            'Format': 'srt',
            'ThreeLetterISOLanguageName': 'eng',
          },
          {
            'Id': 'sub-2',
            'ProviderName': 'Open Subtitles',
            'Name': 'The.Crow.2024.1080p.WEBRip.x264-GalaxyRG',
            'Format': 'srt',
            'IsHashMatch': true,
            'HearingImpaired': true,
          },
        ],
      });

      final all = await fake.client.searchSubtitles('item-1', language: 'en');
      // Jellyfin's search takes no title, so the sheet's title field filters by
      // name, ignoring the punctuation release names use for spaces.
      final byTitle = await fake.client.searchSubtitles('item-1', language: 'en', title: 'The Crow 2024');
      final filtered = await fake.client.searchSubtitles('item-1', language: 'en', title: 'bluray');

      expect(all.map((r) => r.key), ['sub-1', 'sub-2']);
      expect(all.first.title, 'The Crow (2024) BLURAY');
      expect(all.first.displayTitle, 'Open Subtitles · SRT');
      expect(all.last.displayTitle, 'Open Subtitles · SRT · SDH');
      expect(all.last.perfectMatch, isTrue);
      // Downloading needs the language back; the client reads none from Jellyfin's rows.
      expect(all.map((r) => r.languageCode).toSet(), {'en'});
      expect(byTitle.map((r) => r.key), ['sub-1', 'sub-2']);
      expect(filtered.map((r) => r.key), ['sub-1']);
    });

    test('takes only a new file in the chosen language and format, and declines an ambiguous one', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      JellyfinApiCache.initialize(db);
      var after = <(String, String?, String)>[];
      Map<String, Object?> item(List<(String, String?, String)> files) => {
        'Id': 'item-1',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'item-1',
            'MediaStreams': [
              for (final (index, (file, language, codec)) in files.indexed)
                {
                  'Index': index,
                  'Type': 'Subtitle',
                  'Language': language,
                  'Codec': codec,
                  'IsExternal': true,
                  'IsForced': file.contains('.forced.'),
                  'Path': '/movies/$file',
                },
            ],
          },
        ],
      };
      const before = [('Film.en.srt', 'eng', 'subrip')];
      var downloaded = false;
      final fake = clientAnswering({
        '/Users/user-1/Items/item-1': (_) => item(downloaded ? after : before),
        '/Items/item-1/RemoteSearch/Subtitles/sub-1': (_) {
          downloaded = true;
          return http.Response('', 204);
        },
      });
      Future<String?> downloadThenFind(
        List<(String, String?, String)> listed, {
        String language = 'de',
        bool forced = false,
      }) async {
        downloaded = false;
        after = listed;
        await fake.client.downloadSubtitle(
          'item-1',
          SubtitleSearchResult(key: 'sub-1', codec: 'srt', languageCode: language, forced: forced),
        );
        final found = await fake.client.findDownloadedSubtitle('item-1', existingTrackIds: const {0});
        return found?.languageCode;
      }

      // Another client or Bazarr adds a French file in the same window: not ours.
      expect(
        await downloadThenFind([...before, ('Film.fr.srt', 'fre', 'subrip'), ('Film.de.srt', 'ger', 'subrip')]),
        'ger',
      );
      expect(await downloadThenFind([...before, ('Film.fr.srt', 'fre', 'subrip')]), isNull);
      expect(await downloadThenFind([...before, ('Film.de.forced.srt', 'ger', 'subrip')]), isNull, reason: 'forced');
      expect(await downloadThenFind([...before, ('Film.de.forced.srt', 'deu', 'subrip')], forced: true), 'deu');
      // Jellyfin 10.11+ keeps a language whose name has a dash as that name.
      expect(
        await downloadThenFind([...before, ('Film.el.srt', 'Greek, Modern (1453-)', 'subrip')], language: 'el'),
        'Greek, Modern (1453-)',
      );
      expect(
        await downloadThenFind([...before, ('Film.de.srt', 'Greek, Modern (1453-)', 'subrip')], language: 'el'),
        isNull,
      );
      // Jellyfin's own downloads always carry the language it read from the name.
      expect(await downloadThenFind([...before, ('Film.WEB-DL.srt', null, 'subrip')]), isNull);
      expect(await downloadThenFind([...before, ('Film.de.ass', 'ger', 'ass')]), isNull, reason: 'wrong format');
      expect(
        await downloadThenFind([...before, ('Film.de.srt', 'ger', 'subrip'), ('Film.de.0.srt', 'ger', 'subrip')]),
        isNull,
        reason: 'two candidates: decline rather than guess',
      );
    });

    test('finds the downloaded file by path, and leaves playback a fresh catalog', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      JellyfinApiCache.initialize(db);
      // Shape captured from Jellyfin 12.3 around a real download: the new file
      // joins the external streams and every later stream shifts by one.
      Map<String, Object?> item(List<String> files) => {
        'Id': 'item-1',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'item-1',
            'MediaStreams': [
              for (final (index, file) in files.indexed)
                {
                  'Index': index,
                  'Type': 'Subtitle',
                  'Language': file.contains('.de.') ? 'ger' : 'eng',
                  'Codec': 'subrip',
                  'IsExternal': true,
                  'Path': '/movies/$file',
                },
              {'Index': files.length, 'Type': 'Video'},
            ],
          },
        ],
      };
      var downloaded = false;
      final fake = clientAnswering({
        // The new file sorts first, so it takes index 0 and the old one moves to 1.
        '/Users/user-1/Items/item-1': (_) => downloaded ? item(['Film.de.srt', 'Film.en.srt']) : item(['Film.en.srt']),
        '/Items/item-1/RemoteSearch/Subtitles/sub-1': (_) {
          downloaded = true;
          return http.Response('', 204);
        },
      });

      expect(await fake.client.findDownloadedSubtitle('item-1', existingTrackIds: const {0}), isNull);
      final ok = await fake.client.downloadSubtitle(
        'item-1',
        const SubtitleSearchResult(key: 'sub-1', codec: 'srt', languageCode: 'de'),
      );
      final found = await fake.client.findDownloadedSubtitle('item-1', existingTrackIds: const {0});

      expect(ok, isTrue);
      expect(
        fake.requests.where((r) => r.method == 'POST').single.url.path,
        '/Items/item-1/RemoteSearch/Subtitles/sub-1',
      );
      expect(found?.id, 0, reason: 'an id diff would have picked the old file, now at index 1');
      // Playback reads the item cache-first; the poll must have refreshed it,
      // or the reload would resolve the pick against the old numbering.
      final cached = await fake.client.fetchItemFreshCacheFirst('item-1');
      final streams = ((cached!.raw as Map)['MediaSources'] as List).single['MediaStreams'] as List;
      expect(streams.map((s) => s['Path']), contains('/movies/Film.de.srt'));
    });
  });
}
