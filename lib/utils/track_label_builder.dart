import 'codec_utils.dart';
import 'language_codes.dart';

/// Two-part track label: [primary] carries the human-readable name (language
/// first when known), [secondary] the de-emphasized technical detail.
///
/// Sheet rows render the parts on two lines; single-line contexts (track
/// cycling toasts) use [joined].
class TrackLabel {
  final String primary;

  /// Technical detail line. Null when there is none — never an empty string.
  final String? secondary;

  const TrackLabel(this.primary, [this.secondary]);

  String get joined => secondary == null ? primary : '$primary · $secondary';

  @override
  bool operator ==(Object other) => other is TrackLabel && other.primary == primary && other.secondary == secondary;

  @override
  int get hashCode => Object.hash(primary, secondary);

  @override
  String toString() => 'TrackLabel($primary, $secondary)';
}

/// Resolves the display name for a track's language.
///
/// A mappable ISO code wins ([languageCode] is the reliable field on server
/// streams, [language] carries the container code on mpv tracks). When neither
/// maps, a server-provided display name ("Filipino") beats an unmappable code,
/// and bare codes keep the legacy uppercase rendering ("und" → "UND").
String? resolveTrackLanguageDisplay({String? language, String? languageCode}) {
  final code = cleanTrackMetadataValue(languageCode);
  final lang = cleanTrackMetadataValue(language);

  final display = _displayNameIfMapped(code) ?? _displayNameIfMapped(lang);
  if (display != null) return display;

  final fallback = lang ?? code;
  if (fallback == null) return null;
  return _looksLikeLanguageCode(fallback) ? fallback.toUpperCase() : fallback;
}

String? _displayNameIfMapped(String? value) {
  if (value == null) return null;
  final base = value.split(RegExp('[-_]')).first;
  if (LanguageCodes.getLanguageName(base) == null) return null;
  return LanguageCodes.getDisplayName(value.replaceAll('_', '-'));
}

final _languageCodePattern = RegExp(r'^[A-Za-z]{2,3}([-_][A-Za-z0-9]{2,8})?$');

bool _looksLikeLanguageCode(String value) => _languageCodePattern.hasMatch(value);

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

class TrackLabelBuilder {
  TrackLabelBuilder._();

  static TrackLabel audioLabel({
    String? title,
    String? language,
    String? languageCode,
    String? codec,
    int? channels,
    String? displayTitle,
    required int index,
  }) {
    final tech = <String>[];
    if (codec != null && codec.isNotEmpty) tech.add(CodecUtils.formatAudioCodec(codec));
    final channelsLabel = CodecUtils.formatAudioChannels(channels);
    if (channelsLabel != null) tech.add(channelsLabel);

    return _compose(
      languageDisplay: resolveTrackLanguageDisplay(language: language, languageCode: languageCode),
      title: cleanTrackMetadataValue(title),
      displayTitle: cleanTrackMetadataValue(displayTitle),
      rawLanguageValues: [language, languageCode],
      techParts: tech,
      fallbackPrefix: 'Audio Track',
      index: index,
    );
  }

  static TrackLabel subtitleLabel({
    String? title,
    String? language,
    String? languageCode,
    String? codec,
    bool forced = false,
    String? displayTitle,
    required int index,
  }) {
    final cleanedTitle = cleanSubtitleTitle(title, codec: codec);
    return _compose(
      languageDisplay: resolveTrackLanguageDisplay(language: language, languageCode: languageCode),
      title: cleanedTitle,
      displayTitle: cleanSubtitleTitle(displayTitle, codec: codec),
      rawLanguageValues: [language, languageCode],
      techParts: [if (codec != null && codec.isNotEmpty) CodecUtils.formatSubtitleCodec(codec)],
      fallbackPrefix: 'Track',
      index: index,
      forced: forced || _saysForced(cleanedTitle),
    );
  }

  /// Primary ladder: language → title → displayTitle → `'<prefix> N'`. The
  /// title joins the secondary line only when the language took the primary
  /// slot and the title says more than the language/forced flag already do.
  static TrackLabel _compose({
    required String? languageDisplay,
    required String? title,
    required String? displayTitle,
    required List<String?> rawLanguageValues,
    required List<String> techParts,
    required String fallbackPrefix,
    required int index,
    bool forced = false,
  }) {
    String primary;
    String? secondaryTitle;
    if (languageDisplay != null) {
      primary = languageDisplay;
      if (title != null &&
          _metadataToken(title) != 'FORCED' &&
          !_restatesLanguage(title, languageDisplay, rawLanguageValues)) {
        secondaryTitle = title;
      }
    } else if (title != null) {
      primary = title;
    } else if (displayTitle != null) {
      primary = displayTitle;
    } else {
      primary = '$fallbackPrefix ${index + 1}';
    }

    if (forced && !_saysForced(primary)) {
      primary = '$primary (Forced)';
    }

    final secondaryParts = [?secondaryTitle, ...techParts];
    return TrackLabel(primary, secondaryParts.isEmpty ? null : secondaryParts.join(' · '));
  }

  static bool _saysForced(String? value) => _metadataToken(value ?? '').split('_').contains('FORCED');

  static bool _restatesLanguage(String title, String languageDisplay, List<String?> rawLanguageValues) {
    final normalized = title.trim().toLowerCase();
    if (normalized == languageDisplay.trim().toLowerCase()) return true;
    for (final raw in rawLanguageValues) {
      final cleaned = cleanTrackMetadataValue(raw);
      if (cleaned != null && normalized == cleaned.toLowerCase()) return true;
    }
    return false;
  }
}
