import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'livetv_dvr.dart';
import 'media_subscription.dart';

part 'media_grabber_device.g.dart';

List<ChannelMapping> _parseChannelMappings(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) ChannelMapping.fromJson(item),
  ];
}

List<SubscriptionSetting> _parseSettings(Object? raw) {
  final list = flexibleList(raw) ?? const [];
  return [
    for (final item in list)
      if (item is Map<String, dynamic>) SubscriptionSetting.fromJson(item),
  ];
}

@JsonSerializable(createToJson: false)
class MediaGrabber {
  @JsonKey(defaultValue: '')
  final String identifier;
  final String? protocol;
  final String? title;

  const MediaGrabber({required this.identifier, this.protocol, this.title});

  factory MediaGrabber.fromJson(Map<String, dynamic> json) => _$MediaGrabberFromJson(json);
}

/// Tuner/grabber device known to Plex Media Server.
@JsonSerializable(createToJson: false)
class MediaGrabberDevice {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String uuid;
  final String? uri;
  final String? protocol;
  final String? title;
  final String? make;
  final String? model;
  final String? modelNumber;
  final String? firmware;
  @JsonKey(fromJson: flexibleInt)
  final int? tuners;
  final String? sources;
  @JsonKey(fromJson: flexibleInt)
  final int? status;
  @JsonKey(fromJson: flexibleInt)
  final int? state;
  @JsonKey(fromJson: flexibleInt)
  final int? lastSeenAt;
  @JsonKey(name: 'ChannelMapping', fromJson: _parseChannelMappings)
  final List<ChannelMapping> channelMappings;
  @JsonKey(name: 'Setting', fromJson: _parseSettings)
  final List<SubscriptionSetting> settings;

  const MediaGrabberDevice({
    required this.key,
    required this.uuid,
    this.uri,
    this.protocol,
    this.title,
    this.make,
    this.model,
    this.modelNumber,
    this.firmware,
    this.tuners,
    this.sources,
    this.status,
    this.state,
    this.lastSeenAt,
    this.channelMappings = const [],
    this.settings = const [],
  });

  factory MediaGrabberDevice.fromJson(Map<String, dynamic> json) => _$MediaGrabberDeviceFromJson(json);
}

@JsonSerializable(createToJson: false)
class MediaGrabberDeviceChannel {
  @JsonKey(readValue: readStringField, defaultValue: '')
  final String identifier;
  @JsonKey(readValue: readStringField)
  final String? key;
  @JsonKey(readValue: readStringField)
  final String? name;
  @JsonKey(fromJson: flexibleBool)
  final bool drm;
  @JsonKey(fromJson: flexibleBool)
  final bool hd;

  const MediaGrabberDeviceChannel({required this.identifier, this.key, this.name, this.drm = false, this.hd = false});

  factory MediaGrabberDeviceChannel.fromJson(Map<String, dynamic> json) => _$MediaGrabberDeviceChannelFromJson(json);
}

class MediaGrabberChannelMapRequest {
  final List<String> channelsEnabled;
  final Map<String, String> channelMapping;
  final Map<String, String> channelMappingByKey;

  const MediaGrabberChannelMapRequest({
    this.channelsEnabled = const [],
    this.channelMapping = const {},
    this.channelMappingByKey = const {},
  });
}
