import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:vibe_stream/utils/media_image_helper.dart';
import 'package:vibe_stream/widgets/optimized_media_image.dart';

void main() {
  testWidgets('network images use decode resize without disk cache resize', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 160,
          height: 90,
          child: OptimizedMediaImage.thumb(
            imagePath: 'https://example.invalid/episode-thumb.jpg',
            width: 160,
            height: 90,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final resizeProvider = image.image as ResizeImage;
    final cachedProvider = resizeProvider.imageProvider as CachedNetworkImageProvider;

    expect(resizeProvider.height, isNotNull);
    expect(cachedProvider.maxHeight, isNull);
    expect(cachedProvider.maxWidth, isNull);
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
}
