import 'codec_utils.dart';
import '../models/plex_media_info.dart' show buildTrackLabel;

/// Utility for building track labels for audio and subtitle tracks.
///
/// Delegates to the shared [buildTrackLabel] function so Plex-model and
/// MPV-player label logic stays consistent.
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
