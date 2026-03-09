import '../mpv/mpv.dart';

Duration clampSeekPosition(Player player, Duration position) {
  final duration = player.state.duration;
  if (position.isNegative) return Duration.zero;
  if (duration > Duration.zero && position > duration) return duration;
  return position;
}
