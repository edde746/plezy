import '../media/media_item.dart';
import '../media/media_server_client.dart';
import 'playback_initialization_types.dart';

enum PlaybackSourceKind { localFile, remoteDirect, remoteTranscode }

enum PlaybackReportingMode { online, offlineQueue, onlineWithOfflineFallback, disabled }

class PlaybackContext {
  final MediaItem metadata;
  final PlaybackInitializationResult result;
  final PlaybackSourceKind sourceKind;
  final PlaybackReportingMode reportingMode;
  final MediaServerClient? reportingClient;
  final String? clientScopeId;
  final Map<String, String>? streamHeaders;

  const PlaybackContext({
    required this.metadata,
    required this.result,
    required this.sourceKind,
    required this.reportingMode,
    this.reportingClient,
    this.clientScopeId,
    this.streamHeaders,
  });

  bool get usesLocalMedia => sourceKind == PlaybackSourceKind.localFile;
  bool get shouldQueueOnReportFailure => reportingMode == PlaybackReportingMode.onlineWithOfflineFallback;
  bool get shouldQueueOnly => reportingMode == PlaybackReportingMode.offlineQueue;
}
