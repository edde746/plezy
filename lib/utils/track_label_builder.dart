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

String? cleanTrackMetadataValue(String? value) {
  if (value == null) return null;
  var cleaned = value.trim();
  if (cleaned.isEmpty) return null;

  final prefixed = RegExp(r'^(?:title|lang|language)\s*=\s*(.*)$', caseSensitive: false).firstMatch(cleaned);
  if (prefixed != null) {
    cleaned = prefixed.group(1)?.trim() ?? '';
  }

  if ((cleaned.startsWith('"') && cleaned.endsWith('"')) || (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
    cleaned = cleaned.substring(1, cleaned.length - 1).trim();
  }

  return cleaned.isEmpty ? null : cleaned;
}

String? cleanSubtitleTitle(String? title, {String? codec}) {
  var cleaned = cleanTrackMetadataValue(title);
  if (cleaned == null) return null;

  final codecAliases = _subtitleCodecAliases(codec);
  if (codecAliases.isEmpty) return cleaned;

  final parts = cleaned.split(RegExp(r'\s+-\s+'));
  while (parts.isNotEmpty && codecAliases.contains(_metadataToken(parts.last))) {
    parts.removeLast();
  }
  cleaned = parts.join(' - ').trim();

  return cleaned.isEmpty ? null : cleaned;
}

Set<String> _subtitleCodecAliases(String? codec) {
  final aliases = <String>{
    'SUBRIP',
    'SRT',
    'WEBVTT',
    'VTT',
    'ASS',
    'SSA',
    'PGS',
    'PGSSUB',
    'HDMV_PGS_SUBTITLE',
    'DVD',
    'DVDSUB',
    'DVD_SUBTITLE',
    'DVB_SUB',
    'DVB_SUBTITLE',
  };
  if (codec != null && codec.isNotEmpty) {
    aliases.add(_metadataToken(codec));
    aliases.add(_metadataToken(CodecUtils.formatSubtitleCodec(codec)));
    aliases.add(_metadataToken(CodecUtils.getSubtitleExtension(codec)));
  }
  return aliases;
}

String _metadataToken(String value) => value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');

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
  static String buildSubtitleLabel({
    String? title,
    String? language,
    String? codec,
    bool forced = false,
    required int index,
  }) {
    final cleanedTitle = cleanSubtitleTitle(title, codec: codec);
    final cleanedLanguage = cleanTrackMetadataValue(language)?.toUpperCase();
    final extraParts = <String>[];
    if (forced && !_metadataToken(cleanedTitle ?? '').split('_').contains('FORCED')) extraParts.add('Forced');
    if (codec != null && codec.isNotEmpty) {
      extraParts.add(CodecUtils.formatSubtitleCodec(codec));
    }
    return buildTrackLabel(title: cleanedTitle, language: cleanedLanguage, extraParts: extraParts, index: index);
  }
}
