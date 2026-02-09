// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteCommand _$RemoteCommandFromJson(Map<String, dynamic> json) => RemoteCommand(
  type: $enumDecode(_$RemoteCommandTypeEnumMap, json['type'], unknownValue: RemoteCommandType.ping),
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  timestamp: json['timestamp'] == null ? null : DateTime.parse(json['timestamp'] as String),
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RemoteCommandToJson(RemoteCommand instance) => <String, dynamic>{
  'type': _$RemoteCommandTypeEnumMap[instance.type]!,
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'timestamp': instance.timestamp.toIso8601String(),
  'data': instance.data,
};

const _$RemoteCommandTypeEnumMap = {
  RemoteCommandType.dpadUp: 'dpadUp',
  RemoteCommandType.dpadDown: 'dpadDown',
  RemoteCommandType.dpadLeft: 'dpadLeft',
  RemoteCommandType.dpadRight: 'dpadRight',
  RemoteCommandType.select: 'select',
  RemoteCommandType.back: 'back',
  RemoteCommandType.contextMenu: 'contextMenu',
  RemoteCommandType.play: 'play',
  RemoteCommandType.pause: 'pause',
  RemoteCommandType.playPause: 'playPause',
  RemoteCommandType.stop: 'stop',
  RemoteCommandType.seekForward: 'seekForward',
  RemoteCommandType.seekBackward: 'seekBackward',
  RemoteCommandType.nextTrack: 'nextTrack',
  RemoteCommandType.previousTrack: 'previousTrack',
  RemoteCommandType.skipIntro: 'skipIntro',
  RemoteCommandType.skipCredits: 'skipCredits',
  RemoteCommandType.volumeUp: 'volumeUp',
  RemoteCommandType.volumeDown: 'volumeDown',
  RemoteCommandType.volumeMute: 'volumeMute',
  RemoteCommandType.volumeSet: 'volumeSet',
  RemoteCommandType.tabNext: 'tabNext',
  RemoteCommandType.tabPrevious: 'tabPrevious',
  RemoteCommandType.tabDiscover: 'tabDiscover',
  RemoteCommandType.tabLibraries: 'tabLibraries',
  RemoteCommandType.tabSearch: 'tabSearch',
  RemoteCommandType.tabDownloads: 'tabDownloads',
  RemoteCommandType.tabSettings: 'tabSettings',
  RemoteCommandType.home: 'home',
  RemoteCommandType.search: 'search',
  RemoteCommandType.subtitles: 'subtitles',
  RemoteCommandType.audioTracks: 'audioTracks',
  RemoteCommandType.qualitySettings: 'qualitySettings',
  RemoteCommandType.fullscreen: 'fullscreen',
  RemoteCommandType.ping: 'ping',
  RemoteCommandType.pong: 'pong',
  RemoteCommandType.deviceInfo: 'deviceInfo',
  RemoteCommandType.capabilitiesRequest: 'capabilitiesRequest',
  RemoteCommandType.capabilitiesResponse: 'capabilitiesResponse',
  RemoteCommandType.disconnect: 'disconnect',
  RemoteCommandType.ack: 'ack',
};
