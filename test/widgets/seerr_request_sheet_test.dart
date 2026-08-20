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

Map<String, dynamic> _publicSettings() => {
  'initialized': true,
  'localLogin': true,
  'mediaServerLogin': true,
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
    // the instance defaults.
    expect(find.text('Destination server'), findsNothing);
    expect(find.text('Quality profile'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);

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
}
