import 'dart:async';
import 'dart:io' show Platform;

import 'package:uuid/uuid.dart';

import '../../exceptions/media_server_exceptions.dart';
import '../../media/media_source_info.dart';
import '../../models/transcode_quality_preset.dart';
import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../../utils/codec_utils.dart';
import '../../utils/track_label_builder.dart';
import '../playback_initialization_types.dart';
import '../video_decode_capabilities.dart';
import 'silo_api.dart';
import 'silo_json.dart';

const _protocolVersion = 3;
const _uuid = Uuid();

/// Client feature tokens Plezy implements (playback protocol v3).
///
/// Deliberately absent: `seek_reanchor_v1` and `direct_stream_resume_v1`.
/// Plezy's player seeks inside whatever stream it was given and has no hook
/// to re-anchor a copy remux outside its window, so it does not claim to.
List<String> siloClientFeatures(Set<String> serverFeatures) => [
  'playback_plan_v3',
  'neutral_playback_v3_contract_v1',
  'playback_route_diagnostics',
  'embedded_subtitles_v1',
  if (serverFeatures.contains('header_authenticated_media_v1')) 'header_authenticated_media_v1',
];

/// What Plezy's mpv/FFmpeg build decodes. Plezy ships a full FFmpeg build on
/// every platform, so this is the `declared` evidence tier (flat decoder
/// lists, no per-profile bounds) — the same tier Silo's Apple client uses for
/// its FFmpeg player. HEVC and AV1 honour the user's refusal setting and the
/// Android hardware probe through [VideoDecodeCapabilities].
class SiloEngineCapabilities {
  static List<String> videoCodecs() => [
    'h264',
    if (VideoDecodeCapabilities.accepts(RankedVideoCodec.hevc)) 'hevc',
    if (VideoDecodeCapabilities.accepts(RankedVideoCodec.av1)) 'av1',
    'vp9',
    'vp8',
    'mpeg2video',
    'mpeg4',
    'vc1',
    'msmpeg4v3',
  ];

  static const audioCodecs = [
    'aac',
    'ac3',
    'eac3',
    'dts',
    'truehd',
    'flac',
    'mp3',
    'opus',
    'vorbis',
    'alac',
    'pcm_s16le',
    'pcm_s24le',
    'mp2',
  ];

  static const originalContainers = ['mkv', 'mp4', 'mov', 'webm', 'avi', 'mpegts', 'm2ts', 'ts', 'wmv', 'flv', 'ogg'];

  static const subtitleCodecs = ['subrip', 'ass', 'ssa', 'webvtt', 'mov_text', 'hdmv_pgs_subtitle', 'dvd_subtitle'];
}

class SiloCapabilitySnapshot {
  final List<String> features;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> context;

  const SiloCapabilitySnapshot({required this.features, required this.capabilities, required this.context});
}

SiloCapabilitySnapshot buildSiloCapabilitySnapshot({
  required Set<String> serverFeatures,
  required String appVersion,
  required String platform,
}) {
  final video = SiloEngineCapabilities.videoCodecs();
  const audio = SiloEngineCapabilities.audioCodecs;
  final packagedVideo = [
    for (final c in ['h264', 'hevc', 'av1'])
      if (video.contains(c)) c,
  ];
  const packagedAudio = ['aac', 'ac3', 'eac3', 'mp3', 'opus', 'flac'];

  Map<String, dynamic> subtitles({required bool original}) => {
    'ass_styling': true,
    'embedded_bitmap': original,
    'embedded_text': true,
    'font_attachments': true,
    'sidecar_bitmap': true,
    'sidecar_text': true,
    if (original)
      'native_embedded': [
        {
          'container': 'mkv',
          'codecs': ['subrip', 'ass', 'ssa', 'webvtt', 'hdmv_pgs_subtitle', 'dvd_subtitle'],
          'track_identity': 'ffmpeg_stream_index',
          'ass_styling': true,
          'font_attachments': true,
        },
        {
          'container': 'mp4',
          'codecs': ['mov_text'],
          'track_identity': 'ffmpeg_stream_index',
          'ass_styling': false,
          'font_attachments': false,
        },
      ],
  };

  Map<String, dynamic> delivery({
    required List<String> containers,
    required List<String> videoCodecs,
    required List<String> audioCodecs,
    required bool original,
  }) => {
    'enabled': true,
    'supported_on_device': true,
    'containers': containers,
    'video_codecs': videoCodecs,
    'audio_decode_codecs': audioCodecs,
    'audio_passthrough_codecs': <String>[],
    'max_channels': 8,
    'subtitles': subtitles(original: original),
    'features': <String>[],
    'auth_header_refresh': false,
    // mpv picks the audio stream itself and tone-maps HDR to SDR.
    'validated_claims': original
        ? ['client_selected_audio_track_v1', 'client_managed_dynamic_range_v1']
        : <String>[],
    'transformations': <Object>[],
  };

  final capabilities = {
    'video_evidence': 'declared',
    'audio_evidence': 'declared',
    'codecs_video': video,
    'codecs_video_hardware': <String>[],
    'codecs_audio': audio,
    'containers': SiloEngineCapabilities.originalContainers,
    'max_resolution': '2160p',
    'hdr': false,
  };

  final context = {
    'protocol_version': _protocolVersion,
    'form_factor': _formFactor(),
    'app_version': _clip(appVersion, 64),
    'app_channel': 'stable',
    'device': {
      'platform': _clip(platform.toLowerCase(), 32),
      'os_version': _clip(_osVersion(), 128),
      'platform_details': {'engine': 'libmpv', 'os_name': _clip(platform.toLowerCase(), 64)},
    },
    'output': {
      'hdr_details': {'hdr10': false, 'hdr10_plus': false, 'hlg': false, 'dolby_vision_profiles': <int>[]},
      'display': {'hdr_evidence': 'unknown'},
      'current_sink': 'default',
      'sink_type': 'system_mixer',
      'output_context_id': '${platform.toLowerCase()}:sdr:default',
    },
    'deliveries': {
      'original_http': delivery(
        containers: SiloEngineCapabilities.originalContainers,
        videoCodecs: video,
        audioCodecs: audio,
        original: true,
      ),
      'progressive': delivery(
        containers: const ['mp4', 'mkv'],
        videoCodecs: packagedVideo,
        audioCodecs: packagedAudio,
        original: false,
      ),
      'hls': delivery(
        containers: const ['hls', 'mpegts', 'fmp4', 'mp4'],
        videoCodecs: packagedVideo,
        audioCodecs: packagedAudio,
        original: false,
      ),
    },
  };

  return SiloCapabilitySnapshot(features: siloClientFeatures(serverFeatures), capabilities: capabilities, context: context);
}

String _formFactor() {
  try {
    if (Platform.isAndroid || Platform.isIOS) return 'mobile';
  } catch (_) {}
  return 'desktop';
}

String _osVersion() {
  try {
    return Platform.operatingSystemVersion;
  } catch (_) {
    return 'unknown';
  }
}

String _clip(String value, int max) => value.length <= max ? value : value.substring(0, max);

/// `auto` lets the server direct-play whenever the file fits; any other
/// Plezy preset names its resolution rung.
String siloQualityPreference(TranscodeQualityPreset preset) {
  if (preset.isOriginal) return 'auto';
  final height = preset.resolutionHeight;
  return height == null ? 'auto' : '${height}p';
}

// ------------------------------------------------------------------ plans

/// The parts of a playable decision Plezy needs.
class SiloPlan {
  final String sessionId;
  final String installationId;
  final String attemptId;
  final String planId;
  final String planAttemptKey;

  /// original_http, server_remux_progressive, server_remux_hls,
  /// server_transcode_hls.
  final String delivery;
  final String streamUrl;
  final String fileId;

  /// `source = player + timelineOffsetSeconds`.
  final double timelineOffsetSeconds;
  final double playerStartSeconds;
  final double? sourceDurationSeconds;

  final Map<String, dynamic> selectedAudio;
  final Map<String, dynamic> subtitle;

  const SiloPlan({
    required this.sessionId,
    required this.installationId,
    required this.attemptId,
    required this.planId,
    required this.planAttemptKey,
    required this.delivery,
    required this.streamUrl,
    required this.fileId,
    required this.timelineOffsetSeconds,
    required this.playerStartSeconds,
    required this.sourceDurationSeconds,
    required this.selectedAudio,
    required this.subtitle,
  });

  bool get isOriginal => delivery == 'original_http';
  bool get isTranscode => delivery == 'server_transcode_hls';

  /// Plezy's play-method vocabulary (shown in the player's info overlay).
  String get playMethod => switch (delivery) {
    'original_http' => 'DirectPlay',
    'server_transcode_hls' => 'Transcode',
    _ => 'DirectStream',
  };

  static SiloPlan? fromDecision(Map<String, dynamic> decision, {required String installationId, required String attemptId}) {
    final plan = asMap(decision['playback_plan']);
    if (str(decision['outcome']) != 'playable' || plan.isEmpty) return null;
    final sessionId = strOrNull(plan['session_id']) ?? strOrNull(decision['session_id']);
    final stream = asMap(plan['stream']);
    final url = strOrNull(stream['url']);
    if (sessionId == null || url == null) return null;
    final timeline = asMap(plan['timeline']);
    final source = asMap(plan['source']);
    return SiloPlan(
      sessionId: sessionId,
      installationId: installationId,
      attemptId: attemptId,
      planId: str(plan['plan_id']),
      planAttemptKey: str(plan['plan_attempt_key']),
      delivery: str(plan['delivery']),
      streamUrl: url,
      fileId: strOrNull(plan['effective_media_file_id']) ?? str(source['media_file_id']),
      timelineOffsetSeconds: doubleOrNull(timeline['timeline_offset_seconds']) ?? 0,
      playerStartSeconds: doubleOrNull(timeline['player_start_seconds']) ?? 0,
      sourceDurationSeconds: doubleOrNull(source['duration_seconds']),
      selectedAudio: asMap(asMap(plan['selected_tracks'])['audio']),
      subtitle: asMap(plan['subtitle']),
    );
  }
}

/// Raised when the server refused to make a title playable for this device
/// (`outcome: adaptation_unavailable`). [message] is the server's own text.
PlaybackException siloTerminalDecision(Map<String, dynamic> decision) {
  final terminal = asMap(decision['terminal']);
  final message = str(terminal['message']);
  return PlaybackException(
    message.isNotEmpty ? message : 'This title cannot be played on this device (${str(terminal['reason'])}).',
    reason: PlaybackFailureReason.noPlayableSource,
  );
}

// ------------------------------------------------------------- start body

Map<String, dynamic> buildSiloStartBody({
  required String installationId,
  required String attemptId,
  required String fileId,
  required String profileId,
  required String qualityPreference,
  required SiloCapabilitySnapshot snapshot,
  double? startPosition,
  String? audioTrackId,
  int? audioTrackIndex,
  String? subtitleTrackId,
  int? subtitleTrackIndex,
}) => {
  'protocol_version': _protocolVersion,
  'installation_id': installationId,
  'file_id': fileId,
  'profile_id': profileId,
  'playback_attempt_id': attemptId,
  'quality_preference': qualityPreference,
  'subtitle_fidelity_preference': 'preserve',
  'metered': false,
  'client_features': snapshot.features,
  'client_capabilities': snapshot.capabilities,
  'client_playback_context': snapshot.context,
  // Absent members are omitted: the v2 validator rejects explicit null.
  'start_position': ?startPosition,
  'audio_track_id': ?audioTrackId,
  'audio_track_index': ?audioTrackIndex,
  'subtitle_track_id': ?subtitleTrackId,
  'subtitle_track_index': ?subtitleTrackIndex,
};

String newSiloAttemptId() => _uuid.v4();

// --------------------------------------------------------------- tracks

/// Audio rows for the player menu, from the watch state's version. The id
/// is the ordinal + 1 (Plezy treats 0 as "unset" in places); the Silo
/// identity is `file:{fileId}:audio:{ordinal}`.
List<MediaAudioTrack> siloAudioTracks(Map<String, dynamic> version, {int? selectedOrdinal}) {
  final rows = mapList(version['audio_tracks']);
  final defaultOrdinal = selectedOrdinal ?? intOrNull(version['effective_audio_track_index']);
  return [
    for (var i = 0; i < rows.length; i++)
      MediaAudioTrack(
        id: i + 1,
        index: i,
        codec: strOrNull(rows[i]['codec']),
        language: strOrNull(rows[i]['language']),
        languageCode: strOrNull(rows[i]['language']),
        title: strOrNull(rows[i]['title']) ?? strOrNull(rows[i]['embedded_title']),
        channels: intOrNull(rows[i]['channels']),
        isDefault: boolOr(rows[i]['default']),
        selected: defaultOrdinal != null ? i == defaultOrdinal : boolOr(rows[i]['default']),
      ),
  ];
}

int? siloAudioOrdinalForTrackId(int? trackId) => trackId == null || trackId <= 0 ? null : trackId - 1;

/// Subtitle rows and sidecars from the plan's inventory, which is the only
/// authoritative list (its `combined_index` space spans external, embedded
/// and downloaded tracks). Ids are `combined_index + 1`.
///
/// On an original-file route embedded tracks are read by the player from the
/// container; external and downloaded tracks are loaded as sidecars from the
/// plan's URLs (which need the same auth headers as the stream). On a
/// packaged route the server delivers subtitles as sidecars or burns them
/// in, so every non-burned text track becomes a sidecar.
({List<MediaSubtitleTrack> tracks, List<PlaybackSubtitleSidecar> sidecars}) siloSubtitles(
  SiloPlan plan, {
  required String Function(String url) resolveUrl,
}) {
  final subtitle = plan.subtitle;
  final mode = str(subtitle['mode']);
  final selectedTrackId = strOrNull(subtitle['track_id']);
  final tracks = <MediaSubtitleTrack>[];
  final sidecars = <PlaybackSubtitleSidecar>[];
  for (final item in mapList(subtitle['inventory'])) {
    final combined = intOrNull(item['combined_index']);
    if (combined == null) continue;
    final id = combined + 1;
    final source = str(item['source']);
    final codec = strOrNull(item['codec']);
    final language = strOrNull(item['language']);
    final label = strOrNull(item['label']);
    final trackId = strOrNull(item['track_id']);
    final burnOnly = str(item['delivery']) == 'burn_in_only';
    final isEmbedded = source == 'embedded';
    final rawUrl = strOrNull(item['url']);
    final selected = trackId != null && trackId == selectedTrackId && mode != 'off';

    final asSidecar = !burnOnly &&
        rawUrl != null &&
        (plan.isOriginal ? !isEmbedded : (CodecUtils.isTextSubtitleCodec(codec) || !isEmbedded)) &&
        !(selected && mode == 'burn_in');
    final url = asSidecar ? resolveUrl(rawUrl) : null;
    tracks.add(
      MediaSubtitleTrack(
        id: id,
        index: combined,
        codec: codec,
        language: language,
        languageCode: language,
        title: label,
        selected: selected,
        forced: boolOr(item['forced']),
        key: url,
        external: !isEmbedded,
        usesExternalDelivery: url != null && isEmbedded,
      ),
    );
    if (url != null) {
      sidecars.add(
        PlaybackSubtitleSidecar(
          sourceStreamId: id,
          // Real files are cheap to fetch; extracted embedded tracks on a
          // packaged route wait until selected.
          preload: !isEmbedded,
          track: SubtitleTrack.uri(
            url,
            title: cleanSubtitleTitle(label, codec: codec) ?? cleanTrackMetadataValue(language),
            language: cleanTrackMetadataValue(language),
            codec: codec,
            isDefault: selected,
            isForced: boolOr(item['forced']),
          ),
        ),
      );
    }
  }
  return (tracks: tracks, sidecars: sidecars);
}

/// The Silo track identity of a subtitle row built by [siloSubtitles].
String? siloSubtitleTrackIdFor(SiloPlan plan, int subtitleRowId) {
  for (final item in mapList(plan.subtitle['inventory'])) {
    if (intOrNull(item['combined_index']) == subtitleRowId - 1) return strOrNull(item['track_id']);
  }
  return null;
}

// -------------------------------------------------------------- reporting

/// Progress and stop reporting for the sessions this client opened.
///
/// Plezy reports by `playSessionId`, which is the Silo session id. Each
/// session keeps its own strictly increasing `sequence` and a queue so
/// samples reach the server in order; stop carries the final sample and a
/// `stop_id` minted once, and is resent unchanged on transient failures.
/// Sessions are tied to the client (one server, one profile) that opened
/// them, so progress cannot be reported against another server or profile.
class SiloPlaybackReporter {
  SiloPlaybackReporter(this._api);

  final SiloApi _api;
  final Map<String, _ReportingSession> _sessions = {};

  void register(SiloPlan plan, {required String contentId}) {
    _sessions[plan.sessionId] = _ReportingSession(plan: plan, contentId: contentId);
  }

  SiloPlan? planFor(String? sessionId) => sessionId == null ? null : _sessions[sessionId]?.plan;

  /// The open session for [contentId], when Plezy did not echo its id.
  _ReportingSession? _sessionFor(String? sessionId, String contentId) {
    if (sessionId != null) {
      final s = _sessions[sessionId];
      return s != null && s.contentId == contentId ? s : null;
    }
    final matches = _sessions.values.where((s) => s.contentId == contentId && !s.stopped).toList();
    return matches.length == 1 ? matches.single : null;
  }

  Future<void> progress({
    required String contentId,
    required String? sessionId,
    required Duration playerPosition,
    required bool isPaused,
  }) {
    final session = _sessionFor(sessionId, contentId);
    if (session == null || session.stopped) return Future.value();
    final body = {
      'installation_id': session.plan.installationId,
      'sequence': ++session.sequence,
      'position': session.sourceSeconds(playerPosition),
      'is_paused': isPaused,
    };
    return session.enqueue(() async {
      try {
        await _api.playbackProgress(session.plan.sessionId, body);
      } on MediaServerHttpException catch (e) {
        _handleReportError(session, e);
      }
    });
  }

  Future<void> stop({
    required String contentId,
    required String? sessionId,
    required Duration playerPosition,
    Duration? duration,
  }) {
    final session = _sessionFor(sessionId, contentId);
    if (session == null || session.stopped) return Future.value();
    session.stopped = true;
    var position = session.sourceSeconds(playerPosition);
    // At the end of the file report the full runtime, so the server's
    // watched threshold applies to what was actually watched.
    final runtime = session.plan.sourceDurationSeconds;
    if (runtime != null && runtime > 0 && position >= runtime - 1.5) position = runtime;
    final body = {
      'installation_id': session.plan.installationId,
      'stop_id': session.stopId,
      'sequence': ++session.sequence,
      'position': position,
      'is_paused': true,
    };
    return session.enqueue(() async {
      try {
        final receipt = await _api.stopPlayback(session.plan.sessionId, body);
        appLogger.d('Silo: playback stopped (${str(receipt['outcome'])})');
      } on MediaServerHttpException catch (e) {
        // 404/410: the server already ended the session; nothing to do.
        if (e.statusCode != 404 && e.statusCode != 410) {
          appLogger.w('Silo: stop report failed', error: e);
        }
      } catch (e) {
        appLogger.w('Silo: stop report failed', error: e);
      } finally {
        _sessions.remove(session.plan.sessionId);
      }
    });
  }

  void _handleReportError(_ReportingSession session, MediaServerHttpException e) {
    switch (e.statusCode) {
      case 410:
        session.stopped = true;
        _sessions.remove(session.plan.sessionId);
        throw PlaybackSessionTerminatedException(code: 410, reason: 'The server ended this playback session.');
      case 404:
        // Expired after inactivity. Plezy reopens playback on its own error
        // paths; reporting into a dead session would only repeat the 404.
        session.stopped = true;
        _sessions.remove(session.plan.sessionId);
        appLogger.w('Silo: playback session expired on the server');
      default:
        appLogger.w('Silo: progress report failed', error: e);
    }
  }

  /// Stop every open session (client teardown).
  Future<void> stopAll() async {
    final open = _sessions.values.where((s) => !s.stopped).toList();
    for (final session in open) {
      await stop(contentId: session.contentId, sessionId: session.plan.sessionId, playerPosition: session.lastPlayer);
    }
  }
}

class _ReportingSession {
  _ReportingSession({required this.plan, required this.contentId}) : stopId = _uuid.v4();

  final SiloPlan plan;
  final String contentId;
  final String stopId;
  int sequence = 0;
  bool stopped = false;
  Duration lastPlayer = Duration.zero;
  Future<void> _tail = Future.value();

  double sourceSeconds(Duration player) {
    lastPlayer = player;
    final seconds = player.inMilliseconds / 1000 + plan.timelineOffsetSeconds;
    return seconds < 0 ? 0 : double.parse(seconds.toStringAsFixed(3));
  }

  Future<void> enqueue(Future<void> Function() send) {
    final next = _tail.then((_) => send());
    _tail = next.catchError((Object _) {});
    return next;
  }
}
