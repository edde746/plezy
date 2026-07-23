import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app_logger.dart';

enum AndroidStartupPhase {
  nativeOnCreate('native_on_create'),
  dartMain('dart_main'),
  runApp('runApp'),
  firstFrame('first_frame'),
  databaseOpenStarted('database_open_started'),
  databaseReady('database_ready'),
  credentialsLoaded('credentials_loaded'),
  bindingStarted('binding_started'),
  bindingSettled('binding_settled'),
  mainScreen('main_screen');

  const AndroidStartupPhase(this.id);

  final String id;
}

enum AndroidUiState {
  mainScreen('main_screen'),
  player('player');

  const AndroidUiState(this.id);

  final String id;
}

/// Best-effort bridge for the newest Android 11+ historical process exit.
abstract final class AndroidExitDiagnostics {
  static const _channel = MethodChannel('com.plezy/device');
  static const _allowedReasons = {'crash', 'native_crash', 'anr', 'low_memory', 'user_requested', 'other'};
  static const _allowedAbis = {'arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86', 'unknown'};
  static const _allowedCodecContexts = {
    'audio:aac',
    'audio:ac3',
    'audio:eac3',
    'audio:dts',
    'audio:truehd',
    'audio:flac',
    'audio:pcm',
    'audio:other',
    'video:dolby_vision',
    'video:hevc',
    'video:avc',
    'video:other',
  };
  static const _allowedUiStates = {'startup', 'authentication', 'main_screen', 'player', 'player_disposed'};
  static const _allowedStartupPhases = {
    'native_on_create',
    'dart_main',
    'runApp',
    'first_frame',
    'database_open_started',
    'database_ready',
    'credentials_loaded',
    'binding_started',
    'binding_settled',
    'main_screen',
  };
  static final _decoderNamePattern = RegExp(r'^[A-Za-z0-9_.:-]{1,96}$');
  static final _startupWatch = Stopwatch()..start();
  static final List<({String phase, int elapsedMs})> _pendingBreadcrumbs = [];
  static var _telemetryReady = false;
  static var _nativeOnCreateRecorded = false;
  static var _lastElapsedMs = 0;

  /// Flushes phase breadcrumbs recorded before Sentry's app runner started.
  static void markTelemetryReady() {
    if (_telemetryReady) return;
    _telemetryReady = true;
    final pending = List.of(_pendingBreadcrumbs);
    _pendingBreadcrumbs.clear();
    for (final mark in pending) {
      _sendBreadcrumb(mark.phase, mark.elapsedMs);
    }
  }

  /// Persists and records one fixed, privacy-safe startup phase.
  static void markStartupPhase(AndroidStartupPhase phase) {
    try {
      if (Platform.isAndroid && !_nativeOnCreateRecorded) {
        _nativeOnCreateRecorded = true;
        _recordPhase(AndroidStartupPhase.nativeOnCreate.id, 0);
      }
      final measuredMs = _startupWatch.elapsedMilliseconds;
      final elapsedMs = measuredMs < _lastElapsedMs ? _lastElapsedMs : measuredMs;
      _lastElapsedMs = elapsedMs;
      _recordPhase(phase.id, elapsedMs);
      if (Platform.isAndroid) {
        unawaited(_persistStartupPhase(phase.id));
      }
    } catch (_) {
      // Startup diagnostics must never affect the startup path.
    }
  }

  static void _recordPhase(String phase, int elapsedMs) {
    try {
      appLogger.i('Startup phase: phase=$phase elapsedMs=$elapsedMs');
    } catch (_) {
      // Local logging is best-effort.
    }
    if (_telemetryReady) {
      _sendBreadcrumb(phase, elapsedMs);
    } else {
      _pendingBreadcrumbs.add((phase: phase, elapsedMs: elapsedMs));
    }
  }

  static void _sendBreadcrumb(String phase, int elapsedMs) {
    try {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Startup phase $phase',
            category: 'startup.phase',
            data: {'phase': phase, 'elapsedMs': elapsedMs},
          ),
        ).catchError((_) {}),
      );
    } catch (_) {
      // Breadcrumb emission is best-effort.
    }
  }

  static Future<void> _persistStartupPhase(String phase) async {
    try {
      await _channel.invokeMethod<bool>('setStartupPhase', phase);
    } catch (_) {
      // Native phase persistence is best-effort.
    }
  }

  static Future<void> markUiState(AndroidUiState state) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('setRuntimeUiState', state.id);
    } catch (_) {
      // Runtime diagnostics are best-effort and must never affect navigation.
    }
  }

  /// Records a native-sanitized previous-exit report in local logs and Sentry.
  ///
  /// Native persistence makes this one-shot across launches. Every failure is
  /// intentionally contained because historical diagnostics must not affect
  /// startup.
  static Future<void> logPreviousExit() async {
    if (!Platform.isAndroid) return;
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('getPreviousExit');
      final report = _validate(raw);
      if (report == null) return;

      appLogger.w(
        'Previous Android application exit: '
        'reason=${report['reason']} status=${report['status']} '
        'importance=${report['importance']} timestamp=${report['timestamp']} '
        'deviceModel=${report['deviceModel']} apiLevel=${report['apiLevel']} '
        'abi=${report['abi']} lowRam=${report['lowRam']} '
        'startupPhase=${report['startupPhase'] ?? 'omitted'} '
        'codecContext=${report['codecContext'] ?? 'omitted'} '
        'channels=${report['channelCount'] ?? 'omitted'} sampleRate=${report['sampleRate'] ?? 'omitted'} '
        'decoder=${report['selectedDecoder'] ?? 'omitted'} '
        'passthrough=${report['passthroughEnabled'] ?? 'omitted'} '
        'downmix=${report['downmixEnabled'] ?? 'omitted'} '
        'normalization=${report['normalizationEnabled'] ?? 'omitted'} '
        'uiState=${report['uiState'] ?? 'omitted'}',
      );
      await Sentry.captureMessage(
        'Previous Android application exit',
        level: SentryLevel.warning,
        withScope: (scope) => scope.setContexts('android_previous_exit', report),
      );
    } catch (_) {
      // Historical diagnostics are best-effort and must never escape startup.
    }
  }

  static Map<String, Object?>? _validate(Map<String, Object?>? raw) {
    if (raw == null) return null;
    final reason = raw['reason'];
    final status = raw['status'];
    final importance = raw['importance'];
    final timestamp = raw['timestamp'];
    final deviceModel = raw['deviceModel'];
    final apiLevel = raw['apiLevel'];
    final abi = raw['abi'];
    final lowRam = raw['lowRam'];
    final startupPhase = raw['startupPhase'];
    final codecContext = raw['codecContext'];
    final channelCount = raw['channelCount'];
    final sampleRate = raw['sampleRate'];
    final selectedDecoder = raw['selectedDecoder'];
    final passthroughEnabled = raw['passthroughEnabled'];
    final downmixEnabled = raw['downmixEnabled'];
    final normalizationEnabled = raw['normalizationEnabled'];
    final uiState = raw['uiState'];
    if (reason is! String || !_allowedReasons.contains(reason)) return null;
    if (status is! int || importance is! int || timestamp is! int) return null;
    if (deviceModel is! String ||
        deviceModel.isEmpty ||
        deviceModel.length > 80 ||
        deviceModel.runes.any(_isControlCharacter)) {
      return null;
    }
    if (apiLevel is! int || apiLevel < 1 || abi is! String || !_allowedAbis.contains(abi) || lowRam is! bool) {
      return null;
    }
    if (startupPhase != null && (startupPhase is! String || !_allowedStartupPhases.contains(startupPhase))) {
      return null;
    }
    if (codecContext != null && (codecContext is! String || !_allowedCodecContexts.contains(codecContext))) return null;
    if (channelCount != null && (channelCount is! int || channelCount < 1 || channelCount > 32)) return null;
    if (sampleRate != null && (sampleRate is! int || sampleRate < 1 || sampleRate > 768000)) return null;
    if (selectedDecoder != null && (selectedDecoder is! String || !_decoderNamePattern.hasMatch(selectedDecoder))) {
      return null;
    }
    if (passthroughEnabled != null && passthroughEnabled is! bool) return null;
    if (downmixEnabled != null && downmixEnabled is! bool) return null;
    if (normalizationEnabled != null && normalizationEnabled is! bool) return null;
    if (uiState != null && (uiState is! String || !_allowedUiStates.contains(uiState))) return null;
    return <String, Object?>{
      'reason': reason,
      'status': status,
      'importance': importance,
      'timestamp': timestamp,
      'deviceModel': deviceModel,
      'apiLevel': apiLevel,
      'abi': abi,
      'lowRam': lowRam,
      if (startupPhase case final String safeStartupPhase) 'startupPhase': safeStartupPhase,
      if (codecContext case final String safeCodecContext) 'codecContext': safeCodecContext,
      if (channelCount case final int safeChannelCount) 'channelCount': safeChannelCount,
      if (sampleRate case final int safeSampleRate) 'sampleRate': safeSampleRate,
      if (selectedDecoder case final String safeSelectedDecoder) 'selectedDecoder': safeSelectedDecoder,
      if (passthroughEnabled case final bool safePassthroughEnabled) 'passthroughEnabled': safePassthroughEnabled,
      if (downmixEnabled case final bool safeDownmixEnabled) 'downmixEnabled': safeDownmixEnabled,
      if (normalizationEnabled case final bool safeNormalizationEnabled)
        'normalizationEnabled': safeNormalizationEnabled,
      if (uiState case final String safeUiState) 'uiState': safeUiState,
    };
  }

  static bool _isControlCharacter(int rune) => rune < 0x20 || rune == 0x7f;
}
