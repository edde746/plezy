// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteDevice _$RemoteDeviceFromJson(Map<String, dynamic> json) => RemoteDevice(
  id: json['id'] as String,
  name: json['name'] as String,
  platform: json['platform'] as String,
  connectedAt: json['connectedAt'] == null ? null : DateTime.parse(json['connectedAt'] as String),
  capabilities: (json['capabilities'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as bool)),
);

Map<String, dynamic> _$RemoteDeviceToJson(RemoteDevice instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'platform': instance.platform,
  'connectedAt': instance.connectedAt.toIso8601String(),
  'capabilities': instance.capabilities,
};

RemoteSession _$RemoteSessionFromJson(Map<String, dynamic> json) => RemoteSession(
  sessionId: json['sessionId'] as String,
  pin: json['pin'] as String,
  role: $enumDecode(_$RemoteSessionRoleEnumMap, json['role'], unknownValue: RemoteSessionRole.remote),
  status:
      $enumDecodeNullable(
        _$RemoteSessionStatusEnumMap,
        json['status'],
        unknownValue: RemoteSessionStatus.disconnected,
      ) ??
      RemoteSessionStatus.disconnected,
  connectedDevice: json['connectedDevice'] == null
      ? null
      : RemoteDevice.fromJson(json['connectedDevice'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$RemoteSessionToJson(RemoteSession instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'pin': instance.pin,
  'role': _$RemoteSessionRoleEnumMap[instance.role]!,
  'status': _$RemoteSessionStatusEnumMap[instance.status]!,
  'connectedDevice': instance.connectedDevice,
  'createdAt': instance.createdAt.toIso8601String(),
  'errorMessage': instance.errorMessage,
};

const _$RemoteSessionRoleEnumMap = {RemoteSessionRole.host: 'host', RemoteSessionRole.remote: 'remote'};

const _$RemoteSessionStatusEnumMap = {
  RemoteSessionStatus.disconnected: 'disconnected',
  RemoteSessionStatus.connecting: 'connecting',
  RemoteSessionStatus.connected: 'connected',
  RemoteSessionStatus.reconnecting: 'reconnecting',
  RemoteSessionStatus.error: 'error',
};
