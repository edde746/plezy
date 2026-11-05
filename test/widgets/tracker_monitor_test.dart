import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/widgets/tracker_playback_notice.dart';
import 'package:plezy/widgets/tracker_session_monitor.dart';
import 'package:provider/provider.dart';

void main() {
  late _TestTrackersProvider trackers;

  setUp(() => trackers = _TestTrackersProvider());
  tearDown(() => trackers.dispose());

  Future<void> pumpMonitor(WidgetTester tester, {bool enabled = true, int minutes = 5}) => tester.pumpWidget(
    ChangeNotifierProvider<TrackersProvider>.value(
      value: trackers,
      child: TrackerSessionMonitor(enabled: enabled, intervalMinutes: minutes, child: const SizedBox()),
    ),
  );

  Future<void> pumpNotice(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider<TrackersProvider>.value(
      value: trackers,
      child: const MaterialApp(home: Scaffold(body: TrackerPlaybackNotice())),
    ),
  );

  testWidgets('polls within the jitter window, then schedules another check', (tester) async {
    await pumpMonitor(tester);
    await tester.pump(const Duration(seconds: 239));
    expect(trackers.checks, 0);
    await tester.pump(const Duration(seconds: 121));
    expect(trackers.checks, 1);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, inInclusiveRange(2, 3));
    final checksBeforeDispose = trackers.checks;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, checksBeforeDispose);
  });

  testWidgets('offline mode cancels polling and online mode restarts it', (tester) async {
    await pumpMonitor(tester);
    await pumpMonitor(tester, enabled: false);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, 0);
    await pumpMonitor(tester);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('polling continues underneath an open playback route', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<TrackersProvider>.value(
        value: trackers,
        child: MaterialApp(
          home: TrackerSessionMonitor(
            enabled: true,
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(
                    Navigator.of(
                      context,
                    ).push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Playback')))),
                  ),
                  child: const Text('Play'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Playback'), findsOneWidget);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('background cancels polling and foreground restarts it', (tester) async {
    await pumpMonitor(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(minutes: 6));
    expect(trackers.checks, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('changing the interval replaces the pending timer immediately', (tester) async {
    await pumpMonitor(tester, minutes: 10);
    await tester.pump(const Duration(seconds: 20));
    await pumpMonitor(tester, minutes: 1);
    await tester.pump(const Duration(seconds: 47));
    expect(trackers.checks, 0);
    await tester.pump(const Duration(seconds: 25));
    expect(trackers.checks, 1);
    await pumpMonitor(tester, enabled: false, minutes: 1);
    await tester.pump(const Duration(minutes: 10));
    expect(trackers.checks, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a newly lost login produces one temporary playback notice', (tester) async {
    await pumpNotice(tester);
    final text = t.services.reconnectWarning(service: 'Trakt');
    trackers.warnings = [TrackerService.trakt];
    await tester.pump();
    await tester.pump();
    expect(find.text(text), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(find.text(text), findsNothing);
    trackers.warnings = [TrackerService.trakt];
    await tester.pump();
    expect(find.text(text), findsNothing);
    trackers.warnings = [];
    trackers.warnings = [TrackerService.trakt];
    await tester.pump();
    await tester.pump();
    expect(find.text(text), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('entering playback does not replay previously recorded warnings', (tester) async {
    trackers.warnings = [TrackerService.trakt];
    await pumpNotice(tester);
    expect(find.text(t.services.reconnectWarning(service: 'Trakt')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('several newly lost logins share one notice', (tester) async {
    await pumpNotice(tester);
    trackers.warnings = [TrackerService.trakt, TrackerService.mal];
    await tester.pump();
    await tester.pump();
    expect(find.text(t.services.reconnectWarningMany(count: 2)), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('recovery before the frame drops the pending notice', (tester) async {
    await pumpNotice(tester);
    trackers.warnings = [TrackerService.trakt];
    trackers.warnings = [];
    await tester.pump();
    await tester.pump();
    expect(find.text(t.services.reconnectWarning(service: 'Trakt')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}

class _TestTrackersProvider extends TrackersProvider {
  _TestTrackersProvider()
    : super.forTesting(
        connectPipeline:
            ({required logLabel, required authorize, required enrich, required save, required assign}) async => false,
      );

  int checks = 0;
  List<TrackerService> _warnings = [];

  @override
  Future<void> validateSessions() async {
    checks++;
  }

  @override
  List<TrackerService> get reconnectRequiredServices => [..._warnings];

  set warnings(List<TrackerService> value) {
    _warnings = value;
    safeNotifyListeners();
  }
}
