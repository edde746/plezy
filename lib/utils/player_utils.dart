import '../mpv/mpv.dart';

const restartBeforePreviousItemThreshold = Duration(seconds: 3);

bool shouldRestartBeforePreviousItem(Duration position) {
  return position > restartBeforePreviousItemThreshold;
}

Duration clampSeekPosition(Player player, Duration position) {
  final duration = player.state.duration;
  if (position.isNegative) return Duration.zero;
  if (duration > Duration.zero && position > duration) return duration;
  return position;
}
