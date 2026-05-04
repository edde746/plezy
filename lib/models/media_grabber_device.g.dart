// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_grabber_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaGrabber _$MediaGrabberFromJson(Map<String, dynamic> json) => MediaGrabber(
  identifier: json['identifier'] as String? ?? '',
  protocol: json['protocol'] as String?,
  title: json['title'] as String?,
);

MediaGrabberDevice _$MediaGrabberDeviceFromJson(Map<String, dynamic> json) => MediaGrabberDevice(
  key: json['key'] as String? ?? '',
  uuid: json['uuid'] as String? ?? '',
  uri: json['uri'] as String?,
  protocol: json['protocol'] as String?,
  title: json['title'] as String?,
  make: json['make'] as String?,
  model: json['model'] as String?,
  modelNumber: json['modelNumber'] as String?,
  firmware: json['firmware'] as String?,
  tuners: flexibleInt(json['tuners']),
  sources: json['sources'] as String?,
  status: flexibleInt(json['status']),
  state: flexibleInt(json['state']),
  lastSeenAt: flexibleInt(json['lastSeenAt']),
  channelMappings: json['ChannelMapping'] == null ? const [] : _parseChannelMappings(json['ChannelMapping']),
  settings: json['Setting'] == null ? const [] : _parseSettings(json['Setting']),
);

MediaGrabberDeviceChannel _$MediaGrabberDeviceChannelFromJson(Map<String, dynamic> json) => MediaGrabberDeviceChannel(
  identifier: readStringField(json, 'identifier') as String? ?? '',
  key: readStringField(json, 'key') as String?,
  name: readStringField(json, 'name') as String?,
  drm: json['drm'] == null ? false : flexibleBool(json['drm']),
  hd: json['hd'] == null ? false : flexibleBool(json['hd']),
);
