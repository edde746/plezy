import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/screens/settings/mdblist_explore_shelves_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_client.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

class _Account extends TrackersProvider {
  _Account(this.client);
  final MdblistClient client;
  @override
  MdblistClient get mdblistCatalogClient => client;
  @override
  String get mdblistUsername => 'test-account';
}

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('discover AI and feed lists, select, rename, reorder, disable and restore shelves', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final requests = <http.Request>[];
    final client = MdblistClient(
      const TrackerSession(accessToken: 'test-only', createdAt: 0),
      onSessionInvalidated: () {},
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode([
            {'id': 7, 'name': 'Movies', 'type': 'ai', 'mediatype': null},
            {'id': 8, 'name': 'Shows', 'type': 'feed'},
          ]),
          200,
        );
      }),
    );
    final account = _Account(client);
    final sources = CatalogSourcesProvider();
    await tester.runAsync(() => sources.onActiveProfileChanged('test-profile'));
    addTearDown(() {
      client.dispose();
      account.dispose();
      sources.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TrackersProvider>.value(value: account),
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: sources),
        ],
        child: MaterialApp(
          theme: monoTheme(MonoPalette.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => const MdblistExploreShelvesScreen())),
                child: const Text('Open shelves'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open shelves'));
    await tester.pumpAndSettle();
    expect(find.text('Connected as @test-account'), findsOneWidget);
    await tester.tap(find.byTooltip('Add shelf').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add shelf').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cinema');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Move Cinema down'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Save shelves'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(sources.mdblistShelves.map((shelf) => shelf.listId), [8, 7]);
    expect(sources.mdblistShelves.first.enabled, isFalse);
    expect(sources.mdblistShelves.last.title, 'Cinema');
    expect(requests.every((request) => request.method == 'GET'), isTrue);
    await tester.tap(find.text('Open shelves'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Save shelves'));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(sources.mdblistShelves.map((shelf) => shelf.listId), [7]);
    await tester.tap(find.text('Open shelves'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => sources.onActiveProfileChanged('other-profile'));
    await tester.tap(find.text('Save shelves'));
    await tester.pumpAndSettle();
    expect(find.text(t.explore.mdblistShelves.accountChanged), findsOneWidget);
    expect(sources.mdblistShelves, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(seconds: 60)));
}
