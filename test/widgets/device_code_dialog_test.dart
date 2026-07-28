import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/widgets/device_code_dialog.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('copy control exposes the activation code as its value', (tester) async {
    final semantics = tester.ensureSemantics();
    const code = DeviceCode(
      deviceCode: 'device-token',
      userCode: 'ABCD-EFGH',
      verificationUrl: 'https://example.com/activate',
      expiresIn: 600,
      interval: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DeviceCodeDialog(code: code, serviceName: 'Example', onCancel: () {}),
      ),
    );

    final finder = find.bySemanticsLabel(t.services.deviceCode.copyCode);
    expect(finder, findsOneWidget);
    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.value, code.userCode);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel(code.userCode), findsNothing);
    semantics.dispose();
  });
}
