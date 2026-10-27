import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:provider/provider.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/lending/lending_service.dart';
import 'package:plezy/screens/lending/public_libraries_screen.dart';
import 'package:plezy/screens/sources/add_source_screen.dart';
import 'package:plezy/screens/sources/open_media_screen.dart';
import 'package:plezy/screens/sources/source_navigation.dart';
import 'package:plezy/screens/sources/sources_screen.dart';
import 'package:plezy/screens/sources/source_widgets.dart';
import 'package:plezy/screens/sources/publication_reader_screen.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/publication_shelf.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/provider_mark.dart';
import 'fixtures/memory_sources.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SourceDatabase db;
  late MemorySources sources;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plezy-source-ui-');
    db = SourceDatabase(NativeDatabase.memory());
    sources = MemorySources(SourceRepository(db), directory);
    sources.sources = [
      for (final kind in [FileSourceKind.googleDrive, FileSourceKind.oneDrive, FileSourceKind.dropbox])
        FileSource(
          id: kind.name,
          profileId: 'alice',
          kind: kind,
          name: switch (kind) {
            FileSourceKind.googleDrive => 'Google Drive',
            FileSourceKind.oneDrive => 'OneDrive',
            _ => 'Dropbox',
          },
        ),
    ];
    LocaleSettings.setLocaleSync(AppLocale.en);
    if (Platform.environment['PLEZY_UI_SCREENSHOTS'] != null) {
      final font = FontLoader('Roboto')
        ..addFont(
          File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf').readAsBytes().then((b) => ByteData.sublistView(b)),
        );
      await font.load();
      final material = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await material.load();
      for (final face in ['Rounded', 'Outlined']) {
        final f = FontLoader('packages/material_symbols_icons/MaterialSymbols$face')
          ..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbols$face.ttf'));
        await f.load();
      }
    }
  });
  tearDown(() async {
    sources.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(WidgetTester tester, Widget screen, MonoPalette palette, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<TrackersProvider>(create: (_) => TrackersProvider()),
        ],
        child: RepaintBoundary(
          key: const ValueKey('capture'),
          child: InputModeTracker(
            child: MaterialApp(
              theme: Platform.environment['PLEZY_UI_SCREENSHOTS'] == null
                  ? monoTheme(palette)
                  : monoTheme(palette).copyWith(
                      textTheme: monoTheme(palette).textTheme.apply(fontFamily: 'Roboto'),
                      primaryTextTheme: monoTheme(palette).primaryTextTheme.apply(fontFamily: 'Roboto'),
                      appBarTheme: monoTheme(palette).appBarTheme.copyWith(
                        titleTextStyle: monoTheme(palette).appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
                      ),
                    ),
              debugShowCheckedModeBanner: false,
              home: screen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (Platform.environment['PLEZY_UI_SCREENSHOTS'] != null) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final root = Platform.environment['PLEZY_UI_SCREENSHOTS'];
    if (root == null) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture')));
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await File('$root/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final light in [false, true]) {
    for (final narrow in [false, true]) {
      testWidgets('sources and approved marks fit ${light ? 'light' : 'dark'} ${narrow ? 'phone' : 'desktop'}', (
        tester,
      ) async {
        await pump(
          tester,
          const SourcesScreen(),
          light ? MonoPalette.light : MonoPalette.dark,
          Size(narrow ? 390 : 1200, narrow ? 844 : 900),
        );
        expect(find.byType(FileSourceMark), findsNWidgets(3));
        expect(find.text(isolateDisplayText('Google Drive')), findsWidgets);
        await capture(tester, 'sources-${light ? 'light' : 'dark'}-${narrow ? 'phone' : 'desktop'}');
      });
    }
  }
  testWidgets('Open media uses one Files and books entry and focus-aware source rows for nested tools', (tester) async {
    await pump(tester, const SourcesScreen(), MonoPalette.dark, const Size(390, 844));
    final openMediaEntry = find.descendant(of: find.byType(SourcesScreen), matching: find.text(t.universalMedia.title));
    expect(openMediaEntry, findsOneWidget);

    await tester.tap(openMediaEntry);
    await tester.pumpAndSettle();

    final openMedia = find.byType(OpenMediaScreen);
    expect(openMedia, findsOneWidget);
    expect(find.descendant(of: openMedia, matching: find.text(t.universalMedia.intro)), findsOneWidget);
    expect(find.descendant(of: openMedia, matching: find.byType(SourceTile)), findsNWidgets(2));
    expect(find.descendant(of: openMedia, matching: find.text(t.universalMedia.wifiTransfer)), findsOneWidget);
    expect(find.descendant(of: openMedia, matching: find.text(t.universalMedia.converterTitle)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('OverDrive is visibly coming soon without a patron credential form', (tester) async {
    await sources.repository.savePreference('alice', 'lending:libraries', {
      'libraries': [
        const LendingLibrary(
          id: 'card',
          provider: LendingProvider.overdrive,
          name: 'Public library',
          home: 'https://libbyapp.com',
        ).toJson(),
      ],
    });
    await pump(tester, const PublicLibrariesScreen(), MonoPalette.dark, const Size(1200, 900));
    expect(find.text(isolateDisplayText(t.lending.comingSoon)), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(ProviderMark), findsNWidgets(2));
    await capture(tester, 'public-libraries-dark');
    await tester.tap(find.text('Libby / OverDrive'));
    await tester.pumpAndSettle();
    expect(find.text(t.lending.comingSoonDescription), findsOneWidget);
    expect(find.text(t.lending.signIn), findsNothing);
    expect(tester.takeException(), isNull);
    await capture(tester, 'libby-coming-soon');
  });
  for (final (fixed, comic) in [(false, false), (true, false), (true, true)]) {
    testWidgets('reader preferences fit large text and show applicable controls ($fixed, $comic)', (tester) async {
      await pump(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ReaderSettingsScreen(settings: const {}, fixed: fixed, comic: comic, onChanged: (_) async {}),
        ),
        MonoPalette.dark,
        const Size(390, 844),
      );
      expect(find.text(t.fileSources.pageLayout), fixed ? findsWidgets : findsNothing);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('book cover grid reflows at large text on a narrow display', (tester) async {
    await sources.repository.cacheEntries('alice', [
      for (var i = 0; i < 4; i++)
        SourceEntry(
          sourceId: 'googleDrive',
          id: 'book$i',
          title: 'A longer book title to read comfortably',
          author: 'A named author',
          kind: SourceItemKind.ebook,
          files: [PublicationFile(id: '$i', name: '$i.epub', mimeType: 'application/epub+zip')],
        ),
    ]);
    await pump(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SourcesScreen(shelf: PublicationShelf.ebooks),
      ),
      MonoPalette.dark,
      const Size(390, 844),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'books-large-text-phone');
  });
  testWidgets('conditional shelves use the shared menu items', (tester) async {
    sources.shelves = {PublicationShelf.ebooks, PublicationShelf.audiobooks};
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              for (final item in sourceLibraryMenu(context).whereType<AppMenuItem<String>>()) Text(item.label!),
            ],
          ),
        ),
      ),
      MonoPalette.dark,
      const Size(390, 844),
    );
    expect(find.text(t.fileSources.ebooks), findsOneWidget);
    expect(find.text(t.fileSources.audiobooks), findsOneWidget);
    expect(find.text(t.fileSources.comics), findsNothing);
    sources.shelves.add(PublicationShelf.comics);
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              for (final item in sourceLibraryMenu(context).whereType<AppMenuItem<String>>()) Text(item.label!),
            ],
          ),
        ),
      ),
      MonoPalette.dark,
      const Size(390, 844),
    );
    expect(find.text(t.fileSources.comics), findsOneWidget);
  });
  testWidgets('cloud setup keeps registration tucked away and uses Microsoft sign-in artwork', (tester) async {
    await pump(tester, AddSourceScreen(existing: sources.sources[1]), MonoPalette.light, const Size(390, 844));
    expect(find.text(t.fileSources.microsoftSignIn), findsOneWidget);
    expect(find.text(t.fileSources.clientId), findsNothing);
    expect(find.byType(ProviderMark), findsWidgets);
    await capture(tester, 'onedrive-setup-light');
  });
}
