import 'player_log_level.dart';

/// A log entry from the player.
class PlayerLog {
  /// The log level of this message.
  final PlayerLogLevel level;

  /// The prefix/category of the log message (e.g., 'cplayer', 'ffmpeg').
  final String prefix;

  /// The log message text.
  final String text;

  const PlayerLog({
    required this.level,
    required this.prefix,
    required this.text,
  });

  @override
  String toString() => '[$prefix] ${level.name}: $text';
}
