/// Parses the capability tables printed by FFmpeg's encoder and muxer commands.
/// FFmpeg adds flags over time, so the parser accepts any uppercase capability
/// letter in the fixed-width flag column.
abstract final class FfmpegCapabilities {
  static final RegExp _encoderLine = RegExp(r'^\s*[A-Z.]{6}\s+(\S+)', multiLine: true);
  static final RegExp _muxerLine = RegExp(r'^\s*(?:D?E)\s+(\S+)', multiLine: true);

  static Set<String> parseEncoders(String listing) => {
    for (final match in _encoderLine.allMatches(listing)) match.group(1)!,
  };

  static Set<String> parseMuxers(String listing) => {
    for (final match in _muxerLine.allMatches(listing)) match.group(1)!,
  };
}
