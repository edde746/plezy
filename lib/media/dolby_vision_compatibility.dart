import 'media_display_criteria.dart';
import '../mpv/models.dart';

/// Profile-aware gate shared by the playback backends. A color range alone is
/// not enough to request Dolby Vision conversion: HDR10 and HLG streams can
/// carry similar color tags without being Dolby Vision sources.
bool shouldRequestCompatibleDolbyVisionRendition({
  required bool requested,
  required MediaDisplayCriteria? source,
  Set<int> supportedNativeProfiles = const {},
  bool allowExperimentalProfile7 = false,
}) {
  if (!requested || source?.hasDolbyVision != true) return false;

  final profile = source!.doviProfile;
  if (profile != null && supportedNativeProfiles.contains(profile)) return false;
  if (profile == 7 && allowExperimentalProfile7) return false;
  return true;
}

/// A server request for SDR is only a request. Before a Dolby Vision
/// compatibility transcode is handed to a player, require its HLS master
/// playlist to explicitly describe every video variant as SDR. This checks
/// the server's output signaling; it does not claim Dolby-reference pixel
/// accuracy or prove that a misconfigured transcoder tone-mapped correctly.
bool hlsMasterDeclaresSdrVideoOutput(String manifest) {
  if (!manifest.trimLeft().startsWith('#EXTM3U')) return false;

  final variants = RegExp(r'^#EXT-X-STREAM-INF:(.*)$', multiLine: true).allMatches(manifest);
  if (variants.isEmpty) return false;

  final sdrRange = RegExp(r'(?:^|,)VIDEO-RANGE=(?:"SDR"|SDR)(?:,|$)', caseSensitive: false);
  return variants.every((variant) => sdrRange.hasMatch(variant.group(1)!.trim()));
}

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
