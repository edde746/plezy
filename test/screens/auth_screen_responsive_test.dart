import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/auth_screen.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final viewports =
      <({String name, Size physicalSize, double devicePixelRatio, double expectedButtonHeight, bool isTv})>[
        (name: 'phone', physicalSize: const Size(390, 844), devicePixelRatio: 1, expectedButtonHeight: 56, isTv: false),
        (
          name: 'desktop',
          physicalSize: const Size(1280, 800),
          devicePixelRatio: 1,
          expectedButtonHeight: 56,
          isTv: false,
        ),
        (
          name: '4K physical TV',
          physicalSize: const Size(3840, 2160),
          devicePixelRatio: 2,
          expectedButtonHeight: 75,
          isTv: true,
        ),
        (
          name: '4K logical TV',
          physicalSize: const Size(3840, 2160),
          devicePixelRatio: 1,
          expectedButtonHeight: 86,
          isTv: true,
        ),
      ];

  for (final viewport in viewports) {
    testWidgets('login choices fit and scale on ${viewport.name}', (tester) async {
      tester.view.physicalSize = viewport.physicalSize;
      tester.view.devicePixelRatio = viewport.devicePixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(TvDetectionService.debugReset);
      if (viewport.isTv) TvDetectionService.debugSetAppleTVOverride(true);

      await tester.pumpWidget(
        TranslationProvider(child: const MaterialApp(home: AuthScreen(initializeServices: false))),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(t.auth.signInWithPlex), findsOneWidget);
      expect(find.text(t.auth.connectToMediaBrowser(product: 'Jellyfin')), findsOneWidget);

      final plexButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, t.auth.signInWithPlex));
      final minimumHeight = plexButton.style!.minimumSize!.resolve({})!.height;
      expect(minimumHeight, closeTo(viewport.expectedButtonHeight, 1));
    });
  }
}
