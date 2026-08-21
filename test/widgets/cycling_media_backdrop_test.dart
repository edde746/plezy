import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/widgets/cycling_media_backdrop.dart';
import 'package:plezy/widgets/tv_spotlight_background.dart';

import '../test_helpers/prefs.dart';

const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
const _rotationInterval = Duration(seconds: 1);
const _fadeDuration = Duration(milliseconds: 20);

void main() {
  late Directory directory;
  late File first;
  late File second;
  late File third;
  late Map<String, MemoryImage> imageProviders;

  setUp(() async {
    // TvSpotlightBackground reads the corner-backdrop pref during build.
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    directory = Directory.systemTemp.createTempSync('plezy-backdrop-cycle');
    final bytes = base64Decode(_png);
    first = File('${directory.path}/first.png')..writeAsBytesSync(bytes);
    second = File('${directory.path}/second.png')..writeAsBytesSync(bytes);
    third = File('${directory.path}/third.png')..writeAsBytesSync(bytes);
    imageProviders = {
      first.path: MemoryImage(base64Decode(_png)),
      second.path: MemoryImage(base64Decode(_png)),
      third.path: MemoryImage(base64Decode(_png)),
    };
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  Widget buildBackdrop(
    List<String> paths, {
    bool active = true,
    bool disableAnimations = false,
    bool tickerEnabled = true,
    Object? mediaKey = 'movie-1',
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 180), devicePixelRatio: 1, disableAnimations: disableAnimations),
        child: TickerMode(
          enabled: tickerEnabled,
          child: SizedBox(
            width: 320,
            height: 180,
            child: CyclingMediaBackdrop(
              mediaKey: mediaKey,
              imagePaths: paths,
              client: null,
              imageProviderResolver: (path) => imageProviders[path],
              allowNetwork: false,
              active: active,
              width: 320,
              height: 180,
              fallbackColor: Colors.black,
              rotationInterval: _rotationInterval,
              fadeDuration: _fadeDuration,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAsyncBackdrop(
    List<String> paths, {
    required Future<bool> Function(File file) fileExists,
    Object? mediaKey = 'movie-1',
    List<String> fallbackPaths = const [],
  }) {
    final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: 320,
      displayHeight: 180,
      imageType: ImageType.art,
    );
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 180), devicePixelRatio: 1),
        child: SizedBox(
          width: 320,
          height: 180,
          child: CyclingMediaBackdrop(
            mediaKey: mediaKey,
            imagePaths: paths,
            fallbackImagePaths: fallbackPaths,
            client: null,
            localArtworkPathResolver: (path) => path,
            imageProviderResolver: (path) {
              final provider = imageProviders[path];
              return provider == null
                  ? null
                  : MediaImageHelper.boundedDecode(provider, memWidth: memWidth, memHeight: memHeight);
            },
            localFileExists: fileExists,
            allowNetwork: false,
            width: 320,
            height: 180,
            fallbackColor: Colors.black,
            rotationInterval: _rotationInterval,
            fadeDuration: _fadeDuration,
          ),
        ),
      ),
    );
  }

  String pathForProvider(ImageProvider provider) {
    while (provider is ResizeImage) {
      provider = provider.imageProvider;
    }
    if (provider case FileImage(:final file)) return file.path;
    return imageProviders.entries.singleWhere((entry) => identical(entry.value, provider)).key;
  }

  List<String> renderedFilePaths(WidgetTester tester) {
    return tester.widgetList<Image>(find.byType(Image)).map((image) {
      return pathForProvider(image.image);
    }).toList();
  }

  void expectVisibleBackdrop(WidgetTester tester, String path) {
    final image = tester.widgetList<Image>(find.byType(Image)).last;
    expect(pathForProvider(image.image), path);
    expect(image.opacity?.value ?? 1, 1);
  }

  Future<void> finishImageTransition(WidgetTester tester, {Duration fadeDuration = _fadeDuration}) async {
    final incoming = find.byType(Image).last;
    final image = tester.widget<Image>(incoming);
    var source = image.image;
    while (source is ResizeImage) {
      source = source.imageProvider;
    }
    if (source is MemoryImage) {
      final configuration = createLocalImageConfiguration(tester.element(incoming));
      await tester.runAsync(() {
        final frame = Completer<void>();
        final stream = image.image.resolve(configuration);
        late final ImageStreamListener listener;
        listener = ImageStreamListener(
          (_, _) {
            stream.removeListener(listener);
            frame.complete();
          },
          onError: (Object error, StackTrace? stackTrace) {
            stream.removeListener(listener);
            frame.completeError(error, stackTrace);
          },
        );
        stream.addListener(listener);
        return frame.future;
      });
    } else {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    }
    await tester.pump();
    await tester.pump(fadeDuration);
    await tester.pump();
  }

  testWidgets('rotates loaded backdrops in order and wraps', (tester) async {
    await tester.pumpWidget(buildBackdrop([first.path, second.path, third.path]));
    expect(renderedFilePaths(tester), [first.path]);

    await tester.pump(_rotationInterval);
    expect(renderedFilePaths(tester).last, second.path);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    await tester.pump(_rotationInterval);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, third.path);

    await tester.pump(_rotationInterval);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, first.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('skips a missing incoming image without dropping the settled backdrop', (tester) async {
    final missing = '${directory.path}/missing.png';
    await tester.pumpWidget(buildBackdrop([first.path, missing, third.path]));

    await tester.pump(_rotationInterval);
    expect(renderedFilePaths(tester), [first.path]);
    await tester.pump();
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, third.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pending local rotation keeps the settled backdrop until the file resolves', (tester) async {
    final checks = <String, Completer<bool>>{};
    final probes = <String, int>{};
    Future<bool> fileExists(File file) {
      probes.update(file.path, (count) => count + 1, ifAbsent: () => 1);
      return (checks[file.path] ??= Completer<bool>()).future;
    }

    await tester.pumpWidget(buildAsyncBackdrop([first.path, second.path], fileExists: fileExists));
    checks[first.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, first.path);

    await tester.pump(_rotationInterval);
    expect(checks[second.path], isNotNull);
    expect(renderedFilePaths(tester), [first.path]);
    expect(probes[second.path], 1);

    checks[second.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    expect(renderedFilePaths(tester), [first.path, second.path]);
    final incoming = tester.widget<Image>(find.byType(Image).last);
    final resized = incoming.image as ResizeImage;
    final (expectedWidth, expectedHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: 320,
      displayHeight: 180,
      imageType: ImageType.art,
    );
    expect(resized.width, expectedWidth);
    expect(resized.height, expectedHeight);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('late local completion cannot replace a newer media path', (tester) async {
    final checks = <String, Completer<bool>>{};
    Future<bool> fileExists(File file) => (checks[file.path] ??= Completer<bool>()).future;

    await tester.pumpWidget(buildAsyncBackdrop([first.path], fileExists: fileExists, mediaKey: 'movie-a'));
    expect(find.byType(Image), findsNothing);

    await tester.pumpWidget(buildAsyncBackdrop([second.path], fileExists: fileExists, mediaKey: 'movie-b'));
    checks[second.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    checks[first.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(renderedFilePaths(tester), [second.path]);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('confirmed missing local path advances once and stays cached', (tester) async {
    final missing = '${directory.path}/missing.png';
    final checks = <String, Completer<bool>>{};
    final probes = <String, int>{};
    Future<bool> fileExists(File file) {
      probes.update(file.path, (count) => count + 1, ifAbsent: () => 1);
      return (checks[file.path] ??= Completer<bool>()).future;
    }

    await tester.pumpWidget(buildAsyncBackdrop([first.path], fileExists: fileExists, mediaKey: 'settled'));
    checks[first.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, first.path);

    await tester.pumpWidget(
      buildAsyncBackdrop([missing, second.path], fileExists: fileExists, mediaKey: 'replacement'),
    );
    expect(renderedFilePaths(tester), [first.path]);

    checks[missing]!.complete(false);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(checks[second.path], isNotNull);
    expect(renderedFilePaths(tester), [first.path]);

    checks[second.path]!.complete(true);
    await tester.pump();
    await tester.pump();
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(
      buildAsyncBackdrop([missing, second.path], fileExists: fileExists, mediaKey: 'replacement'),
    );
    await tester.pump(_rotationInterval * 2);
    expect(probes[missing], 1);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pauses while the application is not resumed', (tester) async {
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    await tester.pumpWidget(buildBackdrop([first.path, second.path]));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(_rotationInterval * 3);
    expect(renderedFilePaths(tester), [first.path]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(_rotationInterval - const Duration(milliseconds: 1));
    expect(renderedFilePaths(tester), [first.path]);
    await tester.pump(const Duration(milliseconds: 1));
    await finishImageTransition(tester);
    expect(renderedFilePaths(tester), [second.path]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pauses while its TickerMode subtree is hidden', (tester) async {
    final paths = [first.path, second.path];
    await tester.pumpWidget(buildBackdrop(paths, tickerEnabled: false));

    await tester.pump(_rotationInterval * 3);
    expect(renderedFilePaths(tester), [first.path]);

    await tester.pumpWidget(buildBackdrop(paths));
    await tester.pump(_rotationInterval);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeps one backdrop static', (tester) async {
    await tester.pumpWidget(buildBackdrop([first.path]));

    await tester.pump(_rotationInterval * 3);
    expect(renderedFilePaths(tester), [first.path]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resets to the first backdrop when media changes', (tester) async {
    await tester.pumpWidget(buildBackdrop([first.path, second.path]));
    await tester.pump(_rotationInterval);
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, second.path);

    await tester.pumpWidget(buildBackdrop([third.path, first.path], mediaKey: 'movie-2'));
    await finishImageTransition(tester);
    expectVisibleBackdrop(tester, third.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('does not auto-rotate when reduced motion is requested', (tester) async {
    await tester.pumpWidget(buildBackdrop([first.path, second.path], disableAnimations: true));

    await tester.pump(_rotationInterval * 3);
    expect(renderedFilePaths(tester), [first.path]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TV spotlight rotates the Jellyfin item backdrop list', (tester) async {
    final item = JellyfinMediaItem(
      id: 'show-1',
      kind: MediaKind.show,
      artPath: first.path,
      backdropPaths: [first.path, second.path],
      serverId: 'server-1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TvSpotlightBackground(
          item: item,
          client: null,
          showInfo: false,
          allowNetwork: false,
          localArtworkPathResolver: (path) => path,
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    await tester.pump();
    expect(renderedFilePaths(tester), [first.path]);

    await tester.pump(const Duration(seconds: 10));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    await tester.pump();
    expect(renderedFilePaths(tester).last, second.path);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
