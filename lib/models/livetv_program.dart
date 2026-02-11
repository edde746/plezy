/// Represents an EPG program entry (what's on a channel at a given time)
class LiveTvProgram {
  final String? key;
  final String? ratingKey;
  final String? guid;
  final String title;
  final String? summary;
  final String? type;
  final int? year;
  final int? beginsAt; // epoch seconds
  final int? endsAt; // epoch seconds
  final String? grandparentTitle; // series name for episodes
  final String? parentTitle; // season name
  final int? index; // episode number
  final int? parentIndex; // season number
  final String? thumb;
  final String? art;
  final String? channelIdentifier;
  final String? channelCallSign;
  final bool? live;
  final bool? premiere;

  LiveTvProgram({
    this.key,
    this.ratingKey,
    this.guid,
    required this.title,
    this.summary,
    this.type,
    this.year,
    this.beginsAt,
    this.endsAt,
    this.grandparentTitle,
    this.parentTitle,
    this.index,
    this.parentIndex,
    this.thumb,
    this.art,
    this.channelIdentifier,
    this.channelCallSign,
    this.live,
    this.premiere,
  });

  factory LiveTvProgram.fromJson(Map<String, dynamic> json) {
    return LiveTvProgram(
      key: json['key'] as String?,
      ratingKey: json['ratingKey'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String? ?? 'Unknown Program',
      summary: json['summary'] as String?,
      type: json['type'] as String?,
      year: (json['year'] as num?)?.toInt(),
      beginsAt: (json['beginsAt'] as num?)?.toInt(),
      endsAt: (json['endsAt'] as num?)?.toInt(),
      grandparentTitle: json['grandparentTitle'] as String?,
      parentTitle: json['parentTitle'] as String?,
      index: (json['index'] as num?)?.toInt(),
      parentIndex: (json['parentIndex'] as num?)?.toInt(),
      thumb: json['thumb'] as String?,
      art: json['art'] as String?,
      channelIdentifier: json['channelIdentifier'] as String?,
      channelCallSign: json['channelCallSign'] as String?,
      live: json['live'] == true || json['live'] == 1 || json['live'] == '1',
      premiere: json['premiere'] == true || json['premiere'] == 1 || json['premiere'] == '1',
    );
  }

  /// Start time as DateTime
  DateTime? get startTime => beginsAt != null ? DateTime.fromMillisecondsSinceEpoch(beginsAt! * 1000) : null;

  /// End time as DateTime
  DateTime? get endTime => endsAt != null ? DateTime.fromMillisecondsSinceEpoch(endsAt! * 1000) : null;

  /// Duration in minutes
  int get durationMinutes {
    if (beginsAt == null || endsAt == null) return 0;
    return ((endsAt! - beginsAt!) / 60).round();
  }

  /// Whether this program is currently airing
  bool get isCurrentlyAiring {
    if (beginsAt == null || endsAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= beginsAt! && now < endsAt!;
  }

  /// Progress through the program (0.0 to 1.0)
  double get progress {
    if (beginsAt == null || endsAt == null) return 0.0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now < beginsAt!) return 0.0;
    if (now >= endsAt!) return 1.0;
    return (now - beginsAt!) / (endsAt! - beginsAt!);
  }

  /// Display title including series info for episodes
  String get displayTitle {
    if (grandparentTitle != null && index != null) {
      final seasonEpisode = parentIndex != null ? 'S${parentIndex}E$index' : 'E$index';
      return '$grandparentTitle - $seasonEpisode - $title';
    }
    return title;
  }
}
