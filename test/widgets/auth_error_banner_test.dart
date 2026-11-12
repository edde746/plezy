import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/widgets/auth_error_banner.dart';
import 'package:provider/provider.dart';

import '../test_helpers/multi_server_fixtures.dart';

void main() {
  late MultiServerManager manager;
  late MultiServerProvider provider;

  setUp(() {
    manager = MultiServerManager();
    provider = testMultiServerProvider(manager);
  });

  tearDown(() {
    provider.dispose();
    manager.dispose();
  });

  Future<void> pumpBanner(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider<MultiServerProvider>.value(
      value: provider,
      child: const MaterialApp(home: Scaffold(body: AuthErrorBanner())),
    ),
  );

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

  Future<void> pumpTrackers(WidgetTester tester, _TestTrackersProvider trackers, {double textScale = 1}) =>
      tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: provider),
            ChangeNotifierProvider<TrackersProvider>.value(value: trackers),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: const Scaffold(body: AuthErrorBanner()),
          ),
        ),
      );

  testWidgets('lost tracker logins are named beside an existing server warning', (tester) async {
    manager.debugMarkAuthErrorForTesting(ServerId('expired'));
    final trackers = _TestTrackersProvider()..warnings = [TrackerService.trakt, TrackerService.mal];
    addTearDown(trackers.dispose);

    await pumpTrackers(tester, trackers);

    expect(find.text(t.connections.sessionExpiredOne(name: 'expired')), findsOneWidget);
    expect(find.text(t.connections.sessionExpiredOne(name: t.trakt.title)), findsOneWidget);
    expect(find.text(t.connections.sessionExpiredOne(name: t.services.names.mal)), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsNWidgets(3));
  });

  testWidgets('tracker sign-in uses the existing connection flow and hides after recovery', (tester) async {
    final trackers = _TestTrackersProvider()..warnings = [TrackerService.trakt];
    addTearDown(trackers.dispose);
    await pumpTrackers(tester, trackers);

    await tester.tap(find.text(t.connections.signInAgain));
    await tester.pump();
    expect(trackers.traktConnections, 1);
    expect(find.text(t.connections.sessionExpiredOne(name: t.trakt.title)), findsOneWidget);

    trackers.warnings = [];
    await tester.pump();
    expect(find.text(t.connections.sessionExpiredOne(name: t.trakt.title)), findsNothing);
    expect(find.text(t.connections.signInAgain), findsNothing);
  });

  testWidgets('tracker reconnect is disabled while another tracker is connecting', (tester) async {
    final trackers = _TestTrackersProvider()
      ..warnings = [TrackerService.trakt]
      ..connecting = TrackerService.mal;
    addTearDown(trackers.dispose);
    await pumpTrackers(tester, trackers);

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.tap(find.text(t.connections.signInAgain));
    expect(trackers.traktConnections, 0);
  });

  testWidgets('tracker warning fits a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final trackers = _TestTrackersProvider()..warnings = [TrackerService.trakt];
    addTearDown(trackers.dispose);

    await pumpTrackers(tester, trackers, textScale: 3);

    expect(find.text(t.connections.sessionExpiredOne(name: t.trakt.title)), findsOneWidget);
    expect(find.text(t.connections.signInAgain), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestTrackersProvider extends TrackersProvider {
  List<TrackerService> _warnings = [];
  TrackerService? connecting;
  int traktConnections = 0;

  set warnings(List<TrackerService> value) {
    _warnings = value;
    notifyListeners();
  }

  @override
  List<TrackerService> get reconnectRequiredServices => _warnings;

  @override
  bool isConnecting(TrackerService service) => connecting == service;

  @override
  Future<bool> connectTrakt({required void Function(DeviceCode code) onCodeReady}) async {
    traktConnections++;
    // Do not emit a device code: this exercises the launcher without opening a
    // browser or depending on a live tracker account.
    return false;
  }
}
