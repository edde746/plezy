import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'livetv_dvr.g.dart';

List<ChannelMapping> _parseChannelMappings(Object? raw) {
  final result = <ChannelMapping>[];
  if (raw is List) {
    for (final item in raw) {
      try {
        result.add(ChannelMapping.fromJson(item as Map<String, dynamic>));
      } catch (_) {}
    }
  }
  return result;
}

/// Represents a Plex Live TV DVR device (e.g., HDHomeRun tuner, IPTV provider)
@JsonSerializable(createToJson: false)
class LiveTvDvr {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
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
  @JsonKey(name: 'ChannelMapping', fromJson: _parseChannelMappings)
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

  factory LiveTvDvr.fromJson(Map<String, dynamic> json) => _$LiveTvDvrFromJson(json);
}

/// Represents a channel mapping within a DVR device
@JsonSerializable(createToJson: false)
class ChannelMapping {
  final String? channelKey;
  final String? deviceIdentifier;
  @JsonKey(fromJson: flexibleBool)
  final bool? enabled;
  final String? lineupIdentifier;

  ChannelMapping({this.channelKey, this.deviceIdentifier, this.enabled, this.lineupIdentifier});

  factory ChannelMapping.fromJson(Map<String, dynamic> json) => _$ChannelMappingFromJson(json);
}
