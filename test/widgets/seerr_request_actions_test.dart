import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/services/catalog/seerr_catalog_source.dart';
import 'package:plezy/services/catalog/seerr_requests.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/widgets/catalog_context_menu.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/seerr_request_actions.dart';
import 'package:provider/provider.dart';

import '../test_helpers/theme.dart';

const _me = 1;

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

SeerrCatalogSource _source(
  FutureOr<http.Response> Function(http.Request request) handler, {
  int permissions = SeerrPermission.request,
}) {
  final client = SeerrClient(
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
    httpClient: MockClient((request) async {
      if (request.url.path == '/api/v1/settings/public') return _json({'message': 'Not Found'}, status: 404);
      return handler(request);
    }),
  );
  final source = SeerrCatalogSource(client);
  addTearDown(() {
    source.dispose();
    client.dispose();
  });
  return source;
}

Map<String, dynamic> _requestJson({
  int id = 7,
  int tmdbId = 10,
  String type = 'movie',
  int status = 1,
  bool is4k = false,
  int requestedBy = _me,
  int mediaStatus = 1,
  int? serviceId,
  int? serviceId4k,
}) => {
  'id': id,
  'status': status,
  'is4k': is4k,
  'type': type,
  'createdAt': '2026-11-01T10:00:00.000Z',
  'media': {
    'id': 55,
    'mediaType': type,
    'tmdbId': tmdbId,
    'status': mediaStatus,
    'status4k': 1,
    'serviceId': serviceId,
    'serviceId4k': serviceId4k,
  },
  'requestedBy': {'id': requestedBy},
};

SeerrTitleRequests _title(Map<String, dynamic> json) {
  final request = SeerrRequest.fromJson(json);
  return SeerrTitleRequests(media: request.media, requests: [request]);
}

/// A button that runs [onPressed] with a context under a Scaffold, the way a
/// card or an action bar would.
Future<void> _pumpTrigger(
  WidgetTester tester,
  Future<void> Function(BuildContext context) onPressed, {
  CatalogSourcesProvider? sources,
}) async {
  final app = MaterialApp(
    theme: ThemeData(extensions: const [testMonoTokens]),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(onPressed: () => unawaited(onPressed(context)), child: const Text('go')),
      ),
    ),
  );
  await tester.pumpWidget(
    sources == null ? app : ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources, child: app),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

/// Whether primary focus sits inside the dialog button labelled [label].
bool _focusIsOnDialogButton(WidgetTester tester, String label) {
  final button = tester.element(find.widgetWithText(DialogActionButton, label));
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var inside = false;
  focused.visitAncestorElements((element) {
    if (element != button) return true;
    inside = true;
    return false;
  });
  return inside;
}

class _SeerrOnlySources extends CatalogSourcesProvider {
  _SeerrOnlySources(this.seerr);

  final SeerrCatalogSource seerr;

  @override
  List<CatalogSource> get connectedSources => [seerr];

  @override
  SeerrCatalogSource? get seerrSource => seerr;
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  final strings = t.seerr.requests;

  group('permission gating', () {
    test('a plain user is offered only the deletion of their own pending requests', () {
      final source = _source((request) => fail('no HTTP expected'));

      final ownPending = seerrRequestActions(source, _title(_requestJson()), MediaKind.movie);
      expect(ownPending.single, isA<SeerrDeleteRequestAction>());

      expect(
        seerrRequestActions(source, _title(_requestJson(status: 2, mediaStatus: 5, serviceId: 0)), MediaKind.movie),
        isEmpty,
        reason: 'approved requests and the files behind them are for managers',
      );
      expect(
        seerrRequestActions(source, _title(_requestJson(requestedBy: 99)), MediaKind.movie),
        isEmpty,
        reason: "someone else's request",
      );
    });

    test('a manager is offered both actions, the removal naming the service and variants', () {
      final source = _source((request) => fail('no HTTP expected'), permissions: SeerrPermission.manageRequests);

      final movie = seerrRequestActions(
        source,
        _title(_requestJson(status: 2, mediaStatus: 5, serviceId: 0, requestedBy: 99)),
        MediaKind.movie,
      );
      expect(movie, hasLength(2));
      expect(movie.first, isA<SeerrDeleteRequestAction>());
      expect(movie.first.subtitle, t.explore.badge.available);
      final removal = movie.last as SeerrRemoveCompletelyAction;
      expect(removal.mediaId, 55);
      expect(removal.variants, {false});
      expect(removal.service, 'Radarr');

      final show = seerrRequestActions(
        source,
        _title(_requestJson(type: 'tv', status: 2, is4k: true, serviceId: 0, serviceId4k: 1)),
        MediaKind.show,
      );
      expect((show.last as SeerrRemoveCompletelyAction).variants, {false, true});
      expect((show.last as SeerrRemoveCompletelyAction).service, strings.serviceBoth(service: 'Sonarr'));
      expect(show.first.subtitle, contains('4K'));

      // Nothing reached Sonarr/Radarr yet: there is a request to delete, but
      // no files to remove.
      final pending = seerrRequestActions(source, _title(_requestJson(requestedBy: 99)), MediaKind.movie);
      expect(pending.single, isA<SeerrDeleteRequestAction>());
    });

    test('an admin passes every gate', () {
      final source = _source((request) => fail('no HTTP expected'), permissions: SeerrPermission.admin);
      final actions = seerrRequestActions(
        source,
        _title(_requestJson(status: 2, serviceId: 0, requestedBy: 99)),
        MediaKind.movie,
      );
      expect(actions.map((a) => a.runtimeType), [SeerrDeleteRequestAction, SeerrRemoveCompletelyAction]);
    });
  });

  group('remove completely', () {
    SeerrRemoveCompletelyAction removal(SeerrCatalogSource source) =>
        seerrRequestActions(source, _title(_requestJson(status: 2, mediaStatus: 5, serviceId: 0)), MediaKind.movie).last
            as SeerrRemoveCompletelyAction;

    testWidgets('the confirmation names the title and the file loss, with Cancel focused and a red confirm', (
      tester,
    ) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);
      bool? result;
      await _pumpTrigger(tester, (context) async {
        result = await runSeerrRequestAction(context, source: source, action: removal(source), title: 'Fight Club');
      });

      expect(find.text(strings.removeCompletelyTitle(title: 'Fight Club')), findsOneWidget);
      expect(find.text(strings.removeCompletelyBody(title: 'Fight Club', service: 'Radarr')), findsOneWidget);
      final warning = strings.removeCompletelyWarning(title: 'Fight Club');
      expect(warning, allOf(contains('Fight Club'), contains('files'), contains('cannot be undone')));
      expect(find.text(warning), findsOneWidget);

      expect(_focusIsOnDialogButton(tester, t.common.cancel), isTrue);
      expect(_focusIsOnDialogButton(tester, strings.removeCompletely), isFalse);

      final confirm = tester.widget<FilledButton>(find.widgetWithText(FilledButton, strings.removeCompletely));
      final scheme = Theme.of(tester.element(find.byType(AlertDialog))).colorScheme;
      expect(confirm.style?.backgroundColor?.resolve(const {}), scheme.error);
      expect(confirm.style?.foregroundColor?.resolve(const {}), scheme.onError);

      // A remote's SELECT lands on the focused button: Cancel.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isFalse);
      expect(calls, isEmpty, reason: 'nothing is deleted without an explicit confirm');
    });

    testWidgets('confirming removes the files, then the Seerr record, and reports success', (tester) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}?${request.url.query}');
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);
      var notified = 0;
      source.requests.addListener(() => notified++);
      bool? result;
      await _pumpTrigger(tester, (context) async {
        result = await runSeerrRequestAction(context, source: source, action: removal(source), title: 'Fight Club');
      });

      await tester.tap(find.widgetWithText(FilledButton, strings.removeCompletely));
      await tester.pumpAndSettle();

      expect(calls, ['DELETE /api/v1/media/55/file?is4k=false', 'DELETE /api/v1/media/55?']);
      expect(result, isTrue);
      expect(notified, 1, reason: 'open surfaces re-read Seerr');
      expect(find.text(strings.removedCompletely(title: 'Fight Club')), findsOneWidget);
    });

    testWidgets('a permission Seerr no longer grants is reported as such, and nothing is retried', (tester) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return switch (request.url.path) {
          '/api/v1/auth/me' => _json({'id': _me, 'displayName': 'Alice', 'permissions': SeerrPermission.request}),
          _ => _json({'status': 403, 'error': 'You do not have permission to access this endpoint'}, status: 403),
        };
      }, permissions: SeerrPermission.manageRequests);
      final action = removal(source);
      bool? result;
      await _pumpTrigger(tester, (context) async {
        result = await runSeerrRequestAction(context, source: source, action: action, title: 'Fight Club');
      });

      await tester.tap(find.widgetWithText(FilledButton, strings.removeCompletely));
      await tester.pumpAndSettle();

      expect(calls, ['DELETE /api/v1/media/55/file', 'GET /api/v1/auth/me']);
      expect(result, isFalse);
      expect(find.text(t.seerr.permissionDenied), findsOneWidget);
      // The client adopted the current mask, so the action is no longer offered.
      expect(source.requests.canManage, isFalse);
      expect(
        seerrRequestActions(source, _title(_requestJson(status: 2, mediaStatus: 5, serviceId: 0)), MediaKind.movie),
        isEmpty,
      );
    });

    testWidgets('a refusal from Seerr (no instance configured) shows its message and keeps the record', (tester) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return _json({'message': 'No Radarr server configured to delete media files'}, status: 409);
      }, permissions: SeerrPermission.manageRequests);
      await _pumpTrigger(
        tester,
        (context) => runSeerrRequestAction(context, source: source, action: removal(source), title: 'Fight Club'),
      );

      await tester.tap(find.widgetWithText(FilledButton, strings.removeCompletely));
      await tester.pumpAndSettle();

      expect(calls, ['DELETE /api/v1/media/55/file']);
      expect(
        find.text(strings.actionFailed(error: 'No Radarr server configured to delete media files')),
        findsOneWidget,
      );
    });
  });

  group('delete request', () {
    testWidgets('confirms with Cancel focused, then withdraws the request', (tester) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return http.Response('', 204);
      });
      final action = seerrRequestActions(source, _title(_requestJson()), MediaKind.movie).single;
      bool? result;
      await _pumpTrigger(tester, (context) async {
        result = await runSeerrRequestAction(context, source: source, action: action, title: 'Fight Club');
      });

      expect(find.text(strings.deleteRequestTitle), findsOneWidget);
      expect(find.text(strings.deleteRequestBody(title: 'Fight Club')), findsOneWidget);
      expect(_focusIsOnDialogButton(tester, t.common.cancel), isTrue);
      expect(calls, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, strings.deleteRequest));
      await tester.pumpAndSettle();

      expect(calls, ['DELETE /api/v1/request/7']);
      expect(result, isTrue);
      expect(find.text(strings.requestDeleted), findsOneWidget);
    });

    testWidgets("Seerr's 401 for a request that may no longer be deleted reads as a permission denial", (tester) async {
      final source = _source(
        (request) => switch (request.url.path) {
          '/api/v1/auth/me' => _json({'id': _me, 'displayName': 'Alice', 'permissions': SeerrPermission.request}),
          _ => _json({'message': 'You do not have permission to delete this request.'}, status: 401),
        },
      );
      final action = seerrRequestActions(source, _title(_requestJson()), MediaKind.movie).single;
      await _pumpTrigger(
        tester,
        (context) => runSeerrRequestAction(context, source: source, action: action, title: 'Fight Club'),
      );

      await tester.tap(find.widgetWithText(FilledButton, strings.deleteRequest));
      await tester.pumpAndSettle();

      expect(find.text(t.seerr.permissionDenied), findsOneWidget);
      expect(find.text(strings.requestDeleted), findsNothing);
    });
  });

  group('menus', () {
    testWidgets('the actions menu lists what is allowed and runs the pick through its confirmation', (tester) async {
      final calls = <String>[];
      final source = _source((request) {
        calls.add('${request.method} ${request.url.path}');
        return http.Response('', 204);
      }, permissions: SeerrPermission.manageRequests);
      final actions = seerrRequestActions(
        source,
        _title(_requestJson(status: 2, mediaStatus: 5, serviceId: 0)),
        MediaKind.movie,
      );
      await _pumpTrigger(
        tester,
        (context) => showSeerrRequestActionsMenu(context, source: source, actions: actions, title: 'Fight Club'),
      );

      expect(find.text(strings.deleteRequest), findsOneWidget);
      expect(find.text(strings.removeCompletely), findsOneWidget);
      expect(find.text('Radarr'), findsOneWidget);

      await tester.tap(find.text(strings.deleteRequest));
      await tester.pumpAndSettle();

      expect(find.text(strings.deleteRequestTitle), findsOneWidget);
      expect(calls, isEmpty, reason: 'picking a menu row only opens the confirmation');
      expect(_focusIsOnDialogButton(tester, t.common.cancel), isTrue);
    });

    testWidgets('a catalog card menu offers the actions once Seerr\'s state for the title is known', (tester) async {
      final source = _source((request) {
        if (request.url.path == '/api/v1/request') {
          return _json({
            'pageInfo': {'page': 1, 'pages': 1, 'results': 2},
            'results': [
              _requestJson(id: 7, tmdbId: 10),
              _requestJson(id: 8, tmdbId: 20, status: 2, mediaStatus: 5, serviceId: 0),
            ],
          });
        }
        if (request.url.path.startsWith('/api/v1/movie/')) {
          final id = int.parse(request.url.pathSegments.last);
          return _json({'id': id, 'title': 'Title $id'});
        }
        fail('unexpected ${request.url}');
      });
      final sources = _SeerrOnlySources(source);
      addTearDown(sources.dispose);
      final items = (await tester.runAsync(source.fetchHubs))!.single.page.items;
      final pending = items.firstWhere((i) => i.ids.tmdb == 10);
      final approved = items.firstWhere((i) => i.ids.tmdb == 20);

      await _pumpTrigger(tester, (context) => showCatalogItemMenu(context, pending), sources: sources);
      expect(find.text(t.mediaMenu.viewDetails), findsOneWidget);
      expect(find.text(strings.deleteRequest), findsOneWidget);
      expect(find.text(strings.removeCompletely), findsNothing);

      // Dismiss the sheet, then open the menu of the approved title: a plain
      // user may do nothing about it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _pumpTrigger(tester, (context) => showCatalogItemMenu(context, approved), sources: sources);
      expect(find.text(t.mediaMenu.viewDetails), findsOneWidget);
      expect(find.text(strings.deleteRequest), findsNothing);
      expect(find.text(strings.removeCompletely), findsNothing);

      // A title no read has covered gets no request actions either.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _pumpTrigger(
        tester,
        (context) => showCatalogItemMenu(
          context,
          const CatalogItem(
            source: CatalogSourceId.seerr,
            kind: MediaKind.movie,
            title: 'Unseen',
            ids: CatalogItemIds(tmdb: 999),
          ),
        ),
        sources: sources,
      );
      expect(find.text(strings.deleteRequest), findsNothing);
    });
  });
}
