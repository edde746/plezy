// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';

@freezed
sealed class BufferRange with _$BufferRange {
  const factory BufferRange({required Duration start, required Duration end}) = _BufferRange;
}

final RegExp _httpStatusPattern = RegExp(r'\b(?:HTTP error |Response code: )(\d{3})\b');

/// Server statuses that end playback outright: nothing client-side recovers a
/// transcoding-limit rejection or a file the server cannot read. Everything
/// else (notably the 503 the reconnect path retries) is transient.
const Set<int> fatalPlaybackHttpStatuses = {404, 500};

/// [cause] is an optional machine-readable tag (e.g. `server-http-500`),
/// letting the UI branch without parsing [message].
@Freezed(toStringOverride: false)
sealed class PlayerError with _$PlayerError {
  const PlayerError._();

  const factory PlayerError(String message, {String? cause}) = _PlayerError;

  /// Cause tag for a server-side HTTP 500 — shared-user bandwidth or
  /// transcoding limit rejection set by the server owner.
  static const String serverHttp500 = 'server-http-500';

  /// Cause tag for a server-side HTTP 404 on the media stream. The server
  /// resolved the item but cannot read the file behind it (moved, deleted, or
  /// on unavailable storage), so no retry or backend switch can recover it.
  static const String serverHttp404 = 'server-http-404';

  /// HTTP status [logText] reports, or null when it names none.
  ///
  /// A [PlayerError] carries no status field: mpv only ever tells us the
  /// end-file reason. ffmpeg does log the status, one warn-level line ahead of
  /// the error-level failure (`http: HTTP error 404 Not Found`), and media3's
  /// exception chain stringifies it as `Response code: 404`, so scanning the
  /// player's own log stream is the only way to recover it.
  static int? httpStatusFromLog(String logText) {
    final match = _httpStatusPattern.firstMatch(logText);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

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
    @Default(false) bool isContainer,
    String? uri,
  }) = _SubtitleTrack;

  factory SubtitleTrack.uri(
    String uri, {
    String? title,
    String? language,
    String? codec,
    bool isDefault = false,
    bool isForced = false,
    bool isContainer = false,
  }) => SubtitleTrack(
    id: 'external:$uri',
    title: title,
    language: language,
    codec: codec,
    isDefault: isDefault,
    isForced: isForced,
    isExternal: true,
    isContainer: isContainer,
    uri: uri,
  );

  static const auto = SubtitleTrack(id: 'auto', title: 'Auto');

  static const off = SubtitleTrack(id: 'no', title: 'Off');
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
