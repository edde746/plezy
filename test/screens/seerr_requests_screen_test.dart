import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/explore_provider.dart';
import 'package:plezy/screens/seerr_requests_screen.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/catalog/seerr_requests.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/media/media_hub.dart';

import '../test_helpers/theme.dart';

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
  _Seerr({required this.list, this.permissions = SeerrPermission.request, this.failDetails = const {}});

  FutureOr<http.Response> Function(Map<String, String> query) list;
  final int permissions;
  final Set<int> failDetails;

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
      if (failDetails.contains(id)) return _json({'message': 'TMDB down'}, status: 500);
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

Future<void> _pumpScreen(WidgetTester tester, _Seerr seerr) async {
  addTearDown(seerr.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: SeerrRequestsScreen(source: seerr.source),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _row(int requestId) => find.byKey(ValueKey('seerr_request_$requestId'));

Finder _inRow(int requestId, String text) => find.descendant(of: _row(requestId), matching: find.text(text));

/// A row of the filter picker.
Finder _filterOption(String label) => find.descendant(of: find.byType(SimpleDialog), matching: find.text(label));

void main() {
  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  final strings = t.seerr.requests;

  testWidgets('lists the user\'s requests newest first with type, variant, seasons and status', (tester) async {
    final seerr = _Seerr(
      list: (_) => _page([
        _request(id: 3, tmdbId: 30, type: 'tv', status: 2, mediaStatus: 3),
        _request(id: 2, tmdbId: 20, is4k: true),
        _request(id: 1, tmdbId: 10, status: 3),
      ]),
    );
    await _pumpScreen(tester, seerr);

    expect(seerr.listQueries.single, {
      'take': '20',
      'skip': '0',
      'filter': 'all',
      'sort': 'added',
      'requestedBy': '$_me',
    });
    expect(find.text(strings.myRequests), findsOneWidget);

    final titles = ['Title 30', 'Title 20', 'Title 10'];
    final tops = [for (final title in titles) tester.getTopLeft(find.text(title)).dy];
    expect(tops, orderedEquals([...tops]..sort()), reason: 'in the order Seerr returned them');

    expect(_inRow(3, t.explore.badge.processing), findsOneWidget);
    expect(_inRow(2, t.explore.badge.pendingApproval), findsOneWidget);
    expect(_inRow(1, t.explore.badge.declined), findsOneWidget);
    expect(
      find.descendant(
        of: _row(3),
        matching: find.textContaining(strings.seasonsList(seasons: '1, 2')),
      ),
      findsOneWidget,
    );
    expect(find.descendant(of: _row(3), matching: find.textContaining(t.common.mediaKind.show)), findsOneWidget);
    expect(find.descendant(of: _row(2), matching: find.textContaining('4K')), findsOneWidget);
    expect(find.descendant(of: _row(2), matching: find.textContaining('2020')), findsOneWidget);
  });

  testWidgets('the status filter re-queries Seerr and shows which filter is on', (tester) async {
    final seerr = _Seerr(
      list: (query) => query['filter'] == 'pending'
          ? _page([_request(id: 2, tmdbId: 20)])
          : _page([_request(id: 2, tmdbId: 20), _request(id: 1, tmdbId: 10, status: 2)]),
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
    expect(find.byTooltip('${strings.filter}: ${strings.filterPending}'), findsOneWidget);
  });

  testWidgets('a filter with no matches says so instead of looking like an empty account', (tester) async {
    final seerr = _Seerr(
      list: (query) => query['filter'] == 'failed' ? _page(const []) : _page([_request(id: 1, tmdbId: 10)]),
    );
    await _pumpScreen(tester, seerr);

    await tester.tap(find.byTooltip('${strings.filter}: ${strings.filterAll}'));
    await tester.pumpAndSettle();
    await tester.tap(_filterOption(strings.filterFailed));
    await tester.pumpAndSettle();

    expect(find.text(strings.emptyFiltered), findsOneWidget);
    expect(find.text(strings.empty), findsNothing);
  });

  testWidgets('pages by offset as the end of the list comes into view', (tester) async {
    final seerr = _Seerr(
      list: (query) => query['skip'] == '0'
          ? _page([for (var i = 1; i <= 20; i++) _request(id: i, tmdbId: 100 + i)], pages: 2, total: 23)
          : _page([for (var i = 21; i <= 23; i++) _request(id: i, tmdbId: 100 + i)], page: 2, pages: 2, total: 23),
    );
    await _pumpScreen(tester, seerr);
    expect(seerr.listQueries, hasLength(1), reason: 'the second page waits until the user gets near it');

    await tester.dragUntilVisible(_row(20), find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(seerr.listQueries, hasLength(2));
    expect(seerr.listQueries.last['skip'], '20');
    expect(seerr.listQueries.last['take'], '20');

    await tester.dragUntilVisible(_row(23), find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Title 123'), findsOneWidget);
    expect(seerr.listQueries, hasLength(2), reason: 'the last page ends the paging');
    expect(find.byKey(const ValueKey('seerr_requests_load_more')), findsNothing);
  });

  testWidgets('pull-to-refresh and the refresh action reload the first page', (tester) async {
    var generation = 0;
    final seerr = _Seerr(list: (_) => _page([_request(id: 1, tmdbId: generation == 0 ? 10 : 11)]));
    await _pumpScreen(tester, seerr);
    expect(find.text('Title 10'), findsOneWidget);

    generation = 1;
    await tester.fling(find.text('Title 10'), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();
    expect(seerr.listQueries, hasLength(2));
    expect(find.text('Title 11'), findsOneWidget);

    await tester.tap(find.byTooltip(t.common.refresh));
    await tester.pumpAndSettle();
    expect(seerr.listQueries, hasLength(3));
  });

  testWidgets('an empty account and a failed load each get their own state, the failure with a retry', (tester) async {
    var fail = true;
    final seerr = _Seerr(list: (_) => fail ? _json({'message': 'boom'}, status: 500) : _page(const []));
    await _pumpScreen(tester, seerr);

    expect(find.text(strings.loadFailed), findsOneWidget);

    fail = false;
    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();

    expect(find.text(strings.loadFailed), findsNothing);
    expect(find.text(strings.empty), findsOneWidget);
  });

  group('row menu', () {
    testWidgets('a plain user may delete only their own pending request', (tester) async {
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
      expect(seerr.listQueries, hasLength(2), reason: 'the list re-reads Seerr after the deletion');
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

    testWidgets('hold SELECT opens the menu from a remote, and its confirmation starts on Cancel', (tester) async {
      final seerr = _Seerr(list: (_) => _page([_request(id: 2, tmdbId: 20)]));
      await _pumpScreen(tester, seerr);

      // The first row takes focus once the list has loaded.
      final rowFocus = Focus.of(tester.element(find.text('Title 20')));
      expect(rowFocus.hasPrimaryFocus, isTrue);

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

    testWidgets('a request whose title could not be looked up is still listed and deletable', (tester) async {
      final seerr = _Seerr(list: (_) => _page([_request(id: 2, tmdbId: 20)]), failDetails: {20});
      await _pumpScreen(tester, seerr);

      final placeholder = strings.unknownTitle(id: 20);
      expect(find.text(placeholder), findsOneWidget);

      await tester.longPress(find.text(placeholder));
      await tester.pumpAndSettle();
      expect(find.text(t.mediaMenu.viewDetails), findsNothing, reason: 'there is no title to open');
      expect(find.text(strings.deleteRequest), findsOneWidget);
    });
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

    test('only the requests shelf gets its own icon and View All destination', () {
      expect(seerrRequestsHubIcon(SeerrRequests.hubId), isNotNull);
      expect(seerrRequestsHubIcon('plex.hub'), isNull);
      expect(seerrRequestsHubIcon(null), isNull);
    });

    testWidgets('View All opens the requests list for the shelf and stays generic for others', (tester) async {
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
      expect(seerrRequestsViewAll(context, 'plex.hub'), isNull);
      expect(seerrRequestsViewAll(context, null), isNull);
      final viewAll = seerrRequestsViewAll(context, SeerrRequests.hubId);
      expect(viewAll, isNotNull);
      // No Seerr source in scope: the callback is a no-op rather than a crash.
      viewAll!();
      await tester.pumpAndSettle();
      expect(find.byType(SeerrRequestsScreen), findsNothing);
    });
  });
}
