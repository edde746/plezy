import 'codec_utils.dart';

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
    final parts = <String>[];
    if (title != null && title.isNotEmpty) {
      parts.add(title);
    }
    if (language != null && language.isNotEmpty) {
      parts.add(language.toUpperCase());
    }
    if (codec != null && codec.isNotEmpty) {
      parts.add(CodecUtils.formatAudioCodec(codec));
    }
    if (channelsCount != null) {
      parts.add('${channelsCount}ch');
    }
    return parts.isEmpty ? 'Audio Track ${index + 1}' : parts.join(' · ');
  }

  /// Build a label for a subtitle track.
  ///
  /// Combines title, language, and codec (with friendly codec names).
  static String buildSubtitleLabel({
    String? title,
    String? language,
    String? codec,
    required int index,
  }) {
    final parts = <String>[];
    if (title != null && title.isNotEmpty) {
      parts.add(title);
    }
    if (language != null && language.isNotEmpty) {
      parts.add(language.toUpperCase());
    }
    if (codec != null && codec.isNotEmpty) {
      parts.add(CodecUtils.formatSubtitleCodec(codec));
    }
    return parts.isEmpty ? 'Track ${index + 1}' : parts.join(' · ');
  }
}
