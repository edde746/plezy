import '../database/app_database.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import 'multi_server_manager.dart';
import 'playback_context.dart';
import 'playback_initialization_service.dart';

class PlaybackSourceResolver {
  final MultiServerManager serverManager;
  final AppDatabase database;

  const PlaybackSourceResolver({required this.serverManager, required this.database});

  /// Prefers a downloaded copy when in offline library mode, when the
  /// requested quality preset is original (an omitted preset keeps it on), or
  /// when [downloadOutranksQuality] says the preset carries no user intent a
  /// local copy would violate — the saved startup default rather than a
  /// quality picked for this playback (issue #2466).
  Future<PlaybackContext> resolve(
    PlaybackInitializationOptions options, {
    required bool offlineLibraryMode,
    bool downloadOutranksQuality = false,
  }) async {
    final metadata = options.metadata;
    final reportingClient = _playbackClient(serverIdOrNull(metadata.serverId), offlineLibraryMode: offlineLibraryMode);
    final service = PlaybackInitializationService(client: reportingClient, database: database);
    final result = await service.getPlaybackData(
      options,
      preferOffline: offlineLibraryMode || options.qualityPreset.isOriginal || downloadOutranksQuality,
      requireOffline: offlineLibraryMode,
    );

    final sourceKind = result.usesLocalMedia
        ? PlaybackSourceKind.localFile
        : result.isTranscoding
        ? PlaybackSourceKind.remoteTranscode
        : PlaybackSourceKind.remoteDirect;
    final reportingMode = _reportingMode(
      sourceKind: sourceKind,
      client: reportingClient,
      offlineLibraryMode: offlineLibraryMode,
    );
    return PlaybackContext(
      metadata: metadata,
      result: result,
      sourceKind: sourceKind,
      reportingMode: reportingMode,
      reportingClient: reportingClient,
      streamHeaders: _streamHeaders(
        client: reportingClient,
        sourceKind: sourceKind,
        sessionIdentifier: options.sessionIdentifier,
        trackStreamUrl: metadata.kind == MediaKind.track ? result.videoUrl : null,
      ),
    );
  }

  /// [trackStreamUrl] is the stream URL when it plays a track. A track that
  /// names its Plex session in that URL gets no session header: gapless
  /// playback opens the next track with the playing track's headers, so the
  /// header would reach the next track's stream naming the wrong session
  /// (PMS refuses a music transcode start for that with HTTP 400), and it
  /// would make every track's headers differ from the rest of its server's.
  Map<String, String>? _streamHeaders({
    required MediaServerClient? client,
    required PlaybackSourceKind sourceKind,
    String? sessionIdentifier,
    String? trackStreamUrl,
  }) {
    if (client == null || sourceKind == PlaybackSourceKind.localFile) return null;

    final headers = Map<String, String>.from(client.streamHeaders);
    if (client.backend == MediaBackend.plex &&
        sessionIdentifier != null &&
        Uri.tryParse(trackStreamUrl ?? '')?.queryParameters['X-Plex-Session-Identifier'] != sessionIdentifier) {
      headers['X-Plex-Session-Identifier'] = sessionIdentifier;
    }
    return headers;
  }

  MediaServerClient? _playbackClient(ServerId? serverId, {required bool offlineLibraryMode}) {
    if (serverId == null ||
        !serverManager.isServerVisible(serverId) ||
        serverManager.refusedServerIds.contains(serverId)) {
      return null;
    }
    final client = serverManager.getClient(serverId);
    if (offlineLibraryMode && !serverManager.isClientOnline(serverId)) return null;
    return client;
  }

  PlaybackReportingMode _reportingMode({
    required PlaybackSourceKind sourceKind,
    required MediaServerClient? client,
    required bool offlineLibraryMode,
  }) {
    if (client != null) {
      return sourceKind == PlaybackSourceKind.localFile
          ? PlaybackReportingMode.onlineWithOfflineFallback
          : PlaybackReportingMode.online;
    }
    if (sourceKind == PlaybackSourceKind.localFile || offlineLibraryMode) return PlaybackReportingMode.offlineQueue;
    return PlaybackReportingMode.disabled;
  }
}
