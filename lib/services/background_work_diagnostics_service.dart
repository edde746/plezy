import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import 'download_manager_service.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

/// Why background downloads are expected to fail on this device.
///
/// Ordered by how actionable the remedy is; [BackgroundWorkStatus.reasons]
/// preserves the order the native classifier emits.
enum BackgroundWorkReason {
  /// AOSP per-app "Restricted" background usage. Samsung's "Background usage
  /// limits" (Sleeping apps / Deep sleeping apps) lands here too.
  backgroundRestricted('background_restricted'),

  /// App standby bucket is RESTRICTED or NEVER — deferred indefinitely.
  standbyRestricted('standby_restricted'),

  /// The downloader's notification channel is muted, which removes the
  /// foreground-service anchor keeping downloads alive across screen-off.
  downloadChannelBlocked('download_channel_blocked'),

  /// Notifications are off app-wide.
  notificationsDisabled('notifications_disabled'),

  /// Data Saver blocks metered background traffic.
  dataSaver('data_saver'),

  /// No OS-visible restriction, but downloads empirically stop making progress
  /// whenever the app is backgrounded. Covers OEMs that block background work
  /// while reporting a clean bucket.
  oemUnknown('oem_unknown');

  const BackgroundWorkReason(this.id);

  final String id;

  static BackgroundWorkReason? fromId(String id) {
    for (final reason in values) {
      if (reason.id == id) return reason;
    }
    return null;
  }
}

/// Severity of the detected restrictions.
enum BackgroundWorkVerdict {
  /// Nothing detected, or the platform cannot tell us.
  ok,

  /// Downloads will run, but not under every network condition.
  degraded,

  /// Downloads are expected to stall the moment the app leaves the foreground.
  blocked,
}

/// Settings screen a remedy button routes to. Mirrors `BackgroundSettingsTarget`.
enum BackgroundSettingsTarget {
  appDetails('app_details'),
  appNotifications('app_notifications'),
  notificationChannel('notification_channel');

  const BackgroundSettingsTarget(this.id);

  final String id;
}

/// Immutable result of one probe.
@immutable
class BackgroundWorkStatus {
  const BackgroundWorkStatus({
    this.verdict = BackgroundWorkVerdict.ok,
    this.reasons = const [],
    this.standbyBucket,
    this.ignoringBatteryOptimizations,
    this.probed = false,
  });

  final BackgroundWorkVerdict verdict;
  final List<BackgroundWorkReason> reasons;
  final int? standbyBucket;
  final bool? ignoringBatteryOptimizations;

  /// False before the first successful native probe (and on every non-Android
  /// platform), so callers can distinguish "healthy" from "never asked".
  final bool probed;

  bool get isBlocked => verdict == BackgroundWorkVerdict.blocked;
  bool get isHealthy => verdict == BackgroundWorkVerdict.ok;

  /// The reason a single-line summary should lead with, if any.
  BackgroundWorkReason? get primaryReason => reasons.isEmpty ? null : reasons.first;

  /// Which Settings screen best addresses [primaryReason].
  BackgroundSettingsTarget get remedyTarget => switch (primaryReason) {
    BackgroundWorkReason.notificationsDisabled => BackgroundSettingsTarget.appNotifications,
    BackgroundWorkReason.downloadChannelBlocked => BackgroundSettingsTarget.notificationChannel,
    _ => BackgroundSettingsTarget.appDetails,
  };

  BackgroundWorkStatus withReason(BackgroundWorkReason reason) {
    if (reasons.contains(reason)) return this;
    return BackgroundWorkStatus(
      verdict: BackgroundWorkVerdict.blocked,
      reasons: [...reasons, reason],
      standbyBucket: standbyBucket,
      ignoringBatteryOptimizations: ignoringBatteryOptimizations,
      probed: probed,
    );
  }

  /// Compact form for the log upload header — the whole point of Phase 2 is
  /// that a support thread can be answered from one uploaded log.
  String describe() {
    if (!probed) return 'unknown';
    final parts = <String>[
      verdict.name,
      if (reasons.isNotEmpty) reasons.map((r) => r.id).join('+'),
      if (standbyBucket != null) 'bucket:$standbyBucket',
      if (ignoringBatteryOptimizations != null) 'batteryWhitelist:$ignoringBatteryOptimizations',
    ];
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      other is BackgroundWorkStatus &&
      other.verdict == verdict &&
      listEquals(other.reasons, reasons) &&
      other.standbyBucket == standbyBucket &&
      other.ignoringBatteryOptimizations == ignoringBatteryOptimizations &&
      other.probed == probed;

  @override
  int get hashCode =>
      Object.hash(verdict, Object.hashAll(reasons), standbyBucket, ignoringBatteryOptimizations, probed);
}

/// Aggregate process-wide download activity at a single instant.
typedef DownloadActivitySnapshot = ({
  int activeTasks,
  int completedTasks,
  int failedTasks,
  int downloadedBytes,
  int progressUnits,
  bool? networkAvailable,
  int networkStateGeneration,
});

typedef DownloadStallObservation = ({
  DownloadActivitySnapshot paused,
  DownloadActivitySnapshot resumed,
  Duration backgroundGap,
});

/// Detects OEMs that silently kill background work while reporting a clean
/// standby bucket (Xiaomi, Oppo, Vivo, Huawei), by watching whether downloads
/// actually advance while the app sits in the background.
///
/// Pure and clock-injected so the whole state machine is unit-testable.
class DownloadStallDetector {
  DownloadStallDetector({
    this.minimumBackgroundGap = const Duration(seconds: 60),
    this.minimumProgressBytes = 64 * 1024,
    this.observationsToConfirm = 2,
  });

  /// Shorter background trips prove nothing — the OS grants a grace period
  /// before it starts deferring work.
  final Duration minimumBackgroundGap;

  /// Below this, "progress" is indistinguishable from a buffer flush.
  final int minimumProgressBytes;

  /// Two independent observations before accusing the OEM, so one flaky
  /// network blip cannot produce a false warning.
  final int observationsToConfirm;

  DownloadActivitySnapshot? _pausedSnapshot;
  DateTime? _pausedAt;
  int _consecutiveStalls = 0;

  int get consecutiveStalls => _consecutiveStalls;

  bool get isStalled => _consecutiveStalls >= observationsToConfirm;

  /// Arms the detector. Only meaningful while something is actually downloading.
  void onPaused(DownloadActivitySnapshot snapshot, DateTime at) {
    if (snapshot.activeTasks <= 0) {
      _clearArmedSnapshot();
      return;
    }
    _pausedSnapshot = snapshot;
    _pausedAt = at;
  }

  /// Captures the resume state synchronously, before any awaited platform or
  /// settings work can allow later progress to leak into this observation.
  DownloadStallObservation? captureResumed(DownloadActivitySnapshot snapshot, DateTime at) {
    final pausedSnapshot = _pausedSnapshot;
    final pausedAt = _pausedAt;
    _clearArmedSnapshot();
    if (pausedSnapshot == null || pausedAt == null) return null;
    return (paused: pausedSnapshot, resumed: snapshot, backgroundGap: at.difference(pausedAt));
  }

  /// Scores a captured background trip. Returns true only when this trip has
  /// just confirmed a repeated OEM stall.
  bool evaluate(DownloadStallObservation? observation, {required bool networkAvailable}) {
    if (observation == null) return false;
    final pausedSnapshot = observation.paused;
    final snapshot = observation.resumed;

    final completedInBackground = snapshot.completedTasks > pausedSnapshot.completedTasks;
    final byteDelta = snapshot.downloadedBytes - pausedSnapshot.downloadedBytes;
    final progressDelta = snapshot.progressUnits - pausedSnapshot.progressUnits;

    // Real transfer progress clears prior evidence even when the network or
    // policy check below is inconclusive. A terminal event may omit byte data,
    // so completion and percentage progress are independent evidence.
    if (completedInBackground || byteDelta >= minimumProgressBytes || progressDelta > 0) {
      _consecutiveStalls = 0;
      return false;
    }

    // Removed rows and other backwards counters are not evidence of a stall.
    if (byteDelta < 0 || progressDelta < 0) return false;
    if (observation.backgroundGap < minimumBackgroundGap) return false;

    // Require known-good endpoints, no network/server transition anywhere in
    // the background window, and an eligible download policy at resume.
    if (!networkAvailable ||
        pausedSnapshot.networkAvailable != true ||
        snapshot.networkAvailable != true ||
        snapshot.networkStateGeneration != pausedSnapshot.networkStateGeneration) {
      return false;
    }

    final activeTasksDropped = snapshot.activeTasks < pausedSnapshot.activeTasks;
    final taskFailed = snapshot.failedTasks > pausedSnapshot.failedTasks;
    if (activeTasksDropped && !taskFailed) {
      // A paused/cancelled/removed task is not evidence of an OEM restriction.
      return false;
    }

    final wasConfirmed = isStalled;
    _consecutiveStalls++;
    return !wasConfirmed && isStalled;
  }

  /// Convenience wrapper for direct callers and unit tests.
  bool onResumed(DownloadActivitySnapshot snapshot, DateTime at, {required bool networkAvailable}) {
    return evaluate(captureResumed(snapshot, at), networkAvailable: networkAvailable);
  }

  void reset() {
    _clearArmedSnapshot();
    _consecutiveStalls = 0;
  }

  void _clearArmedSnapshot() {
    _pausedSnapshot = null;
    _pausedAt = null;
  }
}

/// Probes the OS for reasons background downloads will not run, and watches for
/// the symptom on OEMs that will not admit to it.
///
/// Every failure path resolves to [BackgroundWorkVerdict.ok]: a warning we
/// cannot substantiate trains users to ignore the ones we can.
class BackgroundWorkDiagnosticsService extends ChangeNotifier
    with WidgetsBindingObserver, DisposableChangeNotifierMixin {
  BackgroundWorkDiagnosticsService._()
    : _channelOverride = null,
      _clockOverride = null,
      _networkProbeOverride = null,
      _supportedOverride = null;

  @visibleForTesting
  BackgroundWorkDiagnosticsService.forTesting({
    MethodChannel? channel,
    DownloadStallDetector? stallDetector,
    DateTime Function()? clock,
    Future<bool> Function()? networkProbe,
    bool supported = true,
  }) : _channelOverride = channel,
       _stallDetector = stallDetector ?? DownloadStallDetector(),
       _clockOverride = clock,
       _networkProbeOverride = networkProbe,
       _supportedOverride = supported;

  static final BackgroundWorkDiagnosticsService instance = BackgroundWorkDiagnosticsService._();

  static const MethodChannel _deviceChannel = MethodChannel('com.plezy/device');

  final MethodChannel? _channelOverride;
  final DateTime Function()? _clockOverride;
  final Future<bool> Function()? _networkProbeOverride;
  final bool? _supportedOverride;

  DownloadStallDetector _stallDetector = DownloadStallDetector();
  DownloadActivitySnapshot Function()? _activitySource;
  BackgroundWorkStatus _status = const BackgroundWorkStatus();
  BackgroundWorkStatus _lastProbedStatus = const BackgroundWorkStatus();
  Future<void>? _inFlightRefresh;
  bool _observing = false;
  bool _channelMissing = false;

  MethodChannel get _channel => _channelOverride ?? _deviceChannel;

  DateTime _now() => (_clockOverride ?? DateTime.now)();

  /// Android phone/tablet only. TV boxes are mains-powered, and surfacing
  /// mobile battery/data restrictions there is noise.
  bool get isSupported => _supportedOverride ?? (Platform.isAndroid && !PlatformDetector.isTV());

  BackgroundWorkStatus get status => _status;

  /// One-line summary for the log upload header.
  String describeSync() => isSupported ? _status.describe() : 'n/a';

  /// Lets the download layer publish aggregate progress without this service
  /// reaching into providers.
  void bindActivitySource(DownloadActivitySnapshot Function() source) {
    _activitySource = source;
    _startObserving();
    // Populate the banner, Settings tile, and log header on a cold start.
    // Concurrent profile binds coalesce through [refresh].
    unawaited(refresh());
  }

  void unbindActivitySource(DownloadActivitySnapshot Function() source) {
    // Compared by `==` rather than `identical` so an instance-method tear-off
    // from the same provider matches on every SDK.
    if (_activitySource != source) return;
    _activitySource = null;
  }

  void _startObserving() {
    if (_observing || !isSupported) return;
    final binding = WidgetsBinding.instance;
    _observing = true;
    binding.addObserver(this);
  }

  /// Re-probes the OS. Coalesces concurrent calls — the bucket is cheap to read
  /// but there is no reason to read it three times on a single resume.
  Future<BackgroundWorkStatus> refresh() async {
    if (!isSupported || _channelMissing || isDisposed) return _status;
    final inFlight = _inFlightRefresh;
    if (inFlight != null) {
      await inFlight;
      return _status;
    }
    final refresh = _refresh();
    _inFlightRefresh = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_inFlightRefresh, refresh)) _inFlightRefresh = null;
    }
    return _status;
  }

  Future<void> _refresh() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('getBackgroundWorkSignals');
      if (isDisposed) return;
      if (raw == null) return;
      _applyStatus(_parse(raw));
    } on MissingPluginException {
      // Stale native build — never warn on a signal we could not read.
      _channelMissing = true;
    } catch (e) {
      appLogger.d('Background work probe failed: $e');
    }
  }

  BackgroundWorkStatus _parse(Map<String, Object?> raw) {
    final verdict = switch (raw['verdict']) {
      'blocked' => BackgroundWorkVerdict.blocked,
      'degraded' => BackgroundWorkVerdict.degraded,
      _ => BackgroundWorkVerdict.ok,
    };
    final reasons = <BackgroundWorkReason>[];
    final rawReasons = raw['reasons'];
    if (rawReasons is List) {
      for (final entry in rawReasons) {
        if (entry is! String) continue;
        final reason = BackgroundWorkReason.fromId(entry);
        // oem_unknown is ours, never the platform's — refuse it over the wire.
        if (reason != null && reason != BackgroundWorkReason.oemUnknown) reasons.add(reason);
      }
    }
    final bucket = raw['standbyBucket'];
    final whitelisted = raw['ignoringBatteryOptimizations'];
    return BackgroundWorkStatus(
      // Trust our own reason parse over the reported verdict: an unknown reason
      // id from a newer native build must not silently downgrade to blocked.
      verdict: reasons.isEmpty ? BackgroundWorkVerdict.ok : verdict,
      reasons: reasons,
      standbyBucket: bucket is int ? bucket : null,
      ignoringBatteryOptimizations: whitelisted is bool ? whitelisted : null,
      probed: true,
    );
  }

  void _applyStatus(BackgroundWorkStatus probed) {
    if (isDisposed) return;
    _lastProbedStatus = probed;
    _applyCurrentStatus();
  }

  void _applyCurrentStatus() {
    // A confirmed empirical stall outlives any single probe: the OS keeps
    // reporting healthy on exactly the devices this catches.
    final next = _stallDetector.isStalled
        ? _lastProbedStatus.withReason(BackgroundWorkReason.oemUnknown)
        : _lastProbedStatus;
    if (next == _status) return;
    final previous = _status;
    _status = next;
    if (previous.verdict != next.verdict || !listEquals(previous.reasons, next.reasons)) {
      appLogger.i('Background work status: ${next.describe()}');
    }
    safeNotifyListeners();
  }

  /// Opens the Settings screen that addresses [target]. Returns false when the
  /// device has no such screen, so the caller can fall back to written steps.
  Future<bool> openSettings(BackgroundSettingsTarget target) async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('openBackgroundSettings', target.id) ?? false;
    } catch (e) {
      appLogger.w('Opening background settings failed', error: e);
      return false;
    }
  }

  /// Clears an empirical stall verdict after the user reports having fixed it.
  Future<void> clearStallEvidence() async {
    if (isDisposed) return;
    _stallDetector.reset();
    _applyCurrentStatus();
    await refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final source = _activitySource;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (source != null) _stallDetector.onPaused(source(), _now());
      case AppLifecycleState.resumed:
        final snapshot = source?.call();
        final observation = snapshot == null ? null : _stallDetector.captureResumed(snapshot, _now());
        unawaited(_onResumed(observation));
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _onResumed(DownloadStallObservation? observation) async {
    try {
      if (observation != null) {
        final networkAvailable = await _networkAllowsStallScoring();
        if (isDisposed) return;
        final wasStalled = _stallDetector.isStalled;
        final confirmed = _stallDetector.evaluate(observation, networkAvailable: networkAvailable);
        if (wasStalled && !_stallDetector.isStalled) _applyCurrentStatus();
        if (confirmed) {
          appLogger.w(
            'Background downloads made no progress across ${_stallDetector.observationsToConfirm} '
            'backgrounded periods — treating as an OEM background restriction',
          );
        }
      }
      await refresh();
    } catch (e) {
      appLogger.d('Background work resume check failed: $e');
    }
  }

  Future<bool> _networkAllowsStallScoring() async {
    final probe = _networkProbeOverride;
    if (probe != null) return probe();
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none)) return false;
      return !await DownloadManagerService.shouldBlockDownloadOnCellularWith(connectivity);
    } catch (_) {
      // Unknown connectivity or policy is inconclusive, not proof of a stall.
      return false;
    }
  }

  @override
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }
}
