import '../utils/app_logger.dart';
import '../utils/codec_utils.dart';
import '../utils/track_label_builder.dart' show buildTrackLabel;

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

  /// Creates a [PlexMediaInfo] from cached metadata JSON (as stored by [PlexApiCache]).
  /// Parses audio/subtitle tracks from `Media[0].Part[0].Stream[]` so that
  /// offline playback can still apply language-based track selection.
  static PlexMediaInfo? fromMetadataJson(Map<String, dynamic> metadata) {
    final media = metadata['Media'] as List<dynamic>?;
    if (media == null || media.isEmpty) return null;
    final parts = media.first['Part'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    final streams = parts.first['Stream'] as List<dynamic>?;

    final audioTracks = <PlexAudioTrack>[];
    final subtitleTracks = <PlexSubtitleTrack>[];

    if (streams != null) {
      for (final s in streams) {
        try {
          final streamType = s['streamType'] as int?;
          if (streamType == 2) {
            audioTracks.add(PlexAudioTrack(
              id: s['id'] as int,
              index: s['index'] as int?,
              codec: s['codec'] as String?,
              language: s['language'] as String?,
              languageCode: s['languageCode'] as String?,
              title: s['title'] as String?,
              displayTitle: s['displayTitle'] as String?,
              channels: s['channels'] as int?,
              selected: s['selected'] == 1 || s['selected'] == true,
            ));
          } else if (streamType == 3) {
            subtitleTracks.add(PlexSubtitleTrack(
              id: s['id'] as int,
              index: s['index'] as int?,
              codec: s['codec'] as String?,
              language: s['language'] as String?,
              languageCode: s['languageCode'] as String?,
              title: s['title'] as String?,
              displayTitle: s['displayTitle'] as String?,
              selected: s['selected'] == 1 || s['selected'] == true,
              forced: s['forced'] == 1,
              key: s['key'] as String?,
            ));
          }
        } catch (e) {
          appLogger.d('Skipping malformed stream in cached metadata', error: e);
        }
      }
    }

    return PlexMediaInfo(
      videoUrl: '',
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
      chapters: const [],
    );
  }
}

/// Mixin for building track labels with a consistent pattern.
///
/// Used by [PlexAudioTrack] and [PlexSubtitleTrack] to provide a [buildLabel]
/// method that delegates to the shared [buildTrackLabel] function.
mixin _TrackLabelMixin {
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

class PlexAudioTrack with _TrackLabelMixin {
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

class PlexSubtitleTrack with _TrackLabelMixin {
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

  static String? _classifyChapterTitle(String title, RegExp introPattern, RegExp creditsPattern) {
    if (introPattern.hasMatch(title)) return 'intro';
    if (creditsPattern.hasMatch(title)) return 'credits';
    return null;
  }

  /// Returns [PlaybackExtras] using real markers when available, otherwise
  /// synthesises markers from chapter titles matching intro/credits patterns.
  /// When real markers exist, reclassifies markers with unknown types against
  /// the patterns so non-standard type strings (e.g. "OP-Song") get recognized.
  factory PlaybackExtras.withChapterFallback({
    required List<PlexChapter> chapters,
    required List<PlexMarker> markers,
    String? introPatternStr,
    String? creditsPatternStr,
  }) {
    final introPattern = RegExp(
      introPatternStr ?? r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$',
      caseSensitive: false,
    );
    final creditsPattern = RegExp(
      creditsPatternStr ?? r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$',
      caseSensitive: false,
    );

    if (markers.isNotEmpty) {
      // Reclassify markers with non-standard types against the patterns
      final reclassified = markers.map((m) {
        if (m.type == 'intro' || m.type == 'credits') return m;
        final newType = _classifyChapterTitle(m.type, introPattern, creditsPattern);
        if (newType != null) {
          return PlexMarker(id: m.id, type: newType, startTimeOffset: m.startTimeOffset, endTimeOffset: m.endTimeOffset);
        }
        return m;
      }).toList();
      return PlaybackExtras(chapters: chapters, markers: reclassified);
    }

    final synthetic = <PlexMarker>[];
    for (var i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final title = ch.title;
      if (title == null || title.isEmpty) continue;

      final type = _classifyChapterTitle(title, introPattern, creditsPattern);
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
