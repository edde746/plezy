/// Represents an upcoming scheduled recording from the DVR
class ScheduledRecording {
  final String? key;
  final String? ratingKey;
  final String? guid;
  final String title;
  final String? summary;
  final String? type;
  final int? beginsAt;
  final int? endsAt;
  final String? grandparentTitle;
  final String? parentTitle;
  final int? index;
  final int? parentIndex;
  final String? thumb;
  final String? art;
  final String? channelIdentifier;
  final String? channelCallSign;
  final String? subscriptionID;
  final String? status;

  ScheduledRecording({
    this.key,
    this.ratingKey,
    this.guid,
    required this.title,
    this.summary,
    this.type,
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
    this.subscriptionID,
    this.status,
  });

  factory ScheduledRecording.fromJson(Map<String, dynamic> json) {
    return ScheduledRecording(
      key: json['key'] as String?,
      ratingKey: json['ratingKey'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String? ?? 'Unknown',
      summary: json['summary'] as String?,
      type: json['type'] as String?,
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
      subscriptionID: json['subscriptionID'] as String?,
      status: json['status'] as String?,
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

  /// Display title including series info for episodes
  String get displayTitle {
    if (grandparentTitle != null && index != null) {
      final seasonEpisode = parentIndex != null ? 'S${parentIndex}E$index' : 'E$index';
      return '$grandparentTitle - $seasonEpisode - $title';
    }
    return title;
  }
}
