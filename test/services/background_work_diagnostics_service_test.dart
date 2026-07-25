import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/background_work_diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadStallDetector', () {
    late DownloadStallDetector detector;
    final start = DateTime(2026, 7, 25, 12);

    setUp(() {
      detector = DownloadStallDetector(
        minimumBackgroundGap: const Duration(seconds: 60),
        minimumProgressBytes: 64 * 1024,
        observationsToConfirm: 2,
      );
    });

    test('needs two consecutive stalls before accusing the OEM', () {
      detector.onPaused(_activity(), start);
      expect(detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true), isFalse);
      expect(detector.isStalled, isFalse);

      detector.onPaused(_activity(), start.add(const Duration(minutes: 6)));
      expect(detector.onResumed(_activity(), start.add(const Duration(minutes: 11)), networkAvailable: true), isTrue);
      expect(detector.isStalled, isTrue);
    });

    test('confirms only once, so the warning is not re-raised every resume', () {
      for (var i = 0; i < 2; i++) {
        detector.onPaused(_activity(), start);
        detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      }
      expect(detector.isStalled, isTrue);

      detector.onPaused(_activity(), start);
      expect(
        detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true),
        isFalse,
        reason: 'already confirmed',
      );
    });

    test('real background progress clears the counter', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      expect(detector.consecutiveStalls, 1);

      detector.onPaused(_activity(), start.add(const Duration(minutes: 6)));
      detector.onResumed(
        _activity(downloadedBytes: 1000 + 5 * 1024 * 1024),
        start.add(const Duration(minutes: 11)),
        networkAvailable: true,
      );
      expect(detector.consecutiveStalls, 0);
    });

    test('a completed download below the byte floor clears the counter', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      expect(detector.consecutiveStalls, 1);

      detector.onPaused(_activity(), start.add(const Duration(minutes: 6)));
      detector.onResumed(
        _activity(activeTasks: 0, completedTasks: 1, downloadedBytes: 21 * 1024),
        start.add(const Duration(minutes: 11)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 0);
    });

    test('a completion with omitted byte counters still clears the counter', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      expect(detector.consecutiveStalls, 1);

      detector.onPaused(_activity(downloadedBytes: 500 * 1024 * 1024), start.add(const Duration(minutes: 6)));
      detector.onResumed(
        _activity(activeTasks: 0, completedTasks: 1, downloadedBytes: 0),
        start.add(const Duration(minutes: 11)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 0);
    });

    test('percentage progress clears the counter when byte length is unknown', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      expect(detector.consecutiveStalls, 1);

      detector.onPaused(_activity(progressUnits: 20), start.add(const Duration(minutes: 6)));
      detector.onResumed(_activity(progressUnits: 21), start.add(const Duration(minutes: 11)), networkAvailable: true);

      expect(detector.consecutiveStalls, 0);
    });

    test('an idle app is never scored', () {
      detector.onPaused(_activity(activeTasks: 0), start);
      expect(
        detector.onResumed(_activity(activeTasks: 0), start.add(const Duration(hours: 8)), networkAvailable: true),
        isFalse,
      );
      expect(detector.consecutiveStalls, 0);
    });

    test('a task removed without failing is inconclusive', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      expect(detector.consecutiveStalls, 1);

      detector.onPaused(_activity(), start.add(const Duration(minutes: 6)));
      detector.onResumed(_activity(activeTasks: 0), start.add(const Duration(minutes: 11)), networkAvailable: true);

      expect(detector.consecutiveStalls, 1);
    });

    test('a newly failed active task is stall evidence', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(
        _activity(activeTasks: 0, failedTasks: 1),
        start.add(const Duration(minutes: 5)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 1);
    });

    test('a short background trip proves nothing', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(seconds: 30)), networkAvailable: true);

      expect(detector.consecutiveStalls, 0);
    });

    test('being offline is not evidence of a restriction', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: false);

      expect(detector.consecutiveStalls, 0);
    });

    test('an offline endpoint is inconclusive even when policy allows downloads', () {
      detector.onPaused(_activity(networkAvailable: false), start);
      detector.onResumed(
        _activity(networkAvailable: false),
        start.add(const Duration(minutes: 5)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 0);
    });

    test('a network transition during the background window is inconclusive', () {
      detector.onPaused(_activity(networkStateGeneration: 4), start);
      detector.onResumed(
        _activity(networkStateGeneration: 5),
        start.add(const Duration(minutes: 5)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 0);
    });

    test('downloads deleted while backgrounded are inconclusive', () {
      detector.onPaused(_activity(activeTasks: 2, downloadedBytes: 900 * 1024 * 1024), start);
      detector.onResumed(
        _activity(downloadedBytes: 10 * 1024 * 1024),
        start.add(const Duration(minutes: 5)),
        networkAvailable: true,
      );

      expect(detector.consecutiveStalls, 0);
    });

    test('reset clears both the armed snapshot and the count', () {
      detector.onPaused(_activity(), start);
      detector.onResumed(_activity(), start.add(const Duration(minutes: 5)), networkAvailable: true);
      detector.reset();
      expect(detector.consecutiveStalls, 0);

      expect(detector.onResumed(_activity(), start.add(const Duration(minutes: 10)), networkAvailable: true), isFalse);
    });
  });

  group('BackgroundWorkStatus', () {
    test('describe reports unknown until a probe lands', () {
      expect(const BackgroundWorkStatus().describe(), 'unknown');
    });

    test('describe carries verdict, reasons and raw signals for log uploads', () {
      const status = BackgroundWorkStatus(
        verdict: BackgroundWorkVerdict.blocked,
        reasons: [BackgroundWorkReason.backgroundRestricted, BackgroundWorkReason.standbyRestricted],
        standbyBucket: 45,
        ignoringBatteryOptimizations: false,
        probed: true,
      );

      expect(status.describe(), 'blocked background_restricted+standby_restricted bucket:45 batteryWhitelist:false');
    });

    test('routes notification faults to their valid settings screens', () {
      const channel = BackgroundWorkStatus(
        verdict: BackgroundWorkVerdict.degraded,
        reasons: [BackgroundWorkReason.downloadChannelBlocked],
        probed: true,
      );
      const appWide = BackgroundWorkStatus(
        verdict: BackgroundWorkVerdict.blocked,
        reasons: [BackgroundWorkReason.notificationsDisabled],
        probed: true,
      );
      const battery = BackgroundWorkStatus(
        verdict: BackgroundWorkVerdict.blocked,
        reasons: [BackgroundWorkReason.backgroundRestricted],
        probed: true,
      );

      expect(channel.remedyTarget, BackgroundSettingsTarget.notificationChannel);
      expect(appWide.remedyTarget, BackgroundSettingsTarget.appNotifications);
      expect(battery.remedyTarget, BackgroundSettingsTarget.appDetails);
    });
  });

  group('BackgroundWorkDiagnosticsService', () {
    late List<MethodCall> calls;
    late Map<String, Object?> signals;
    const channel = MethodChannel('com.plezy/device.test');

    BackgroundWorkDiagnosticsService buildService({
      DownloadStallDetector? stallDetector,
      Future<bool> Function()? networkProbe,
      DateTime Function()? clock,
      bool supported = true,
    }) => BackgroundWorkDiagnosticsService.forTesting(
      channel: channel,
      stallDetector: stallDetector,
      networkProbe: networkProbe,
      clock: clock,
      supported: supported,
    );

    setUp(() {
      calls = [];
      signals = {'verdict': 'ok', 'reasons': <String>[]};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'getBackgroundWorkSignals' => signals,
          'openBackgroundSettings' => true,
          _ => null,
        };
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('a healthy probe stays healthy but records that it ran', () async {
      final service = buildService();

      final status = await service.refresh();

      expect(status.verdict, BackgroundWorkVerdict.ok);
      expect(status.reasons, isEmpty);
      expect(status.probed, isTrue);
      expect(service.describeSync(), 'ok');
    });

    test('binding download activity performs the cold-start probe', () async {
      signals = {
        'verdict': 'blocked',
        'reasons': ['background_restricted'],
      };
      final service = buildService();

      service.bindActivitySource(_activity);
      await Future<void>.delayed(Duration.zero);

      expect(calls.where((call) => call.method == 'getBackgroundWorkSignals'), hasLength(1));
      expect(service.status.isBlocked, isTrue);
      service.unbindActivitySource(_activity);
      service.dispose();
    });

    test('unsupported devices neither observe nor probe', () async {
      final service = buildService(supported: false);

      service.bindActivitySource(_activity);
      await Future<void>.delayed(Duration.zero);

      expect(service.isSupported, isFalse);
      expect(calls, isEmpty);
      expect(service.status.probed, isFalse);
      service.unbindActivitySource(_activity);
      service.dispose();
    });

    test('parses a blocked verdict with its reasons in order', () async {
      signals = {
        'verdict': 'blocked',
        'reasons': ['background_restricted', 'standby_restricted'],
        'standbyBucket': 45,
        'ignoringBatteryOptimizations': false,
      };
      final service = buildService();

      final status = await service.refresh();

      expect(status.verdict, BackgroundWorkVerdict.blocked);
      expect(status.reasons, [BackgroundWorkReason.backgroundRestricted, BackgroundWorkReason.standbyRestricted]);
      expect(status.standbyBucket, 45);
      expect(status.primaryReason, BackgroundWorkReason.backgroundRestricted);
    });

    test('a blocked verdict with no recognizable reason is not trusted', () async {
      // A newer native build emitting an unknown reason id must not produce a
      // warning the UI has nothing to say about.
      signals = {
        'verdict': 'blocked',
        'reasons': ['some_future_reason'],
      };
      final service = buildService();

      final status = await service.refresh();

      expect(status.verdict, BackgroundWorkVerdict.ok);
      expect(status.reasons, isEmpty);
    });

    test('refuses an oem_unknown reason arriving over the wire', () async {
      signals = {
        'verdict': 'blocked',
        'reasons': ['oem_unknown'],
      };
      final service = buildService();

      final status = await service.refresh();

      expect(status.reasons, isEmpty);
      expect(status.verdict, BackgroundWorkVerdict.ok);
    });

    test('data saver alone is degraded, not blocked', () async {
      signals = {
        'verdict': 'degraded',
        'reasons': ['data_saver'],
      };
      final service = buildService();

      final status = await service.refresh();

      expect(status.verdict, BackgroundWorkVerdict.degraded);
      expect(status.isBlocked, isFalse);
      expect(status.isHealthy, isFalse);
    });

    test('concurrent refreshes coalesce into a single platform call', () async {
      final service = buildService();

      await Future.wait([service.refresh(), service.refresh(), service.refresh()]);

      expect(calls.where((c) => c.method == 'getBackgroundWorkSignals'), hasLength(1));
    });

    test('a missing native handler never produces a warning and stops asking', () async {
      var attempts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        attempts++;
        throw MissingPluginException();
      });
      final service = buildService();

      final first = await service.refresh();
      final second = await service.refresh();

      expect(first.verdict, BackgroundWorkVerdict.ok);
      expect(first.probed, isFalse);
      expect(second.probed, isFalse);
      expect(attempts, 1);
    });

    test('an in-flight probe completing after disposal is ignored', () async {
      final gate = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) {
        calls.add(call);
        return gate.future;
      });
      final service = buildService();

      final refresh = service.refresh();
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      gate.complete({
        'verdict': 'blocked',
        'reasons': ['background_restricted'],
      });

      await expectLater(refresh, completes);
      expect(service.status.probed, isFalse);
    });

    test('a confirmed stall survives a probe that reports everything is fine', () async {
      final detector = DownloadStallDetector(observationsToConfirm: 1, minimumBackgroundGap: Duration.zero);
      final service = buildService(stallDetector: detector, networkProbe: () async => true);
      detector.onPaused(_activity(downloadedBytes: 0), DateTime(2026));
      detector.onResumed(_activity(downloadedBytes: 0), DateTime(2026, 1, 1, 1), networkAvailable: true);
      expect(detector.isStalled, isTrue);

      final status = await service.refresh();

      expect(status.verdict, BackgroundWorkVerdict.blocked);
      expect(status.reasons, [BackgroundWorkReason.oemUnknown]);
    });

    test('clearing stall evidence drops the reason and re-probes', () async {
      final detector = DownloadStallDetector(observationsToConfirm: 1, minimumBackgroundGap: Duration.zero);
      final service = buildService(stallDetector: detector, networkProbe: () async => true);
      detector.onPaused(_activity(downloadedBytes: 0), DateTime(2026));
      detector.onResumed(_activity(downloadedBytes: 0), DateTime(2026, 1, 1, 1), networkAvailable: true);
      await service.refresh();
      expect(service.status.isBlocked, isTrue);

      await service.clearStallEvidence();

      expect(service.status.reasons, isEmpty);
      expect(service.status.verdict, BackgroundWorkVerdict.ok);
      expect(detector.isStalled, isFalse);
    });

    test('opening settings forwards the target id the native side expects', () async {
      final service = buildService();

      final opened = await service.openSettings(BackgroundSettingsTarget.notificationChannel);

      expect(opened, isTrue);
      final call = calls.firstWhere((c) => c.method == 'openBackgroundSettings');
      expect(call.arguments, 'notification_channel');
    });

    test('lifecycle resume scores the synchronously captured snapshot', () async {
      final detector = DownloadStallDetector(observationsToConfirm: 1, minimumBackgroundGap: Duration.zero);
      final networkGate = Completer<bool>();
      var now = DateTime(2026);
      var activity = _activity(downloadedBytes: 1000);
      final service = buildService(stallDetector: detector, networkProbe: () => networkGate.future, clock: () => now);
      DownloadActivitySnapshot source() => activity;
      service.bindActivitySource(source);
      await Future<void>.delayed(Duration.zero);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      activity = _activity(downloadedBytes: 5 * 1024 * 1024);
      networkGate.complete(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(detector.isStalled, isTrue, reason: 'progress after resume must not be credited to the background window');
      expect(service.status.reasons, contains(BackgroundWorkReason.oemUnknown));
      service.unbindActivitySource(source);
      service.dispose();
    });

    test('notifies listeners only when the status actually changes', () async {
      signals = {
        'verdict': 'blocked',
        'reasons': ['background_restricted'],
      };
      final service = buildService();
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.refresh();
      await service.refresh();

      expect(notifications, 1);
    });
  });
}

DownloadActivitySnapshot _activity({
  int activeTasks = 1,
  int completedTasks = 0,
  int failedTasks = 0,
  int downloadedBytes = 1000,
  int progressUnits = 0,
  bool? networkAvailable = true,
  int networkStateGeneration = 0,
}) => (
  activeTasks: activeTasks,
  completedTasks: completedTasks,
  failedTasks: failedTasks,
  downloadedBytes: downloadedBytes,
  progressUnits: progressUnits,
  networkAvailable: networkAvailable,
  networkStateGeneration: networkStateGeneration,
);
