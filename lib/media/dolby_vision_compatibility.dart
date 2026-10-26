import 'media_display_criteria.dart';
import '../mpv/models.dart';

/// Profile-aware gate shared by the playback backends. A color range alone is
/// not enough to request Dolby Vision conversion: HDR10 and HLG streams can
/// carry similar color tags without being Dolby Vision sources.
bool shouldRequestCompatibleDolbyVisionRendition({required bool requested, required MediaDisplayCriteria? source}) =>
    requested && source?.hasDolbyVision == true;

/// Keep the native or device-local DV route first. If that route cannot
/// initialize an identified DV source, retry once through the media server's
/// video transcoder, provided the source is online and the backend supports
/// video transcoding. These narrow causes avoid hiding network, permission,
/// missing-file, or audio-output failures behind an unrelated transcode.
bool shouldAttemptAutomaticDolbyVisionCompatibilityFallback({
  required MediaDisplayCriteria? source,
  required bool isOnline,
  required bool isLive,
  required bool serverSupportsTranscoding,
  required bool alreadyTranscoding,
  required bool alreadyAttempted,
  required Set<int> fatalHttpStatuses,
  required String? failureCause,
}) {
  if (source?.hasDolbyVision != true ||
      !isOnline ||
      isLive ||
      !serverSupportsTranscoding ||
      alreadyTranscoding ||
      alreadyAttempted ||
      fatalHttpStatuses.isNotEmpty) {
    return false;
  }

  return failureCause == PlayerError.streamInitFailed || failureCause == PlayerError.openTimedOut;
}
