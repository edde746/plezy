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
