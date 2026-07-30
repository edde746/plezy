import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/settings/add_jellyfin_screen.dart';
import 'package:plezy/services/jellyfin_auth_service.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/jellyfin_lan_discovery_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/multi_server_fixtures.dart';
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

JellyfinConnectionAuthService _successfulAuthService({required bool quickConnect}) {
  Map<String, Object?> authResponse() => {
    'AccessToken': '',
    'User': {
      'Id': 'opaque-user',
      'Name': 'Opaque User',
      'Policy': {'IsAdministrator': false},
    },
  };

  return JellyfinConnectionAuthService(
    clientName: 'Plezy',
    clientVersion: 'test',
    deviceName: 'Opaque Device',
    testHttpClientFactory: () => MockClient((request) async {
      switch (request.url.path) {
        case '/System/Info/Public':
          return http.Response(
            jsonEncode({'Id': 'opaque-machine', 'ServerName': 'Opaque Server', 'Version': '10.9.0'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/QuickConnect/Enabled':
          return http.Response(jsonEncode(quickConnect), 200, headers: {'content-type': 'application/json'});
        case '/QuickConnect/Initiate':
          return http.Response(
            jsonEncode({'Code': '654321', 'Secret': 'opaque-secret'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        case '/QuickConnect/Connect':
          return http.Response(jsonEncode({'Authenticated': true}), 200, headers: {'content-type': 'application/json'});
        case '/Users/AuthenticateByName':
        case '/Users/AuthenticateWithQuickConnect':
          return http.Response(jsonEncode(authResponse()), 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('', 404);
    }),
  );
}

class _NoTimerPlexHomeService extends PlexHomeService {
  _NoTimerPlexHomeService({required super.connections, required super.profileConnections, required super.storage});

  @override
  Future<void> start() async {}

  @override
  Future<void> reloadFromStorage() async {}
}

class _CountingJellyfinManager extends MultiServerManager {
  int calls = 0;

  @override
  Future<bool> addJellyfinConnection(JellyfinConnection connection) async {
    calls++;
    updateServerStatus(ServerId(connection.serverMachineId), true);
    return true;
  }
}

class _RouteJoinFailure implements Exception {
  const _RouteJoinFailure();
}

class _NoWatchActiveProfileProvider extends ActiveProfileProvider {
  _NoWatchActiveProfileProvider({
    required super.registry,
    required super.plexHome,
    required super.connections,
    required super.storage,
  });

  @override
  Future<void> initialize() async {}
}

class _CountingActiveProfileBinder extends ActiveProfileBinder {
  _CountingActiveProfileBinder({
    required super.activeProfile,
    required super.connections,
    required super.profileConnections,
    required super.serverManager,
    required super.multiServerProvider,
    required super.pinPrompt,
  });

  int calls = 0;

  @override
  Future<void> rebindIfActive(String profileId) async {
    calls++;
  }
}

class _FailingRouteJoinRegistry extends ProfileConnectionRegistry {
  _FailingRouteJoinRegistry(super.db);

  @override
  Future<void> upsert(ProfileConnection connection, {bool makeDefault = false}) async {
    await super.upsert(connection, makeDefault: makeDefault);
    throw const _RouteJoinFailure();
  }
}

class _RouteHarness {
  _RouteHarness._({
    required this.db,
    required this.storage,
    required this.profiles,
    required this.connections,
    required this.profileConnections,
    required this.plexHome,
    required this.activeProfiles,
    required this.manager,
    required this.multiServerProvider,
    required this.binder,
  });

  final AppDatabase db;
  final StorageService storage;
  final ProfileRegistry profiles;
  final ConnectionRegistry connections;
  final ProfileConnectionRegistry profileConnections;
  final PlexHomeService plexHome;
  final ActiveProfileProvider activeProfiles;
  final _CountingJellyfinManager manager;
  final MultiServerProvider multiServerProvider;
  final _CountingActiveProfileBinder binder;
  static Future<_RouteHarness> create({bool failJoin = false}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final storage = await StorageService.getInstance();
    final profiles = ProfileRegistry(db);
    final connections = ConnectionRegistry(db);
    final profileConnections = failJoin ? _FailingRouteJoinRegistry(db) : ProfileConnectionRegistry(db);
    final plexHome = _NoTimerPlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    final activeProfiles = _NoWatchActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
    final manager = _CountingJellyfinManager();
    final multiServerProvider = testMultiServerProvider(manager);
    final binder = _CountingActiveProfileBinder(
      activeProfile: activeProfiles,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: manager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (_, {String? errorMessage}) async => null,
    );
    return _RouteHarness._(
      db: db,
      storage: storage,
      profiles: profiles,
      connections: connections,
      profileConnections: profileConnections,
      plexHome: plexHome,
      activeProfiles: activeProfiles,
      manager: manager,
      multiServerProvider: multiServerProvider,
      binder: binder,
    );
  }

  Widget app({required bool quickConnect, required ValueChanged<Future<bool?>> onRoute}) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<StorageService>.value(value: storage),
        Provider<ProfileRegistry>.value(value: profiles),
        Provider<ConnectionRegistry>.value(value: connections),
        Provider<ProfileConnectionRegistry>.value(value: profileConnections),
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfiles),
        Provider<ActiveProfileBinder>.value(value: binder),
      ],
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => onRoute(
              Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddJellyfinScreen(
                    authServiceFactory: () => _successfulAuthService(quickConnect: quickConnect),
                    localDiscoveryFactory: _noLocalServers,
                  ),
                ),
              ),
            ),
            child: const Text('Open route'),
          ),
        ),
      ),
    );
  }

  Future<void> dispose() async {
    binder.dispose();
    multiServerProvider.dispose();
    await activeProfiles.resetForTesting();
    activeProfiles.dispose();
    await plexHome.dispose();
    await db.close();
  }
}

Future<List<DiscoveredJellyfinServer>> _noLocalServers() async => const [];

void main() {
  group('resolveJellyfinClientVersion', () {
    PackageInfo packageInfo(String version) =>
        PackageInfo(appName: 'Plezy', packageName: 'com.example.plezy', version: version, buildNumber: '1');

    test('uses a non-empty package version', () async {
      final version = await resolveJellyfinClientVersion(packageInfoLoader: () async => packageInfo(' 2.9.1 '));
      expect(version, '2.9.1');
    });

    test('falls back when the package version is empty', () async {
      for (final packageVersion in ['', '   ']) {
        final version = await resolveJellyfinClientVersion(packageInfoLoader: () async => packageInfo(packageVersion));
        expect(version, '1.0');
      }
    });

    test('falls back when package metadata lookup throws', () async {
      final version = await resolveJellyfinClientVersion(
        packageInfoLoader: () async => throw StateError('version metadata unavailable'),
      );
      expect(version, '1.0');
    });
  });

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
    expect(tester.widget<TextField>(find.byType(TextField)).keyboardType, TextInputType.url);
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

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Url');
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    // Returning to the URL field by D-pad must not raise the system keyboard;
    // only an explicit Select does. Auto-opening on focus made the form
    // untraversable on Apple TV (#1728).
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });

  /// Drives the Apple TV Add Jellyfin flow up to the credentials step and
  /// leaves focus on the username field, as the probe does.
  Future<void> pumpAppleTvCredentialsStep(WidgetTester tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    await tester.pumpWidget(
      InputModeTracker(
        child: _testApp(
          AddJellyfinScreen(authServiceFactory: () => _jellyfinAuthService(), localDiscoveryFactory: _noLocalServers),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'https://jf.example.com'));
    await tester.pump();
  }

  List<String> drainTextInput(WidgetTester tester) {
    final methods = tester.testTextInput.log.map((call) => call.method).toList();
    tester.testTextInput.log.clear();
    return methods;
  }

  testWidgets('Apple TV probe handoff attaches text input exactly once', (tester) async {
    await pumpAppleTvCredentialsStep(tester);

    drainTextInput(tester);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    final handoff = drainTextInput(tester);

    // The username field's first focus legitimately raises input once. What
    // must not happen is a second attach: EditableText used to schedule a
    // connection restart on submit (submit action + non-null onFieldSubmitted)
    // and re-show the URL field it had just dismissed, so the handoff carried
    // two setClient/show pairs. On tvOS that tears the system keyboard down
    // and re-presents it while the next field is claiming it.
    expect(handoff.where((m) => m == 'TextInput.setClient'), hasLength(1));
    expect(handoff.where((m) => m == 'TextInput.show'), hasLength(1));

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'AddJellyfin:Username');
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).readOnly, isFalse);
  });

  testWidgets('Apple TV D-pad traversal stops raising the keyboard after each field is seen', (tester) async {
    await pumpAppleTvCredentialsStep(tester);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    // On device the D-pad belongs to the tvOS keyboard while it is up, so a
    // user can only traverse after dismissing it. Model that: dismiss via the
    // platform (as UIKit does), which must leave focus on the field, and only
    // then send the arrow.
    Future<void> dismissIfOpen() async {
      final open = tester.widgetList<TextField>(find.byType(TextField)).any((field) => !field.readOnly);
      if (!open) return;
      final focused = FocusManager.instance.primaryFocus?.debugLabel;
      tester.testTextInput.closeConnection();
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, focused, reason: 'dismissal must not move focus');
    }

    Future<void> walk() async {
      for (final key in [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowUp]) {
        for (var step = 0; step < 3; step++) {
          await dismissIfOpen();
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
        }
      }
    }

    // First pass may raise input once per field it has never focused before —
    // arriving at a field is an intent to type.
    await walk();

    // Every later pass must be silent. `onFocus` re-raised the system keyboard
    // on every single traversal step, which made the form unusable.
    for (var pass = 2; pass <= 3; pass++) {
      drainTextInput(tester);
      await walk();
      final traversal = drainTextInput(tester);
      expect(traversal, isNot(contains('TextInput.setClient')), reason: 'pass $pass');
      expect(traversal, isNot(contains('TextInput.show')), reason: 'pass $pass');
    }
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

  testWidgets('password sign-in commits one complete bundle and binds once', (tester) async {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    final harness = await _RouteHarness.create();
    await tester.runAsync(() => CredentialVault.protect('opaque-vault-warmup'));
    late Future<bool?> routeResult;
    await tester.pumpWidget(harness.app(quickConnect: false, onRoute: (result) => routeResult = result));
    await tester.tap(find.text('Open route'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'https://media.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Opaque User');
    await tester.enterText(find.byType(TextField).at(2), 'opaque-password');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(harness.binder.calls, 1);
    expect(find.text('Open route'), findsOneWidget);

    expect(await routeResult, isTrue);
    final bundle = await tester.runAsync(() async {
      return (
        profiles: await harness.profiles.list(),
        connections: await harness.connections.list(),
        joins: await harness.profileConnections.listAll(),
      );
    });
    expect(bundle!.profiles, hasLength(1));
    expect(bundle.connections, hasLength(1));
    expect(bundle.joins, hasLength(1));
    expect(bundle.joins.single.profileId, bundle.profiles.single.id);
    expect(bundle.joins.single.connectionId, bundle.connections.single.id);
    expect(harness.storage.getActiveProfileId(), bundle.profiles.single.id);
    expect(harness.activeProfiles.activeId, bundle.profiles.single.id);
    expect(harness.binder.calls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.dispose();
  });

  testWidgets('Quick Connect commits one complete bundle and binds once', (tester) async {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    final harness = await _RouteHarness.create();
    await tester.runAsync(() => CredentialVault.protect('opaque-vault-warmup'));
    late Future<bool?> routeResult;
    await tester.pumpWidget(harness.app(quickConnect: true, onRoute: (result) => routeResult = result));
    await tester.tap(find.text('Open route'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'https://media.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Quick Connect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(await routeResult, isTrue);
    final bundle = await tester.runAsync(() async {
      return (
        profiles: await harness.profiles.list(),
        connections: await harness.connections.list(),
        joins: await harness.profileConnections.listAll(),
      );
    });
    expect(bundle!.profiles, hasLength(1));
    expect(bundle.connections, hasLength(1));
    expect(bundle.joins, hasLength(1));
    expect(bundle.joins.single.profileId, bundle.profiles.single.id);
    expect(bundle.joins.single.connectionId, bundle.connections.single.id);
    expect(harness.storage.getActiveProfileId(), bundle.profiles.single.id);
    expect(harness.activeProfiles.activeId, bundle.profiles.single.id);
    expect(harness.binder.calls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await harness.dispose();
  });

  testWidgets('join failure leaves route open, state unchanged, and never binds', (tester) async {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    final harness = await _RouteHarness.create(failJoin: true);
    await tester.runAsync(() => CredentialVault.protect('opaque-vault-warmup'));
    var routeCompleted = false;
    late Future<bool?> routeResult;
    await tester.pumpWidget(
      harness.app(
        quickConnect: false,
        onRoute: (result) {
          routeResult = result;
          result.then((_) => routeCompleted = true);
        },
      ),
    );
    await tester.tap(find.text('Open route'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'https://media.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Opaque User');
    await tester.enterText(find.byType(TextField).at(2), 'opaque-password');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(routeCompleted, isFalse);
    expect(find.textContaining('Sign-in failed'), findsOneWidget);
    final bundle = await tester.runAsync(() async {
      return (
        profiles: await harness.profiles.list(),
        connections: await harness.connections.list(),
        joins: await harness.profileConnections.listAll(),
      );
    });
    expect(bundle!.profiles, isEmpty);
    expect(bundle.connections, isEmpty);
    expect(bundle.joins, isEmpty);
    expect(harness.storage.getActiveProfileId(), isNull);
    expect(harness.binder.calls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    routeResult.ignore();
    await harness.dispose();
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
