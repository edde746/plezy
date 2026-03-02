enum RemoteCommandType {
  // Navigation
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  select,
  back,
  contextMenu,

  // Playback
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

  // Volume
  volumeUp,
  volumeDown,
  volumeMute,
  volumeSet,

  // Tab Navigation
  tabNext,
  tabPrevious,
  tabDiscover,
  tabLibraries,
  tabSearch,
  tabDownloads,
  tabSettings,

  // Quick Actions
  home,
  search,
  subtitles,
  audioTracks,
  qualitySettings,
  fullscreen,

  // Session Management
  ping,
  pong,
  deviceInfo,
  disconnect,
  ack,
  syncState,
}

class RemoteCommand {
  final RemoteCommandType type;
  final Map<String, dynamic>? data;

  const RemoteCommand({required this.type, this.data});

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    final index = json['t'] as int;
    return RemoteCommand(
      type: index < RemoteCommandType.values.length ? RemoteCommandType.values[index] : RemoteCommandType.ping,
      data: json['d'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'t': type.index, if (data != null) 'd': data};
  }

  @override
  String toString() => 'RemoteCommand(${type.name}, data: $data)';
}
