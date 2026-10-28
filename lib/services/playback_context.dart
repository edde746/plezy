import '../media/media_item.dart';
import '../media/media_server_client.dart';
import 'playback_initialization_types.dart';

enum PlaybackSourceKind { localFile, remoteDirect, remoteTranscode }

enum PlaybackReportingMode { online, offlineQueue, onlineWithOfflineFallback, localOnly, disabled }

typedef ExternalPlaybackRenewal = Future<({Uri uri, Map<String, String> headers})> Function();
typedef ExternalPlaybackProgress = Future<void> Function(String state, Duration position, Duration duration);
typedef ExternalPlaybackRelease = Future<void> Function();
typedef ExternalPlaybackSourceResolver = Future<ExternalPlaybackSource?> Function(MediaItem metadata);

/// A short-lived stream selected from a connected provider. The descriptor is
/// memory-only: signed URLs and request headers must never become part of
/// queue state, playback metadata, logs, or persistence.
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
    this.onProgress,
    this.initialPosition = Duration.zero,
    ExternalPlaybackRelease? onRelease,
  }) : headers = Map.unmodifiable(headers),
       _releaseCallback = onRelease;

  final String mediaGlobalKey;
  final String profileId;
  final Uri uri;
  final Map<String, String> headers;
  final ExternalPlaybackRenewal? renew;
  final Uri? subtitleUri;
  final String? subtitleTitle;
  final String? subtitleLanguage;
  final ExternalPlaybackRenewal? subtitleRenew;

  /// Resume position resolved by the source journal before the native player
  /// is opened. Queue transitions use it for source-owned resume state.
  final Duration initialPosition;

  /// Optional owner for progress from a connected source that is not a server
  /// library item. Server matched playback continues to use its normal watch
  /// queue; a standalone cloud file can keep progress in its source journal.
  final ExternalPlaybackProgress? onProgress;

  /// Releases source-owned progress/session state when this lease stops being
  /// the committed player source.
  final ExternalPlaybackRelease? _releaseCallback;
  Future<void>? _releaseFuture;
  bool get isReleased => _releaseFuture != null;
  ExternalPlaybackRelease? get onRelease => release;
  Future<void> release() => _releaseFuture ??= Future<void>.sync(() async {
    await _releaseCallback?.call();
  });

  /// Only local-source adapters and completed downloads produce these URIs.
  /// Remote add-on/provider parsers continue to accept HTTP(S) only.
  bool get isLocal => const {'file', 'content'}.contains(uri.scheme);

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
