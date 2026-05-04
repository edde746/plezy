import '../utils/json_utils.dart';

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
  final String? serverId;
  final String? serverName;
  final String? liveDvrKey;
  final String? providerIdentifier;

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
    this.serverId,
    this.serverName,
    this.liveDvrKey,
    this.providerIdentifier,
  });

  factory LiveTvProgram.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? mediaOverride}) {
    // Grid endpoint nests timing/channel info inside Media[] and Channel[].
    // When mediaOverride is supplied, the caller is pinning this parse to a
    // specific airing (one Media entry); treat it as authoritative for
    // begin/end/channel fields.
    final hasOverride = mediaOverride != null;
    final media = mediaOverride ?? (json['Media'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final channel = (json['Channel'] as List?)?.firstOrNull as Map<String, dynamic>?;

    int? pickInt(String key) {
      final fromMedia = flexibleInt(media?[key]);
      final fromJson = flexibleInt(json[key]);
      return hasOverride ? (fromMedia ?? fromJson) : (fromJson ?? fromMedia);
    }

    String? pickString(String key) {
      final fromMedia = media?[key]?.toString();
      final fromJson = json[key] as String?;
      return hasOverride ? (fromMedia ?? fromJson) : (fromJson ?? fromMedia);
    }

    return LiveTvProgram(
      key: json['key'] as String?,
      ratingKey: json['ratingKey'] as String?,
      guid: json['guid'] as String?,
      title: json['title'] as String? ?? 'Unknown Program',
      summary: json['summary'] as String?,
      type: json['type'] as String?,
      year: flexibleInt(json['year']),
      beginsAt: pickInt('beginsAt'),
      endsAt: pickInt('endsAt'),
      grandparentTitle: json['grandparentTitle'] as String?,
      parentTitle: json['parentTitle'] as String?,
      index: flexibleInt(json['index']),
      parentIndex: flexibleInt(json['parentIndex']),
      thumb: json['thumb'] as String? ?? json['grandparentThumb'] as String?,
      art: json['art'] as String?,
      channelIdentifier: pickString('channelIdentifier') ?? channel?['id']?.toString(),
      channelCallSign: pickString('channelCallSign'),
      live: flexibleBool(json['live']),
      premiere: flexibleBool(json['premiere']),
    );
  }

  LiveTvProgram copyWith({String? serverId, String? serverName, String? liveDvrKey, String? providerIdentifier}) {
    return LiveTvProgram(
      key: key,
      ratingKey: ratingKey,
      guid: guid,
      title: title,
      summary: summary,
      type: type,
      year: year,
      beginsAt: beginsAt,
      endsAt: endsAt,
      grandparentTitle: grandparentTitle,
      parentTitle: parentTitle,
      index: index,
      parentIndex: parentIndex,
      thumb: thumb,
      art: art,
      channelIdentifier: channelIdentifier,
      channelCallSign: channelCallSign,
      live: live,
      premiere: premiere,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      liveDvrKey: liveDvrKey ?? this.liveDvrKey,
      providerIdentifier: providerIdentifier ?? this.providerIdentifier,
    );
  }

  DateTime? get startTime => beginsAt != null ? DateTime.fromMillisecondsSinceEpoch(beginsAt! * 1000) : null;

  DateTime? get endTime => endsAt != null ? DateTime.fromMillisecondsSinceEpoch(endsAt! * 1000) : null;

  int get durationMinutes {
    if (beginsAt == null || endsAt == null) return 0;
    return ((endsAt! - beginsAt!) / 60).round();
  }

  bool get isCurrentlyAiring {
    if (beginsAt == null || endsAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= beginsAt! && now < endsAt!;
  }

  double get progress {
    if (beginsAt == null || endsAt == null) return 0.0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now < beginsAt!) return 0.0;
    if (now >= endsAt!) return 1.0;
    return (now - beginsAt!) / (endsAt! - beginsAt!);
  }

  String get displayTitle {
    if (grandparentTitle != null && index != null) {
      final seasonEpisode = parentIndex != null ? 'S${parentIndex}E$index' : 'E$index';
      return '$grandparentTitle - $seasonEpisode - $title';
    }
    return title;
  }
}
