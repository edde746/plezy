import 'package:flutter/foundation.dart';
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
  Future<void> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return;

    await PipService.enter(width: _playerSize?.width.toInt(), height: _playerSize?.height.toInt());
  }
}
