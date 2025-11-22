import 'package:flutter/material.dart';

/// Get the replay icon based on the duration
/// Returns numbered icons (replay_5, replay_10, replay_30) when available,
/// otherwise returns generic replay icon
IconData getReplayIcon(int seconds) {
  switch (seconds) {
    case 5:
      return Icons.replay_5;
    case 10:
      return Icons.replay_10;
    case 30:
      return Icons.replay_30;
    default:
      return Icons.replay; // Generic icon for custom durations
  }
}

/// Get the forward icon based on the duration
/// Returns numbered icons (forward_5, forward_10, forward_30) when available,
/// otherwise returns generic forward icon
IconData getForwardIcon(int seconds) {
  switch (seconds) {
    case 5:
      return Icons.forward_5;
    case 10:
      return Icons.forward_10;
    case 30:
      return Icons.forward_30;
    default:
      return Icons.forward; // Generic icon for custom durations
  }
}
