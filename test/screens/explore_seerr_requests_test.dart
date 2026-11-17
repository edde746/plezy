import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/screens/explore_screen.dart';
import 'package:plezy/screens/hub_detail_screen.dart';
import 'package:plezy/screens/seerr_requests_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

class _SeerrSources extends CatalogSourcesProvider {
  _SeerrSources(this.seerr);

  final SeerrCatalogSource seerr;

  @override
  List<CatalogSource> get connectedSources => [seerr];

  @override
  CatalogSource? get activeSource => seerr;

  @override
  SeerrCatalogSource? get seerrSource => seerr;
}

/// Seerr with one title per discover row and the given requests.
MockClient _seerr({required List<Map<String, Object?>> requests, List<String>? listCalls}) =>
    MockClient((request) async {
      final path = request.url.path.substring('/api/v1'.length);
      Map<String, Object?> discover(int id, String title) => {
        'page': 1,
        'totalPages': 1,
        'results': [
          {'id': id, 'mediaType': 'movie', 'title': title},
        ],
      };
      switch (path) {
        case '/settings/public':
          return _json({'message': 'Not Found'}, status: 404);
        case '/discover/trending':
          return _json(discover(901, 'Trending Title'));
        case '/discover/movies':
          return _json(discover(902, 'Popular Movie'));
        case '/discover/tv':
        case '/discover/movies/upcoming':
        case '/discover/tv/upcoming':
          return _json({'page': 1, 'totalPages': 1, 'results': <Object>[]});
        case '/request':
          listCalls?.add(request.url.query);
          return _json({
            'pageInfo': {'page': 1, 'pages': 1, 'pageSize': 25, 'results': requests.length},
            'results': requests,
          });
      }
      if (path.startsWith('/movie/')) {
        final id = int.parse(request.url.pathSegments.last);
        return _json({'id': id, 'title': 'Requested $id'});
      }
      fail('unexpected ${request.method} ${request.url}');
    });

Map<String, Object?> _request(int id, int tmdbId, {int status = 1}) => {
  'id': id,
  'status': status,
  'is4k': false,
  'type': 'movie',
  'createdAt': '2026-11-01T10:00:00.000Z',
  'media': {'id': 50 + id, 'mediaType': 'movie', 'tmdbId': tmdbId, 'status': 1, 'status4k': 1},
  'requestedBy': {'id': 1},
};

Future<void> _pumpExplore(WidgetTester tester, MockClient mock) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 1,
      permissions: SeerrPermission.request,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      product: SeerrProduct.jellyseerr,
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: mock,
  );
  final source = SeerrCatalogSource(client);
  final sources = _SeerrSources(source);
  final explore = ExploreProvider(sources);
  addTearDown(explore.dispose);
  addTearDown(sources.dispose);
  addTearDown(source.dispose);
  addTearDown(client.dispose);

  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
          ChangeNotifierProvider<ExploreProvider>.value(value: explore),
        ],
        child: MaterialApp(theme: monoTheme(MonoPalette.dark), home: const ExploreScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('My requests leads the Seerr Explore rows, with each card badged by request status', (tester) async {
    final listCalls = <String>[];
    await _pumpExplore(tester, _seerr(requests: [_request(2, 20), _request(1, 10, status: 3)], listCalls: listCalls));

    expect(listCalls, hasLength(1));
    expect(Uri.splitQueryString(listCalls.single)['requestedBy'], '1');

    final mine = find.text(t.seerr.requests.myRequests);
    expect(mine, findsOneWidget);
    expect(find.text(t.explore.totalResults(n: 2)), findsOneWidget);
    expect(
      tester.getTopLeft(mine).dy,
      lessThan(tester.getTopLeft(find.text(t.explore.rows.trending)).dy),
      reason: "the user's own shelf sits above the discover rows",
    );
    expect(find.text('Requested 20'), findsAtLeast(1));
    expect(find.text('Requested 10'), findsAtLeast(1));
    expect(find.text(t.explore.badge.pendingApproval), findsOneWidget);
    expect(find.text(t.explore.badge.declined), findsOneWidget);
  });

  testWidgets('View All on the shelf opens the requests list, not the generic grid', (tester) async {
    await _pumpExplore(tester, _seerr(requests: [_request(2, 20)]));

    await tester.tap(find.text(t.seerr.requests.myRequests));
    await tester.pumpAndSettle();

    expect(find.byType(SeerrRequestsScreen), findsOneWidget);
    expect(find.byType(HubDetailScreen), findsNothing);
    expect(find.byKey(const ValueKey('seerr_request_2')), findsOneWidget);
  });

  testWidgets('without requests there is no shelf and the discover rows stand as before', (tester) async {
    await _pumpExplore(tester, _seerr(requests: const []));

    expect(find.text(t.seerr.requests.myRequests), findsNothing);
    expect(find.text(t.explore.rows.trending), findsOneWidget);
    expect(find.text('Trending Title'), findsAtLeast(1));
  });

  testWidgets('the TV rail carries the shelf too', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _pumpExplore(tester, _seerr(requests: [_request(2, 20)]));

    expect(find.text(t.seerr.requests.myRequests), findsAtLeast(1));
    expect(find.text('Requested 20'), findsAtLeast(1));
  });
}
