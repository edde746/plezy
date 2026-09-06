import 'dart:async';
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
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_session_store.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/seerr_request_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/theme.dart';

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Parks a mock response behind a completer the test releases later, so a
/// detail load can be completed out of order with the sheet's selections.
Future<http.Response> _gate(List<Completer<http.Response>> pending) {
  final completer = Completer<http.Response>();
  pending.add(completer);
  return completer.future;
}

/// The advanced-section spinner keeps the frame scheduler busy, so tests with
/// a detail load in flight step frames instead of settling.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Map<String, dynamic> _radarrServer({
  required int id,
  required String name,
  int profileId = 6,
  String folder = '/movies',
}) => {
  'id': id,
  'name': name,
  'is4k': false,
  'isDefault': id == 0,
  'activeProfileId': profileId,
  'activeDirectory': folder,
};

Map<String, dynamic> _radarrDetail(Map<String, dynamic> server, {required String profileName}) => {
  'server': server,
  'profiles': [
    {'id': server['activeProfileId'], 'name': profileName},
  ],
  'rootFolders': [
    {'id': 1, 'path': server['activeDirectory']},
  ],
};

Future<void> _pickServer(WidgetTester tester, String name) async {
  await tester.tap(find.text('Destination server'));
  await _pumpFrames(tester);
  await tester.tap(find.text(name));
  await _pumpFrames(tester);
}

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

/// Keep widget persistence in its own fake-async zone. The real store's static
/// FIFO retains futures from earlier widget zones that no longer get pumped;
/// `runAsync` cannot drain those zones. Provider tests cover the real FIFO.
class _MemorySessionStore extends SeerrSessionStore {
  final _sessions = <String, SeerrSession>{};

  @override
  Future<SeerrSession?> load(String userUuid) async => _sessions[userUuid];

  @override
  Future<void> save(String userUuid, SeerrSession session) async {
    _sessions[userUuid] = session;
  }

  @override
  Future<void> clear(String userUuid) async {
    _sessions.remove(userUuid);
  }
}

Future<SeerrAccountProvider> _account(MockClient mock, int permissions) async {
  final account = SeerrAccountProvider(
    store: _MemorySessionStore(),
    authService: SeerrAuthService(httpClientFactory: () => mock),
  );
  addTearDown(account.dispose);
  await account.adoptSession(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.quickConnect,
      identifier: 'alice',
      secret: '',
      cookie: 'cookie',
      userId: 1,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      createdAt: 0,
    ),
  );
  return account;
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
  SeerrAccountProvider? account,
}) async {
  final app = MaterialApp(
    theme: ThemeData(extensions: const [testMonoTokens]),
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
                          onPressed: () =>
                              showSeerrRequestSheet(context, source: source, kind: kind, tmdbId: tmdbId, title: title),
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
  );
  await tester.pumpWidget(
    account == null ? app : ChangeNotifierProvider<SeerrAccountProvider>.value(value: account, child: app),
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

  testWidgets('a real handler denial reconciles revoked authority and closes the hosted sheet', (tester) async {
    // Permission, quota and blocklist errors use the same handler response.
    // The raw authority read, not message matching, closes the revoked surface.
    final paths = <String>[];
    final mock = MockClient((request) async {
      paths.add(request.url.path);
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/603':
          return _json({
            'id': 603,
            'title': 'The Matrix',
            'mediaInfo': {'status': 1},
          });
        case '/api/v1/request':
          return _json({'message': 'You do not have permission to make this request.'}, status: 403);
        case '/api/v1/auth/me':
          return _json({'id': 1, 'displayName': 'Alice', 'permissions': 0});
      }
      fail('unexpected request ${request.url.path}');
    });
    final account = await _account(mock, SeerrPermission.request);
    final source = SeerrCatalogSource(account.catalogClient!);
    addTearDown(source.dispose);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 603, title: 'The Matrix', account: account);
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();

    expect(paths.sublist(paths.length - 2), ['/api/v1/request', '/api/v1/auth/me']);
    expect(find.byType(SeerrRequestSheet), findsNothing);
    expect(paths.where((path) => path == '/api/v1/request'), hasLength(1));
    expect(account.isConnected, isTrue);
    expect(account.permissions, 0);
    expect(find.text(t.seerr.permissionRevoked), findsOneWidget);
    expect(source.client.session.permissions, 0);
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

  testWidgets('permission changes the account adopts while open reshape and then close the sheet', (tester) async {
    // The provider adopts a refreshed mask in place (no client rebuild):
    // an advanced grant must fetch the servers the initial load skipped,
    // and losing the request permission must close the sheet with the
    // reason surfaced on the host.
    var permissions = SeerrPermission.request;
    final paths = <String>[];
    final mock = MockClient((request) async {
      paths.add(request.url.path);
      switch (request.url.path) {
        case '/api/v1/auth/me':
          return _json({'id': 1, 'displayName': 'Alice', 'permissions': permissions});
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/service/radarr':
          return _json([_radarrServer(id: 0, name: 'Radarr Main'), _radarrServer(id: 1, name: 'Radarr Alt')]);
        case '/api/v1/service/radarr/0':
          return _json(_radarrDetail(_radarrServer(id: 0, name: 'Radarr Main'), profileName: '1080p'));
      }
      fail('unexpected request ${request.url.path}');
    });
    final account = await _account(mock, permissions);
    final source = SeerrCatalogSource(account.catalogClient!);
    addTearDown(source.dispose);

    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club', account: account);
    expect(paths, isNot(contains('/api/v1/service/radarr')));
    expect(find.text('Destination server'), findsNothing);

    permissions = SeerrPermission.request | SeerrPermission.requestAdvanced;
    await account.refreshUser();
    await tester.pumpAndSettle();

    expect(find.text('Destination server'), findsOneWidget);
    expect(find.text('Radarr Main'), findsOneWidget);

    permissions = 0;
    await account.refreshUser();
    await tester.pumpAndSettle();

    expect(find.byType(SeerrRequestSheet), findsNothing);
    expect(find.text(t.seerr.permissionRevoked), findsOneWidget);
  });

  testWidgets('a quota denial keeps the modal sheet usable and shows the original error', (tester) async {
    var posts = 0;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/auth/me':
          return _json({'id': 1, 'permissions': SeerrPermission.request});
        case '/api/v1/request':
          posts++;
          return _json({'message': 'Request quota exceeded'}, status: 403);
      }
      fail('no login or replay expected');
    });
    final source = _source(mock);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSeerrRequestSheet(
                context,
                source: source,
                kind: MediaKind.movie,
                tmdbId: 550,
                title: 'Fight Club',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.byType(SeerrRequestSheet), findsOneWidget);
    expect(find.text('Request quota exceeded'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Request')).onPressed, isNotNull);
  });

  testWidgets('a replaced account silently closes its old sheet and ignores the late submission', (tester) async {
    final post = Completer<http.Response>();
    final mock = MockClient((request) async {
      return switch (request.url.path) {
        '/api/v1/settings/public' => _json(_publicSettings()),
        '/api/v1/movie/550' => _json({'id': 550, 'title': 'Fight Club'}),
        '/api/v1/request' => post.future,
        _ => fail('unexpected ${request.url.path}'),
      };
    });
    final account = await _account(mock, SeerrPermission.request);
    final source = SeerrCatalogSource(account.catalogClient!);
    addTearDown(source.dispose);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club', account: account);
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await _pumpFrames(tester);
    final replacement = account.session!.copyWith(cookie: 'new-account');
    await account.adoptSession(replacement);
    await tester.pumpAndSettle();
    expect(find.byType(SeerrRequestSheet), findsNothing);
    post.complete(_json({'id': 11, 'status': 2}, status: 201));
    await tester.pumpAndSettle();
    expect(find.text(t.seerr.requestSubmitted), findsNothing);
    expect(find.text(t.seerr.permissionRevoked), findsNothing);
    expect(find.text('request'), findsOneWidget);
    expect(account.session?.cookie, 'new-account');
  });

  testWidgets('a revoke and regrant discards the older advanced server list', (tester) async {
    var permissions = SeerrPermission.request;
    final lists = <Completer<http.Response>>[];
    Map<String, dynamic>? posted;
    final fresh = _radarrServer(id: 1, name: 'Current', profileId: 9, folder: '/current');
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/auth/me':
          return _json({'id': 1, 'permissions': permissions});
        case '/api/v1/service/radarr':
          return _gate(lists);
        case '/api/v1/service/radarr/1':
          return _json(_radarrDetail(fresh, profileName: 'Current'));
        case '/api/v1/request':
          posted = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('stale server must not be selected: ${request.url.path}');
    });
    final account = await _account(mock, permissions);
    final source = SeerrCatalogSource(account.catalogClient!);
    addTearDown(source.dispose);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club', account: account);
    permissions |= SeerrPermission.requestAdvanced;
    await account.refreshUser();
    await _pumpFrames(tester);
    permissions = SeerrPermission.request;
    await account.refreshUser();
    await _pumpFrames(tester);
    permissions |= SeerrPermission.requestAdvanced;
    await account.refreshUser();
    await _pumpFrames(tester);
    expect(lists, hasLength(2));
    permissions |= SeerrPermission.request4k;
    await account.refreshUser();
    await _pumpFrames(tester);
    lists[1].complete(_json([fresh]));
    await tester.pumpAndSettle();
    lists[0].complete(_json([_radarrServer(id: 0, name: 'Stale')]));
    await tester.pumpAndSettle();
    expect(find.text('Current (Default)'), findsOneWidget);
    expect(find.text('Stale'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();
    expect(posted, {
      'mediaType': 'movie',
      'mediaId': 550,
      'is4k': false,
      'serverId': 1,
      'profileId': 9,
      'rootFolder': '/current',
    });
  });

  testWidgets('a focused 4K option revokes safely and a later grant does not restore its old selection', (
    tester,
  ) async {
    var permissions = SeerrPermission.request | SeerrPermission.request4k;
    Map<String, dynamic>? posted;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json({..._publicSettings(), 'movie4kEnabled': true});
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/auth/me':
          return _json({'id': 1, 'permissions': permissions});
        case '/api/v1/request':
          posted = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('unexpected ${request.url.path}');
    });
    final account = await _account(mock, permissions);
    final source = SeerrCatalogSource(account.catalogClient!);
    addTearDown(source.dispose);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club', account: account);
    await tester.tap(find.text('Request in 4K'));
    Focus.of(tester.element(find.text('Request in 4K'))).requestFocus();
    await tester.pumpAndSettle();
    permissions = SeerrPermission.request;
    await account.refreshUser();
    await tester.pumpAndSettle();
    expect(find.text('Request in 4K'), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'seerr_request_submit');
    permissions |= SeerrPermission.request4k;
    await account.refreshUser();
    await tester.pumpAndSettle();
    expect(find.text('Request in 4K'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'seerr_request_submit');
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();
    expect(posted, {'mediaType': 'movie', 'mediaId': 550, 'is4k': false});
  });

  testWidgets('a revoked request closes a modal sheet without popping its underlying screen', (tester) async {
    final mock = MockClient(
      (request) async => switch (request.url.path) {
        '/api/v1/settings/public' => _json(_publicSettings()),
        '/api/v1/movie/550' => _json({'id': 550, 'title': 'Fight Club'}),
        '/api/v1/auth/me' => _json({'id': 1, 'permissions': 0}),
        '/api/v1/request' => _json({'message': 'Request forbidden'}, status: 403),
        _ => fail('unexpected ${request.url.path}'),
      },
    );
    final source = _source(mock);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSeerrRequestSheet(
                context,
                source: source,
                kind: MediaKind.movie,
                tmdbId: 550,
                title: 'Fight Club',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();
    expect(find.byType(SeerrRequestSheet), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(find.text(t.seerr.permissionRevoked), findsOneWidget);
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

  testWidgets('a slow detail load for a server the user left never replaces the current server', (tester) async {
    Map<String, dynamic>? postedBody;
    final pendingAlt = <Completer<http.Response>>[];
    final main = _radarrServer(id: 0, name: 'Radarr Main');
    final alt = _radarrServer(id: 1, name: 'Radarr Alt', profileId: 8, folder: '/alt');
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/service/radarr':
          return _json([main, alt]);
        case '/api/v1/service/radarr/0':
          return _json(_radarrDetail(main, profileName: '1080p'));
        case '/api/v1/service/radarr/1':
          return _gate(pendingAlt);
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock, permissions: SeerrPermission.request | SeerrPermission.requestAdvanced);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club');
    expect(find.text('1080p (Default)'), findsOneWidget);

    await _pickServer(tester, 'Radarr Alt');
    expect(find.byType(LoadingIndicatorBox), findsOneWidget);
    expect(find.text('1080p (Default)'), findsNothing);

    await _pickServer(tester, 'Radarr Main');
    expect(find.byType(LoadingIndicatorBox), findsNothing);
    expect(find.text('1080p (Default)'), findsOneWidget);

    pendingAlt.single.complete(_json(_radarrDetail(alt, profileName: 'Alt 720p')));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingIndicatorBox), findsNothing);
    expect(find.text('1080p (Default)'), findsOneWidget);
    expect(find.text('Alt 720p (Default)'), findsNothing);
    expect(find.text('/alt (Default)'), findsNothing);

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

  testWidgets('re-selecting the same server applies only the newest detail response', (tester) async {
    Map<String, dynamic>? postedBody;
    final pendingMain = <Completer<http.Response>>[];
    var mainCalls = 0;
    final main = _radarrServer(id: 0, name: 'Radarr Main');
    final alt = _radarrServer(id: 1, name: 'Radarr Alt', profileId: 8, folder: '/alt');
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/service/radarr':
          return _json([main, alt]);
        case '/api/v1/service/radarr/0':
          // The initial load answers at once; every re-selection is gated.
          if (mainCalls++ == 0) return _json(_radarrDetail(main, profileName: 'Initial'));
          return _gate(pendingMain);
        case '/api/v1/service/radarr/1':
          return _json(_radarrDetail(alt, profileName: 'Alt 720p'));
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(mock, permissions: SeerrPermission.request | SeerrPermission.requestAdvanced);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club');
    expect(find.text('Initial (Default)'), findsOneWidget);

    // Main -> Alt -> Main -> Alt -> Main: two Main loads in flight.
    await _pickServer(tester, 'Radarr Alt');
    await _pickServer(tester, 'Radarr Main');
    await _pickServer(tester, 'Radarr Alt');
    await _pickServer(tester, 'Radarr Main');
    expect(pendingMain, hasLength(2));
    expect(find.byType(LoadingIndicatorBox), findsOneWidget);

    // The first (abandoned) load lands: same server id, but it must neither
    // clear the spinner nor install its detail over the live load.
    pendingMain[0].complete(_json(_radarrDetail(main, profileName: 'Stale')));
    await _pumpFrames(tester);
    expect(find.byType(LoadingIndicatorBox), findsOneWidget);
    expect(find.text('Stale (Default)'), findsNothing);

    pendingMain[1].complete(_json(_radarrDetail(main, profileName: 'Fresh')));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingIndicatorBox), findsNothing);
    expect(find.text('Fresh (Default)'), findsOneWidget);
    expect(find.text('Stale (Default)'), findsNothing);

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

  testWidgets('switching to a variant without servers drops the in-flight detail load', (tester) async {
    Map<String, dynamic>? postedBody;
    final pendingMain = <Completer<http.Response>>[];
    var mainCalls = 0;
    final main = _radarrServer(id: 0, name: 'Radarr Main');
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json({..._publicSettings(), 'movie4kEnabled': true});
        case '/api/v1/movie/550':
          return _json({'id': 550, 'title': 'Fight Club'});
        case '/api/v1/service/radarr':
          return _json([main]);
        case '/api/v1/service/radarr/0':
          if (mainCalls++ == 0) return _json(_radarrDetail(main, profileName: '1080p'));
          return _gate(pendingMain);
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 11, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(
      mock,
      permissions:
          SeerrPermission.request |
          SeerrPermission.requestAdvanced |
          SeerrPermission.request4k |
          SeerrPermission.request4kMovie,
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.movie, tmdbId: 550, title: 'Fight Club');
    expect(find.text('1080p (Default)'), findsOneWidget);

    // 4K on (no 4K instance: nothing selected), off again: a fresh load.
    await tester.tap(find.text('Request in 4K'));
    await tester.pumpAndSettle();
    expect(find.text('Advanced'), findsNothing);
    await tester.tap(find.text('Request in 4K'));
    await _pumpFrames(tester);
    expect(pendingMain, hasLength(1));
    expect(find.byType(LoadingIndicatorBox), findsOneWidget);

    // Back to 4K while that load is in flight: no spinner anywhere, and the
    // late response must not resurrect the non-4K destination.
    await tester.tap(find.text('Request in 4K'));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingIndicatorBox), findsNothing);
    pendingMain[0].complete(_json(_radarrDetail(main, profileName: '1080p')));
    await tester.pumpAndSettle();
    expect(find.byType(LoadingIndicatorBox), findsNothing);
    expect(find.text('Advanced'), findsNothing);
    expect(find.text('1080p (Default)'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Request'));
    await tester.pumpAndSettle();
    expect(postedBody, {'mediaType': 'movie', 'mediaId': 550, 'is4k': true});
  });

  testWidgets('tags the user cleared stay empty when an older detail load lands', (tester) async {
    Map<String, dynamic>? postedBody;
    final pendingMain = <Completer<http.Response>>[];
    var mainCalls = 0;
    final mock = MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json({..._publicSettings(), 'series4kEnabled': true});
        case '/api/v1/tv/46260':
          return _json(_tvDetails(anime: false));
        case '/api/v1/service/sonarr':
          return _json([_sonarrServer()]);
        case '/api/v1/service/sonarr/0':
          if (mainCalls++ == 0) return _json(_sonarrDetail());
          return _gate(pendingMain);
        case '/api/v1/request':
          postedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 12, 'status': 2}, status: 201);
      }
      fail('unexpected request ${request.url.path}');
    });
    final source = _source(
      mock,
      permissions:
          SeerrPermission.request |
          SeerrPermission.requestAdvanced |
          SeerrPermission.request4k |
          SeerrPermission.request4kTv,
    );

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await _pumpSheet(tester, source: source, kind: MediaKind.show, tmdbId: 46260, title: 'Naruto');
    expect(find.text('tv'), findsOneWidget);

    // Two 4K round-trips leave two loads for the same Sonarr instance in
    // flight; only the second is the live one.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Request in 4K'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Request in 4K'));
      await _pumpFrames(tester);
    }
    expect(pendingMain, hasLength(2));
    pendingMain[1].complete(_json(_sonarrDetail()));
    await tester.pumpAndSettle();
    expect(find.text('tv'), findsOneWidget);

    // The user clears the instance's default tag.
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'tv'));
    await tester.pumpAndSettle();
    expect(find.text('No tags'), findsOneWidget);

    // The abandoned load lands with the default tag: the edit must survive.
    pendingMain[0].complete(_json(_sonarrDetail()));
    await tester.pumpAndSettle();
    expect(find.text('No tags'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'tv')).value, isFalse);

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
      'profileId': 1,
      'rootFolder': '/tv',
      'languageProfileId': 1,
      'tags': <int>[],
    });
  });
}
