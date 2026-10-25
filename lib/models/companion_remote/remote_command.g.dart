// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RemoteCommand _$RemoteCommandFromJson(Map<String, dynamic> json) =>
    _RemoteCommand(
      type: const _RemoteCommandTypeConverter().fromJson(
        (json['t'] as num).toInt(),
      ),
      data: json['d'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RemoteCommandToJson(_RemoteCommand instance) =>
    <String, dynamic>{
      't': const _RemoteCommandTypeConverter().toJson(instance.type),
      'd': instance.data,
    };
