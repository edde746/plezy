import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/games/steam_game_activity_panel.dart';
import 'package:plezy/theme/mono_theme.dart';

void main() {
  testWidgets('activity controls fit a narrow RTL detail view at large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var linked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.oled),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SteamGameActivityPanel(appId: 620, isCurrent: () => true, onLink: () => linked = true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(t.games.includeFriends), findsOneWidget);
    final link = find.text(t.games.linkSteamAccount);
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pump();
    expect(linked, isTrue);
    expect(tester.takeException(), isNull);
    final steamMenu = find.text(t.games.openInSteam);
    await tester.ensureVisible(steamMenu);
    await tester.tap(steamMenu);
    await tester.pumpAndSettle();
    final cloud = find.text(t.games.steamCloudFiles);
    await tester.ensureVisible(cloud);
    await tester.tap(cloud);
    await tester.pumpAndSettle();
    expect(find.text(t.games.steamCloudHelp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
