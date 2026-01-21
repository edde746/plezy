import 'package:flutter/material.dart';
import '../mpv/mpv.dart';
import '../services/pip_service.dart';

/// Manages video Picture-in-Picture mode
class VideoPIPManager {
  final Player player;

  VideoPIPManager({required this.player});

  Size? _playerSize;
  Size? get playerSize => _playerSize;

  /// Access PiP state from the service
  ValueNotifier<bool> get isPipActive => PipService().isPipActive;

  /// Toggle native PiP
  /// Returns a tuple of (success, error message) for error handling
  Future<(bool success, String? error)> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return (false, 'PiP not supported on this device');

    // Try to get actual video dimensions from MPV
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
      // Fall through to use viewport size
    }

    // Fall back to viewport size if video dimensions unavailable
    width ??= _playerSize?.width.toInt();
    height ??= _playerSize?.height.toInt();

    return await PipService.enter(width: width, height: height);
  }
}
