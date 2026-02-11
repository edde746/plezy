/// Represents a Plex Live TV DVR device (e.g., HDHomeRun tuner, IPTV provider)
class LiveTvDvr {
  final String key;
  final String uuid;
  final String? make;
  final String? model;
  final String? modelNumber;
  final String? firmware;
  final int? tuners;
  final String? lineup;
  final String? lineupTitle;
  final String? lineupURL;
  final String? country;
  final String? language;
  final String? status;
  final List<ChannelMapping> channelMappings;

  LiveTvDvr({
    required this.key,
    required this.uuid,
    this.make,
    this.model,
    this.modelNumber,
    this.firmware,
    this.tuners,
    this.lineup,
    this.lineupTitle,
    this.lineupURL,
    this.country,
    this.language,
    this.status,
    this.channelMappings = const [],
  });

  factory LiveTvDvr.fromJson(Map<String, dynamic> json) {
    final mappings = <ChannelMapping>[];
    if (json['ChannelMapping'] != null) {
      for (final item in json['ChannelMapping'] as List) {
        try {
          mappings.add(ChannelMapping.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    return LiveTvDvr(
      key: json['key'] as String? ?? '',
      uuid: json['uuid'] as String? ?? '',
      make: json['make'] as String?,
      model: json['model'] as String?,
      modelNumber: json['modelNumber'] as String?,
      firmware: json['firmware'] as String?,
      tuners: (json['tuners'] as num?)?.toInt(),
      lineup: json['lineup'] as String?,
      lineupTitle: json['lineupTitle'] as String?,
      lineupURL: json['lineupURL'] as String?,
      country: json['country'] as String?,
      language: json['language'] as String?,
      status: json['status'] as String?,
      channelMappings: mappings,
    );
  }
}

/// Represents a channel mapping within a DVR device
class ChannelMapping {
  final String? channelKey;
  final String? deviceIdentifier;
  final bool? enabled;
  final String? lineupIdentifier;

  ChannelMapping({
    this.channelKey,
    this.deviceIdentifier,
    this.enabled,
    this.lineupIdentifier,
  });

  factory ChannelMapping.fromJson(Map<String, dynamic> json) {
    return ChannelMapping(
      channelKey: json['channelKey'] as String?,
      deviceIdentifier: json['deviceIdentifier'] as String?,
      enabled: json['enabled'] == true || json['enabled'] == 1,
      lineupIdentifier: json['lineupIdentifier'] as String?,
    );
  }
}
