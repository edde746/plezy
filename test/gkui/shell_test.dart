import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/gkui/diagnostics.dart';
import 'package:plezy/main_gkui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(diagnosticsChannelName),
      (call) async => <String, Object>{
        'app': '0.1.0 (1)',
        'android': '4.4.4 / API 19',
        'abi': 'armeabi-v7a',
        'memory class': '256 MiB',
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(diagnosticsChannelName),
      null,
    );
  });

  for (final size in <Size>[
    const Size(800, 480),
    const Size(1280, 720),
  ]) {
    testWidgets(
        'shell renders and navigates at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PlezyGkuiApp());
      await tester.pumpAndSettle();
      expect(find.text('Plezy GKUI'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Poster grid placeholder for the first hardware gate'),
          findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();
      expect(find.text('0.1.0 (1)'), findsOneWidget);
      if (size.height >= 700) {
        expect(find.text('4.4.4 / API 19'), findsOneWidget);
        expect(find.text('armeabi-v7a'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
