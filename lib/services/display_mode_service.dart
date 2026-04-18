import 'dart:io';

import 'package:flutter/services.dart';

import 'fullscreen_state_manager.dart';
import 'settings_service.dart';
import '../utils/app_logger.dart';

/// Orchestrates Windows display mode matching (refresh rate, HDR) during video playback.
/// Uses the same platform channel as the mpv player (com.plezy/mpv_player).
class DisplayModeService {
  static const _channel = MethodChannel('com.plezy/mpv_player');

  final SettingsService _settings;
  final FullscreenStateManager _fullscreen;

  bool _displayModeChanged = false;
  bool _hdrStateChanged = false;

  bool get hdrStateChanged => _hdrStateChanged;
  bool get anyChangeApplied => _displayModeChanged || _hdrStateChanged;

  DisplayModeService(this._settings, this._fullscreen);

  /// Apply display matching based on video properties. Returns the delay
  /// duration to wait before starting playback.
  Future<Duration> applyDisplayMatching({required double? fps, required double? sigPeak}) async {
    if (!Platform.isWindows) return Duration.zero;
    if (!_fullscreen.isFullscreen) {
      appLogger.d('Display matching skipped: not in fullscreen');
      return Duration.zero;
    }

    bool anyChange = false;

    // Refresh rate matching.
    if (_settings.getMatchRefreshRate() && fps != null && fps > 0) {
      try {
        final success = await _matchRefreshRate(fps);
        anyChange |= success;
      } catch (e) {
        appLogger.w('Failed to match refresh rate', error: e);
      }
    }

    // Dynamic range matching.
    if (_settings.getMatchDynamicRange() && sigPeak != null && sigPeak > 1.0) {
      try {
        final success = await _enableSystemHDR();
        anyChange |= success;
      } catch (e) {
        appLogger.w('Failed to enable system HDR', error: e);
      }
    }

    if (anyChange) {
      final delaySec = _settings.getDisplaySwitchDelay();
      return Duration(seconds: delaySec);
    }

    return Duration.zero;
  }

  /// Restore all display settings to their original state.
  Future<void> restoreAll() async {
    if (!Platform.isWindows) return;

    if (_hdrStateChanged) {
      try {
        await _channel.invokeMethod('restoreSystemHDR');
        _hdrStateChanged = false;
        appLogger.d('Restored system HDR state');
      } catch (e) {
        appLogger.w('Failed to restore system HDR', error: e);
      }
    }

    if (_displayModeChanged) {
      try {
        await _channel.invokeMethod('restoreDisplayMode');
        _displayModeChanged = false;
        appLogger.d('Restored display mode');
      } catch (e) {
        appLogger.w('Failed to restore display mode', error: e);
      }
    }
  }

  Future<bool> _matchRefreshRate(double fps) async {
    final currentMode = await _channel.invokeMapMethod<String, dynamic>('getCurrentDisplayMode');
    if (currentMode == null) return false;

    final currentWidth = currentMode['width'] as int;
    final currentHeight = currentMode['height'] as int;
    final currentRate = currentMode['refreshRate'] as int;

    // Find best matching rate from available modes.
    final modes = await _channel.invokeListMethod<Map>('getDisplayModes');
    if (modes == null || modes.isEmpty) return false;

    final bestRate = _findBestRefreshRate(fps, modes, currentWidth, currentHeight);
    if (bestRate == 0 || bestRate == currentRate) return false;

    final success = await _channel.invokeMethod<bool>('setDisplayMode', {
      'width': currentWidth,
      'height': currentHeight,
      'refreshRate': bestRate,
    });

    if (success == true) {
      _displayModeChanged = true;
      appLogger.d('Matched refresh rate: ${fps}fps -> ${bestRate}Hz');
      return true;
    }
    return false;
  }

  Future<bool> _enableSystemHDR() async {
    final supported = await _channel.invokeMethod<bool>('isHDRSupported');
    if (supported != true) return false;

    final alreadyEnabled = await _channel.invokeMethod<bool>('isHDREnabled');
    if (alreadyEnabled == true) return false;

    final success = await _channel.invokeMethod<bool>('setSystemHDR', {'enabled': true});

    if (success == true) {
      _hdrStateChanged = true;
      appLogger.d('Enabled system HDR for HDR content');
      return true;
    }
    return false;
  }

  /// Find the best matching refresh rate for a video fps.
  /// Mirrors the C++ FindBestRefreshRate algorithm.
  static int _findBestRefreshRate(double videoFps, List<Map> modes, int currentWidth, int currentHeight) {
    if (videoFps <= 0) return 0;

    // Collect unique refresh rates at current resolution.
    final rates = <int>{};
    for (final mode in modes) {
      final w = mode['width'] as int;
      final h = mode['height'] as int;
      if (w == currentWidth && h == currentHeight) {
        rates.add(mode['refreshRate'] as int);
      }
    }

    if (rates.isEmpty) return 0;

    int bestRate = 0;
    int bestMultiplier = 0;

    for (final rate in rates) {
      final ratio = rate / videoFps;
      final rounded = ratio.roundToDouble();

      if (rounded < 1.0) continue;

      final multiplier = rounded.toInt();
      final deviation = (ratio - rounded).abs() / rounded;

      // Within 0.5% tolerance.
      if (deviation > 0.005) continue;

      if (bestRate == 0 || multiplier < bestMultiplier || (multiplier == bestMultiplier && rate > bestRate)) {
        bestRate = rate;
        bestMultiplier = multiplier;
      }
    }

    return bestRate;
  }
}
