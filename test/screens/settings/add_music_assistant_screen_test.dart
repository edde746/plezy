import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/screens/settings/add_music_assistant_screen.dart';
import 'package:plezy/screens/settings/local_server_discovery.dart';
import 'package:plezy/services/music_assistant_lan_discovery_service.dart';
import 'package:plezy/theme/mono_theme.dart';

void main() {
  group('normalizeMusicAssistantUrl', () {
    test('a bare LAN address gets the scheme and the default port', () {
      // The single most likely thing a user types. Without the port default it
      // would silently resolve to :80 and fail to connect.
      expect(normalizeMusicAssistantUrl('10.0.2.107'), 'http://10.0.2.107:8095');
      expect(normalizeMusicAssistantUrl('  mass.local  '), 'http://mass.local:8095');
    });

    test('an explicit port is kept', () {
      expect(normalizeMusicAssistantUrl('10.0.2.107:9000'), 'http://10.0.2.107:9000');
      expect(normalizeMusicAssistantUrl('http://mass.local:8095'), 'http://mass.local:8095');
    });

    test('a websocket URL copied out of Music Assistant becomes its HTTP form', () {
      // The connection stores HTTP because the image proxy and the flow stream
      // are derived from it; the transport re-derives the socket URL.
      expect(normalizeMusicAssistantUrl('ws://10.0.2.107:8095/ws'), 'http://10.0.2.107:8095');
      expect(normalizeMusicAssistantUrl('wss://mass.example.com/ws'), 'https://mass.example.com');
    });

    test('https keeps its own default port rather than 8095', () {
      expect(normalizeMusicAssistantUrl('https://mass.example.com'), 'https://mass.example.com');
    });

    test('a trailing slash and a trailing /ws are both trimmed', () {
      expect(normalizeMusicAssistantUrl('http://10.0.2.107:8095/'), 'http://10.0.2.107:8095');
      expect(normalizeMusicAssistantUrl('http://10.0.2.107:8095/ws'), 'http://10.0.2.107:8095');
    });

    test('a path prefix survives, because a server can be hosted under one', () {
      expect(normalizeMusicAssistantUrl('http://proxy/mass/ws'), 'http://proxy:8095/mass');
    });

    test('unusable input is rejected rather than guessed at', () {
      expect(normalizeMusicAssistantUrl(''), isNull);
      expect(normalizeMusicAssistantUrl('   '), isNull);
      expect(normalizeMusicAssistantUrl('ftp://10.0.2.107'), isNull);
    });
  });

  test('the connection row id is derived from the server id, so re-adding upserts', () {
    // A fresh uuid per add would register a second client for one server.
    expect(
      musicAssistantConnectionId('fe2f5b6fd78e4608bb8b075a6c269fbf'),
      musicAssistantConnectionId('fe2f5b6fd78e4608bb8b075a6c269fbf'),
    );
    expect(musicAssistantConnectionId('abc'), isNot(musicAssistantConnectionId('def')));
  });

  group('isMusicAssistantRepoint', () {
    MusicAssistantConnection ma(String baseUrl, {String serverId = 'fe2f5b6f'}) => MusicAssistantConnection(
      id: musicAssistantConnectionId(serverId),
      displayName: 'Basement NAS',
      baseUrl: baseUrl,
      serverId: serverId,
      createdAt: DateTime.utc(2026),
    );

    test('a server claiming an existing server_id from a new address is a repoint', () {
      // The attack the shared row id makes possible. The greeting is
      // unauthenticated, so anything on the network can announce the
      // `server_id` of the user's real server; the upsert then takes over that
      // row and its baseUrl with it, from a discovery list the user was
      // invited to tap. This is what makes the change visible instead.
      expect(
        isMusicAssistantRepoint(existing: ma('http://10.0.2.107:8095'), incoming: ma('http://10.0.2.66:8095')),
        isTrue,
      );
    });

    test('re-adding the same server at the same address is not a repoint', () {
      // The ordinary case, and the whole reason the row id is shared. It must
      // not put a dialog in front of a user who changed nothing.
      expect(
        isMusicAssistantRepoint(existing: ma('http://10.0.2.107:8095'), incoming: ma('http://10.0.2.107:8095')),
        isFalse,
      );
    });

    test('a first add has nothing to overwrite', () {
      expect(isMusicAssistantRepoint(existing: null, incoming: ma('http://10.0.2.107:8095')), isFalse);
    });
  });

  group('local discovery', () {
    Widget screen(List<DiscoveredMusicAssistantServer> found) => InputModeTracker(
      child: MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        home: AddMusicAssistantScreen(localDiscoveryFactory: () async => found),
      ),
    );

    testWidgets('a discovered server is labelled and is the first thing on screen', (tester) async {
      // The advert carries no name, so the label has to come from somewhere —
      // the product name plus the advertised version is all there is.
      await tester.pumpWidget(
        screen(const [
          DiscoveredMusicAssistantServer(address: 'http://10.0.2.107:8095', id: 'srv-1', version: '2.6.3'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Music Assistant 2.6.3'), findsOneWidget);
      expect(find.text('http://10.0.2.107:8095'), findsOneWidget);
      // The row invites the tap that adds it, rather than sending the user to
      // a form.
      expect(find.text('Tap to connect'), findsOneWidget);
    });

    testWidgets('the URL field is a fallback, not the default', (tester) async {
      // The regression this guards: the screen used to open on an empty URL
      // field with discovery beneath it, which made every user do by hand the
      // thing the network had already answered.
      await tester.pumpWidget(
        screen(const [
          DiscoveredMusicAssistantServer(address: 'http://10.0.2.107:8095', id: 'srv-1', version: '2.6.3'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Server URL'), findsNothing);
      expect(find.text('Enter an address instead'), findsOneWidget);

      await tester.tap(find.text('Enter an address instead'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Server URL'), findsOneWidget);
    });

    testWidgets('the D-pad can reach a discovered row and leave it again', (tester) async {
      await tester.pumpWidget(
        screen(const [
          DiscoveredMusicAssistantServer(address: 'http://10.0.2.107:8095', id: 'srv-1', version: '2.6.3'),
        ]),
      );
      await tester.pumpAndSettle();

      tester.binding.focusManager.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // A group of tiles a remote can enter and not leave is worse than no
      // group, so the row must hand focus on to the manual-entry control.
      expect(find.byType(DiscoveredServerTile), findsOneWidget);
    });

    testWidgets('an advert with no version still names the product', (tester) async {
      await tester.pumpWidget(
        screen(const [DiscoveredMusicAssistantServer(address: 'http://10.0.2.9:8095', id: 'srv-2')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Music Assistant'), findsOneWidget);
    });

    testWidgets('finding nothing opens the manual field rather than dead-ending', (tester) async {
      // With no servers to tap, the fallback is the only way forward, so it
      // stops being a fallback. Making the user press one more button to
      // reach it would be a wall in front of the door.
      await tester.pumpWidget(screen(const []));
      await tester.pumpAndSettle();

      expect(find.text('No Music Assistant servers found'), findsOneWidget);
      expect(find.text('Search again'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Server URL'), findsOneWidget);
      expect(find.text('Enter an address instead'), findsNothing);
    });
  });
}
