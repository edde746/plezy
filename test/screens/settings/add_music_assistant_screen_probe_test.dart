import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/settings/add_music_assistant_screen.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

import '../../music_assistant/fake_ma_server.dart';

/// The probe half of the add-server form, which is where the concrete log leak
/// was: `appLogger.w('Music Assistant probe failed for $url')` runs on every
/// failed attempt, and nothing had ever registered the URL for redaction.
void main() {
  setUp(LogRedactionManager.clearTrackedValues);
  tearDown(LogRedactionManager.clearTrackedValues);

  Widget app(Widget home) => MaterialApp(theme: monoTheme(MonoPalette.dark), home: home);

  testWidgets('a failed probe cannot leak the server hostname into the log buffer', (tester) async {
    // A hostname, not an IP: the generic IPv4 pattern already masks
    // `10.0.2.107` without anyone registering anything, so an IP fixture would
    // pass with the fix reverted. `music.home.lan` and `*.ts.net` names do not
    // match that pattern and shipped verbatim.
    const host = 'music.home.lan';

    await tester.pumpWidget(
      app(
        AddMusicAssistantScreen(
          localDiscoveryFactory: () async => const [],
          apiFactory: () =>
              MusicAssistantApi(channelFactory: (_) async => throw const MaConnectionException('refused')),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, host);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(LogRedactionManager.redact('Music Assistant probe failed for http://$host:8095'), isNot(contains(host)));
  });

  group('a server that wants a sign-in', () {
    /// Each step of the form opens its own socket, so each gets its own fake.
    final sockets = <FakeMaServer>[];

    Future<void> findServer(WidgetTester tester) async {
      sockets.clear();
      await tester.pumpWidget(
        app(
          AddMusicAssistantScreen(
            localDiscoveryFactory: () async => const [],
            apiFactory: () => MusicAssistantApi(
              channelFactory: (url) {
                sockets.add(
                  FakeMaServer(
                    responder: (command, args) => switch (command) {
                      'auth/login' => {'success': false, 'error': 'Invalid username or password'},
                      _ => const MaErrorReply(20, 'Authentication is required.'),
                    },
                  ),
                );
                return sockets.last.open(url);
              },
              autoReconnect: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'mass.local');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    testWidgets('the form asks for credentials rather than saving a server that refuses everything', (tester) async {
      await findServer(tester);

      expect(find.widgetWithText(TextField, t.addServer.username), findsOneWidget);
      expect(find.widgetWithText(TextField, t.addServer.password), findsOneWidget);
      expect(find.widgetWithText(FilledButton, t.addServer.signIn), findsOneWidget);
    });

    testWidgets('a wrong password says so, and leaves the form up to try again', (tester) async {
      await findServer(tester);

      await tester.enterText(find.widgetWithText(TextField, t.addServer.username), 'jack');
      await tester.enterText(find.widgetWithText(TextField, t.addServer.password), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, t.addServer.signIn));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.text(t.addServer.musicAssistantSignInRejected), findsOneWidget);
      expect(find.widgetWithText(FilledButton, t.addServer.signIn), findsOneWidget);
    });

    testWidgets('an empty form is stopped before anything is sent', (tester) async {
      await findServer(tester);
      await tester.tap(find.widgetWithText(FilledButton, t.addServer.signIn));
      await tester.pumpAndSettle();

      expect(sockets, hasLength(1), reason: 'only the probe opened a socket');
      expect(find.text(t.addServer.required), findsNWidgets(2));
    });
  });
}
