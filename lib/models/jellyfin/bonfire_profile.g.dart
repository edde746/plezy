// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonfire_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BonfireProfile _$BonfireProfileFromJson(Map<String, dynamic> json) =>
    BonfireProfile(
      profileUserId: readStringField(json, 'profileUserId') as String? ?? '',
      profileName: readStringField(json, 'profileName') as String? ?? '',
      avatarInitial: readStringField(json, 'avatarInitial') as String? ?? '',
      avatarColor: readStringField(json, 'avatarColor') as String? ?? '',
      transparentAvatar: json['transparentAvatar'] == null
          ? false
          : flexibleBool(json['transparentAvatar']),
      requiresPin: json['requiresPin'] == null
          ? false
          : flexibleBool(json['requiresPin']),
      hasPin: json['hasPin'] == null ? false : flexibleBool(json['hasPin']),
      isMaster: json['isMaster'] == null
          ? false
          : flexibleBool(json['isMaster']),
      isAdministrator: json['isAdministrator'] == null
          ? false
          : flexibleBool(json['isAdministrator']),
      lockoutMinutes: flexibleIntOrZero(json['lockoutMinutes']),
      bypassPinOnLocalNetwork: json['bypassPinOnLocalNetwork'] == null
          ? false
          : flexibleBool(json['bypassPinOnLocalNetwork']),
      allowedDeviceIds: _stringListOrEmpty(json['allowedDeviceIds']),
      isBonfire: json['isBonfire'] == null
          ? false
          : flexibleBool(json['isBonfire']),
      profileImage: readStringField(json, 'profileImage') as String?,
      masterUserId: readStringField(json, 'masterUserId') as String? ?? '',
    );

Map<String, dynamic> _$BonfireProfileToJson(BonfireProfile instance) =>
    <String, dynamic>{
      'profileUserId': instance.profileUserId,
      'profileName': instance.profileName,
      'avatarInitial': instance.avatarInitial,
      'avatarColor': instance.avatarColor,
      'transparentAvatar': instance.transparentAvatar,
      'requiresPin': instance.requiresPin,
      'hasPin': instance.hasPin,
      'isMaster': instance.isMaster,
      'isAdministrator': instance.isAdministrator,
      'lockoutMinutes': instance.lockoutMinutes,
      'bypassPinOnLocalNetwork': instance.bypassPinOnLocalNetwork,
      'allowedDeviceIds': instance.allowedDeviceIds,
      'isBonfire': instance.isBonfire,
      'profileImage': instance.profileImage,
      'masterUserId': instance.masterUserId,
    };
