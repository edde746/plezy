import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../mpv/mpv.dart';
import '../services/pip_service.dart';

/// Manages video Picture-in-Picture mode
class VideoPIPManager {
  final Player player;
  StreamSubscription? _playingSubscription;

  VideoPIPManager({required this.player}) {
    // Set up PiP control callbacks
    _setupPipCallbacks();
    _listenToPlayerState();
  }

  Size? _playerSize;
  Size? get playerSize => _playerSize;

  void _setupPipCallbacks() {
    final pipService = PipService();

    pipService.onPlayPause = () {
      player.playOrPause();
    };

    pipService.onSeek = (offset) {
      final currentPosition = player.state.position;
      final newPosition = currentPosition + Duration(seconds: offset);
      player.seek(newPosition);
    };
  }

  void _listenToPlayerState() {
    _playingSubscription = player.streams.playing.listen((isPlaying) {
      // Update play/pause icon when playing state changes
      PipService.updatePlayPauseIcon(isPlaying: isPlaying);
    });
  }

  void dispose() {
    _playingSubscription?.cancel();
  }

  /// Access PiP state from the service
  ValueNotifier<bool> get isPipActive => PipService().isPipActive;

  /// Toggle native PiP
  Future<void> togglePIP() async {
    final supported = await PipService.isSupported();
    if (!supported) return;

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

    // Pass current playing state so PiP overlay shows correct icon
    final isPlaying = player.state.playing;

    await PipService.enter(width: width, height: height, isPlaying: isPlaying);
  }
}
