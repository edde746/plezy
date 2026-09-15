import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';

part 'livetv_dvr.g.dart';

List<ChannelMapping> _parseChannelMappings(Object? raw) => parseFlexibleJsonList(raw, ChannelMapping.fromJson);

/// A Plex Live TV DVR (e.g., HDHomeRun tuner, IPTV provider), reduced to what
/// Plezy renders: identity, lineup labelling, and the enabled-channel mapping.
/// Plex also reports tuner hardware, `Setting`, and `Device` relations for DVR
/// setup, which Plezy does not implement.
@JsonSerializable(createToJson: false)
class LiveTvDvr {
  @JsonKey(defaultValue: '')
  final String key;
  final String? lineup;
  final String? lineupTitle;
  final String? lineupURL;
  @JsonKey(name: 'ChannelMapping', fromJson: _parseChannelMappings)
  final List<ChannelMapping> channelMappings;

  LiveTvDvr({required this.key, this.lineup, this.lineupTitle, this.lineupURL, this.channelMappings = const []});

  factory LiveTvDvr.fromJson(Map<String, dynamic> json) => _$LiveTvDvrFromJson(json);
}

/// Represents a channel mapping within a DVR device
@JsonSerializable(createToJson: false)
class ChannelMapping {
  final String? channelKey;
  @JsonKey(fromJson: flexibleBool)
  final bool? enabled;

  ChannelMapping({this.channelKey, this.enabled});

  factory ChannelMapping.fromJson(Map<String, dynamic> json) => _$ChannelMappingFromJson(json);
}
