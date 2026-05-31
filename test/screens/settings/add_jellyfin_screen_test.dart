import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/screens/settings/add_jellyfin_screen.dart';
import 'package:plezy/services/jellyfin_auth_service.dart';
import 'package:plezy/services/jellyfin_lan_discovery_service.dart';
import 'package:plezy/utils/platform_detector.dart';

Profile _profile(String id) =>
    Profile.local(id: id, displayName: id, sortOrder: 0, createdAt: DateTime.fromMillisecondsSinceEpoch(0));

JellyfinConnectionAuthService _jellyfinAuthService({bool quickConnectEnabled = false}) {
  return JellyfinConnectionAuthService(
    clientName: 'Plezy',
    clientVersion: 'test',
    deviceName: 'TestDevice',
    testHttpClientFactory: () => MockClient((request) async {
      switch (request.url.path) {
        case '/System/Info/Public':
          return http.Response(
            jsonEncode({'Id': 'srv-1', 'ServerName': 'Home', 'Version': '10.9.0'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/QuickConnect/Enabled':
          return http.Response(jsonEncode(quickConnectEnabled), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('', 404);
    }),
  );
}

JellyfinConnectionAuthService _jellyfinAuthServiceForBareHost() {
  return JellyfinConnectionAuthService(
    clientName: 'Plezy',
    clientVersion: 'test',
    deviceName: 'TestDevice',
    testHttpClientFactory: () => MockClient((request) async {
      switch (request.url.path) {
        case '/System/Info/Public':
          if (request.url.scheme == 'http' && request.url.host == 'jf.example.com' && request.url.port == 8096) {
            return http.Response(
              jsonEncode({'Id': 'srv-1', 'ServerName': 'Home', 'Version': '10.9.0'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          throw Exception('offline');
        case '/QuickConnect/Enabled':
          return http.Response(jsonEncode(false), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('', 404);
    }),
  );
}

Future<List<DiscoveredJellyfinServer>> _noLocalServers() async => const [];

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    TvDetectionService.setForceTVSync(false);
  });

  testWidgets('autofocuses the server URL field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AddJellyfinScreen(localDiscoveryFactory: _noLocalServers)));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.autofocus, isTrue);
  });

  testWidgets('TV initial focus opens the server URL keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(home: AddJellyfinScreen(localDiscoveryFactory: _noLocalServers)),
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('Android TV remote navigation stays with virtual URL keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(home: AddJellyfinScreen(localDiscoveryFactory: _noLocalServers)),
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
  });

  testWidgets('D-pad moves from URL to credentials after server is found', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddJellyfinScreen(
          authServiceFactory: () => _jellyfinAuthService(),
          localDiscoveryFactory: _noLocalServers,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'https://jf.example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Username');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
  });

  testWidgets('accepts a bare Jellyfin host and expands it before probing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddJellyfinScreen(
          authServiceFactory: () => _jellyfinAuthServiceForBareHost(),
          localDiscoveryFactory: _noLocalServers,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'jf.example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'http://jf.example.com:8096');
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('selecting a discovered Jellyfin server probes that address', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddJellyfinScreen(
          authServiceFactory: () => _jellyfinAuthService(),
          localDiscoveryFactory: () async => [
            DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-1', name: 'Home'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, contains('http://192.168.1.20:8096'));
    expect(find.text('Jellyfin 10.9.0'), findsOneWidget);
  });

  group('Jellyfin profile binding decisions', () {
    test('creates a local profile only on true first-run with no profiles', () {
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: null, hasProfiles: false), isTrue);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: null, hasProfiles: false),
        isFalse,
      );
    });

    test('uses existing active profile without prompting or creating', () {
      final active = _profile('active');
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: active, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: active, hasProfiles: true),
        isFalse,
      );
    });

    test('prompts when profiles exist but no profile is active', () {
      expect(shouldCreateLocalJellyfinProfile(targetProfile: null, activeProfile: null, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: null, activeProfile: null, hasProfiles: true),
        isTrue,
      );
    });

    test('explicit target profile never creates or prompts', () {
      final target = _profile('target');
      expect(shouldCreateLocalJellyfinProfile(targetProfile: target, activeProfile: null, hasProfiles: true), isFalse);
      expect(
        shouldPromptForJellyfinProfileSelection(targetProfile: target, activeProfile: null, hasProfiles: true),
        isFalse,
      );
    });
  });
}
