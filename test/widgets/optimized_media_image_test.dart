import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
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
        MediaImageHelper.serverArtworkProvider(imageUrl: imageUrl, memWidth: 200, memHeight: 180) as ResizeImage;
    final sharedCached = sharedProvider.imageProvider as CachedNetworkImageProvider;

    expect(widgetCached, sharedCached);
    expect(widgetProvider.width, sharedProvider.width);
    expect(widgetProvider.width, 200);
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
    expect(localResize.width, 120);
    expect(localResize.height, 180);
    expect(localResize.policy, ResizeImagePolicy.fit);
    expect(localProvider.file.path, file.path);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
