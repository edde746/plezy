import 'package:flutter/material.dart';
import '../mpv/mpv.dart';
import '../services/pip_service.dart';

/// Manages video Picture-in-Picture mode
class VideoPIPManager {
  final Player player;

  VideoPIPManager({required this.player});

  Size? _playerSize;
  Size? get playerSize => _playerSize;

  /// Callback to prepare video filter before entering PiP
  VoidCallback? onBeforeEnterPip;

  /// Update player size for PiP aspect ratio calculation
  void updatePlayerSize(Size size) {
    _playerSize = size;
  }

  /// Access PiP state from the service
  ValueNotifier<bool> get isPipActive => PipService().isPipActive;

  /// Get current video dimensions (display or storage or fallback to viewport)
  Future<(int? width, int? height)> _getVideoDimensions() async {
    int? width;
    int? height;

    try {
      final dwidth = await player.getProperty('dwidth');
      final dheight = await player.getProperty('dheight');
      if (dwidth != null && dheight != null) {
        width = int.tryParse(dwidth);
        height = int.tryParse(dheight);
      }
    } catch (_) {}

    if (width == null || height == null) {
      try {
        final videoWidth = await player.getProperty('width');
        final videoHeight = await player.getProperty('height');
        if (videoWidth != null && videoHeight != null) {
          width = int.tryParse(videoWidth);
          height = int.tryParse(videoHeight);
        }
      } catch (_) {}
    }

    width ??= _playerSize?.width.toInt();
    height ??= _playerSize?.height.toInt();

    return (width, height);
  }

  /// Toggle native PiP
  /// Returns a tuple of (success, error message) for error handling
  Future<(bool success, String? error)> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return (false, 'PiP not supported on this device');

    // Reset video filter to contain mode BEFORE entering PiP
    onBeforeEnterPip?.call();

    // Wait a frame for the filter change to take effect
    await Future.delayed(const Duration(milliseconds: 50));

    final dims = await _getVideoDimensions();
    return await PipService.enter(width: dims.$1, height: dims.$2);
  }

  /// Update auto-PiP readiness on the native side
  Future<void> updateAutoPipState({required bool isPlaying}) async {
    if (!isPlaying) {
      await PipService.setAutoPipReady(ready: false);
      return;
    }

    final dims = await _getVideoDimensions();
    await PipService.setAutoPipReady(ready: true, width: dims.$1, height: dims.$2);
  }

  /// Disable auto-PiP (called on dispose or when leaving player)
  Future<void> disableAutoPip() async {
    await PipService.setAutoPipReady(ready: false);
  }
}
