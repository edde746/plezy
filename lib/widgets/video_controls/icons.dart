import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Get the replay icon based on the duration
/// Returns numbered icons (replay_5, replay_10, replay_30) when available,
/// otherwise returns generic replay icon
IconData getReplayIcon(int seconds) {
  switch (seconds) {
    case 5:
      return Symbols.replay_5_rounded;
    case 10:
      return Symbols.replay_10_rounded;
    case 30:
      return Symbols.replay_30_rounded;
    default:
      return Symbols.replay_rounded; // Generic icon for custom durations
  }
}

/// Get the forward icon based on the duration
/// Returns numbered icons (forward_5, forward_10, forward_30) when available,
/// otherwise returns generic forward icon
IconData getForwardIcon(int seconds) {
  switch (seconds) {
    case 5:
      return Symbols.forward_5_rounded;
    case 10:
      return Symbols.forward_10_rounded;
    case 30:
      return Symbols.forward_30_rounded;
    default:
      return Symbols.forward_rounded; // Generic icon for custom durations
  }
}
