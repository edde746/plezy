import 'mpv_log_level.dart';

/// A log entry from the MPV player.
class MpvLog {
  /// The log level of this message.
  final MpvLogLevel level;

  /// The prefix/category of the log message (e.g., 'cplayer', 'ffmpeg').
  final String prefix;

  /// The log message text.
  final String text;

  const MpvLog({
    required this.level,
    required this.prefix,
    required this.text,
  });

  @override
  String toString() => '[$prefix] ${level.name}: $text';
}
