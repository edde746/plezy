/// Represents a Live TV channel from the EPG
class LiveTvChannel {
  final String key;
  final String? identifier;
  final String? callSign;
  final String? title;
  final String? thumb;
  final String? art;
  final String? number;
  final bool hd;
  final String? lineup;
  final String? slug;
  final bool? drm;

  // Multi-server support
  final String? serverId;
  final String? serverName;

  LiveTvChannel({
    required this.key,
    this.identifier,
    this.callSign,
    this.title,
    this.thumb,
    this.art,
    this.number,
    this.hd = false,
    this.lineup,
    this.slug,
    this.drm,
    this.serverId,
    this.serverName,
  });

  factory LiveTvChannel.fromJson(Map<String, dynamic> json) {
    return LiveTvChannel(
      key: json['key'] as String? ?? json['ratingKey'] as String? ?? json['identifier'] as String? ?? json['channelIdentifier'] as String? ?? '',
      identifier: json['identifier'] as String? ?? json['channelIdentifier'] as String?,
      callSign: json['callSign'] as String?,
      title: json['title'] as String? ?? json['callSign'] as String?,
      thumb: json['thumb'] as String?,
      art: json['art'] as String?,
      number: json['number'] as String? ?? json['channelNumber'] as String? ?? json['channelVcn']?.toString(),
      hd: json['hd'] == true || json['hd'] == 1,
      lineup: json['lineup'] as String?,
      slug: json['slug'] as String?,
      drm: json['drm'] == true || json['drm'] == 1,
    );
  }

  LiveTvChannel copyWith({String? serverId, String? serverName}) {
    return LiveTvChannel(
      key: key,
      identifier: identifier,
      callSign: callSign,
      title: title,
      thumb: thumb,
      art: art,
      number: number,
      hd: hd,
      lineup: lineup,
      slug: slug,
      drm: drm,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
    );
  }

  /// Display name: prefer callSign, fallback to title
  String get displayName => callSign ?? title ?? 'Channel $number';
}
