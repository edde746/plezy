import '../utils/codec_utils.dart';

class PlexMediaInfo {
  final String videoUrl;
  final List<PlexAudioTrack> audioTracks;
  final List<PlexSubtitleTrack> subtitleTracks;
  final List<PlexChapter> chapters;
  final int? partId;

  PlexMediaInfo({
    required this.videoUrl,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.chapters,
    this.partId,
  });
  int? getPartId() => partId;
}

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

/// Mixin for building track labels with a consistent pattern
mixin TrackLabelBuilder {
  int get id;
  int? get index;
  String? get displayTitle;
  String? get language;

  /// Builds a label from the given parts
  /// If displayTitle is present, returns it
  /// Otherwise, combines language and additional parts
  String buildLabel(List<String> additionalParts) {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }
    return buildTrackLabel(language: language, extraParts: additionalParts, index: (index ?? id) - 1);
  }
}

class PlexAudioTrack with TrackLabelBuilder {
  @override
  final int id;
  @override
  final int? index;
  final String? codec;
  @override
  final String? language;
  final String? languageCode;
  final String? title;
  @override
  final String? displayTitle;
  final int? channels;
  final bool selected;

  PlexAudioTrack({
    required this.id,
    this.index,
    this.codec,
    this.language,
    this.languageCode,
    this.title,
    this.displayTitle,
    this.channels,
    required this.selected,
  });

  String get label {
    final additionalParts = <String>[];
    if (codec != null) additionalParts.add(CodecUtils.formatAudioCodec(codec!));
    if (channels != null) additionalParts.add('${channels!}ch');
    return buildLabel(additionalParts);
  }
}

class PlexSubtitleTrack with TrackLabelBuilder {
  @override
  final int id;
  @override
  final int? index;
  final String? codec;
  @override
  final String? language;
  final String? languageCode;
  final String? title;
  @override
  final String? displayTitle;
  final bool selected;
  final bool forced;
  final String? key;

  PlexSubtitleTrack({
    required this.id,
    this.index,
    this.codec,
    this.language,
    this.languageCode,
    this.title,
    this.displayTitle,
    required this.selected,
    required this.forced,
    this.key,
  });

  String get label {
    final additionalParts = <String>[];
    if (forced) additionalParts.add('Forced');
    return buildLabel(additionalParts);
  }

  /// Returns true if this subtitle track is an external file (sidecar subtitle)
  /// External subtitles have a key property that points to /library/streams/{id}
  bool get isExternal => key != null && key!.isNotEmpty;

  /// Constructs the full URL for fetching external subtitle files
  /// Returns null if this is not an external subtitle
  String? getSubtitleUrl(String baseUrl, String token) {
    if (!isExternal) return null;

    // Determine file extension based on codec
    final ext = CodecUtils.getSubtitleExtension(codec);

    // Construct URL with authentication token
    return '$baseUrl$key.$ext?X-Plex-Token=$token';
  }
}

class PlexChapter {
  final int id;
  final int? index;
  final int? startTimeOffset;
  final int? endTimeOffset;
  final String? title;
  final String? thumb;

  PlexChapter({required this.id, this.index, this.startTimeOffset, this.endTimeOffset, this.title, this.thumb});

  String get label => title ?? 'Chapter ${(index ?? 0) + 1}';

  Duration get startTime => Duration(milliseconds: startTimeOffset ?? 0);
  Duration? get endTime => endTimeOffset != null ? Duration(milliseconds: endTimeOffset!) : null;
}

class PlexMarker {
  final int id;
  final String type;
  final int startTimeOffset;
  final int endTimeOffset;

  PlexMarker({required this.id, required this.type, required this.startTimeOffset, required this.endTimeOffset});

  Duration get startTime => Duration(milliseconds: startTimeOffset);
  Duration get endTime => Duration(milliseconds: endTimeOffset);

  bool get isIntro => type == 'intro';
  bool get isCredits => type == 'credits';

  bool containsPosition(Duration position) {
    final posMs = position.inMilliseconds;
    return posMs >= startTimeOffset && posMs < endTimeOffset;
  }
}

/// Combined chapters and markers fetched in a single API call
class PlaybackExtras {
  final List<PlexChapter> chapters;
  final List<PlexMarker> markers;

  PlaybackExtras({required this.chapters, required this.markers});

  static final _introPattern = RegExp(
    r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$',
    caseSensitive: false,
  );
  static final _creditsPattern = RegExp(
    r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$',
    caseSensitive: false,
  );

  static String? _classifyChapterTitle(String title) {
    if (_introPattern.hasMatch(title)) return 'intro';
    if (_creditsPattern.hasMatch(title)) return 'credits';
    return null;
  }

  /// Returns [PlaybackExtras] using real markers when available, otherwise
  /// synthesises markers from chapter titles matching intro/credits patterns.
  factory PlaybackExtras.withChapterFallback({
    required List<PlexChapter> chapters,
    required List<PlexMarker> markers,
  }) {
    if (markers.isNotEmpty) {
      return PlaybackExtras(chapters: chapters, markers: markers);
    }

    final synthetic = <PlexMarker>[];
    for (var i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final title = ch.title;
      if (title == null || title.isEmpty) continue;

      final type = _classifyChapterTitle(title);
      if (type == null) continue;

      final start = ch.startTimeOffset;
      if (start == null) continue;

      final end = ch.endTimeOffset ??
          (i + 1 < chapters.length ? chapters[i + 1].startTimeOffset : null);
      if (end == null) continue;

      synthetic.add(PlexMarker(id: ch.id, type: type, startTimeOffset: start, endTimeOffset: end));
    }

    return PlaybackExtras(chapters: chapters, markers: synthetic);
  }
}
