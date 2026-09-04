import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/seerr_request_sheet.dart';

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

SeerrCatalogSource _source(MockClient mock, {int permissions = SeerrPermission.request}) {
  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 1,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: mock,
  );
  final source = SeerrCatalogSource(client);
  addTearDown(() {
    source.dispose();
    client.dispose();
  });
  return source;
}

Map<String, dynamic> _publicSettings({int? mediaServerType}) => {
  'initialized': true,
  'localLogin': true,
  'mediaServerLogin': true,
  'mediaServerType': ?mediaServerType,
  'movie4kEnabled': false,
  'series4kEnabled': false,
  'partialRequestsEnabled': true,
};

/// Mirrors production: the sheet is opened via [showSeerrRequestSheet] on a
/// pushed route that hosts its own [OverlaySheetHost] (like
/// CatalogItemDetailScreen), so the sheet renders in the host's stack rather
/// than as a route of its own.
Future<void> _pumpSheet(
  WidgetTester tester, {
  required SeerrCatalogSource source,
  required MediaKind kind,
  required int tmdbId,
  required String title,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OverlaySheetHost(
                    canPop: true,
                    child: Scaffold(
                      body: Builder(
                        builder: (context) => Center(
                          child: TextButton(
                            onPressed: () => showSeerrRequestSheet(
                              context,
                              source: source,
                              kind: kind,
                              tmdbId: tmdbId,
                              title: title,
                            ),
                            child: const Text('request'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('request'));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _sonarrServer() => {
  'id': 0,
  'name': 'Sonarr Main',
  'is4k': false,
  'isDefault': true,
  'activeProfileId': 1,
  'activeDirectory': '/tv',
  'activeLanguageProfileId': 1,
  'activeAnimeProfileId': 2,
  'activeAnimeDirectory': '/anime',
  'activeAnimeLanguageProfileId': 2,
  'activeTags': [7],
  'activeAnimeTags': [5],
};

Map<String, dynamic> _sonarrDetail() => {
  'server': _sonarrServer(),
  'profiles': [
    {'id': 1, 'name': 'TV'},
    {'id': 2, 'name': 'Anime'},
  ],
  'rootFolders': [
    {'id': 1, 'path': '/tv'},
    {'id': 2, 'path': '/anime'},
  ],
  'languageProfiles': [
    {'id': 1, 'name': 'English'},
    {'id': 2, 'name': 'Japanese'},
  ],
  'tags': [
    {'id': 5, 'label': 'anime'},
    {'id': 7, 'label': 'tv'},
    {'id': 9, 'label': 'uhd'},
  ],
};

Map<String, dynamic> _tvDetails({required bool anime}) => {
  'id': 46260,
  'name': 'Naruto',
  'keywords': [
    {'id': 9715, 'name': 'superhero'},
    if (anime) {'id': 210024, 'name': 'anime'},
  ],
  'seasons': [
    {'seasonNumber': 1, 'episodeCount': 57, 'name': 'Season 1'},
  ],
  'mediaInfo': {'status': 1, 'status4k': 1, 'seasons': [], 'requests': []},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('TV: disables unavailable seasons, drops specials, posts selected seasons', (tester) async {
    Map<String, dynamic>? postedBody;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/tv/1396':
          return _json({
            'id': 1396,
            'name': 'Breaking Bad',
            'seasons': [
              {'seasonNumber': 0, 'episodeCount': 5, 'name': 'Specials'},
              {'seasonNumber': 1, 'episodeCount': 7, 'name': 'Season 1'},
              {'seasonNumber': 2, 'episodeCount': 13, 'name': 'Season 2'},
            ],
            'mediaInfo': {
              'status': 4,
              'status4k': 1,
              'seasons': [
                {'seasonNumber': 1, 'status': 5, 'status4k': 1},
              ],
              'requests': [],
            },
          });
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 10, 'status': 1}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.show, tmdbId: 1396, title: 'Breaking Bad');

    expect(find.text('Specials'), findsNothing);
    expect(find.text('Season 1'), findsOneWidget);
    expect(find.text('Season 2'), findsOneWidget);
    // Season 1 is available on the server: checked, disabled, labeled.
    expect(find.text('Available'), findsOneWidget);
    final season1 = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('Season 1'), matching: find.byType(CheckboxListTile)),
    );
    expect(season1.onChanged, isNull);
    expect(season1.value, isTrue);

    // Nothing selected yet: submit disabled.
    final submitFinder = find.widgetWithText(FilledButton, 'Request');
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);
    final focusableSubmit = tester.widget<FocusableButton>(
      find.ancestor(of: submitFinder, matching: find.byType(FocusableButton)),
    );
    expect(focusableSubmit.useBackgroundFocus, isTrue);

    await tester.tap(find.text('Season 2'));
    await tester.pump();
    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);

    final season2 = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('Season 2'), matching: find.byType(CheckboxListTile)),
    );
    season2.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'seerr_request_submit');

    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(postedBody, {
      'mediaType': 'tv',
      'mediaId': 1396,
      'seasons': [2],
      'is4k': false,
    });
    // The sheet closed but the hosting screen must survive the submit —
    // a bare Navigator.pop here would pop the whole detail route.
    expect(find.text('Season 2'), findsNothing);
    expect(find.text('request'), findsOneWidget);
    expect(find.text('Request submitted'), findsOneWidget);
  });

  testWidgets('movie that is already available offers nothing to request', (tester) async {
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {'status': 5, 'status4k': 1},
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    expect(find.text('Available'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('failed and completed requests do not block re-requesting a movie', (tester) async {
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {
              'status': 1,
              'requests': [
                {'id': 1, 'status': 4, 'is4k': false},
                {'id': 2, 'status': 5, 'is4k': false},
              ],
            },
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    // Only pending/approved requests hold a claim; a failed arr push or a
    // settled request must leave the title re-requestable.
    final submit = find.widgetWithText(FilledButton, 'Request');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(find.text('Requested'), findsNothing);
  });

  testWidgets('a failed request unblocks a stale Processing status when nothing live backs it', (tester) async {
    // Seerr marks the request Failed on arr-push failure but can leave the
    // media status Processing; that stale status must not keep blocking.
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {
              'status': 3,
              'requests': [
                {'id': 1, 'status': 4, 'is4k': false},
              ],
            },
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    expect(find.text('Processing'), findsNothing);
    final submit = find.widgetWithText(FilledButton, 'Request');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('a live approved retry keeps a failed title blocked as Processing', (tester) async {
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {
              'status': 3,
              'requests': [
                {'id': 1, 'status': 4, 'is4k': false},
                {'id': 2, 'status': 2, 'is4k': false},
              ],
            },
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    expect(find.text('Processing'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a Jellyseerr blocklisted movie offers nothing to request', (tester) async {
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          // mediaServerType present -> Jellyseerr -> status 6 = BLOCKLISTED.
          return _json(_publicSettings(mediaServerType: SeerrMediaServerType.jellyfin));
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {'status': 6},
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    expect(find.text('Blocklisted'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the settings fetch upgrades a legacy session so Overseerr code 7 stays requestable', (tester) async {
    // The session starts without a product (legacy persist); code 7 would be
    // conservatively blocked. The sheet's settings fetch resolves the
    // instance as Overseerr (no mediaServerType), where 7 is meaningless,
    // so the title must offer a request.
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {'status': 7},
          });
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix');

    expect(find.text('Blocklisted'), findsNothing);
    final submit = find.widgetWithText(FilledButton, 'Request');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
  });

  testWidgets('advanced permission loads servers and sends destination overrides', (tester) async {
    Map<String, dynamic>? postedBody;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/service/radarr':
          return _json([
            {
              'id': 0,
              'name': 'Radarr Main',
              'is4k': false,
              'isDefault': true,
              'activeProfileId': 6,
              'activeDirectory': '/movies',
            },
          ]);
        case '/api/v1/service/radarr/0':
          return _json({
            'server': {
              'id': 0,
              'name': 'Radarr Main',
              'is4k': false,
              'isDefault': true,
              'activeProfileId': 6,
              'activeDirectory': '/movies',
            },
            'profiles': [
              {'id': 6, 'name': '1080p'},
              {'id': 7, 'name': '4K Remux'},
            ],
            'rootFolders': [
              {'id': 1, 'path': '/movies'},
            ],
          });
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock, permissions: SeerrPermission.admin);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club');

    // Single server: no server picker, but profile/folder pickers show
    // the instance defaults, marked the way Seerr's web requester does.
    expect(find.text('Destination server'), findsNothing);
    expect(find.text('Quality profile'), findsOneWidget);
    expect(find.text('1080p (Default)'), findsOneWidget);
    // No `tags` in the detail: nothing to pick, nothing to override.
    expect(find.text('Tags'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();

    expect(postedBody, {
      'mediaType': 'movie',
      'mediaId': 550,
      'is4k': false,
      'serverId': 0,
      'profileId': 6,
      'rootFolder': '/movies',
    });
  });

  testWidgets('an anime series seeds the advanced pickers from the Sonarr anime defaults', (tester) async {
    Map<String, dynamic>? postedBody;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/tv/46260':
          return _json(_tvDetails(anime: true));
        case '/api/v1/service/sonarr':
          // The list endpoint reports no usable tags (`activeTags: []`).
          return _json([
            {..._sonarrServer(), 'activeTags': <int>[]}..remove('activeAnimeTags'),
          ]);
        case '/api/v1/service/sonarr/0':
          return _json(_sonarrDetail());
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 12, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock, permissions: SeerrPermission.request | SeerrPermission.requestAdvanced);

    // Season, 4K-less advanced pickers, tags, note, and the button need
    // more than the default 600px test viewport's 75% sheet cap.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.show, tmdbId: 46260, title: 'Naruto');

    expect(find.text('Anime (Default)'), findsOneWidget);
    expect(find.text('/anime (Default)'), findsOneWidget);
    expect(find.text('Japanese (Default)'), findsOneWidget);
    expect(find.text('anime'), findsOneWidget);
    expect(find.text('This series is an anime.'), findsOneWidget);

    await tester.tap(find.text('Season 1'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();

    expect(postedBody, {
      'mediaType': 'tv',
      'mediaId': 46260,
      'seasons': [1],
      'is4k': false,
      'serverId': 0,
      'profileId': 2,
      'rootFolder': '/anime',
      'languageProfileId': 2,
      'tags': [5],
    });
  });

  testWidgets('a non-anime series keeps the standard defaults and lets the user edit tags', (tester) async {
    Map<String, dynamic>? postedBody;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/tv/46260':
          return _json(_tvDetails(anime: false));
        case '/api/v1/service/sonarr':
          return _json([_sonarrServer()]);
        case '/api/v1/service/sonarr/0':
          return _json(_sonarrDetail());
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 12, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock, permissions: SeerrPermission.request | SeerrPermission.requestAdvanced);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.show, tmdbId: 46260, title: 'Naruto');

    expect(find.text('TV (Default)'), findsOneWidget);
    expect(find.text('/tv (Default)'), findsOneWidget);
    expect(find.text('This series is an anime.'), findsNothing);
    expect(find.text('tv'), findsOneWidget);
    // Collapsed until the row is tapped: only the season checkboxes exist.
    expect(find.byType(CheckboxListTile), findsNWidgets(2));

    // Selections made before the tag list opens must survive it: the tag
    // list is inline, so no page swap can rebuild the sheet from scratch.
    await tester.tap(find.text('Season 1'));
    await tester.pump();

    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNWidgets(5));
    await tester.tap(find.text('uhd'));
    await tester.pump(); // summary is now "tv, uhd", so 'tv' names only the row
    await tester.tap(find.text('tv'));
    await tester.pumpAndSettle();
    // Summary reflects the edit ('tv' now names only the deselected row).
    expect(find.text('uhd'), findsNWidgets(2));
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('uhd'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();

    expect(postedBody, {
      'mediaType': 'tv',
      'mediaId': 46260,
      'seasons': [1],
      'is4k': false,
      'serverId': 0,
      'profileId': 1,
      'rootFolder': '/tv',
      'languageProfileId': 1,
      'tags': [9],
    });
  });
}
