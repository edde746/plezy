// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trusted_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrustedDevice _$TrustedDeviceFromJson(Map<String, dynamic> json) => TrustedDevice(
  peerId: json['peerId'] as String,
  deviceName: json['deviceName'] as String,
  platform: json['platform'] as String,
  firstConnected: json['firstConnected'] == null ? null : DateTime.parse(json['firstConnected'] as String),
  lastConnected: json['lastConnected'] == null ? null : DateTime.parse(json['lastConnected'] as String),
  isApproved: json['isApproved'] as bool? ?? false,
);

Map<String, dynamic> _$TrustedDeviceToJson(TrustedDevice instance) => <String, dynamic>{
  'peerId': instance.peerId,
  'deviceName': instance.deviceName,
  'platform': instance.platform,
  'firstConnected': instance.firstConnected.toIso8601String(),
  'lastConnected': instance.lastConnected.toIso8601String(),
  'isApproved': instance.isApproved,
};
