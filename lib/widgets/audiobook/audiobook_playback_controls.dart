import 'package:flutter/material.dart';

/// Playback controls for audiobook player (play/pause, skip, seek)
class AudiobookPlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final bool hasPreviousTrack;
  final bool hasNextTrack;
  final VoidCallback onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(Duration offset) onSeekRelative;

  const AudiobookPlaybackControls({
    super.key,
    required this.isPlaying,
    required this.hasPreviousTrack,
    required this.hasNextTrack,
    required this.onPlayPause,
    this.onPrevious,
    this.onNext,
    required this.onSeekRelative,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous track
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 48,
            color: hasPreviousTrack ? Colors.white : Colors.white30,
            onPressed: hasPreviousTrack ? onPrevious : null,
          ),
          const SizedBox(width: 16),

          // Rewind 30s
          IconButton(
            icon: const Icon(Icons.replay_30),
            iconSize: 48,
            color: Colors.white,
            onPressed: () => onSeekRelative(const Duration(seconds: -30)),
          ),
          const SizedBox(width: 24),

          // Play/Pause
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 56,
              color: Colors.black,
              onPressed: onPlayPause,
            ),
          ),
          const SizedBox(width: 24),

          // Forward 30s
          IconButton(
            icon: const Icon(Icons.forward_30),
            iconSize: 48,
            color: Colors.white,
            onPressed: () => onSeekRelative(const Duration(seconds: 30)),
          ),
          const SizedBox(width: 16),

          // Next track
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 48,
            color: hasNextTrack ? Colors.white : Colors.white30,
            onPressed: hasNextTrack ? onNext : null,
          ),
        ],
      ),
    );
  }
}
