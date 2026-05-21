import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/platform_detector.dart';
import 'package:vibe_stream/widgets/tv_virtual_keyboard.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('keyboard enter submits without inserting highlighted key', (tester) async {
    final controller = TextEditingController();
    String? submitted;
    addTearDown(controller.dispose);

    await _pumpKeyboard(tester, controller: controller, onSubmitted: (value) => submitted = value);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.text, isEmpty);
    expect(submitted, isEmpty);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('engine-synthesized select activates highlighted key', (tester) async {
    final controller = TextEditingController(text: 'query');
    String? submitted;
    addTearDown(controller.dispose);

    await _pumpKeyboard(tester, controller: controller, onSubmitted: (value) => submitted = value);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(controller.text, 'query1');
    expect(submitted, isNull);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('directional pad enter activates highlighted key', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await _pumpKeyboard(tester, controller: controller);

    _dispatchKey(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
    await tester.pump();

    expect(controller.text, '1');
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('keyboard enter inserts newline for multiline input', (tester) async {
    final controller = TextEditingController(text: 'a');
    addTearDown(controller.dispose);

    await _pumpKeyboard(tester, controller: controller, keyboardType: TextInputType.multiline, maxLines: 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.text, 'a\n');
    expect(find.byType(Dialog), findsOneWidget);
  });
}

Future<void> _pumpKeyboard(
  WidgetTester tester, {
  required TextEditingController controller,
  TextInputType? keyboardType,
  int? maxLines,
  ValueChanged<String>? onSubmitted,
}) async {
  TvDetectionService.debugSetAppleTVOverride(true);
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  late BuildContext context;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  unawaited(
    showTvVirtualKeyboard(
      context: context,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
    ),
  );
  await tester.pumpAndSettle();
}

KeyEventResult _dispatchKey(KeyEvent event) {
  FocusNode? node = FocusManager.instance.primaryFocus;
  while (node != null) {
    final result = node.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    if (result == KeyEventResult.handled) return result;
    node = node.parent;
  }
  return KeyEventResult.ignored;
}
