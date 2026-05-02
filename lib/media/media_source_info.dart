import '../utils/codec_utils.dart';
import '../utils/track_label_builder.dart' show buildTrackLabel;

class MediaSourceInfo {
  final String videoUrl;
  final List<MediaAudioTrack> audioTracks;
  final List<MediaSubtitleTrack> subtitleTracks;
  final List<MediaChapter> chapters;
  final int? partId;
  final double? frameRate;

  /// Jellyfin source id for the *selected* version (null on Plex). Lets the
  /// trickplay loader request the right tile sheet when an item has multiple
  /// `MediaSources`.
  final String? mediaSourceId;

  /// Jellyfin default stream indexes for this source. A subtitle index of -1
  /// is an explicit server/user decision to start with subtitles off.
  final int? defaultAudioStreamIndex;
  final int? defaultSubtitleStreamIndex;

  /// Jellyfin trickplay manifest for the selected source, keyed by tile
  /// width. Null when the server didn't run trickplay extraction. Plex stays
  /// null here and uses [partId] + the BIF service instead.
  final Map<int, TrickplayInfo>? trickplayByWidth;

  MediaSourceInfo({
    required this.videoUrl,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.chapters,
    this.partId,
    this.frameRate,
    this.mediaSourceId,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
    this.trickplayByWidth,
  });
  int? getPartId() => partId;
}

/// Per-resolution Jellyfin trickplay manifest. Mirrors `TrickplayInfoDto`
/// from the Jellyfin OpenAPI spec.
class TrickplayInfo {
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final int thumbnailCount;
  final int interval;
  final int bandwidth;

  const TrickplayInfo({
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.thumbnailCount,
    required this.interval,
    required this.bandwidth,
  });
}

/// Mixin for building track labels with a consistent pattern.
///
/// Used by [MediaAudioTrack] and [MediaSubtitleTrack] to provide a [buildLabel]
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

class MediaAudioTrack with _TrackLabelMixin {
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

  MediaAudioTrack({
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

class MediaSubtitleTrack with _TrackLabelMixin {
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
  final bool external;

  MediaSubtitleTrack({
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
    this.external = false,
  });

  String get label {
    final additionalParts = <String>[];
    if (forced) additionalParts.add('Forced');
    return buildLabel(additionalParts);
  }

  /// Returns true if this subtitle track is an external file (sidecar subtitle).
  /// Some backends provide a direct key/URL, others require constructing one
  /// from stream metadata.
  bool get isExternal => external || (key != null && key!.isNotEmpty);
}

class MediaChapter {
  final int id;
  final int? index;
  final int? startTimeOffset;
  final int? endTimeOffset;
  final String? title;
  final String? thumb;

  MediaChapter({required this.id, this.index, this.startTimeOffset, this.endTimeOffset, this.title, this.thumb});

  /// Backfill missing `endTimeOffset` on each chapter from the next chapter's
  /// `startTimeOffset`. Jellyfin sends only starts; the seek-bar tick UI needs
  /// duration ranges. Mutates [chapters] in place and returns it.
  static List<MediaChapter> backfillEndOffsets(List<MediaChapter> chapters, {int? runtimeMs}) {
    for (var i = 0; i < chapters.length - 1; i++) {
      final c = chapters[i];
      if (c.endTimeOffset != null) continue;
      chapters[i] = MediaChapter(
        id: c.id,
        index: c.index,
        startTimeOffset: c.startTimeOffset,
        endTimeOffset: chapters[i + 1].startTimeOffset,
        title: c.title,
        thumb: c.thumb,
      );
    }
    if (runtimeMs != null && chapters.isNotEmpty) {
      final last = chapters.last;
      final start = last.startTimeOffset;
      if (last.endTimeOffset == null && start != null && runtimeMs > start) {
        chapters[chapters.length - 1] = MediaChapter(
          id: last.id,
          index: last.index,
          startTimeOffset: start,
          endTimeOffset: runtimeMs,
          title: last.title,
          thumb: last.thumb,
        );
      }
    }
    return chapters;
  }

  String get label => title ?? 'Chapter ${(index ?? 0) + 1}';

  Duration get startTime => Duration(milliseconds: startTimeOffset ?? 0);
  Duration? get endTime => endTimeOffset != null ? Duration(milliseconds: endTimeOffset!) : null;

  /// Find the chapter index containing [position]. Returns null if none match.
  /// A chapter's end defaults to the next chapter's start when [endTimeOffset]
  /// is missing; the final chapter without an end extends to infinity.
  static int? indexAtPosition(Duration position, List<MediaChapter> chapters) {
    final positionMs = position.inMilliseconds;
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs =
          chapter.endTimeOffset ??
          (i < chapters.length - 1 ? chapters[i + 1].startTimeOffset ?? 0 : double.maxFinite.toInt());
      if (positionMs >= startMs && positionMs < endMs) return i;
    }
    return null;
  }
}

class MediaMarker {
  final int id;
  final String type;
  final int startTimeOffset;
  final int endTimeOffset;

  MediaMarker({required this.id, required this.type, required this.startTimeOffset, required this.endTimeOffset});

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
  final List<MediaChapter> chapters;
  final List<MediaMarker> markers;

  PlaybackExtras({required this.chapters, required this.markers});

  static String? _classifyChapterTitle(String title, RegExp introPattern, RegExp creditsPattern) {
    if (introPattern.hasMatch(title)) return 'intro';
    if (creditsPattern.hasMatch(title)) return 'credits';
    return null;
  }

  /// Returns [PlaybackExtras] using real markers when available, filling any
  /// missing marker types from chapter titles matching intro/credits patterns.
  /// [forceChapterFallback] prefers chapter-derived markers for any type they
  /// provide. When real markers exist, reclassifies markers with unknown types
  /// against the patterns so non-standard type strings get recognized.
  factory PlaybackExtras.withChapterFallback({
    required List<MediaChapter> chapters,
    required List<MediaMarker> markers,
    String? introPatternStr,
    String? creditsPatternStr,
    bool forceChapterFallback = false,
  }) {
    final introPattern = RegExp(
      introPatternStr ?? r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?:\s?\d+)?$',
      caseSensitive: false,
    );
    final creditsPattern = RegExp(
      creditsPatternStr ?? r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$',
      caseSensitive: false,
    );

    final synthetic = <MediaMarker>[];
    for (var i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final title = ch.title;
      if (title == null || title.isEmpty) continue;

      final type = _classifyChapterTitle(title, introPattern, creditsPattern);
      if (type == null) continue;

      final start = ch.startTimeOffset;
      if (start == null) continue;

      final end = ch.endTimeOffset ?? (i + 1 < chapters.length ? chapters[i + 1].startTimeOffset : null);
      if (end == null) continue;

      synthetic.add(MediaMarker(id: ch.id, type: type, startTimeOffset: start, endTimeOffset: end));
    }

    if (markers.isNotEmpty) {
      // Reclassify markers with non-standard types against the patterns.
      final reclassified = markers.map((m) {
        if (m.type == 'intro' || m.type == 'credits') return m;
        final newType = _classifyChapterTitle(m.type, introPattern, creditsPattern);
        if (newType != null) {
          return MediaMarker(
            id: m.id,
            type: newType,
            startTimeOffset: m.startTimeOffset,
            endTimeOffset: m.endTimeOffset,
          );
        }
        return m;
      }).toList();

      if (synthetic.isEmpty) return PlaybackExtras(chapters: chapters, markers: reclassified);

      final syntheticTypes = synthetic.map((m) => m.type).toSet();
      final nativeTypes = reclassified.map((m) => m.type).toSet();
      final merged = forceChapterFallback
          ? <MediaMarker>[...reclassified.where((m) => !syntheticTypes.contains(m.type)), ...synthetic]
          : <MediaMarker>[...reclassified, ...synthetic.where((m) => !nativeTypes.contains(m.type))];
      merged.sort((a, b) => a.startTimeOffset.compareTo(b.startTimeOffset));
      return PlaybackExtras(chapters: chapters, markers: merged);
    }

    return PlaybackExtras(chapters: chapters, markers: synthetic);
  }
}
