import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mpv/mpv.dart';
import '../utils/app_logger.dart';
import 'settings_service.dart';

typedef VideoVolumePersistenceWriter = Future<void> Function(double volume);

/// Owns every logical volume transition for one video [Player].
///
/// User intent is published immediately while native writes remain strictly
/// one-at-a-time. A burst keeps only its latest pending target, so deltas are
/// accumulated against the latest requested volume rather than delayed player
/// state.
final class VideoVolumeController implements ValueListenable<double> {
  VideoVolumeController({
    required this.player,
    required SettingsService settings,
    required double initialVolume,
    VideoVolumePersistenceWriter? persistVolume,
  }) : _settings = settings,
       _persistVolume = persistVolume ?? ((volume) => settings.write(SettingsService.volume, volume)),
       _desiredVolume = ValueNotifier<double>(_clampForSettings(settings, initialVolume)),
       _confirmedVolume = _clampForSettings(settings, initialVolume),
       _preferredVolume = _initialPreferredVolume(settings),
       _lastPersistedVolume = _initialPreferredVolume(settings) {
    _volumeSubscription = player.streams.volume.listen(
      _handlePlayerVolume,
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;
        appLogger.w('Video volume observation failed', error: error, stackTrace: stackTrace);
      },
    );
  }

  final Player player;
  final SettingsService _settings;
  final VideoVolumePersistenceWriter _persistVolume;
  final ValueNotifier<double> _desiredVolume;

  late final StreamSubscription<double> _volumeSubscription;
  _VolumeTransition? _pending;
  _VolumeTransition? _activeTransition;
  Completer<void>? _idleCompleter;
  double _confirmedVolume;
  double _preferredVolume;
  double _lastPersistedVolume;
  bool _draining = false;
  bool _disposed = false;

  static double _clampForSettings(SettingsService settings, double volume) {
    return volume.clamp(0.0, settings.read(SettingsService.maxVolume).toDouble()).toDouble();
  }

  static double _initialPreferredVolume(SettingsService settings) {
    final stored = settings.read(SettingsService.volume);
    return _clampForSettings(settings, stored.isFinite ? stored : SettingsService.volume.defaultValue);
  }

  @override
  double get value => _desiredVolume.value;

  @override
  void addListener(VoidCallback listener) => _desiredVolume.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _desiredVolume.removeListener(listener);

  /// Completes when the currently scheduled apply/persistence drain is idle.
  /// It never completes with an error; failures are contained and logged here.
  Future<void> get idle => _idleCompleter?.future ?? Future<void>.value();

  bool ownsPlayer(Player candidate) => identical(player, candidate);

  /// Applies and persists a relative change against the latest user intent.
  void adjust(double delta) {
    if (_disposed || !delta.isFinite) return;
    final target = _clamp(value + delta);
    _schedule(target, persistedVolume: target);
  }

  /// Applies an absolute slider preview without persisting intermediate values.
  void preview(double volume) {
    if (_disposed || !volume.isFinite) return;
    _schedule(_clamp(volume), persistedVolume: null);
  }

  /// Applies and persists an absolute volume selection.
  void commit(double volume) {
    if (_disposed || !volume.isFinite) return;
    final target = _clamp(volume);
    _schedule(target, persistedVolume: target);
  }

  /// Mutes without replacing the preferred volume with zero, or restores the
  /// latest logically preferred non-zero value when already muted.
  void toggleMute() {
    if (_disposed) return;
    if (value > 0) {
      _schedule(0, persistedVolume: value);
      return;
    }

    final preferred = _preferredVolume.isFinite && _preferredVolume > 0
        ? _preferredVolume
        : SettingsService.volume.defaultValue;
    final restored = _clamp(preferred);
    _schedule(restored, persistedVolume: restored);
  }

  double _clamp(double volume) => _clampForSettings(_settings, volume);

  void _schedule(double playerVolume, {required double? persistedVolume}) {
    if (_disposed) return;
    final persisted = persistedVolume == null ? null : _clamp(persistedVolume);
    if (persisted != null) _preferredVolume = persisted;

    _setDesiredVolume(playerVolume);
    final active = _activeTransition;
    if (_draining &&
        _pending == null &&
        active != null &&
        active.playerVolume == playerVolume &&
        active.persistedVolume == persisted) {
      return;
    }
    _pending = _VolumeTransition(playerVolume: playerVolume, persistedVolume: persisted);
    if (_draining) return;

    _draining = true;
    _idleCompleter = Completer<void>();
    unawaited(_drain());
  }

  Future<void> _drain() async {
    try {
      while (!_disposed) {
        final transition = _pending;
        if (transition == null) break;
        _pending = null;
        _activeTransition = transition;

        try {
          await player.setVolume(transition.playerVolume);
        } catch (error, stackTrace) {
          if (_disposed) return;
          appLogger.w('Video volume apply failed', error: error, stackTrace: stackTrace);
          if (_pending == null) {
            if (transition.persistedVolume != null) {
              _preferredVolume = _lastPersistedVolume;
            }
            _setDesiredVolume(_confirmedVolume);
          }
          continue;
        }

        if (_disposed) return;
        _confirmedVolume = transition.playerVolume;

        // A newer user intent supersedes both this apply's UI state and its
        // persistence. Drain only the latest record next.
        if (_pending != null || transition.persistedVolume == null) continue;

        try {
          await _persistVolume(transition.persistedVolume!);
          if (_disposed) return;
          _lastPersistedVolume = transition.persistedVolume!;
        } catch (error, stackTrace) {
          if (_disposed) return;
          appLogger.w('Video volume persistence failed', error: error, stackTrace: stackTrace);
        }
      }
    } catch (error, stackTrace) {
      // The expected player/persistence failures are handled above. Keep one
      // final containment boundary so fire-and-forget UI commands never leak.
      if (!_disposed) {
        appLogger.e('Video volume transition failed unexpectedly', error: error, stackTrace: stackTrace);
      }
    } finally {
      if (!_disposed) {
        _draining = false;
        final completer = _idleCompleter;
        _idleCompleter = null;
        if (completer != null && !completer.isCompleted) completer.complete();
      }
    }
  }

  void _handlePlayerVolume(double volume) {
    if (_disposed || _draining || !volume.isFinite) return;
    final observed = _clamp(volume);
    _confirmedVolume = observed;
    _setDesiredVolume(observed);
  }

  void _setDesiredVolume(double volume) {
    if (_disposed || _desiredVolume.value == volume) return;
    _desiredVolume.value = volume;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pending = null;
    unawaited(
      _volumeSubscription.cancel().catchError((Object error, StackTrace stackTrace) {
        appLogger.w('Video volume observation cleanup failed', error: error, stackTrace: stackTrace);
      }),
    );
    final completer = _idleCompleter;
    _idleCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
    _desiredVolume.dispose();
  }
}

final class _VolumeTransition {
  const _VolumeTransition({required this.playerVolume, required this.persistedVolume});

  final double playerVolume;
  final double? persistedVolume;
}
