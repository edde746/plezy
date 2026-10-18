import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/settings_mutation_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

/// A companion host that declines to apply the setting: `stopHostServer`
/// leaves the server running, which is what `applyCompanionRemoteServerSetting`
/// reports as `false`. Crypto-not-ready and a caught start failure reach the
/// same return, so this stands in for all three.
class _DecliningCompanionRemoteProvider extends CompanionRemoteProvider {
  _DecliningCompanionRemoteProvider() : super.forTesting(peerServiceFactory: CompanionRemotePeerService.new);

  @override
  bool get isHostServerRunning => true;

  @override
  Future<void> stopHostServer({void Function()? checkCurrent}) async => checkCurrent?.call();

  @override
  Future<void> startHostServer({void Function()? checkCurrent}) async => checkCurrent?.call();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _DecliningCompanionRemoteProvider companion;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    // The disable path: the effect asks the host to stop, and it doesn't.
    await settings.write(SettingsService.enableCompanionRemoteServer, false);
    companion = _DecliningCompanionRemoteProvider();
  });

  tearDown(() => companion.dispose());

  Future<BuildContext> pumpHost(WidgetTester tester, {Widget? child}) async {
    late BuildContext captured;
    await tester.pumpWidget(
      ChangeNotifierProvider<CompanionRemoteProvider>.value(
        value: companion,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                captured = context;
                return child ?? const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('a declining effect is reported to the caller, not thrown past it', (tester) async {
    final context = await pumpHost(tester);

    final failure = await const SettingsMutationService().applyEffects(
      context,
      SettingsService.enableCompanionRemoteServer,
      rebuildRoot: false,
    );

    expect(failure, isNotNull);
    expect(failure!.pref.key, SettingsService.enableCompanionRemoteServer.key);
    expect(failure.display, t.settings.companionRemoteServerStopFailed);
  });

  testWidgets('a bulk replay finishes and returns the failure instead of aborting', (tester) async {
    final context = await pumpHost(tester);

    final failures = await const SettingsMutationService().applyStoredEffects(
      context,
      previousRootConfiguration: SettingsMutationService.captureRootConfiguration(),
    );

    expect(failures, hasLength(1));
    expect(failures.single.pref.key, SettingsService.enableCompanionRemoteServer.key);
  });

  testWidgets('toggling the setting tile surfaces the reason instead of raising an async error', (tester) async {
    await pumpHost(
      tester,
      child: SettingSwitchTile(
        pref: SettingsService.enableCompanionRemoteServer,
        icon: Icons.phone_android,
        title: 'Companion Remote Server',
      ),
    );

    // Switch it on, then off: the off write is the one whose effect declines.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t.settings.companionRemoteServerStopFailed), findsOneWidget);
  });
}
