import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/trackers/oauth_proxy_client.dart';
import 'package:plezy/widgets/oauth_proxy_dialog.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('copy control exposes the OAuth URL as its value', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const start = OAuthProxyStart(session: 'session-token', url: 'https://example.com/oauth/start', expiresIn: 600);

    await tester.pumpWidget(
      MaterialApp(
        home: OAuthProxyDialog(start: start, serviceName: 'Example', onCancel: () {}),
      ),
    );

    final finder = find.bySemanticsLabel(t.services.oauthProxy.copyUrl);
    expect(finder, findsOneWidget);
    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.value, start.url);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel(start.url), findsNothing);
    semantics.dispose();
  });
}
