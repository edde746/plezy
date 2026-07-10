import '../../database/app_database.dart';
import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../media/media_source_info.dart';
import '../../models/transcode_quality_preset.dart';
import '../../utils/session_identifier.dart';
import '../multi_server_manager.dart';
import '../playback_initialization_service.dart';
import '../playback_source_resolver.dart';
import '../settings_service.dart';

/// Everything the music engine needs to open and report one track.
class MusicSource {
  /// Playable stream URL (or `file://` path for downloaded tracks).
  final String url;

  /// HTTP headers to open [url] with (Plex identity headers; null for
  /// local files and backends that self-authenticate via the query string).
  final Map<String, String>? headers;

  /// Server playback session id to echo in progress reports.
  final String? playSessionId;

  /// `DirectPlay` / `Transcode` for progress reports.
  final String? playMethod;

  final int selectedMediaIndex;
  final String? selectedMediaSourceId;

  /// True when [url] points at a downloaded/local copy.
  final bool isOffline;

  final MediaSourceInfo? mediaInfo;

  /// Client that should receive progress reports for this track (null when
  /// its server is unreachable — offline reports queue locally instead).
  final MediaServerClient? reportingClient;

  const MusicSource({
    required this.url,
    this.headers,
    this.playSessionId,
    this.playMethod,
    this.selectedMediaIndex = 0,
    this.selectedMediaSourceId,
    this.isOffline = false,
    this.mediaInfo,
    this.reportingClient,
  });
}

/// Seam between the music engine and playback initialization, so tests can
/// inject synthetic sources without any network or database.
abstract class MusicSourceResolver {
  Future<MusicSource> resolve(MediaItem track);
}

/// Production resolver: delegates to the shared [PlaybackSourceResolver] /
/// [PlaybackInitializationService] pipeline, which routes
/// [MediaKind.track] items down the per-backend audio path (music transcode
/// preset) and substitutes downloaded copies before touching the network.
class ServerMusicSourceResolver implements MusicSourceResolver {
  final MultiServerManager serverManager;
  final AppDatabase database;

  ServerMusicSourceResolver({required this.serverManager, required this.database});

  @override
  Future<MusicSource> resolve(MediaItem track) async {
    final settings = await SettingsService.getInstance();
    final context = await PlaybackSourceResolver(serverManager: serverManager, database: database).resolve(
      metadata: track,
      selectedMediaIndex: 0,
      offlineLibraryMode: false,
      // Video-shaped preset is ignored for tracks; `original` also keeps the
      // resolver's downloaded-copy preference on.
      qualityPreset: TranscodeQualityPreset.original,
      audioQualityPreset: settings.read(SettingsService.musicQualityPreset),
      // Plex music transcode requires both session ids; fresh per track so
      // concurrent gapless arming never reuses a live transcode session.
      sessionIdentifier: generateSessionIdentifier(),
      transcodeSessionId: generateSessionIdentifier(),
    );

    final result = context.result;
    final url = result.videoUrl;
    if (url == null) {
      throw PlaybackException('No audio URL available for ${track.title ?? track.id}');
    }

    return MusicSource(
      url: url,
      headers: context.streamHeaders,
      playSessionId: result.playSessionId,
      playMethod: result.playMethod ?? (result.isTranscoding ? 'Transcode' : 'DirectPlay'),
      selectedMediaIndex: result.selectedMediaIndex,
      selectedMediaSourceId: result.selectedMediaSourceId,
      isOffline: result.isOffline,
      mediaInfo: result.mediaInfo,
      reportingClient: context.reportingClient,
    );
  }
}
