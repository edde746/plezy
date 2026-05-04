class BufferRange {
  final Duration start;
  final Duration end;
  const BufferRange({required this.start, required this.end});
}

/// [cause] is an optional machine-readable tag (e.g. `server-http-500`),
/// letting the UI branch without parsing [message].
class PlayerError {
  /// Cause tag for a server-side HTTP 500 — shared-user bandwidth or
  /// transcoding limit rejection set by the server owner.
  static const String serverHttp500 = 'server-http-500';

  final String message;
  final String? cause;
  const PlayerError(this.message, {this.cause});

  @override
  String toString() => message;
}

enum PlayerLogLevel { none, fatal, error, warn, info, verbose, debug, trace }

class AudioTrack {
  final String id;
  final String? title;
  final String? language;
  final String? codec;
  final int? channels;
  int? get channelsCount => channels;
  final int? sampleRate;
  final int? bitrate;
  final bool isDefault;
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

  static const auto = AudioTrack(id: 'auto', title: 'Auto');

  static const off = AudioTrack(id: 'no', title: 'Off');

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

class SubtitleTrack {
  final String id;
  final String? title;
  final String? language;
  final String? codec;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;
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

  factory SubtitleTrack.uri(String uri, {String? title, String? language}) {
    return SubtitleTrack(id: 'external:$uri', title: title, language: language, isExternal: true, uri: uri);
  }

  static const auto = SubtitleTrack(id: 'auto', title: 'Auto');

  static const off = SubtitleTrack(id: 'no', title: 'Off');

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

class Tracks {
  final List<AudioTrack> audio;
  final List<SubtitleTrack> subtitle;

  const Tracks({this.audio = const [], this.subtitle = const []});

  Tracks copyWith({List<AudioTrack>? audio, List<SubtitleTrack>? subtitle}) {
    return Tracks(audio: audio ?? this.audio, subtitle: subtitle ?? this.subtitle);
  }

  @override
  String toString() => 'Tracks(audio: ${audio.length}, subtitle: ${subtitle.length})';
}

/// Sentinel value used to distinguish "not provided" from "explicitly set to null" in copyWith.
const _sentinel = Object();

class TrackSelection {
  final AudioTrack? audio;
  final SubtitleTrack? subtitle;
  final SubtitleTrack? secondarySubtitle;

  const TrackSelection({this.audio, this.subtitle, this.secondarySubtitle});

  /// Creates a copy with the given fields replaced.
  /// Use [secondarySubtitle] with explicit null to clear the secondary subtitle.
  TrackSelection copyWith({AudioTrack? audio, SubtitleTrack? subtitle, Object? secondarySubtitle = _sentinel}) {
    return TrackSelection(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
      secondarySubtitle: identical(secondarySubtitle, _sentinel)
          ? this.secondarySubtitle
          : secondarySubtitle as SubtitleTrack?,
    );
  }

  @override
  String toString() => 'TrackSelection(audio: $audio, subtitle: $subtitle, secondarySubtitle: $secondarySubtitle)';
}

class AudioDevice {
  final String name;
  final String description;

  const AudioDevice({required this.name, this.description = ''});

  static const auto = AudioDevice(name: 'auto', description: 'Auto');

  @override
  String toString() => 'AudioDevice($name, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioDevice && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class PlayerLog {
  final PlayerLogLevel level;
  final String prefix;
  final String text;

  const PlayerLog({required this.level, required this.prefix, required this.text});

  @override
  String toString() => '[$prefix] ${level.name}: $text';
}

class Media {
  final String uri;
  final Map<String, String>? headers;
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
