/// Log level for player messages.
enum PlayerLogLevel {
  /// No logging.
  none,

  /// Fatal errors only.
  fatal,

  /// Errors.
  error,

  /// Warnings.
  warn,

  /// Informational messages.
  info,

  /// Verbose output.
  verbose,

  /// Debug messages.
  debug,

  /// Trace-level output (very verbose).
  trace,
}

/// Represents an audio track in the media.
class AudioTrack {
  /// Unique identifier for the track.
  final String id;

  /// Human-readable title of the track.
  final String? title;

  /// Language code (e.g., 'eng', 'jpn').
  final String? language;

  /// Audio codec (e.g., 'aac', 'ac3', 'dts').
  final String? codec;

  /// Number of audio channels.
  final int? channels;

  /// Alias for channels (media_kit compatibility).
  int? get channelsCount => channels;

  /// Sample rate in Hz.
  final int? sampleRate;

  /// Bitrate in bits per second.
  final int? bitrate;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this track is forced.
  final bool isForced;

  const AudioTrack({
    required this.id,
    this.title,
    this.language,
    this.codec,
    this.channels,
    this.sampleRate,
    this.bitrate,
    this.isDefault = false,
    this.isForced = false,
  });

  /// Auto-select track.
  static const auto = AudioTrack(id: 'auto', title: 'Auto');

  /// Disable audio.
  static const off = AudioTrack(id: 'no', title: 'Off');

  /// Returns a display name for the track.
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    return 'Track $id';
  }

  @override
  String toString() => 'AudioTrack($id, $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a subtitle track in the media.
class SubtitleTrack {
  /// Unique identifier for the track.
  final String id;

  /// Human-readable title of the track.
  final String? title;

  /// Language code (e.g., 'eng', 'jpn').
  final String? language;

  /// Subtitle codec/format (e.g., 'subrip', 'ass', 'pgs').
  final String? codec;

  /// Whether this is the default track.
  final bool isDefault;

  /// Whether this track is forced (e.g., for foreign language segments).
  final bool isForced;

  /// Whether this is an external subtitle file.
  final bool isExternal;

  /// URI of external subtitle file (if isExternal is true).
  final String? uri;

  const SubtitleTrack({
    required this.id,
    this.title,
    this.language,
    this.codec,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.uri,
  });

  /// Create a subtitle track from an external URI.
  factory SubtitleTrack.uri(String uri, {String? title, String? language}) {
    return SubtitleTrack(id: 'external:$uri', title: title, language: language, isExternal: true, uri: uri);
  }

  /// Auto-select track.
  static const auto = SubtitleTrack(id: 'auto', title: 'Auto');

  /// Disable subtitles.
  static const off = SubtitleTrack(id: 'no', title: 'Off');

  /// Returns a display name for the track.
  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    if (isExternal) return 'External';
    return 'Track $id';
  }

  @override
  String toString() => 'SubtitleTrack($id, $displayName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SubtitleTrack && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Container for all available tracks in the media.
class Tracks {
  /// Available audio tracks.
  final List<AudioTrack> audio;

  /// Available subtitle tracks.
  final List<SubtitleTrack> subtitle;

  const Tracks({this.audio = const [], this.subtitle = const []});

  /// Creates a copy with the given fields replaced.
  Tracks copyWith({List<AudioTrack>? audio, List<SubtitleTrack>? subtitle}) {
    return Tracks(audio: audio ?? this.audio, subtitle: subtitle ?? this.subtitle);
  }

  @override
  String toString() => 'Tracks(audio: ${audio.length}, subtitle: ${subtitle.length})';
}

/// Represents the currently selected tracks.
class TrackSelection {
  /// Currently selected audio track.
  final AudioTrack? audio;

  /// Currently selected subtitle track.
  final SubtitleTrack? subtitle;

  const TrackSelection({this.audio, this.subtitle});

  /// Creates a copy with the given fields replaced.
  TrackSelection copyWith({AudioTrack? audio, SubtitleTrack? subtitle}) {
    return TrackSelection(audio: audio ?? this.audio, subtitle: subtitle ?? this.subtitle);
  }

  @override
  String toString() => 'TrackSelection(audio: $audio, subtitle: $subtitle)';
}

/// Represents an audio output device.
class AudioDevice {
  /// Unique identifier for the device.
  final String name;

  /// Human-readable description of the device.
  final String description;

  const AudioDevice({required this.name, this.description = ''});

  /// Default/auto audio device.
  static const auto = AudioDevice(name: 'auto', description: 'Auto');

  @override
  String toString() => 'AudioDevice($name, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioDevice && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// A log entry from the player.
class PlayerLog {
  /// The log level of this message.
  final PlayerLogLevel level;

  /// The prefix/category of the log message (e.g., 'cplayer', 'ffmpeg').
  final String prefix;

  /// The log message text.
  final String text;

  const PlayerLog({required this.level, required this.prefix, required this.text});

  @override
  String toString() => '[$prefix] ${level.name}: $text';
}

/// Represents a media source for the player.
class Media {
  /// The URI of the media (file path, HTTP URL, etc.).
  final String uri;

  /// Optional HTTP headers for network requests.
  final Map<String, String>? headers;

  /// Optional start position for playback.
  final Duration? start;

  const Media(this.uri, {this.headers, this.start});

  @override
  String toString() => 'Media($uri)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Media && runtimeType == other.runtimeType && uri == other.uri && start == other.start;

  @override
  int get hashCode => uri.hashCode ^ start.hashCode;
}
