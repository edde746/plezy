import 'codec_utils.dart';

/// Builds a track label from parts with the standard `' · '` joiner pattern.
///
/// Shared by both Plex track models and MPV track label utilities.
/// If [title] is non-empty it is added first, then [language], then [extraParts].
/// Falls back to `'$fallbackPrefix ${index + 1}'` when no parts are available.
String buildTrackLabel({
  String? title,
  String? language,
  List<String> extraParts = const [],
  required int index,
  String fallbackPrefix = 'Track',
}) {
  final parts = <String>[];
  if (title != null && title.isNotEmpty) parts.add(title);
  if (language != null && language.isNotEmpty) parts.add(language);
  parts.addAll(extraParts);
  return parts.isEmpty ? '$fallbackPrefix ${index + 1}' : parts.join(' · ');
}

/// Utility for building track labels for audio and subtitle tracks.
class TrackLabelBuilder {
  TrackLabelBuilder._();

  /// Build a label for an audio track.
  ///
  /// Combines title, language, codec, and channel count.
  static String buildAudioLabel({
    String? title,
    String? language,
    String? codec,
    int? channelsCount,
    required int index,
  }) {
    final extraParts = <String>[];
    if (codec != null && codec.isNotEmpty) {
      extraParts.add(CodecUtils.formatAudioCodec(codec));
    }
    if (channelsCount != null) {
      extraParts.add('${channelsCount}ch');
    }
    return buildTrackLabel(
      title: title,
      language: language?.toUpperCase(),
      extraParts: extraParts,
      index: index,
      fallbackPrefix: 'Audio Track',
    );
  }

  /// Build a label for a subtitle track.
  ///
  /// Combines title, language, and codec (with friendly codec names).
  static String buildSubtitleLabel({String? title, String? language, String? codec, required int index}) {
    final extraParts = <String>[];
    if (codec != null && codec.isNotEmpty) {
      extraParts.add(CodecUtils.formatSubtitleCodec(codec));
    }
    return buildTrackLabel(title: title, language: language?.toUpperCase(), extraParts: extraParts, index: index);
  }
}
