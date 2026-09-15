// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/json_converters.dart';

part 'remote_command.freezed.dart';
part 'remote_command.g.dart';

enum RemoteCommandType {
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  select,
  back,
  contextMenu,

  play,
  pause,
  playPause,
  stop,
  seekForward,
  seekBackward,
  nextTrack,
  previousTrack,
  skipIntro,
  skipCredits,

  volumeUp,
  volumeDown,
  volumeMute,
  volumeSet,

  tabNext,
  tabPrevious,
  tabDiscover,
  tabLibraries,
  tabSearch,
  tabDownloads,
  tabSettings,

  home,
  search,
  subtitles,
  audioTracks,
  qualitySettings,
  fullscreen,

  ping,
  pong,
  deviceInfo,
  disconnect,
  ack,
  syncState,

  /// Ask the host to start playing a specific item (or, for a show/season,
  /// its next-unwatched episode). Data payload: `{serverId, ratingKey}`.
  /// Serialized by index — new values must be appended after this one.
  playMedia,
}

class _RemoteCommandTypeConverter extends IndexedEnumConverter<RemoteCommandType> {
  const _RemoteCommandTypeConverter() : super(RemoteCommandType.values, RemoteCommandType.ping);
}

@freezed
sealed class RemoteCommand with _$RemoteCommand {
  const factory RemoteCommand({
    @JsonKey(name: 't') @_RemoteCommandTypeConverter() required RemoteCommandType type,
    @JsonKey(name: 'd') Map<String, dynamic>? data,
  }) = _RemoteCommand;

  factory RemoteCommand.fromJson(Map<String, dynamic> json) => _$RemoteCommandFromJson(json);
}
