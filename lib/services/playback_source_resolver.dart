import '../database/app_database.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../models/transcode_quality_preset.dart';
import 'multi_server_manager.dart';
import 'playback_context.dart';
import 'playback_initialization_service.dart';

class PlaybackSourceResolver {
  final MultiServerManager serverManager;
  final AppDatabase database;

  const PlaybackSourceResolver({required this.serverManager, required this.database});

  Future<PlaybackContext> resolve({
    required MediaItem metadata,
    required int selectedMediaIndex,
    String? selectedMediaSourceId,
    required bool offlineLibraryMode,
    required TranscodeQualityPreset qualityPreset,
    int? selectedAudioStreamId,
    String? sessionIdentifier,
    String? transcodeSessionId,
  }) async {
    final reportingClient = _playbackClient(metadata.serverId, offlineLibraryMode: offlineLibraryMode);
    final service = PlaybackInitializationService(client: reportingClient, database: database);
    final result = await service.getPlaybackData(
      metadata: metadata,
      selectedMediaIndex: selectedMediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
      preferOffline: offlineLibraryMode || qualityPreset.isOriginal,
      qualityPreset: qualityPreset,
      selectedAudioStreamId: selectedAudioStreamId,
      sessionIdentifier: sessionIdentifier,
      transcodeSessionId: transcodeSessionId,
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
    final scopeId = reportingClient?.cacheServerId;

    return PlaybackContext(
      metadata: metadata,
      result: result,
      sourceKind: sourceKind,
      reportingMode: reportingMode,
      reportingClient: reportingClient,
      clientScopeId: scopeId == metadata.serverId ? null : scopeId,
      streamHeaders: _streamHeaders(
        client: reportingClient,
        sourceKind: sourceKind,
        sessionIdentifier: sessionIdentifier,
      ),
    );
  }

  Map<String, String>? _streamHeaders({
    required MediaServerClient? client,
    required PlaybackSourceKind sourceKind,
    String? sessionIdentifier,
  }) {
    if (client == null || sourceKind == PlaybackSourceKind.localFile) return null;

    final headers = Map<String, String>.from(client.streamHeaders);
    if (client.backend == MediaBackend.plex && sessionIdentifier != null) {
      headers['X-Plex-Session-Identifier'] = sessionIdentifier;
    }
    return headers;
  }

  MediaServerClient? _playbackClient(String? serverId, {required bool offlineLibraryMode}) {
    if (serverId == null) return null;
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
