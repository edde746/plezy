import '../mpv/mpv.dart';

/// Seeks by the given offset (can be positive or negative) while clamping
/// the result between 0 and the video duration
void seekWithClamping(MpvPlayer player, Duration offset) {
  final currentPosition = player.state.position;
  final duration = player.state.duration;
  final newPosition = currentPosition + offset;

  // Clamp between 0 and video duration
  final clampedPosition = newPosition.isNegative
      ? Duration.zero
      : (newPosition > duration ? duration : newPosition);

  player.seek(clampedPosition);
}
