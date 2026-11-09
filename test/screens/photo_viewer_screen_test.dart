import 'dart:async';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/photo_viewer_screen.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_mappers.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/immersive_mode_guard.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';

const _partPath = '/library/parts/1/2/photo.jpg';
const _thumbPath = '/library/metadata/1/thumb/2';

void main() {
  // The artwork cache keeps its files here. Downloads in widget tests reach
  // flutter_test's HTTP stub, which answers every request with status 400.
  late Directory artworkCache;
  setUpAll(() => artworkCache = Directory.systemTemp.createTempSync('photo_viewer_test'));
  tearDownAll(() => artworkCache.deleteSync(recursive: true));

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => artworkCache.path,
    );
  });
  tearDown(() {
    ImmersiveModeGuard.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  Widget wrap(Widget home, {MultiServerProvider? provider}) {
    final app = InputModeTracker(
      child: MaterialApp(theme: monoTheme(MonoPalette.dark), home: home),
    );
    return TranslationProvider(
      child: provider == null ? app : ChangeNotifierProvider<MultiServerProvider>.value(value: provider, child: app),
    );
  }

  testWidgets('a photo whose server is unavailable shows the load error and no Play action', (tester) async {
    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo())));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(t.errors.unableToLoad(context: 'Photo')), findsOneWidget);
    expect(find.byTooltip(t.common.play), findsNothing);
  });

  testWidgets('loads the file at screen size, then the thumb, then reports the failure', (tester) async {
    tester.view.physicalSize = const Size(1000, 500);
    tester.view.display.size = const Size(1000, 500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.display.reset);
    final client = _RecordingClient();
    final multi = testMultiServer(clients: [client]);

    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
    await tester.pump();

    expect(client.requests, [
      (path: _partPath, width: 1000, height: 1000, cover: false),
      (path: _thumbPath, width: 1000, height: 1000, cover: false),
    ]);
    expect(find.text(t.errors.unableToLoad(context: 'Photo')), findsOneWidget);
  });

  testWidgets('a photo that fails to download falls back to the thumb, then reports the failure', (tester) async {
    tester.view.physicalSize = const Size(1000, 500);
    tester.view.display.size = const Size(1000, 500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.display.reset);
    final client = _RecordingClient(answersWithUrls: true);
    final multi = testMultiServer(clients: [client]);
    final attempted = <String>[];
    final error = find.text(t.errors.unableToLoad(context: 'Photo'));

    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
    for (var i = 0; i < 500 && error.evaluate().isEmpty; i++) {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        final url = ((image.image as ResizeImage).imageProvider as CachedNetworkImageProvider).url;
        if (!attempted.contains(url)) attempted.add(url);
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    expect(attempted, ['https://server$_partPath?edge=1000', 'https://server$_thumbPath?edge=1000']);
    expect(error, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing drops the image from the memory cache', (tester) async {
    final client = _RecordingClient(answersWithUrls: true);
    final multi = testMultiServer(clients: [client]);
    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
    await tester.pump();

    final provider = tester.widget<Image>(find.byType(Image)).image;
    Object? key;
    unawaited(provider.obtainKey(ImageConfiguration.empty).then((value) => key = value));
    await tester.pump();
    final imageCache = PaintingBinding.instance.imageCache;
    expect(imageCache.statusForKey(key!).tracked, isTrue);

    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pump();

    expect(imageCache.statusForKey(key!).tracked, isFalse);
  });

  testWidgets('caps the requested image on very large monitors', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.display.size = const Size(7680, 4320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.display.reset);
    final client = _RecordingClient();
    final multi = testMultiServer(clients: [client]);

    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
    await tester.pump();

    expect(client.requests.first.width, 3840);
    expect(client.requests.first.height, 3840);
  });

  group('sized to the monitor', () {
    Future<_RecordingClient> openIn(WidgetTester tester, {required Size window, required Size monitor}) async {
      tester.view.physicalSize = window;
      tester.view.display.size = monitor;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.view.display.reset);
      final client = _RecordingClient();
      final multi = testMultiServer(clients: [client]);
      await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
      await tester.pump();
      return client;
    }

    testWidgets('a small window on a 1920 monitor asks for 1920', (tester) async {
      final client = await openIn(tester, window: const Size(1280, 757), monitor: const Size(1920, 1080));

      expect(client.requests.first.width, 1920);
      expect(client.requests.first.height, 1920);
    });

    testWidgets('a monitor in portrait uses its long edge', (tester) async {
      final client = await openIn(tester, window: const Size(700, 1000), monitor: const Size(1440, 2560));

      expect(client.requests.first.width, 2560);
    });

    testWidgets('the window stands in when no display size is reported', (tester) async {
      final client = await openIn(tester, window: const Size(1280, 757), monitor: Size.zero);

      expect(client.requests.first.width, 1280);
    });
  });

  test('a Plex part goes through the sized transcode endpoint without upscaling', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    PlexApiCache.initialize(database);

    final url = testPlexClient().thumbnailUrl(_partPath, width: 1000, height: 1000, cover: false);

    expect(url, contains('/photo/:/transcode?'));
    expect(url, contains('url=${Uri.encodeComponent('$_partPath?X-Plex-Token=token')}'));
    expect(url, contains('minSize=0'));
    expect(url, contains('upscale=0'));
  });

  testWidgets('BACK returns to the opener with focus restored', (tester) async {
    final openerFocus = FocusNode(debugLabel: 'opener');
    addTearDown(openerFocus.dispose);

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              focusNode: openerFocus,
              autofocus: true,
              onPressed: () =>
                  Navigator.push<void>(context, MaterialPageRoute(builder: (_) => PhotoViewerScreen(photo: _photo()))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewerScreen), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PhotoViewerScreen), findsNothing);
    expect(FocusManager.instance.primaryFocus, openerFocus);
  });

  group('keyboard and D-pad', () {
    FocusNode? primaryFocus() => FocusManager.instance.primaryFocus;

    /// Opens the viewer from a focused button, so a stray pop has somewhere to
    /// go and focus has somewhere to return to.
    Future<FocusNode> openFromButton(WidgetTester tester) async {
      final opener = FocusNode(debugLabel: 'opener');
      addTearDown(opener.dispose);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                focusNode: opener,
                autofocus: true,
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => PhotoViewerScreen(photo: _photo())),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewerScreen), findsOneWidget);
      return opener;
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    void runScenarios() {
      testWidgets('focus starts on the photo', (tester) async {
        await openFromButton(tester);

        expect(primaryFocus()?.debugLabel, 'photo_viewer_photo');
      });

      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.gameButtonA,
      ]) {
        testWidgets('${key.keyLabel} on the photo does nothing', (tester) async {
          await openFromButton(tester);

          await press(tester, key);

          expect(find.byType(PhotoViewerScreen), findsOneWidget);
          expect(primaryFocus()?.debugLabel, 'photo_viewer_photo');
        });
      }

      testWidgets('Enter on the photo goes no further than the viewer', (tester) async {
        final reachedAbove = <LogicalKeyboardKey>[];
        await tester.pumpWidget(
          wrap(
            Focus(
              onKeyEvent: (_, event) {
                reachedAbove.add(event.logicalKey);
                return KeyEventResult.ignored;
              },
              child: PhotoViewerScreen(photo: _photo()),
            ),
          ),
        );
        await tester.pump();

        await press(tester, LogicalKeyboardKey.enter);

        expect(reachedAbove, isEmpty);
      });

      testWidgets('Up reaches the back button, and Enter on it closes the viewer', (tester) async {
        final opener = await openFromButton(tester);

        await press(tester, LogicalKeyboardKey.arrowUp);
        expect(primaryFocus()?.debugLabel, 'photo_viewer_back');
        expect(find.byType(PhotoViewerScreen), findsOneWidget);

        await press(tester, LogicalKeyboardKey.enter);
        expect(find.byType(PhotoViewerScreen), findsNothing);
        expect(primaryFocus(), opener);
      });

      testWidgets('Down leaves the back button, after which Enter does nothing again', (tester) async {
        await openFromButton(tester);

        await press(tester, LogicalKeyboardKey.arrowUp);
        await press(tester, LogicalKeyboardKey.arrowDown);
        expect(primaryFocus()?.debugLabel, 'photo_viewer_photo');

        await press(tester, LogicalKeyboardKey.enter);
        expect(find.byType(PhotoViewerScreen), findsOneWidget);
      });

      testWidgets('Left and Right move nothing, from the photo or the back button', (tester) async {
        await openFromButton(tester);

        for (final label in ['photo_viewer_photo', 'photo_viewer_back']) {
          if (label == 'photo_viewer_back') await press(tester, LogicalKeyboardKey.arrowUp);
          await press(tester, LogicalKeyboardKey.arrowLeft);
          await press(tester, LogicalKeyboardKey.arrowRight);
          expect(primaryFocus()?.debugLabel, label);
          expect(find.byType(PhotoViewerScreen), findsOneWidget);
        }
      });

      testWidgets('Escape still closes the viewer from the photo', (tester) async {
        final opener = await openFromButton(tester);

        await press(tester, LogicalKeyboardKey.escape);

        expect(find.byType(PhotoViewerScreen), findsNothing);
        expect(primaryFocus(), opener);
      });
    }

    group('default', runScenarios);

    group('Force TV', () {
      setUp(() async => TvDetectionService.getInstance(forceTv: true));
      tearDown(TvDetectionService.debugReset);

      test('is on', () => expect(PlatformDetector.isTV(), isTrue));

      runScenarios();
    });
  });

  group('header', () {
    setUpAll(() => initializeDateFormatting('en'));

    Future<void> openPhoto(WidgetTester tester, MediaItem photo) async {
      await tester.pumpWidget(wrap(PhotoViewerScreen(photo: photo)));
      await tester.pump();
    }

    testWidgets('shows the title, and the capture date on a second line', (tester) async {
      await openPhoto(
        tester,
        _photo().copyWith(title: 'DSC05369_v1', parentTitle: 'Heri 80', originallyAvailableAt: '2020-12-24'),
      );

      final title = find.text('DSC05369_v1');
      final date = find.text('December 24, 2020');
      expect(title, findsOneWidget);
      expect(date, findsOneWidget);
      expect(find.text('Heri 80'), findsNothing);
      expect(tester.getTopLeft(date).dy, greaterThan(tester.getBottomLeft(title).dy - 1));
      expect(tester.widget<Text>(date).style!.fontSize, lessThan(tester.widget<Text>(title).style!.fontSize!));
    });

    testWidgets('falls back to the album name when the title is empty', (tester) async {
      await openPhoto(tester, _photo().copyWith(title: '', parentTitle: 'Heri 80'));

      expect(find.text('Heri 80'), findsOneWidget);
    });

    testWidgets('shows one line when there is no date', (tester) async {
      await openPhoto(tester, _photo().copyWith(title: 'DSC05369_v1', parentTitle: 'Heri 80'));

      final header = find.ancestor(of: find.text('DSC05369_v1'), matching: find.byType(Column)).first;
      expect(find.descendant(of: header, matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets('shows an unparseable date as the server sent it', (tester) async {
      await openPhoto(tester, _photo().copyWith(originallyAvailableAt: 'sometime'));

      expect(find.text('sometime'), findsOneWidget);
    });

    testWidgets('the load error names the photo by the same title', (tester) async {
      await openPhoto(tester, _photo().copyWith(title: '', parentTitle: 'Heri 80'));

      expect(find.text(t.errors.unableToLoad(context: 'Heri 80')), findsOneWidget);
    });

    testWidgets('a Plex photo row carries its capture date to the header', (tester) async {
      final photo = PlexMappers.mediaItem(
        PlexMetadataDto.fromJsonWithImages({
          'ratingKey': '302855',
          'key': '/library/metadata/302855',
          'type': 'photo',
          'title': 'DSC05369_v1',
          'parentTitle': 'Heri 80',
          'originallyAvailableAt': '2020-12-24',
        }),
      );

      await openPhoto(tester, photo);

      expect(find.text('DSC05369_v1'), findsOneWidget);
      expect(find.text('December 24, 2020'), findsOneWidget);
    });
  });

  testWidgets('hides the system bars on a phone and restores them on close', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode') calls.add(call);
      return null;
    });

    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo())));
    expect(calls.map((call) => call.arguments), ['SystemUiMode.immersiveSticky']);

    calls.clear();
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pump();
    expect(calls.map((call) => call.arguments), contains('SystemUiMode.edgeToEdge'));
  });

  testWidgets('a failure to show the system bars again is logged, not thrown', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode' && call.arguments != 'SystemUiMode.immersiveSticky') {
        throw PlatformException(code: 'unavailable');
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    MemoryLogOutput.clearLogs();

    await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo())));
    await tester.pumpWidget(wrap(const SizedBox()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(MemoryLogOutput.getLogs().map((entry) => entry.message), contains('Failed to restore system UI'));
  });

  group('zoom', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo())));
      await tester.pump();
    }

    /// The zoom InteractiveViewer applies, read from the transform it paints.
    double scaleOf(WidgetTester tester) => tester
        .widget<Transform>(find.descendant(of: find.byType(InteractiveViewer), matching: find.byType(Transform)).first)
        .transform
        .getMaxScaleOnAxis();

    testWidgets('a pinch zooms in', (tester) async {
      await open(tester);
      final center = tester.getCenter(find.byType(InteractiveViewer));

      final first = await tester.startGesture(center - const Offset(50, 0));
      final second = await tester.startGesture(center + const Offset(50, 0));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await first.moveBy(const Offset(-10, 0));
        await second.moveBy(const Offset(10, 0));
        await tester.pump();
      }

      expect(scaleOf(tester), greaterThan(2));
      await first.up();
      await second.up();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the mouse wheel zooms in', (tester) async {
      await open(tester);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);

      await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.byType(InteractiveViewer))));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, -500)));
      await tester.pump();

      expect(scaleOf(tester), greaterThan(1));
    });

    testWidgets('D-pad keys do not zoom', (tester) async {
      await open(tester);

      for (final key in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }

      expect(scaleOf(tester), 1);
      expect(find.byType(PhotoViewerScreen), findsOneWidget);
    });

    testWidgets('maximising the window afterwards does not refetch', (tester) async {
      tester.view.physicalSize = const Size(1280, 757);
      tester.view.display.size = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.view.display.reset);
      final client = _RecordingClient(answersWithUrls: true);
      final multi = testMultiServer(clients: [client]);
      await tester.pumpWidget(wrap(PhotoViewerScreen(photo: _photo()), provider: multi.provider));
      await tester.pump();

      tester.view.physicalSize = const Size(1920, 1080);
      await tester.pump();

      // Rebuilding asks for the same URL again, which the image cache serves.
      expect(client.requests.map((request) => request.width), everyElement(1920));
    });
  });
}

MediaItem _photo() =>
    testMediaItem(
      id: '1',
      backend: MediaBackend.plex,
      kind: MediaKind.photo,
      title: 'Photo',
      thumbPath: _thumbPath,
      serverId: 'server_1',
    ).copyWith(
      mediaVersions: const [
        MediaVersion(
          id: '1',
          parts: [MediaPart(id: 'p1', streamPath: _partPath)],
        ),
      ],
    );

/// Answers every image request with no URL, which the viewer treats as a
/// failed load, so the sequence of attempts shows without touching the network.
class _RecordingClient implements MediaServerClient {
  _RecordingClient({this.answersWithUrls = false});

  /// Answers with a URL naming the requested path and size instead.
  final bool answersWithUrls;
  final requests = <({String? path, int? width, int? height, bool cover})>[];

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    requests.add((path: path, width: width, height: height, cover: cover));
    return answersWithUrls ? 'https://server$path?edge=$width' : '';
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
