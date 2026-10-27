import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/game_streaming_client.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/games/game_connection_dialogs.dart';
import 'package:plezy/theme/mono_theme.dart';

class PairingEngine implements GameStreamingClient {
  final pairing = Completer<void>();
  bool cancelled = false;
  String? pin;
  @override
  Future<GameClientCapabilities> capabilities(GameHost host) async => const GameClientCapabilities(available: true);
  @override
  Future<void> pair(GameHost host, String value) {
    pin = value;
    return pairing.future;
  }

  @override
  Future<List<StreamGame>> games(GameHost host) async => [];
  @override
  Future<void> open(
    GameHost host, {
    required StreamGame game,
    bool touchControls = true,
    bool pyrowave = false,
  }) async {}
  @override
  void cancel() {
    cancelled = true;
  }
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  for (final palette in [MonoPalette.light, MonoPalette.oled]) {
    testWidgets('add computer fits narrow screens at large text (${palette.bg})', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: monoTheme(palette),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(textDirection: TextDirection.rtl, child: child!),
          ),
          home: const Scaffold(body: AddGameComputerDialog()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.games.addComputer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('leaving the PIN dialog cancels the pending native operation', (tester) async {
    final client = PairingEngine();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PairGameComputerDialog(
            host: GameHost(id: 'pc', name: 'PC', address: '192.168.1.2', protocol: GameProtocol.gameStream),
            client: client,
            isCurrent: () => true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(client.pin, matches(RegExp(r'^\d{4}$')));
    await tester.pumpWidget(const SizedBox());
    expect(client.cancelled, isTrue);
    client.pairing.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
