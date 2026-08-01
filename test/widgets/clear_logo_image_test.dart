import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/widgets/optimized_media_image.dart';

void main() {
  Widget buildLogo({String? logoPath, double width = 400, double height = 120, double devicePixelRatio = 3}) {
    return MaterialApp(
      home: MediaQuery(
        // DPR 3 is where the phone hero logo slot (400×120) asks for a
        // 1200-wide decode and runs into the 1000px heroLogo width cap.
        data: MediaQueryData(size: const Size(390, 844), devicePixelRatio: devicePixelRatio, disableAnimations: true),
        child: Center(
          child: ClearLogoImage(
            client: null,
            logoPath: logoPath,
            width: width,
            height: height,
            fallbackBuilder: (context) => const Text('Fallback Title'),
          ),
        ),
      ),
    );
  }

  testWidgets('decodes with the aspect-preserving fit policy', (tester) async {
    await tester.pumpWidget(buildLogo(logoPath: 'https://example.com/logo.png'));

    final provider = tester.widget<Image>(find.byType(Image)).image;

    // Both axes stay bounded so an oversized original can't blow the decode
    // budget, but `fit` keeps the source ratio: capping only the width under
    // the default `exact` policy is what squashed hero logos on phones.
    expect(
      provider,
      isA<ResizeImage>()
          .having((r) => r.policy, 'policy', ResizeImagePolicy.fit)
          .having((r) => r.width, 'width', isNotNull)
          .having((r) => r.height, 'height', isNotNull),
    );
  });

  testWidgets('bounds the TV spotlight slot without pinning it to the slot ratio', (tester) async {
    // The TV slot (520×150 at the 2.0 TV DPR floor) asks for 1040×300 and is
    // capped to 1000×300 — the width clamps, the height doesn't. Under the old
    // `exact` decode that pinned every TV logo to 3.33∶1: a 4313×1035 source
    // served at 1250×300 rendered as 1000×300, 1.25x too tall (checked against
    // PMS 1.43). `fit` scales it to 1000×240 and keeps 4.17∶1.
    await tester.pumpWidget(
      buildLogo(
        logoPath: 'https://example.com/logo.png',
        width: TvLayoutConstants.heroLogoWidth,
        height: TvLayoutConstants.heroLogoHeight,
        devicePixelRatio: 2,
      ),
    );

    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<ResizeImage>()
          .having((r) => r.policy, 'policy', ResizeImagePolicy.fit)
          .having((r) => r.width, 'width', 1000)
          .having((r) => r.height, 'height', 300),
    );
  });

  testWidgets('falls back to the title when there is no logo path', (tester) async {
    await tester.pumpWidget(buildLogo(logoPath: null));

    expect(find.text('Fallback Title'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('falls back to the title when no URL can be built', (tester) async {
    // Relative path with no client (offline) resolves to an empty URL.
    await tester.pumpWidget(buildLogo(logoPath: '/library/metadata/1/clearLogo'));

    expect(find.text('Fallback Title'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('sizes itself to the requested logo slot', (tester) async {
    await tester.pumpWidget(buildLogo(logoPath: null, width: 520, height: 150));

    expect(tester.getSize(find.byType(ClearLogoImage)), const Size(520, 150));
  });
}
