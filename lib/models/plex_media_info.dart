class PlexMediaInfo {
  final String videoUrl;
  final List<PlexAudioTrack> audioTracks;
  final List<PlexSubtitleTrack> subtitleTracks;
  final List<PlexChapter> chapters;

  PlexMediaInfo({
    required this.videoUrl,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.chapters,
  });
}

class PlexAudioTrack {
  final int id;
  final int? index;
  final String? codec;
  final String? language;
  final String? languageCode;
  final String? title;
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
    if (displayTitle != null) return displayTitle!;
    final parts = <String>[];
    if (language != null) parts.add(language!);
    if (codec != null) parts.add(codec!.toUpperCase());
    if (channels != null) parts.add('${channels!}ch');
    return parts.isEmpty ? 'Track ${index ?? id}' : parts.join(' · ');
  }
}

class PlexSubtitleTrack {
  final int id;
  final int? index;
  final String? codec;
  final String? language;
  final String? languageCode;
  final String? title;
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
    if (displayTitle != null) return displayTitle!;
    final parts = <String>[];
    if (language != null) parts.add(language!);
    if (forced) parts.add('Forced');
    return parts.isEmpty ? 'Track ${index ?? id}' : parts.join(' · ');
  }

  /// Returns true if this subtitle track is an external file (sidecar subtitle)
  /// External subtitles have a key property that points to /library/streams/{id}
  bool get isExternal => key != null && key!.isNotEmpty;

  /// Constructs the full URL for fetching external subtitle files
  /// Returns null if this is not an external subtitle
  String? getSubtitleUrl(String baseUrl, String token) {
    if (!isExternal) return null;

    // Determine file extension based on codec
    final ext = _getExtensionFromCodec(codec);

    // Construct URL with authentication token
    return '$baseUrl$key.$ext?X-Plex-Token=$token';
  }

  /// Maps Plex subtitle codec names to file extensions
  String _getExtensionFromCodec(String? codec) {
    if (codec == null) return 'srt';

    switch (codec.toLowerCase()) {
      case 'subrip':
      case 'srt':
        return 'srt';
      case 'ass':
        return 'ass';
      case 'ssa':
        return 'ssa';
      case 'webvtt':
      case 'vtt':
        return 'vtt';
      case 'mov_text':
        return 'srt';
      case 'pgs':
      case 'hdmv_pgs_subtitle':
        return 'sup';
      case 'dvd_subtitle':
      case 'dvdsub':
        return 'sub';
      default:
        return 'srt'; // Default to SRT for unknown codecs
    }
  }
}

class PlexChapter {
  final int id;
  final int? index;
  final int? startTimeOffset;
  final int? endTimeOffset;
  final String? title;
  final String? thumb;

  PlexChapter({
    required this.id,
    this.index,
    this.startTimeOffset,
    this.endTimeOffset,
    this.title,
    this.thumb,
  });

  String get label => title ?? 'Chapter ${(index ?? 0) + 1}';

  Duration get startTime => Duration(milliseconds: startTimeOffset ?? 0);
  Duration? get endTime =>
      endTimeOffset != null ? Duration(milliseconds: endTimeOffset!) : null;
}

class PlexMarker {
  final int id;
  final String type;
  final int startTimeOffset;
  final int endTimeOffset;

  PlexMarker({
    required this.id,
    required this.type,
    required this.startTimeOffset,
    required this.endTimeOffset,
  });

  Duration get startTime => Duration(milliseconds: startTimeOffset);
  Duration get endTime => Duration(milliseconds: endTimeOffset);

  bool get isIntro => type == 'intro';
  bool get isCredits => type == 'credits';

  bool containsPosition(Duration position) {
    final posMs = position.inMilliseconds;
    return posMs >= startTimeOffset && posMs <= endTimeOffset;
  }
}
