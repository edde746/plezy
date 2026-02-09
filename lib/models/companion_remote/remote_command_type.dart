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
  capabilitiesRequest,
  capabilitiesResponse,
  disconnect,
  ack, // Acknowledgment of received command
}

extension RemoteCommandTypeExtension on RemoteCommandType {
  String get displayName {
    switch (this) {
      case RemoteCommandType.dpadUp:
        return 'Up';
      case RemoteCommandType.dpadDown:
        return 'Down';
      case RemoteCommandType.dpadLeft:
        return 'Left';
      case RemoteCommandType.dpadRight:
        return 'Right';
      case RemoteCommandType.select:
        return 'Select';
      case RemoteCommandType.back:
        return 'Back';
      case RemoteCommandType.contextMenu:
        return 'Menu';
      case RemoteCommandType.play:
        return 'Play';
      case RemoteCommandType.pause:
        return 'Pause';
      case RemoteCommandType.playPause:
        return 'Play/Pause';
      case RemoteCommandType.stop:
        return 'Stop';
      case RemoteCommandType.seekForward:
        return 'Seek Forward';
      case RemoteCommandType.seekBackward:
        return 'Seek Backward';
      case RemoteCommandType.nextTrack:
        return 'Next';
      case RemoteCommandType.previousTrack:
        return 'Previous';
      case RemoteCommandType.skipIntro:
        return 'Skip Intro';
      case RemoteCommandType.skipCredits:
        return 'Skip Credits';
      case RemoteCommandType.volumeUp:
        return 'Volume Up';
      case RemoteCommandType.volumeDown:
        return 'Volume Down';
      case RemoteCommandType.volumeMute:
        return 'Mute';
      case RemoteCommandType.volumeSet:
        return 'Set Volume';
      case RemoteCommandType.tabNext:
        return 'Next Tab';
      case RemoteCommandType.tabPrevious:
        return 'Previous Tab';
      case RemoteCommandType.tabDiscover:
        return 'Discover';
      case RemoteCommandType.tabLibraries:
        return 'Libraries';
      case RemoteCommandType.tabSearch:
        return 'Search';
      case RemoteCommandType.tabDownloads:
        return 'Downloads';
      case RemoteCommandType.tabSettings:
        return 'Settings';
      case RemoteCommandType.home:
        return 'Home';
      case RemoteCommandType.search:
        return 'Search';
      case RemoteCommandType.subtitles:
        return 'Subtitles';
      case RemoteCommandType.audioTracks:
        return 'Audio';
      case RemoteCommandType.qualitySettings:
        return 'Quality';
      case RemoteCommandType.fullscreen:
        return 'Fullscreen';
      case RemoteCommandType.ping:
        return 'Ping';
      case RemoteCommandType.pong:
        return 'Pong';
      case RemoteCommandType.deviceInfo:
        return 'Device Info';
      case RemoteCommandType.capabilitiesRequest:
        return 'Capabilities Request';
      case RemoteCommandType.capabilitiesResponse:
        return 'Capabilities Response';
      case RemoteCommandType.disconnect:
        return 'Disconnect';
      case RemoteCommandType.ack:
        return 'Acknowledgment';
    }
  }

  bool get isNavigationCommand {
    return [
      RemoteCommandType.dpadUp,
      RemoteCommandType.dpadDown,
      RemoteCommandType.dpadLeft,
      RemoteCommandType.dpadRight,
      RemoteCommandType.select,
      RemoteCommandType.back,
      RemoteCommandType.contextMenu,
    ].contains(this);
  }

  bool get isPlaybackCommand {
    return [
      RemoteCommandType.play,
      RemoteCommandType.pause,
      RemoteCommandType.playPause,
      RemoteCommandType.stop,
      RemoteCommandType.seekForward,
      RemoteCommandType.seekBackward,
      RemoteCommandType.nextTrack,
      RemoteCommandType.previousTrack,
      RemoteCommandType.skipIntro,
      RemoteCommandType.skipCredits,
    ].contains(this);
  }

  bool get isVolumeCommand {
    return [
      RemoteCommandType.volumeUp,
      RemoteCommandType.volumeDown,
      RemoteCommandType.volumeMute,
      RemoteCommandType.volumeSet,
    ].contains(this);
  }

  bool get isTabCommand {
    return [
      RemoteCommandType.tabNext,
      RemoteCommandType.tabPrevious,
      RemoteCommandType.tabDiscover,
      RemoteCommandType.tabLibraries,
      RemoteCommandType.tabSearch,
      RemoteCommandType.tabDownloads,
      RemoteCommandType.tabSettings,
    ].contains(this);
  }
}
