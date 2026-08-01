import '../database/app_database.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_server_client.dart';
import 'multi_server_manager.dart';
import 'playback_context.dart';
import 'playback_initialization_service.dart';

class PlaybackSourceResolver {
  final MultiServerManager serverManager;
  final AppDatabase database;

  const PlaybackSourceResolver({required this.serverManager, required this.database});

  /// [preferOffline] overrides the default downloaded-copy preference
  /// (`offlineLibraryMode || options.qualityPreset.isOriginal`, so an omitted
  /// preset keeps it on). Pass false for flows that must stay on the server
  /// stream, e.g. a transcode restart.
  Future<PlaybackContext> resolve(
    PlaybackInitializationOptions options, {
    required bool offlineLibraryMode,
    bool? preferOffline,
  }) async {
    final metadata = options.metadata;
    final reportingClient = _playbackClient(serverIdOrNull(metadata.serverId), offlineLibraryMode: offlineLibraryMode);
    final service = PlaybackInitializationService(client: reportingClient, database: database);
    final result = await service.getPlaybackData(
      options,
      preferOffline: preferOffline ?? (offlineLibraryMode || options.qualityPreset.isOriginal),
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
        sessionIdentifier: options.sessionIdentifier,
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

  MediaServerClient? _playbackClient(ServerId? serverId, {required bool offlineLibraryMode}) {
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
