import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/agent_control_protocol.dart';
import 'package:plezy/services/agent_control_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/widgets/agent_control_scope.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  testWidgets('invalid later setting prevents every write in a batch', (tester) async {
    final harness = await _Harness.mount(tester);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.enableHardwareDecoding, true);

    final response = await harness.command('settings.apply', {
      'changes': [
        {'key': 'enable_hardware_decoding', 'value': false},
        {'key': 'unknown_agent_setting', 'value': true},
      ],
    });

    expect(response['ok'], isFalse);
    expect(settings.read(SettingsService.enableHardwareDecoding), isTrue);
  });

  testWidgets('same-profile rebind rejects a captured mutation token', (tester) async {
    final harness = await _Harness.mount(tester);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.enableHardwareDecoding, true);
    final before = await harness.command('app.status', const {});
    final staleToken = before['sessionToken'];

    harness.active.markBindingStarted();
    harness.active.markBindingFinished(success: true);
    final rejected = await harness.command('settings.set', {
      'key': 'enable_hardware_decoding',
      'value': false,
    }, sessionToken: staleToken);
    expect(rejected['ok'], isFalse);
    expect((rejected['error'] as Map)['code'], 'sessionChanged');
    expect(settings.read(SettingsService.enableHardwareDecoding), isTrue);

    final applied = await harness.command('settings.set', {'key': 'enable_hardware_decoding', 'value': false});
    expect(applied['ok'], isTrue);
    expect(settings.read(SettingsService.enableHardwareDecoding), isFalse);
  });

  testWidgets('profile-covering route blocks commands without discarding status', (tester) async {
    final harness = await _Harness.mount(tester);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.enableHardwareDecoding, true);
    final navigator = Navigator.of(harness.context);
    unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Profile selection')))));
    await tester.pumpAndSettle();

    final status = await harness.command('app.status', const {});
    expect((status['result'] as Map)['profileReady'], isFalse);
    final rejected = await harness.command('settings.set', {'key': 'enable_hardware_decoding', 'value': false});
    expect(rejected['ok'], isFalse);
    expect((rejected['error'] as Map)['code'], 'blocked');
    expect(settings.read(SettingsService.enableHardwareDecoding), isTrue);

    navigator.pop();
    await tester.pumpAndSettle();
    final applied = await harness.command('settings.set', {'key': 'enable_hardware_decoding', 'value': false});
    expect(applied['ok'], isTrue);
  });

  testWidgets('reparented profile remains controllable after its root scope is replaced', (tester) async {
    final harness = await _Harness.mount(tester);
    final before = await harness.command('app.status', const {});
    harness.rootKey.value = UniqueKey();
    await tester.pump();

    final after = await harness.command('app.status', const {});
    expect((after['result'] as Map)['profileReady'], isTrue);
    expect(after['sessionToken'], isNot(before['sessionToken']));
    final rejected = await harness.command('settings.set', {
      'key': 'enable_hardware_decoding',
      'value': false,
    }, sessionToken: before['sessionToken']);
    expect((rejected['error'] as Map)['code'], 'sessionChanged');
    final applied = await harness.command('settings.set', {'key': 'enable_hardware_decoding', 'value': false});
    expect(applied['ok'], isTrue);
    expect(SettingsService.instance.read(SettingsService.enableHardwareDecoding), isFalse);
  });

  testWidgets('identity preparation invalidates captured work before listeners fire', (tester) async {
    final harness = await _Harness.mount(tester);
    final status = await harness.command('app.status', const {});
    AgentCommandContext? captured;
    final result = await AgentControlService.instance.executePayload(
      jsonEncode({
        'version': 1,
        'requestId': 'capture-root-effect',
        'sessionToken': status['sessionToken'],
        'command': 'settings.set',
        'arguments': {'key': 'force_tv_mode', 'value': false},
      }),
      onRootRebuild: (context) => captured = context,
    );
    expect(result['ok'], isTrue);
    expect(captured, isNotNull);
    final reservation = harness.active.beginIdentityMutationRequest();
    try {
      expect(
        () => captured!.checkCurrent(),
        throwsA(isA<AgentControlException>().having((error) => error.code, 'code', 'sessionChanged')),
      );
    } finally {
      harness.active.finishIdentityMutationRequest(reservation);
    }
  });

  test('malformed JSON produces a structured failure without reflecting input', () async {
    const sensitiveInput = '{"secret":"never-repeat-this"';
    final result = await AgentControlService.instance.executePayload(sensitiveInput);
    expect(result['ok'], isFalse);
    expect((result['error'] as Map)['code'], 'invalidRequest');
    expect(jsonEncode(result), isNot(contains('never-repeat-this')));
  });
}

class _Harness {
  _Harness(this.active);

  final ActiveProfileProvider active;
  final rootKey = ValueNotifier<Key>(UniqueKey());
  final profileKey = GlobalKey();
  late BuildContext context;
  int _request = 0;

  Future<Map<String, dynamic>> command(String command, Map<String, dynamic> arguments, {Object? sessionToken}) async {
    final service = AgentControlService.instance;
    if (command != 'app.status' && sessionToken == null) {
      sessionToken = (await this.command('app.status', const {}))['sessionToken'];
    }
    return service.executePayload(
      jsonEncode({
        'version': 1,
        'requestId': 'test-${++_request}',
        'command': command,
        'arguments': arguments,
        'sessionToken': sessionToken,
      }),
    );
  }

  static Future<_Harness> mount(WidgetTester tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final storage = await StorageService.getInstance();
    final settings = await SettingsService.getInstance();
    final profiles = ProfileRegistry(database);
    final connections = ConnectionRegistry(database);
    final profileConnections = ProfileConnectionRegistry(database);
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    final active = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    final manager = MultiServerManager();
    final multi = testMultiServerProvider(manager);
    final harness = _Harness(active);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.rootKey.dispose();
      active.dispose();
      multi.dispose();
      manager.dispose();
      await plexHome.dispose();
      await database.close();
    });
    final profile = Profile.local(id: 'agent-test', displayName: 'Agent', createdAt: DateTime(2026));
    await profiles.upsert(profile);
    await storage.setActiveProfileId(profile.id);
    await active.initialize();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsService>.value(value: settings),
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: active),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multi),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              harness.context = context;
              return ValueListenableBuilder<Key>(
                valueListenable: harness.rootKey,
                builder: (_, rootKey, _) => AgentControlScope(
                  key: rootKey,
                  commandContext: () => context,
                  child: AgentControlScope(
                    key: harness.profileKey,
                    profile: true,
                    commandContext: () => context,
                    child: const Scaffold(body: Text('Content')),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return harness;
  }
}
