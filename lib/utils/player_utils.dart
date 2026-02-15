import '../mpv/mpv.dart';

/// Seeks by the given offset (can be positive or negative) while clamping
/// the result between 0 and the video duration.
/// Returns the clamped position that was seeked to.
Duration seekWithClamping(Player player, Duration offset) {
  final currentPosition = player.state.position;
  final duration = player.state.duration;
  final newPosition = currentPosition + offset;

  // Clamp between 0 and video duration
  Duration clampedPosition;
  if (newPosition.isNegative) {
    clampedPosition = Duration.zero;
  } else if (newPosition > duration) {
    clampedPosition = duration;
  } else {
    clampedPosition = newPosition;
  }

  player.seek(clampedPosition);
  return clampedPosition;
}
