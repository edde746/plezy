import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/models/catalog/catalog_metadata.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/external_url.dart';
import 'package:plezy/widgets/catalog_context_menu.dart';

const _item = CatalogItem(
  source: CatalogSourceId.trakt,
  kind: MediaKind.movie,
  title: 'Menu Movie',
  ids: CatalogItemIds(tmdb: 61),
  trailerUrl: 'https://youtu.be/dQw4w9WgXcQ',
  links: [CatalogLink(label: 'StreamCo', url: 'https://example.com/watch', isStreaming: true)],
);

Future<void> _openMenu(WidgetTester tester) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => unawaited(showCatalogItemMenu(context, _item, position: const Offset(10, 10))),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open menu'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('says so when a link cannot be opened', (tester) async {
    const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(urlLauncherChannel, (call) async => call.method == 'launch' ? false : null);
    addTearDown(() => messenger.setMockMethodCallHandler(urlLauncherChannel, null));

    await _openMenu(tester);
    await tester.tap(find.text('Open on StreamCo'));
    await tester.pumpAndSettle();

    expect(find.text(t.explore.detail.linkUnavailable), findsOneWidget);
  });

  group('tvOS runner', () {
    const handoffChannel = MethodChannel('com.plezy/external_player');
    late bool youTubeInstalled;
    late List<String> opened;

    setUp(() {
      debugTvosRunnerOverride = true;
      youTubeInstalled = true;
      opened = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(handoffChannel, (
        call,
      ) async {
        final url = (call.arguments as Map)['url'] as String;
        switch (call.method) {
          case 'canOpenUrl':
            return url == 'youtube://' && youTubeInstalled;
          case 'openUrl':
            opened.add(url);
            return true;
        }
        return null;
      });
    });

    tearDown(() {
      debugTvosRunnerOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(handoffChannel, null);
    });

    testWidgets('drops site links and hands the trailer to the YouTube app', (tester) async {
      await _openMenu(tester);

      expect(find.text('Open on StreamCo'), findsNothing);
      await tester.tap(find.text(t.explore.detail.watchTrailer));
      await tester.pumpAndSettle();

      expect(opened, ['youtube://www.youtube.com/watch?v=dQw4w9WgXcQ']);
    });

    testWidgets('drops the trailer when the YouTube app is missing', (tester) async {
      youTubeInstalled = false;

      await _openMenu(tester);

      expect(find.text(t.mediaMenu.viewDetails), findsOneWidget);
      expect(find.text(t.explore.detail.watchTrailer), findsNothing);
    });
  });
}
