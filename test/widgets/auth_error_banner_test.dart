import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/screens/settings/services_settings_screen.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/widgets/auth_error_banner.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

void main() {
  late MultiServerManager manager;
  late MultiServerProvider provider;
  late _TestTrackersProvider trackers;
  late SeerrAccountProvider seerr;
  late List<String> connectionAttempts;

  setUp(() async {
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    manager = MultiServerManager();
    provider = testMultiServerProvider(manager);
    seerr = SeerrAccountProvider();
    connectionAttempts = [];
    trackers = _TestTrackersProvider(connectionAttempts);
  });

  tearDown(() {
    provider.dispose();
    manager.dispose();
    trackers.dispose();
    seerr.dispose();
  });

  Future<void> pumpBanner(WidgetTester tester, {double textScale = 1}) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MultiServerProvider>.value(value: provider),
        ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
        ChangeNotifierProvider<SeerrAccountProvider>.value(value: seerr),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: AuthErrorBanner()),
      ),
    ),
  );

  void requireReconnect(List<TrackerService> services) => trackers.requireReconnect(services);

  testWidgets('unconfigured services do not produce a warning', (tester) async {
    await pumpBanner(tester);
    expect(find.byType(Material), findsWidgets);
    expect(find.text(t.common.reconnect), findsNothing);
    expect(find.byTooltip(t.services.dismissReconnectWarning), findsNothing);
  });

  testWidgets('a lost tracker names the service beside existing server errors', (tester) async {
    requireReconnect([TrackerService.trakt]);
    manager.debugMarkAuthErrorForTesting(ServerId('expired'));
    await pumpBanner(tester);

    expect(find.text(t.services.reconnectWarning(service: 'Trakt')), findsOneWidget);
    expect(find.text(t.connections.sessionExpiredOne(name: 'expired')), findsOneWidget);
    expect(find.text(t.common.reconnect), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsOneWidget);
  });

  testWidgets('reconnect for one tracker opens that service flow and retains a failed warning', (tester) async {
    requireReconnect([TrackerService.trakt]);
    await pumpBanner(tester);
    await tester.tap(find.text(t.common.reconnect));
    await tester.pumpAndSettle();

    expect(connectionAttempts, ['trakt']);
    expect(trackers.reconnectRequiredServices, [TrackerService.trakt]);
    expect(find.text(t.services.reconnectWarning(service: 'Trakt')), findsOneWidget);
  });

  testWidgets('multiple lost trackers share one banner and open Services with sign-in status', (tester) async {
    requireReconnect([TrackerService.trakt, TrackerService.mal]);
    await pumpBanner(tester);

    expect(find.text(t.services.reconnectWarningMany(count: 2)), findsOneWidget);
    expect(find.text(t.common.reconnect), findsOneWidget);
    await tester.tap(find.text(t.common.reconnect));
    await tester.pumpAndSettle();

    expect(find.byType(ServicesSettingsScreen), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsNWidgets(2));
    expect(connectionAttempts, isEmpty, reason: 'the user chooses which account to reconnect');
  });

  testWidgets('dismissing acknowledges every displayed tracker and clears the banner', (tester) async {
    requireReconnect([TrackerService.trakt, TrackerService.mal]);
    await pumpBanner(tester);
    await tester.tap(find.byTooltip(t.services.dismissReconnectWarning));
    await tester.pumpAndSettle();

    expect(trackers.reconnectRequiredServices, isEmpty);
    expect(find.text(t.common.reconnect), findsNothing);
    expect(trackers.dismissed, [TrackerService.trakt, TrackerService.mal]);
  });

  testWidgets('Services exposes a persisted polling toggle and bounded custom interval', (tester) async {
    requireReconnect([TrackerService.trakt, TrackerService.mal]);
    await pumpBanner(tester);
    await tester.tap(find.text(t.common.reconnect));
    await tester.pumpAndSettle();
    final interval = find.text(t.services.checkInterval);
    await tester.ensureVisible(interval);
    expect(interval, findsOneWidget);
    await tester.tap(find.text(t.services.periodicChecks));
    await tester.pumpAndSettle();
    expect(SettingsService.instance.read(SettingsService.enableTrackerConnectionChecks), isFalse);
    expect(interval, findsNothing);
    await tester.tap(find.text(t.services.periodicChecks));
    await tester.pumpAndSettle();
    expect(interval, findsOneWidget);
    await tester.ensureVisible(interval);
    await tester.tap(interval);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text(t.common.save));
    await tester.pumpAndSettle();
    expect(SettingsService.instance.read(SettingsService.trackerConnectionCheckMinutes), 2);
    expect(find.text(t.services.checkIntervalDescription(minutes: 2)), findsOneWidget);
  });

  testWidgets('multiple tracker warnings fit on a narrow phone with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    requireReconnect(TrackerService.values);
    await pumpBanner(tester, textScale: 3);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'the message and actions must not overflow');
    expect(find.text(t.services.reconnectWarningMany(count: 5)), findsOneWidget);
    expect(find.text(t.common.reconnect), findsOneWidget);
    expect(find.byTooltip(t.services.dismissReconnectWarning), findsOneWidget);
  });

  testWidgets('a server refusing the account (403) is explained without a sign-in that cannot help', (tester) async {
    manager.debugMarkAccessDeniedForTesting(ServerId('denied'));

    await pumpBanner(tester);

    expect(find.text(t.connections.accessDeniedOne(name: 'denied')), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsNothing);
    expect(find.textContaining(t.connections.sessionExpiredOne(name: 'denied')), findsNothing);
  });

  testWidgets('a rejected token keeps its sign-in prompt beside a refused account', (tester) async {
    manager.debugMarkAuthErrorForTesting(ServerId('expired'));
    manager.debugMarkAccessDeniedForTesting(ServerId('denied'));

    await pumpBanner(tester);

    expect(find.text(t.connections.sessionExpiredOne(name: 'expired')), findsOneWidget);
    expect(find.text(t.connections.accessDeniedOne(name: 'denied')), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsOneWidget);
  });
}

/// Drive the banner's account state without involving the global watch retry
/// queue. Real session invalidation, persistence and profile guards are covered
/// in trackers_provider_test.dart and tracker_account_store_scope_test.dart.
class _TestTrackersProvider extends TrackersProvider {
  _TestTrackersProvider(List<String> attempts)
    : super.forTesting(
        connectPipeline:
            ({required logLabel, required authorize, required enrich, required save, required assign}) async {
              attempts.add(logLabel);
              return false;
            },
      );

  final _warnings = <TrackerService>[];
  final dismissed = <TrackerService>[];

  @override
  List<TrackerService> get reconnectRequiredServices => [..._warnings];

  void requireReconnect(List<TrackerService> services) {
    _warnings
      ..clear()
      ..addAll(services);
    safeNotifyListeners();
  }

  @override
  Future<void> dismissReconnectWarning(TrackerService service) async {
    dismissed.add(service);
    _warnings.remove(service);
    safeNotifyListeners();
  }
}
