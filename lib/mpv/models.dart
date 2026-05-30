// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

@freezed
sealed class BufferRange with _$BufferRange {
  const factory BufferRange({required Duration start, required Duration end}) = _BufferRange;
}

/// [cause] is an optional machine-readable tag (e.g. `server-http-500`),
/// letting the UI branch without parsing [message].
@Freezed(toStringOverride: false)
sealed class PlayerError with _$PlayerError {
  const PlayerError._();

  const factory PlayerError(String message, {String? cause}) = _PlayerError;

  /// Cause tag for a server-side HTTP 500 — shared-user bandwidth or
  /// transcoding limit rejection set by the server owner.
  static const String serverHttp500 = 'server-http-500';

  @override
  String toString() => message;
}

enum PlayerLogLevel { none, fatal, error, warn, info, verbose, debug, trace }

@freezed
sealed class AudioTrack with _$AudioTrack {
  const AudioTrack._();

  const factory AudioTrack({
    required String id,
    String? title,
    String? language,
    String? codec,
    int? channels,
    int? sampleRate,
    int? bitrate,
    @Default(false) bool isDefault,
    @Default(false) bool isForced,
  }) = _AudioTrack;

  static const auto = AudioTrack(id: 'auto', title: 'Auto');

  static const off = AudioTrack(id: 'no', title: 'Off');

  int? get channelsCount => channels;

  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    return 'Track $id';
  }
}

@freezed
sealed class SubtitleTrack with _$SubtitleTrack {
  const SubtitleTrack._();

  const factory SubtitleTrack({
    required String id,
    String? title,
    String? language,
    String? codec,
    @Default(false) bool isDefault,
    @Default(false) bool isForced,
    @Default(false) bool isExternal,
    String? uri,
  }) = _SubtitleTrack;

  factory SubtitleTrack.uri(
    String uri, {
    String? title,
    String? language,
    String? codec,
    bool isDefault = false,
    bool isForced = false,
  }) => SubtitleTrack(
    id: 'external:$uri',
    title: title,
    language: language,
    codec: codec,
    isDefault: isDefault,
    isForced: isForced,
    isExternal: true,
    uri: uri,
  );

  static const auto = SubtitleTrack(id: 'auto', title: 'Auto');

  static const off = SubtitleTrack(id: 'no', title: 'Off');

  String get displayName {
    if (title != null && title!.isNotEmpty) return title!;
    if (language != null && language!.isNotEmpty) return language!;
    if (isExternal) return 'External';
    return 'Track $id';
  }
}

@Freezed(toStringOverride: false)
sealed class Tracks with _$Tracks {
  const Tracks._();

  const factory Tracks({
    @Default(<AudioTrack>[]) List<AudioTrack> audio,
    @Default(<SubtitleTrack>[]) List<SubtitleTrack> subtitle,
  }) = _Tracks;

  @override
  String toString() => 'Tracks(audio: ${audio.length}, subtitle: ${subtitle.length})';
}

@freezed
sealed class TrackSelection with _$TrackSelection {
  const factory TrackSelection({AudioTrack? audio, SubtitleTrack? subtitle, SubtitleTrack? secondarySubtitle}) =
      _TrackSelection;
}

@freezed
sealed class AudioDevice with _$AudioDevice {
  const factory AudioDevice({required String name, @Default('') String description}) = _AudioDevice;

  static const auto = AudioDevice(name: 'auto', description: 'Auto');
}

@Freezed(toStringOverride: false)
sealed class PlayerLog with _$PlayerLog {
  const PlayerLog._();

  const factory PlayerLog({required PlayerLogLevel level, required String prefix, required String text}) = _PlayerLog;

  @override
  String toString() => '[$prefix] ${level.name}: $text';
}

@freezed
sealed class Media with _$Media {
  const factory Media(String uri, {Map<String, String>? headers, Duration? start}) = _Media;
}
