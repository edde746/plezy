import '../media/media_item.dart';
import '../media/media_server_client.dart';
import 'playback_initialization_types.dart';

enum PlaybackSourceKind { localFile, remoteDirect, remoteTranscode }

enum PlaybackReportingMode { online, offlineQueue, onlineWithOfflineFallback, localOnly, disabled }

typedef ExternalPlaybackRenewal = Future<({Uri uri, Map<String, String> headers})> Function();

/// A short-lived source selected from a connected provider for a real library
/// item. The descriptor is memory-only: signed URLs and request headers must
/// never become part of queue state, playback metadata, logs, or persistence.
class ExternalPlaybackSource {
  ExternalPlaybackSource({
    required this.mediaGlobalKey,
    required this.profileId,
    required this.uri,
    Map<String, String> headers = const {},
    this.renew,
    this.subtitleUri,
    this.subtitleTitle,
    this.subtitleLanguage,
    this.subtitleRenew,
  }) : headers = Map.unmodifiable(headers);

  final String mediaGlobalKey;
  final String profileId;
  final Uri uri;
  final Map<String, String> headers;
  final ExternalPlaybackRenewal? renew;
  final Uri? subtitleUri;
  final String? subtitleTitle;
  final String? subtitleLanguage;
  final ExternalPlaybackRenewal? subtitleRenew;

  @override
  String toString() => 'ExternalPlaybackSource(media: $mediaGlobalKey, uri: <redacted>)';
}

class PlaybackContext {
  final MediaItem metadata;
  final PlaybackInitializationResult result;
  final PlaybackSourceKind sourceKind;
  final PlaybackReportingMode reportingMode;
  final MediaServerClient? reportingClient;
  final Map<String, String>? streamHeaders;

  const PlaybackContext({
    required this.metadata,
    required this.result,
    required this.sourceKind,
    required this.reportingMode,
    this.reportingClient,
    this.streamHeaders,
  });

  PlaybackContext copyWith({PlaybackInitializationResult? result}) => PlaybackContext(
    metadata: metadata,
    result: result ?? this.result,
    sourceKind: sourceKind,
    reportingMode: reportingMode,
    reportingClient: reportingClient,
    streamHeaders: streamHeaders,
  );

  bool get usesLocalMedia => sourceKind == PlaybackSourceKind.localFile;
  bool get shouldQueueOnReportFailure => reportingMode == PlaybackReportingMode.onlineWithOfflineFallback;
  bool get recordsLocalProgress => reportingMode == PlaybackReportingMode.localOnly;
}
