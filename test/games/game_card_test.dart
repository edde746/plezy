import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/card_focus_scope.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/games/game_artwork.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/games/game_card.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import '../test_helpers/prefs.dart';

void main() {
  final host = GameHost(id: 'pc', name: 'Living room PC', address: '192.168.1.2', protocol: GameProtocol.gameStream);
  final games = List.generate(
    12,
    (i) => StreamGame(hostKey: host.key, id: '${i + 1}', name: 'A game with a long name $i'),
  );
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  for (final palette in [MonoPalette.light, MonoPalette.oled]) {
    testWidgets('poster grid fits a phone with large RTL text (${palette.bg})', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final artwork = GameArtworkLoader(fetch: (_, _) async => null);
      addTearDown(artwork.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: monoTheme(palette),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(size: Size(360, 740), textScaler: TextScaler.linear(2)),
            child: Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GameCardGrid(
                  games: games,
                  builder: (_, game) => GameCard(
                    game: game,
                    host: host,
                    artwork: artwork,
                    favorite: false,
                    onPlay: () {},
                    onFavorite: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.text(games[0].name));
      final second = tester.getRect(find.text(games[1].name));
      expect(first.top, second.top); // Multiple posters, never a vertical list.
      expect(first.left, greaterThan(second.left));
    });
  }

  testWidgets('D-pad shows the shared poster outline and opens the selected game once', (tester) async {
    final focus = FocusNode();
    final artwork = GameArtworkLoader(fetch: (_, _) async => null);
    addTearDown(focus.dispose);
    addTearDown(artwork.dispose);
    var launched = 0;
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          theme: monoTheme(MonoPalette.oled),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 330,
                child: GameCard(
                  game: games.first,
                  host: host,
                  artwork: artwork,
                  favorite: true,
                  focusNode: focus,
                  onPlay: () => launched++,
                  onFavorite: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    InputModeTracker.reportNonPointerInput();
    await tester.pumpAndSettle();
    final border = tester.element(find.byType(CardFocusBorder));
    expect(CardFocusScope.maybeOf(border), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(launched, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card menu exposes the app-owned workspace action when supported', (tester) async {
    final artwork = GameArtworkLoader(fetch: (_, _) async => null);
    addTearDown(artwork.dispose);
    var openedInWorkspace = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.oled),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 330,
              child: GameCard(
                game: games.first,
                host: GameHost(id: 'steam', name: 'Steam PC', address: '192.168.1.3', protocol: GameProtocol.steam),
                artwork: artwork,
                favorite: false,
                onPlay: () {},
                onPlayInWorkspace: () => openedInWorkspace++,
                onFavorite: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(GameCard));
    await tester.pumpAndSettle();
    expect(find.text(t.videoControls.pipButton), findsOneWidget);
    await tester.tap(find.text(t.videoControls.pipButton));
    await tester.pumpAndSettle();

    expect(openedInWorkspace, 1);
    expect(tester.takeException(), isNull);
  });
}
