import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/screens/libraries/tabs/library_browse_tab.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/library_selection_bar.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/focusable_filter_chip.dart';
import '../../test_helpers/library_tab_scaffold.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['PLEZY_SELECTION_PREVIEWS'];
  if (directory == null) return;
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('selection-preview')));
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['PLEZY_SELECTION_PREVIEWS'] == null) return;
    await (FontLoader('Roboto')..addFont(rootBundle.load('assets/go-noto-current-regular.ttf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
  });
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    await StorageService.getInstance();
  });

  Future<_Client> pump(
    WidgetTester tester, {
    ViewMode mode = ViewMode.grid,
    Size size = const Size(1280, 720),
    MediaKind kind = MediaKind.movie,
  }) async {
    await SettingsService.instance.write(SettingsService.viewMode, mode);
    final client = _Client(kind);
    final servers = testMultiServer(clients: [client]);
    await pumpLibraryTab(
      tester,
      provider: servers.provider,
      size: size,
      tab: RepaintBoundary(
        key: const ValueKey('selection-preview'),
        child: LibraryBrowseTab(
          library: MediaLibrary(
            id: 'movies',
            title: 'Movies',
            kind: kind,
            backend: MediaBackend.jellyfin,
            serverId: client.serverId,
          ),
          canGroupByFolders: false,
          isActive: true,
        ),
      ),
    );
    await pumpRequestFrames(tester);
    return client;
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('Select items'));
    await tester.pump();
  }

  Future<void> mark(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('Selection actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await pumpRequestFrames(tester);
  }

  for (final mode in ViewMode.values) {
    testWidgets('$mode selects a Shift-click range and marks exactly those items', (tester) async {
      final client = await pump(tester, mode: mode);
      await start(tester);
      final cards = find.byType(FocusableMediaCard);
      await tester.tap(cards.at(0));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(cards.at(2));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(find.text('3 selected'), findsOneWidget);
      await capture(tester, 'desktop-$mode');
      await mark(tester, 'Mark as Watched');
      expect(client.marked, ['0', '1', '2']);
      expect(find.text('Select items'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('partial failures remain selected and only failures are retried', (tester) async {
    final client = await pump(tester);
    client.failIds.add('1');
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).at(0));
    await tester.tap(find.byType(FocusableMediaCard).at(1));
    await tester.pump();
    await mark(tester, 'Mark as Watched');
    expect(find.text('1 selected'), findsOneWidget);
    expect(client.marked, ['0', '1']);
    client.failIds.clear();
    await mark(tester, 'Mark as Watched');
    expect(client.marked, ['0', '1', '1']);
  });

  testWidgets('unwatched confirms progress reset and cancel dispatches nothing', (tester) async {
    final client = await pump(tester);
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).first);
    await tester.pump();
    await mark(tester, 'Mark as Unwatched');
    expect(find.textContaining('clears playback progress'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(client.unmarked, isEmpty);
    expect(find.text('1 selected'), findsOneWidget);
    await mark(tester, 'Mark as Unwatched');
    await tester.tap(find.text('Mark as Unwatched').last);
    await tester.pumpAndSettle();
    expect(client.unmarked, ['0']);
  });

  testWidgets('show selection discloses descendant scope before dispatch', (tester) async {
    final client = await pump(tester, kind: MediaKind.show);
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).first);
    await tester.pump();
    await mark(tester, 'Mark as Watched');
    expect(find.textContaining('all episodes'), findsOneWidget);
    expect(client.marked, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('keyboard activation toggles a checkbox; Escape exits selection', (tester) async {
    await pump(tester);
    await start(tester);
    final card = tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard).first);
    card.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);
    final semantics = tester.getSemantics(find.byType(MediaCard).first);
    expect(semantics.getSemanticsData().flagsCollection.isChecked, ui.CheckedState.isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Select items'), findsOneWidget);
  });

  testWidgets('authentication replacement retires a pending batch', (tester) async {
    final client = await pump(tester);
    final pending = Completer<void>();
    client.pending = pending.future;
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).at(0));
    await tester.tap(find.byType(FocusableMediaCard).at(1));
    await tester.pump();
    await tester.tap(find.byTooltip('Selection actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as Watched'));
    await tester.pump();
    expect(client.marked, ['0']);
    client.authenticationSessionId = Object();
    pending.complete();
    await tester.pumpAndSettle();
    expect(client.marked, ['0']);
    expect(find.text('Select items'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing sort retires selection before refreshing the query', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump(tester);
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).first);
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byType(FocusableFilterChip).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await pumpRequestFrames(tester);
    expect(find.text('Select items'), findsOneWidget);
    expect(tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard).first).selected, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('narrow selection toolbar and menu remain usable', (tester) async {
    await pump(tester, size: const Size(360, 720));
    await start(tester);
    await tester.tap(find.byType(FocusableMediaCard).first);
    await tester.pump();
    expect(tester.getSize(find.byType(LibrarySelectionBar)).width, 360);
    await tester.tap(find.byTooltip('Selection actions'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as Watched'), findsOneWidget);
    expect(find.text('Mark as Unwatched'), findsOneWidget);
    await capture(tester, 'narrow-menu');
    expect(tester.takeException(), isNull);
  });
}

class _Client implements MediaServerClient {
  final MediaKind kind;
  _Client(this.kind);
  @override
  final ServerId serverId = ServerId('server');
  @override
  String get serverName => 'Server';
  @override
  Object authenticationSessionId = Object();
  @override
  MediaBackend get backend => MediaBackend.jellyfin;
  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;
  final marked = <String>[];
  final unmarked = <String>[];
  final failIds = <String>{};
  Future<void>? pending;
  @override
  Future<void> markWatched(MediaItem item) async {
    marked.add(item.id);
    if (pending != null) await pending;
    if (failIds.contains(item.id)) throw StateError('failed');
  }

  @override
  Future<void> markUnwatched(MediaItem item) async {
    unmarked.add(item.id);
  }

  @override
  Future<MediaItem?> fetchItem(String itemId) async => null;
  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async => [
    const MediaSort(key: 'title', title: 'Title'),
    const MediaSort(key: 'year', title: 'Year'),
  ];
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async =>
      LibraryFilterResult.empty;
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async => LibraryPage(
    items: List.generate(
      4,
      (i) => testMediaItem(
        id: '$i',
        title: 'Movie $i',
        kind: kind,
        backend: backend,
        serverId: serverId,
        serverName: serverName,
      ),
    ),
    totalCount: 4,
  );
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
