import 'dart:io';

import '../models/motion_processing_mode.dart';
import '../mpv/player/player.dart';
import '../utils/app_logger.dart';

/// Applies display-synced MPV temporal interpolation without changing the
/// selected decoder or video output. Windows is the only shipped path with a
/// confirmed blocking-vsync MPV GPU output; the Linux embedded libmpv plane
/// does not provide a vsync interval to MPV's display-sync scheduler.
abstract final class MotionProcessingService {
  static final Expando<_OriginalMotionProperties> _originals = Expando('motion-processing-originals');
  static final Expando<bool> _interpolationBufferReady = Expando('motion-processing-buffer-ready');

  /// Windows uses MPV's embedded gpu-next output with display synchronization.
  static bool get isMpvPlatformSupported => Platform.isWindows;

  static bool supportsPlayer(Player player) => isMpvPlatformSupported && player.playerType == 'mpv';

  /// Whether this player's decoder and renderer were initialized with
  /// interpolation enabled, making live preset changes safe.
  static bool canChangeLive(Player player) => supportsPlayer(player) && _interpolationBufferReady[player] == true;

  /// Configure interpolation before the first file opens so MPV can size its
  /// renderer references and any hardware-decoder surface pool.
  static Future<void> configureForPlayback(Player player, MotionProcessingMode mode) async {
    if (!supportsPlayer(player)) return;
    _interpolationBufferReady[player] = false;

    if (!mode.usesMpvInterpolation) {
      final original = _originals[player];
      if (original != null) await _restoreOriginalProperties(player, original);
      return;
    }

    try {
      await apply(player, mode);
      _interpolationBufferReady[player] = mode.usesMpvInterpolation;
    } catch (_) {
      _interpolationBufferReady[player] = false;
      rethrow;
    }
  }

  /// Applies [mode] to the current MPV player. When switching back to Off,
  /// restore the user's original MPV timing properties rather than assuming
  /// MPV's defaults.
  static Future<void> apply(Player player, MotionProcessingMode mode) async {
    if (!supportsPlayer(player)) throw UnsupportedError('MPV motion interpolation is unavailable on this player.');

    var original = _originals[player];
    if (original == null) {
      original = _OriginalMotionProperties(
        videoSync: await player.getProperty('video-sync'),
        interpolation: await player.getProperty('interpolation'),
        tscale: await player.getProperty('tscale'),
        tscaleBlur: await player.getProperty('tscale-blur'),
        tscaleClamp: await player.getProperty('tscale-clamp'),
      );
      _originals[player] = original;
    }

    try {
      if (mode.usesMpvInterpolation) {
        // `interpolation` is ignored unless the VO synchronizes to the
        // display. Keep these writes before the first file during startup so
        // MPV can size its frame references for the selected temporal filter.
        await player.setProperty('video-sync', 'display-resample');
        await player.setProperty('tscale', 'mitchell');
        await player.setProperty('tscale-blur', '1.0');
        await player.setProperty('tscale-clamp', '1.0');
        await player.setProperty('interpolation', 'yes');
        return;
      }

      await _restoreOriginalProperties(player, original);
      _interpolationBufferReady[player] = false;
    } catch (error, stackTrace) {
      _interpolationBufferReady[player] = false;
      appLogger.w('MotionProcessingService: Failed to apply MPV interpolation', error: error, stackTrace: stackTrace);
      try {
        await _restoreOriginalProperties(player, original);
      } catch (restoreError, restoreStackTrace) {
        appLogger.w(
          'MotionProcessingService: Failed to restore MPV timing after an interpolation error',
          error: restoreError,
          stackTrace: restoreStackTrace,
        );
      }
      rethrow;
    }
  }

  static Future<void> _restoreOriginalProperties(Player player, _OriginalMotionProperties original) async {
    await player.setProperty('interpolation', original.interpolation ?? 'no');
    if (original.tscale != null) await player.setProperty('tscale', original.tscale!);
    if (original.tscaleBlur != null) await player.setProperty('tscale-blur', original.tscaleBlur!);
    if (original.tscaleClamp != null) await player.setProperty('tscale-clamp', original.tscaleClamp!);
    await player.setProperty('video-sync', original.videoSync ?? 'audio');
  }
}

final class _OriginalMotionProperties {
  final String? videoSync;
  final String? interpolation;
  final String? tscale;
  final String? tscaleBlur;
  final String? tscaleClamp;

  const _OriginalMotionProperties({
    required this.videoSync,
    required this.interpolation,
    required this.tscale,
    required this.tscaleBlur,
    required this.tscaleClamp,
  });
}
