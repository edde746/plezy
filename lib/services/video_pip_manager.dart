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

  /// Toggle native PiP
  /// Returns a tuple of (success, error message) for error handling
  Future<(bool success, String? error)> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return (false, 'PiP not supported on this device');

    // Reset video filter to contain mode BEFORE entering PiP
    // This prevents the zoomed/cropped view from being shown in PiP
    onBeforeEnterPip?.call();

    // Wait a frame for the filter change to take effect
    await Future.delayed(const Duration(milliseconds: 50));

    // Get display dimensions for correct aspect ratio (accounts for pixel aspect ratio)
    int? width;
    int? height;

    try {
      final dwidth = await player.getProperty('dwidth');
      final dheight = await player.getProperty('dheight');
      if (dwidth != null && dheight != null) {
        width = int.tryParse(dwidth);
        height = int.tryParse(dheight);
      }
    } catch (_) {
      // Fall through to storage dimensions
    }

    // Fallback to storage dimensions (less accurate for anamorphic content)
    if (width == null || height == null) {
      try {
        final videoWidth = await player.getProperty('width');
        final videoHeight = await player.getProperty('height');
        if (videoWidth != null && videoHeight != null) {
          width = int.tryParse(videoWidth);
          height = int.tryParse(videoHeight);
        }
      } catch (_) {
        // Fall through to viewport size
      }
    }

    // Fall back to viewport size if video dimensions unavailable
    width ??= _playerSize?.width.toInt();
    height ??= _playerSize?.height.toInt();

    return await PipService.enter(width: width, height: height);
  }
}
