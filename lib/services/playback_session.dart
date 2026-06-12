import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import '../media/media_version.dart';
import '../models/transcode_quality_preset.dart';
import 'playback_context.dart';
import 'playback_initialization_types.dart';

/// Immutable snapshot of everything that describes the item currently loaded
/// in the player: the resolver output plus the effective (post-fallback,
/// post-clamping) source selections.
///
/// Built once per resolve and swapped atomically on the screen — failure
/// before the swap means the previous session (and the state derived from
/// it) stays untouched, which replaces the old field-by-field
/// snapshot/rollback bookkeeping.
class PlaybackSession {
  final PlaybackContext context;

  /// Effective quality preset — the requested preset, downgraded to
  /// original when the backend reported a transcode fallback.
  final TranscodeQualityPreset qualityPreset;

  /// Effective media version id, refined from the resolver's clamped
  /// version index when the version list provides one.
  final String? mediaSourceId;

  const PlaybackSession({required this.context, required this.qualityPreset, this.mediaSourceId});

  /// Derives the effective selections from a resolved [context]:
  /// quality falls back to original when the backend rejected the requested
  /// preset, and the media source id follows the clamped version index.
  factory PlaybackSession.fromContext(
    PlaybackContext context, {
    required TranscodeQualityPreset requestedQualityPreset,
    String? requestedMediaSourceId,
  }) {
    final result = context.result;
    final fellBackToOriginal = result.fallbackReason != null && !requestedQualityPreset.isOriginal;
    return PlaybackSession(
      context: context,
      qualityPreset: fellBackToOriginal ? TranscodeQualityPreset.original : requestedQualityPreset,
      mediaSourceId:
          mediaSourceIdForIndex(result.availableVersions, result.selectedMediaIndex) ?? requestedMediaSourceId,
    );
  }

  static String? mediaSourceIdForIndex(List<MediaVersion> versions, int index) {
    if (index < 0 || index >= versions.length) return null;
    return versions[index].id;
  }

  PlaybackInitializationResult get result => context.result;

  MediaItem get metadata => context.metadata;

  MediaServerClient? get reportingClient => context.reportingClient;

  bool get isTranscoding => result.isTranscoding;

  bool get isOffline => result.isOffline;

  String? get playSessionId => result.playSessionId;

  String? get playMethod => result.playMethod;

  int? get audioStreamId => result.activeAudioStreamId;

  int get mediaIndex => result.selectedMediaIndex;

  List<MediaVersion> get availableVersions => result.availableVersions;

  MediaSourceInfo? get mediaInfo => result.mediaInfo;

  Map<String, String>? get streamHeaders => context.streamHeaders;
}
