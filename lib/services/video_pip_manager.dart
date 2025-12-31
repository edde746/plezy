import 'package:flutter/material.dart';
import '../mpv/mpv.dart';
import '../services/pip_service.dart';

/// Manages video Picture-in-Picture mode

class VideoPIPManager {
  final Player player;

  bool isPIPactive = false;

  VideoPIPManager({required this.player});
  
  Size? _playerSize;
  Size? get playerSize => _playerSize;

  /// Toggle native PiP
  Future<void> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return;
    
    await PipService.enter(
      width: _playerSize?.width.toInt(),
      height: _playerSize?.height.toInt(),
    );
    
  }
}