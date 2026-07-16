import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'media_subscription.dart';

part 'livetv_dvr.g.dart';

List<ChannelMapping> _parseChannelMappings(Object? raw) => parseFlexibleJsonList(raw, ChannelMapping.fromJson);

List<SubscriptionSetting> _parseSettings(Object? raw) => parseFlexibleJsonList(raw, SubscriptionSetting.fromJson);

List<Map<String, dynamic>> _parseRawMaps(Object? raw) => flexibleMapList(raw);

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
  @JsonKey(fromJson: flexibleInt)
  final int? tuners;
  final String? lineup;
  final String? lineupTitle;
  final String? lineupURL;
  final String? country;
  final String? language;
  @JsonKey(fromJson: flexibleInt)
  final int? status;
  @JsonKey(fromJson: flexibleInt)
  final int? state;
  final String? protocol;
  final String? sources;
  final String? uri;
  @JsonKey(fromJson: flexibleInt)
  final int? lastSeenAt;
  @JsonKey(name: 'ChannelMapping', fromJson: _parseChannelMappings)
  final List<ChannelMapping> channelMappings;
  @JsonKey(name: 'Setting', fromJson: _parseSettings)
  final List<SubscriptionSetting> settings;
  @JsonKey(name: 'Device', fromJson: _parseRawMaps)
  final List<Map<String, dynamic>> devices;

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
    this.state,
    this.protocol,
    this.sources,
    this.uri,
    this.lastSeenAt,
    this.channelMappings = const [],
    this.settings = const [],
    this.devices = const [],
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
