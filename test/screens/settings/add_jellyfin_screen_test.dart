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
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../../test_helpers/prefs.dart';

Profile _profile(String id) =>
    Profile.local(id: id, displayName: id, sortOrder: 0, createdAt: DateTime.fromMillisecondsSinceEpoch(0));

Widget _testApp(Widget home) => MaterialApp(theme: monoTheme(dark: true), home: home);

JellyfinConnectionAuthService _jellyfinAuthService({bool quickConnectEnabled = false, Duration? initiateDelay}) {
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
        case '/QuickConnect/Initiate':
          if (initiateDelay != null) await Future<void>.delayed(initiateDelay);
          return http.Response(
            jsonEncode({'Code': '123456', 'Secret': 'qc-secret'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/QuickConnect/Connect':
          // Never approved — the panel stays in its waiting state.
          return http.Response(
            jsonEncode({'Authenticated': false}),
            200,
            headers: {'content-type': 'application/json'},
          );
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
    PlatformDetector.debugSetIsDesktopOSOverride(null);
  });

  testWidgets('autofocuses the server URL field', (tester) async {
    await tester.pumpWidget(_testApp(AddJellyfinScreen(localDiscoveryFactory: _noLocalServers)));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.autofocus, isTrue);
  });

  testWidgets('TV initial focus keeps server URL focused without opening keyboard', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await tester.pumpWidget(
      InputModeTracker(child: _testApp(AddJellyfinScreen(localDiscoveryFactory: _noLocalServers))),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
  });

  testWidgets('Android TV D-pad can leave initial URL focus before keyboard opens', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);

    await tester.pumpWidget(
      InputModeTracker(child: _testApp(AddJellyfinScreen(localDiscoveryFactory: _noLocalServers))),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:FindServer');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('TV discovery keeps initial URL focus and D-pad reaches discovered servers', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    await tester.pumpWidget(
      InputModeTracker(
        child: _testApp(
          AddJellyfinScreen(
            localDiscoveryFactory: () async => [
              DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-1', name: 'Home'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Discovered:srv-1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'TvVirtualKeyboard');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);
  });

  testWidgets('D-pad moves from URL through Change to credentials after server is found', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AddJellyfinScreen(authServiceFactory: () => _jellyfinAuthService(), localDiscoveryFactory: _noLocalServers),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'https://jf.example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Username');

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:ChangeServer');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Username');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:ChangeServer');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
  });

  testWidgets('accepts a bare Jellyfin host and expands it before probing', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AddJellyfinScreen(
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

  testWidgets('Quick Connect shows the code prominently and cancel returns to the form', (tester) async {
    resetSharedPreferencesForTest();
    await tester.pumpWidget(
      _testApp(
        AddJellyfinScreen(
          authServiceFactory: () => _jellyfinAuthService(quickConnectEnabled: true),
          localDiscoveryFactory: _noLocalServers,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'https://jf.example.com');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use Quick Connect'));
    // The waiting panel hosts a perpetual spinner, so pumpAndSettle would
    // never settle — pump a few bounded frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Code replaces the form as the centered hero element.
    expect(find.text('123456'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    final codeStyle = tester.widget<Text>(find.text('123456')).style;
    expect(codeStyle?.fontSize, Theme.of(tester.element(find.text('123456'))).textTheme.displayLarge?.fontSize);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('123456'), findsNothing);
    expect(find.byType(TextField), findsWidgets);

    // Let the cancelled poll's backoff timer fire so the test ends clean.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('TV auto Quick Connect never opens the keyboard across the panel swap', (tester) async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetAppleTVOverride(null);
    await TvDetectionService.getInstance(forceTv: true);
    TvDetectionService.setForceTVSync(true);
    // Simulated TV device, not desktop force-TV: keep locked keyboard mode.
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    await tester.pumpWidget(
      InputModeTracker(
        child: _testApp(
          AddJellyfinScreen(
            // Hold /QuickConnect/Initiate open so the frames between probe
            // success and the panel swap are observable — that window is
            // where the focus fallback used to auto-open the keyboard.
            authServiceFactory: () =>
                _jellyfinAuthService(quickConnectEnabled: true, initiateDelay: const Duration(milliseconds: 50)),
            localDiscoveryFactory: () async => [
              DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-1', name: 'Home'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');

    // D-pad to the discovered server and select it — on TV the probe
    // auto-starts Quick Connect.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Discovered:srv-1');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.pump();

    // Pre-swap frames: probe done, initiate in flight — no keyboard.
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    // Quick Connect panel swapped in: code shown, Cancel focused, no keyboard.
    expect(find.text('123456'), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:CancelQuickConnect');

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump();

    // Form returns; the URL field's autofocus re-fires on a fresh host whose
    // first-focus suppression keeps the keyboard closed.
    expect(find.text('123456'), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    // Let the cancelled poll's backoff timer fire so the test ends clean.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('selecting a discovered Jellyfin server probes that address', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AddJellyfinScreen(
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

  testWidgets('D-pad can navigate through discovered Jellyfin servers', (tester) async {
    await tester.pumpWidget(
      InputModeTracker(
        child: _testApp(
          AddJellyfinScreen(
            localDiscoveryFactory: () async => [
              DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-1', name: 'Home'),
              DiscoveredJellyfinServer(address: 'http://192.168.1.30:8096', id: 'srv-2', name: 'Office'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Discovered:srv-1');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Discovered:srv-2');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:FindServer');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Discovered:srv-2');
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
