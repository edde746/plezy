import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

void main() {
  testWidgets('network widget matches the shared server artwork provider', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const imageUrl = 'https://example.invalid/episode-thumb.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 160,
          height: 90,
          child: OptimizedMediaImage.thumb(imagePath: imageUrl, width: 160, height: 90),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final widgetProvider = image.image as ResizeImage;
    final widgetCached = widgetProvider.imageProvider as CachedNetworkImageProvider;
    final sharedProvider =
        MediaImageHelper.serverArtworkProvider(imageUrl: imageUrl, memWidth: 320, memHeight: 180) as ResizeImage;
    final sharedCached = sharedProvider.imageProvider as CachedNetworkImageProvider;

    expect(widgetCached, sharedCached);
    expect(widgetProvider.width, sharedProvider.width);
    expect(widgetProvider.width, 320);
    expect(widgetProvider.height, sharedProvider.height);
    expect(widgetProvider.height, 180);
    expect(widgetProvider.policy, sharedProvider.policy);
    expect(widgetProvider.policy, ResizeImagePolicy.fit);
    expect(widgetProvider.allowUpscaling, sharedProvider.allowUpscaling);
    expect(widgetProvider.allowUpscaling, isFalse);
    expect(widgetCached.url, sharedCached.url);
    expect(widgetCached.url, imageUrl);
    expect(widgetCached.cacheKey, sharedCached.cacheKey);
    expect(widgetCached.cacheKey, isNotNull);
    expect(widgetCached.headers, sharedCached.headers);
    expect(widgetCached.headers, const {'User-Agent': 'Plezy'});
    expect(widgetCached.maxWidth, sharedCached.maxWidth);
    expect(widgetCached.maxWidth, isNull);
    expect(widgetCached.maxHeight, sharedCached.maxHeight);
    expect(widgetCached.maxHeight, isNull);
  });

  testWidgets('supersampled artwork paints through the bicubic kernel (#1697)', (tester) async {
    // The fetch/decode headroom only buys sharpness if the paint resolves it
    // with a phase-stable kernel: FilterQuality.medium snaps to a half-size
    // mipmap level and throws the headroom away again. Nothing else in the
    // suite would notice that regression — it is visual only.
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.display.reset);
    tester.view.display.size = const Size(1920, 1080);

    Future<FilterQuality> qualityFor(ImageType type, {required double dpr}) async {
      tester.view.devicePixelRatio = dpr;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 160,
            height: 90,
            child: OptimizedMediaImage(
              imagePath: 'https://example.invalid/artwork-${type.name}-$dpr.jpg',
              width: 160,
              height: 90,
              imageType: type,
            ),
          ),
        ),
      );
      return tester.widget<Image>(find.byType(Image)).filterQuality;
    }

    expect(await qualityFor(ImageType.poster, dpr: 1), FilterQuality.high);
    expect(await qualityFor(ImageType.thumb, dpr: 1), FilterQuality.high);
    // Backdrops are never supersampled, and neither is anything on a display
    // dense enough that the headroom would be invisible — nothing for cubic
    // to resolve in either case.
    expect(await qualityFor(ImageType.art, dpr: 1), FilterQuality.low);
    expect(await qualityFor(ImageType.poster, dpr: 3), FilterQuality.low);
  });

  testWidgets('artwork dim tints image and fallback paint', (tester) async {
    final artworkDim = AnimationController(vsync: tester);
    addTearDown(artworkDim.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 160,
          height: 90,
          child: OptimizedMediaImage.thumb(
            imagePath: 'https://example.invalid/dimmed-thumb.jpg',
            width: 160,
            height: 90,
            artworkDim: artworkDim,
          ),
        ),
      ),
    );

    expect(tester.widget<Image>(find.byType(Image)).color, isNull);

    artworkDim.value = 0.3;
    await tester.pump();

    final dimmedImage = tester.widget<Image>(find.byType(Image));
    expect(dimmedImage.color, Colors.black.withValues(alpha: 0.3));
    expect(dimmedImage.colorBlendMode, BlendMode.srcATop);

    artworkDim.value = 0;
    await tester.pump();

    final restoredImage = tester.widget<Image>(find.byType(Image));
    expect(restoredImage.color, isNull);
    expect(restoredImage.colorBlendMode, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 160,
          height: 90,
          child: OptimizedMediaImage.thumb(imagePath: null, width: 160, height: 90, artworkDim: artworkDim),
        ),
      ),
    );
    final placeholderFinder = find.descendant(of: find.byType(OptimizedMediaImage), matching: find.byType(Container));
    final baseColor = tester.widget<Container>(placeholderFinder).color!;

    artworkDim.value = 0.3;
    await tester.pump();

    expect(
      tester.widget<Container>(placeholderFinder).color,
      Color.alphaBlend(Colors.black.withValues(alpha: 0.3), baseColor),
    );
  });

  testWidgets('failed image placeholders keep explicit dimensions in loose layouts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OptimizedMediaImage(
                  client: null,
                  imagePath: 'https://example.invalid/broken-actor-image.jpg',
                  width: 96,
                  height: 96,
                  imageType: ImageType.avatar,
                  fallbackIcon: Symbols.person_rounded,
                ),
                const SizedBox(height: 8),
                const Text('Actor Name'),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.person_rounded), findsOneWidget);

    final placeholder = find.descendant(of: find.byType(OptimizedMediaImage), matching: find.byType(Container));
    expect(placeholder, findsOneWidget);
    expect(tester.getSize(placeholder), const Size(96, 96));
  });

  testWidgets('local resolver rejects stale path completions and disposal completions', (tester) async {
    final checks = <String, Completer<bool>>{};
    final probes = <String, int>{};
    var path = '/artwork/a.png';
    late StateSetter rebuild;
    Future<bool> fileExists(File file) {
      probes.update(file.path, (count) => count + 1, ifAbsent: () => 1);
      return (checks[file.path] ??= Completer<bool>()).future;
    }

    Widget resolutionBuilder(BuildContext context, LocalFileResolution resolution, File? file) {
      return Text('${resolution.name}:${file?.path ?? path}');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return ResolvedLocalFile(path: path, fileExists: fileExists, builder: resolutionBuilder);
          },
        ),
      ),
    );
    expect(find.text('pending:/artwork/a.png'), findsOneWidget);

    rebuild(() => path = '/artwork/b.png');
    await tester.pump();
    rebuild(() {});
    await tester.pump();
    expect(find.text('pending:/artwork/b.png'), findsOneWidget);
    expect(probes['/artwork/b.png'], 1);

    checks['/artwork/a.png']!.complete(true);
    await tester.pump();
    expect(find.text('pending:/artwork/b.png'), findsOneWidget);

    checks['/artwork/b.png']!.complete(true);
    await tester.pump();
    await tester.pump();
    expect(find.text('present:/artwork/b.png'), findsOneWidget);

    rebuild(() => path = '/artwork/c.png');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    checks['/artwork/c.png']!.complete(true);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('local resolver caches confirmed missing paths only when requested', (tester) async {
    final probes = <String, int>{};
    var path = '/artwork/missing-a.png';
    late StateSetter rebuild;
    Future<bool> fileExists(File file) {
      probes.update(file.path, (count) => count + 1, ifAbsent: () => 1);
      return Future<bool>.value(false);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return ResolvedLocalFile(
              path: path,
              cacheMissing: true,
              fileExists: fileExists,
              builder: (context, resolution, file) => Text('${resolution.name}:$path'),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('missing:/artwork/missing-a.png'), findsOneWidget);
    expect(probes['/artwork/missing-a.png'], 1);

    rebuild(() {});
    await tester.pump();
    rebuild(() {});
    await tester.pump();
    expect(probes['/artwork/missing-a.png'], 1);

    rebuild(() => path = '/artwork/missing-b.png');
    await tester.pump();
    await tester.pump();
    expect(probes['/artwork/missing-b.png'], 1);

    rebuild(() => path = '/artwork/missing-a.png');
    await tester.pump();
    expect(find.text('missing:/artwork/missing-a.png'), findsOneWidget);
    expect(probes['/artwork/missing-a.png'], 1);
  });

  testWidgets('same local artwork path re-resolves after the file appears', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final directory = Directory.systemTemp.createTempSync('plezy-image-test');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/poster.png');
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return OptimizedMediaImage.thumb(
              imagePath: null,
              localFilePath: file.path,
              width: 80,
              height: 120,
              fallbackIcon: Symbols.image_not_supported_rounded,
            );
          },
        ),
      ),
    );

    expect(find.byIcon(Symbols.image_not_supported_rounded), findsNothing);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.byIcon(Symbols.image_not_supported_rounded), findsOneWidget);

    file.writeAsBytesSync(
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='),
      flush: true,
    );
    rebuild(() {});
    await tester.pump();

    expect(find.byIcon(Symbols.image_not_supported_rounded), findsNothing);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    await tester.pump();
    expect(file.existsSync(), isTrue);
    expect(find.byIcon(Symbols.image_not_supported_rounded), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    final localImage = tester.widget<Image>(find.byType(Image));
    final localResize = localImage.image as ResizeImage;
    final localProvider = localResize.imageProvider as FileImage;
    expect(localResize.width, 160);
    expect(localResize.height, 240);
    expect(localResize.policy, ResizeImagePolicy.fit);
    expect(localProvider.file.path, file.path);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('retains higher-res image when layout shrinks to avoid server re-transcode', (tester) async {
    final sizeNotifier = ValueNotifier<Size>(const Size(300, 450));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    final initialUrl = cachedProvider.url;
    final initialWidth = resizeProvider.width!;
    final initialHeight = resizeProvider.height!;
    expect(initialWidth, greaterThan(0));
    expect(initialHeight, greaterThan(0));

    // Shrink layout dimensions (e.g. window resized smaller)
    sizeNotifier.value = const Size(100, 150);
    await tester.pump();

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    // URL and decode size must not be downgraded to a smaller tier; retains higher-res image!
    expect(cachedProvider.url, equals(initialUrl));
    expect(resizeProvider.width, initialWidth);
    expect(resizeProvider.height, initialHeight);
  });

  testWidgets('debounces upgrade when layout expands during rapid resize', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(100, 150));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    final initialUrl = cachedProvider.url;
    final initialWidth = resizeProvider.width!;
    final initialHeight = resizeProvider.height!;

    // Enlarge layout dimensions (e.g. window dragging larger)
    sizeNotifier.value = const Size(300, 450);
    await tester.pump(); // immediate frame

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    // Immediately after frame, URL remains stable (no intermediate request)
    expect(cachedProvider.url, equals(initialUrl));
    expect(resizeProvider.width, initialWidth);
    expect(resizeProvider.height, initialHeight);

    // After debounce settles (250ms), upgrades to higher tier
    await tester.pump(const Duration(milliseconds: 300));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    expect(cachedProvider.url, isNot(equals(initialUrl)));
    expect(resizeProvider.width!, greaterThan(initialWidth));
    expect(resizeProvider.height!, greaterThan(initialHeight));
  });

  testWidgets('debounces multi-step growth and restarts timer rather than throttling', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(100, 150));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    final initialUrl = cachedProvider.url;
    final initialWidth = resizeProvider.width!;
    final initialHeight = resizeProvider.height!;

    // Step 1: grow to 200x300 at t=0
    sizeNotifier.value = const Size(200, 300);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Step 2: grow to 300x450 at t=100ms (restarts debounce timer)
    sizeNotifier.value = const Size(300, 450);
    await tester.pump();

    // After another 150ms (total 250ms from step 1):
    // A throttled timer would expire at 250ms. Since debounced, it must still be holding initialUrl!
    await tester.pump(const Duration(milliseconds: 150));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, equals(initialUrl));
    expect(resizeProvider.width, initialWidth);
    expect(resizeProvider.height, initialHeight);

    // Settle past debounce from step 2 (another 150ms)
    await tester.pump(const Duration(milliseconds: 150));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, contains('maxWidth=480&maxHeight=720'));
    expect(resizeProvider.width, 480);
    expect(resizeProvider.height, 720);
  });

  testWidgets('cancels pending upgrade when layout shrinks before debounce expires', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(200, 300));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    final initialUrl = cachedProvider.url;
    final initialWidth = resizeProvider.width!;
    final initialHeight = resizeProvider.height!;

    // Grow: initiates pending upgrade timer
    sizeNotifier.value = const Size(400, 600);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Shrink before timer expires: cancels pending upgrade
    sizeNotifier.value = const Size(100, 150);
    await tester.pump();

    // Advance time well past original debounce duration
    await tester.pump(const Duration(milliseconds: 300));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    // Must still retain initial committed size (not upgraded to 400x600 and not shrunk to 100x150)
    expect(cachedProvider.url, equals(initialUrl));
    expect(resizeProvider.width, initialWidth);
    expect(resizeProvider.height, initialHeight);
  });

  testWidgets('reduced tier debounces growth but commits shrinks immediately', (tester) async {
    DevicePerformance.debugReset(override: VisualEffectsSetting.reduced);
    addTearDown(DevicePerformance.debugReset);

    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(100, 150));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    final initialUrl = cachedProvider.url;
    expect(cachedProvider.url, contains('maxWidth=160&maxHeight=240'));
    expect(resizeProvider.width, 120);
    expect(resizeProvider.height, 180);

    // Growth: 100x150 -> 300x450 must debounce (not commit immediately on reduced tier)
    sizeNotifier.value = const Size(300, 450);
    await tester.pump();

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, equals(initialUrl));
    expect(resizeProvider.width, 120);
    expect(resizeProvider.height, 180);

    // After debounce expires, upgrades to the 300x450 tier (reduced tier = 320x480 at DPR 1.0)
    await tester.pump(const Duration(milliseconds: 300));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, contains('maxWidth=320&maxHeight=480'));
    expect(resizeProvider.width, 320);
    expect(resizeProvider.height, 480);

    // Shrink: 300x450 -> 100x150 commits immediately without retention to save RAM
    sizeNotifier.value = const Size(100, 150);
    await tester.pump();

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, contains('maxWidth=160&maxHeight=240'));
    expect(resizeProvider.width, 120);
    expect(resizeProvider.height, 180);
  });

  testWidgets('upgrade on one axis retains larger size on the other axis', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(200, 200));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
                imageType: ImageType.logo,
              ),
            ),
          ),
        ),
      ),
    );

    var image = tester.widget<Image>(find.byType(Image));
    var resizeProvider = image.image as ResizeImage;
    var cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;
    expect(cachedProvider.url, contains('maxWidth=320&maxHeight=300'));
    expect(resizeProvider.width, 320);
    expect(resizeProvider.height, 300);

    // Logo resize: width expands (200 -> 400), height shrinks (200 -> 60)
    sizeNotifier.value = const Size(400, 60);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    image = tester.widget<Image>(find.byType(Image));
    resizeProvider = image.image as ResizeImage;
    cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    // Width upgraded to 600, while height retention is preserved at 300 instead of dropping to 240
    expect(cachedProvider.url, contains('maxWidth=600&maxHeight=300'));
    expect(resizeProvider.width, 600);
    expect(resizeProvider.height, 300);
  });

  testWidgets('pending upgrade refreshes logical size across DPR change', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    tester.view.display.size = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.display.reset();
    });

    final sizeNotifier = ValueNotifier<Size>(const Size(50, 75));
    addTearDown(sizeNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ValueListenableBuilder<Size>(
            valueListenable: sizeNotifier,
            builder: (context, size, _) => SizedBox(
              width: size.width,
              height: size.height,
              child: const OptimizedMediaImage.poster(
                imagePath: 'https://jf.example/Items/1/Images/Primary?api_key=token',
              ),
            ),
          ),
        ),
      ),
    );

    // Step 1: poster expands to 200x300 at 1x (target bucket 400x600)
    sizeNotifier.value = const Size(200, 300);
    await tester.pump();

    // Step 2: in next frame, DPR switches to 3.0 and layout becomes 128x192 (same 400x600 bucket)
    tester.view.devicePixelRatio = 3.0;
    sizeNotifier.value = const Size(128, 192);
    await tester.pump();

    // Settle past debounce duration
    await tester.pump(const Duration(milliseconds: 300));

    final image = tester.widget<Image>(find.byType(Image));
    final resizeProvider = image.image as ResizeImage;
    final cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    // Committed logical size was refreshed to 128x192 (not stale 200x300), so at 3x DPR
    // it requests 400x600, NOT 600x900.
    expect(cachedProvider.url, contains('maxWidth=400&maxHeight=600'));
    expect(resizeProvider.width, 400);
    expect(resizeProvider.height, 600);
  });
}
