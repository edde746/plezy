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
}
