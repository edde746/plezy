import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/screens/hub_detail_screen.dart';
import 'package:plezy/screens/seerr_requests_screen.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/catalog/seerr_requests.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

const _me = 1;

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _request({
  required int id,
  required int tmdbId,
  String type = 'movie',
  int status = 1,
  bool is4k = false,
  int requestedBy = _me,
  int mediaStatus = 1,
  int? serviceId,
  bool? canRemove,
}) => {
  'id': id,
  'status': status,
  'is4k': is4k,
  'type': type,
  'createdAt': '2026-11-01T10:00:00.000Z',
  'media': {
    'id': 1000 + tmdbId,
    'mediaType': type,
    'tmdbId': tmdbId,
    'status': mediaStatus,
    'status4k': 1,
    'serviceId': serviceId,
    'serviceId4k': null,
  },
  'requestedBy': {'id': requestedBy},
  'seasons': [
    if (type == 'tv') {'seasonNumber': 1},
    if (type == 'tv') {'seasonNumber': 2},
  ],
  'canRemove': ?canRemove,
};

http.Response _page(List<Map<String, dynamic>> results, {int page = 1, int pages = 1, int? total}) => _json({
  'pageInfo': {'page': page, 'pages': pages, 'pageSize': 20, 'results': total ?? results.length},
  'results': results,
});

/// A Seerr double: `GET /request` is answered by [list] (called with the
/// query), details are titled after their id, and every DELETE succeeds.
class _Seerr {
  _Seerr({required this.list, this.permissions = SeerrPermission.request});

  FutureOr<http.Response> Function(Map<String, String> query) list;
  final int permissions;

  final listQueries = <Map<String, String>>[];
  final deletes = <String>[];

  late final SeerrClient client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: _me,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      product: SeerrProduct.jellyseerr,
      createdAt: 0,
    ),
    onSessionInvalidated: () {},
    httpClient: MockClient(_handle),
  );

  late final SeerrCatalogSource source = SeerrCatalogSource(client);

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    if (path == '/api/v1/settings/public') return _json({'message': 'Not Found'}, status: 404);
    if (request.method == 'DELETE') {
      deletes.add('${request.method} $path${request.url.hasQuery ? '?${request.url.query}' : ''}');
      return http.Response('', 204);
    }
    if (path == '/api/v1/request') {
      listQueries.add(request.url.queryParameters);
      return list(request.url.queryParameters);
    }
    if (path.startsWith('/api/v1/movie/') || path.startsWith('/api/v1/tv/')) {
      final id = int.parse(request.url.pathSegments.last);
      final isMovie = path.startsWith('/api/v1/movie/');
      return _json({
        'id': id,
        isMovie ? 'title' : 'name': 'Title $id',
        isMovie ? 'releaseDate' : 'firstAirDate': '2020-05-01',
      });
    }
    fail('unexpected ${request.method} ${request.url}');
  }

  void dispose() {
    source.dispose();
    client.dispose();
  }
}

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

/// Opens the screen the way Explore does: over the shelf's own hub, pushed on
/// top of a launcher.
Future<void> _pumpScreen(WidgetTester tester, _Seerr seerr) => _pumpScreenWith(tester, seerr, () {});

/// [afterShelf] runs once the shelf has been read and before the screen opens.
Future<void> _pumpScreenWith(WidgetTester tester, _Seerr seerr, VoidCallback afterShelf) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(seerr.dispose);
  final sources = _SeerrSources(seerr.source);
  addTearDown(sources.dispose);

  final shelf = (await seerr.source.requests.fetchHubs()).single;
  seerr.listQueries.clear();
  afterShelf();
  final hub = MediaHub(
    id: 'explore:seerr:hub:${shelf.id}',
    identifier: 'explore.hub.${shelf.id}',
    title: shelf.title,
    type: 'mixed',
    items: [for (final item in shelf.page.items) item.toMediaItem()],
    size: shelf.page.totalResults ?? shelf.page.items.length,
    more: shelf.page.hasMore,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<CatalogSourcesProvider>.value(
        value: sources,
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(MonoPalette.dark),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SeerrRequestsScreen(source: seerr.source, hub: hub),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder _card(String title) => find.ancestor(of: find.text(title), matching: find.byType(FocusableMediaCard));

Finder _inCard(String title, String text) => find.descendant(of: _card(title), matching: find.text(text));

/// A row of the filter picker.
Finder _filterOption(String label) => find.descendant(of: find.byType(SimpleDialog), matching: find.text(label));

void main() {
  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  final strings = t.seerr.requests;

  testWidgets('is the shared hub grid: one poster card per requested title, badged by request status', (tester) async {
    final seerr = _Seerr(
      list: (_) => _page([
        _request(id: 3, tmdbId: 30, type: 'tv', status: 2, mediaStatus: 3),
        _request(id: 2, tmdbId: 20),
        _request(id: 1, tmdbId: 10, status: 3),
      ]),
    );
    await _pumpScreen(tester, seerr);

    expect(find.byType(HubDetailScreen), findsOneWidget);
    expect(find.text(strings.myRequests), findsOneWidget);
    expect(find.byTooltip(t.libraries.sort), findsOneWidget, reason: 'the grid keeps its own sort action');
    expect(seerr.listQueries.single, {
      'take': '${ExploreProvider.viewAllPageLimit}',
      'skip': '0',
      'filter': 'all',
      'sort': 'added',
      'requestedBy': '$_me',
    });

    expect(find.byType(FocusableMediaCard), findsNWidgets(3));
    final lefts = [
      for (final title in const ['Title 30', 'Title 20', 'Title 10']) tester.getTopLeft(_card(title)).dx,
    ];
    expect(lefts, orderedEquals([...lefts]..sort()), reason: 'in the order Seerr returned them');
    expect(_inCard('Title 30', t.explore.badge.processing), findsOneWidget);
    expect(_inCard('Title 20', t.explore.badge.pendingApproval), findsOneWidget);
    expect(_inCard('Title 10', t.explore.badge.declined), findsOneWidget);
  });

  testWidgets('loads every page of requests, and a title requested on two pages gets one card', (tester) async {
    final seerr = _Seerr(
      list: (query) => query['skip'] == '0'
          ? _page([for (var i = 1; i <= 100; i++) _request(id: i, tmdbId: 100 + i)], pages: 2, total: 103)
          : _page(
              [
                _request(id: 101, tmdbId: 201),
                _request(id: 102, tmdbId: 202),
                _request(id: 103, tmdbId: 101, is4k: true),
              ],
              page: 2,
              pages: 2,
              total: 103,
            ),
    );
    await _pumpScreen(tester, seerr);

    expect([for (final query in seerr.listQueries) (query['skip'], query['take'])], [('0', '100'), ('100', '100')]);
    expect(tester.takeException(), isNull, reason: 'no duplicate card keys');
    expect(find.text('Title 101'), findsOneWidget);
    expect(find.text('Title 202'), findsNothing, reason: 'the grid builds its cards lazily');

    await tester.scrollUntilVisible(find.text('Title 202'), 600, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Title 202'), findsOneWidget);
    expect(find.text('Title 101'), findsNothing);
    expect(seerr.listQueries, hasLength(2), reason: 'scrolling asks Seerr for nothing more');
  });

  testWidgets('the status filter re-queries Seerr and shows which filter is on', (tester) async {
    final seerr = _Seerr(
      list: (query) => switch (query['filter']) {
        'pending' => _page([_request(id: 2, tmdbId: 20)]),
        'failed' => _page(const []),
        _ => _page([_request(id: 2, tmdbId: 20), _request(id: 1, tmdbId: 10, status: 2)]),
      },
    );
    await _pumpScreen(tester, seerr);
    expect(find.text('Title 10'), findsOneWidget);

    await tester.tap(find.byTooltip('${strings.filter}: ${strings.filterAll}'));
    await tester.pumpAndSettle();
    for (final label in [
      strings.filterAll,
      strings.filterPending,
      strings.filterApproved,
      strings.filterProcessing,
      strings.filterAvailable,
      strings.filterFailed,
    ]) {
      expect(_filterOption(label), findsOneWidget);
    }
    await tester.tap(_filterOption(strings.filterPending));
    await tester.pumpAndSettle();

    expect(seerr.listQueries.last['filter'], 'pending');
    expect(seerr.listQueries.last['skip'], '0');
    expect(find.text('Title 10'), findsNothing);
    expect(find.text('Title 20'), findsOneWidget);

    // A filter with no matches empties the grid but keeps the way back.
    await tester.tap(find.byTooltip('${strings.filter}: ${strings.filterPending}'));
    await tester.pumpAndSettle();
    await tester.tap(_filterOption(strings.filterFailed));
    await tester.pumpAndSettle();

    expect(find.byType(FocusableMediaCard), findsNothing);
    expect(find.text(t.hubDetail.noItemsFound), findsOneWidget);
    expect(find.byTooltip('${strings.filter}: ${strings.filterFailed}'), findsOneWidget);
  });

  testWidgets('a filter picked while the list is still loading wins over that load', (tester) async {
    final all = _page([_request(id: 2, tmdbId: 20), _request(id: 1, tmdbId: 10, status: 2)]);
    final seerr = _Seerr(list: (_) => all);
    final gate = Completer<void>();
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await _pumpScreenWith(tester, seerr, () {
      seerr.list = (query) async {
        if (query['filter'] == 'all') await gate.future;
        return query['filter'] == 'pending' ? _page([_request(id: 2, tmdbId: 20)]) : all;
      };
    });
    expect(seerr.listQueries, hasLength(1));

    await tester.tap(find.byTooltip('${strings.filter}: ${strings.filterAll}'));
    await tester.pumpAndSettle();
    await tester.tap(_filterOption(strings.filterPending));
    await tester.pumpAndSettle();
    expect(find.text('Title 10'), findsOneWidget, reason: 'the first load has not answered yet');

    gate.complete();
    await tester.pumpAndSettle();

    expect([for (final query in seerr.listQueries) query['filter']], ['all', 'pending']);
    expect(find.text('Title 10'), findsNothing);
    expect(find.text('Title 20'), findsOneWidget);
  });

  group('card menu', () {
    testWidgets('a plain user may delete only their own pending request, and the grid re-reads Seerr', (tester) async {
      var deleted = false;
      final seerr = _Seerr(
        list: (_) => _page([
          if (!deleted) _request(id: 2, tmdbId: 20),
          _request(id: 1, tmdbId: 10, status: 2, mediaStatus: 5, serviceId: 0),
        ]),
      );
      await _pumpScreen(tester, seerr);

      // Approved and downloaded: nothing destructive on offer.
      await tester.longPress(find.text('Title 10'));
      await tester.pumpAndSettle();
      expect(find.text(t.mediaMenu.viewDetails), findsOneWidget);
      expect(find.text(strings.deleteRequest), findsNothing);
      expect(find.text(strings.removeCompletely), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Title 20'));
      await tester.pumpAndSettle();
      expect(find.text(strings.deleteRequest), findsOneWidget);
      expect(find.text(strings.removeCompletely), findsNothing);

      await tester.tap(find.text(strings.deleteRequest));
      await tester.pumpAndSettle();
      expect(find.text(strings.deleteRequestBody(title: 'Title 20')), findsOneWidget);
      expect(seerr.deletes, isEmpty);

      deleted = true;
      await tester.tap(find.widgetWithText(FilledButton, strings.deleteRequest));
      await tester.pumpAndSettle();

      expect(seerr.deletes, ['DELETE /api/v1/request/2']);
      expect(seerr.listQueries, hasLength(2), reason: 'the grid re-reads Seerr after the deletion');
      expect(find.text('Title 20'), findsNothing);
      expect(find.text('Title 10'), findsOneWidget);
      expect(find.text(strings.requestDeleted), findsOneWidget);
    });

    testWidgets('a manager may also remove a downloaded title completely, for the request\'s variant', (tester) async {
      final seerr = _Seerr(
        permissions: SeerrPermission.manageRequests,
        list: (_) => _page([
          _request(id: 1, tmdbId: 10, status: 2, mediaStatus: 5, serviceId: 0, requestedBy: 99, canRemove: true),
          _request(id: 2, tmdbId: 20, status: 2, mediaStatus: 5, serviceId: 0, requestedBy: 99, canRemove: false),
        ]),
      );
      await _pumpScreen(tester, seerr);

      // Seerr says the instance behind this one is gone: no file removal.
      await tester.longPress(find.text('Title 20'));
      await tester.pumpAndSettle();
      expect(find.text(strings.deleteRequest), findsOneWidget);
      expect(find.text(strings.removeCompletely), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Title 10'));
      await tester.pumpAndSettle();
      expect(find.text(strings.deleteRequest), findsOneWidget);
      expect(find.text(strings.removeCompletely), findsOneWidget);

      await tester.tap(find.text(strings.removeCompletely));
      await tester.pumpAndSettle();
      expect(find.text(strings.removeCompletelyTitle(title: 'Title 10')), findsOneWidget);
      expect(find.text(strings.removeCompletelyWarning(title: 'Title 10')), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, strings.removeCompletely));
      await tester.pumpAndSettle();

      expect(seerr.deletes, ['DELETE /api/v1/media/1010/file?is4k=false', 'DELETE /api/v1/media/1010']);
      expect(seerr.listQueries, hasLength(2));
    });

    testWidgets('the menu key opens it from a remote, and its confirmation starts on Cancel', (tester) async {
      final seerr = _Seerr(list: (_) => _page([_request(id: 2, tmdbId: 20)]));
      await _pumpScreen(tester, seerr);

      // D-pad session parked on the card.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      final card = tester.widget<FocusableMediaCard>(_card('Title 20'));
      card.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(card.focusNode!.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.text(strings.deleteRequest), findsOneWidget);

      await tester.tap(find.text(strings.deleteRequest));
      await tester.pumpAndSettle();

      final cancel = tester.element(find.widgetWithText(DialogActionButton, t.common.cancel));
      var onCancel = false;
      FocusManager.instance.primaryFocus!.context!.visitAncestorElements((element) {
        if (element != cancel) return true;
        onCancel = true;
        return false;
      });
      expect(onCancel, isTrue);
      expect(seerr.deletes, isEmpty);
    });
  });

  testWidgets('BACK from a card goes to the app bar first, then leaves — as in every hub grid', (tester) async {
    final seerr = _Seerr(list: (_) => _page([_request(id: 2, tmdbId: 20)]));
    await _pumpScreen(tester, seerr);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final card = tester.widget<FocusableMediaCard>(_card('Title 20'));
    card.focusNode!.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SeerrRequestsScreen), findsOneWidget);
    expect(card.focusNode!.hasPrimaryFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SeerrRequestsScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  group('Explore helpers', () {
    ExploreRowHub fixedRow(String name) => ExploreRowHub.providerHub(
      providerHubId: name,
      hub: MediaHub(id: name, identifier: name, title: name, type: 'mixed', items: const [], size: 0),
    );

    test('the requests shelf leads the Explore rows; other orders are left alone', () {
      final a = fixedRow('a');
      final b = fixedRow('b');
      final mine = fixedRow(SeerrRequests.hubId);

      expect(seerrRequestsHubFirst([a, b, mine]), [mine, a, b]);
      final already = [mine, a, b];
      expect(seerrRequestsHubFirst(already), same(already));
      final without = [a, b];
      expect(seerrRequestsHubFirst(without), same(without));
    });

    test('only the requests shelf gets its own icon', () {
      expect(seerrRequestsHubIcon(SeerrRequests.hubId), isNotNull);
      expect(seerrRequestsHubIcon('plex.hub'), isNull);
      expect(seerrRequestsHubIcon(null), isNull);
    });

    testWidgets('View All is overridden for the requests shelf only', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seerrRequestsViewAll(context, fixedRow('plex.hub')), isNull);
      expect(seerrRequestsViewAll(context, null), isNull);
      final viewAll = seerrRequestsViewAll(context, fixedRow(SeerrRequests.hubId));
      expect(viewAll, isNotNull);
      // No Seerr source in scope: the callback is a no-op rather than a crash.
      viewAll!();
      await tester.pumpAndSettle();
      expect(find.byType(SeerrRequestsScreen), findsNothing);
    });
  });
}
