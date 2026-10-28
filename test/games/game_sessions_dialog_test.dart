import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_session_exchange.dart';
import 'package:plezy/screens/companion_remote/game_sessions_dialog.dart';

void main() {
  testWidgets('retired connection never publishes a late game title', (tester) async {
    final reply = Completer<GameSessionControlReply>();
    var current = true;
    await tester.pumpWidget(
      MaterialApp(
        home: GameSessionsDialog(request: (_, {target}) => reply.future, isCurrent: () => current),
      ),
    );
    current = false;
    reply.complete(
      GameSessionControlReply(GameSessionControlStatus.ok, [
        RemoteGameSession(id: 'a' * 32, title: 'Private game title', audible: true),
      ]),
    );
    await tester.pump();
    expect(find.text('Private game title'), findsNothing);
    expect(find.text('Game session controls are unavailable. Reconnect or refresh to try again.'), findsOneWidget);
  });

  testWidgets('remote game titles fit narrow RTL and large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GameSessionsDialog(
              isCurrent: () => true,
              request: (_, {target}) async => GameSessionControlReply(GameSessionControlStatus.ok, [
                RemoteGameSession(
                  id: 'a' * 32,
                  title: 'A very long title for a game on the living room computer',
                  audible: false,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Game session actions'), findsOneWidget);
  });
}
