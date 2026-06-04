import '../media/media_display_criteria.dart';
import '../utils/json_utils.dart';

MediaDisplayCriteria? jellyfinDisplayCriteriaFromStream(
  Map<String, dynamic> source,
  Map<String, dynamic>? videoStream,
) {
  if (videoStream == null) return null;

  final doviProfile = flexibleInt(videoStream['DvProfile']);
  final doviCompatibilityId = flexibleInt(videoStream['DvBlSignalCompatibilityId']);
  final videoRangeType = videoStream['VideoRangeType']?.toString().toLowerCase();
  final videoRange = videoStream['VideoRange']?.toString().toLowerCase();
  final transfer = _stringOrNull(videoStream['ColorTransfer']);
  final primaries = _stringOrNull(videoStream['ColorPrimaries']);
  final matrix = _stringOrNull(videoStream['ColorSpace']);
  final defaults = _jellyfinDefaultDisplayColorTags(
    videoRangeType: videoRangeType,
    videoRange: videoRange,
    doviCompatibilityId: doviCompatibilityId,
    transfer: transfer,
    primaries: primaries,
    matrix: matrix,
  );
  final criteria = MediaDisplayCriteria.fromRaw(
    fps: videoStream['RealFrameRate'] ?? videoStream['AverageFrameRate'],
    width: videoStream['Width'] ?? source['Width'],
    height: videoStream['Height'] ?? source['Height'],
    doviProfile: doviProfile,
    doviLevel: videoStream['DvLevel'],
    doviCompatibilityId: doviCompatibilityId,
    transfer: transfer ?? defaults.transfer,
    primaries: primaries ?? defaults.primaries,
    matrix: matrix ?? defaults.matrix,
  );
  return criteria.isUsable ? criteria : null;
}

bool jellyfinVideoStreamIsDolbyVision(Map<String, dynamic> videoStream) {
  final profile = jellyfinDolbyVisionProfile(videoStream);
  if (profile != null && profile > 0) return true;
  if ((flexibleInt(videoStream['DvVersionMajor']) ?? 0) > 0) return true;
  if ((flexibleInt(videoStream['DvVersionMinor']) ?? 0) > 0) return true;

  final text = [
    videoStream['VideoRangeType'],
    videoStream['VideoRange'],
    videoStream['VideoDoViTitle'],
  ].whereType<Object>().map((value) => value.toString().toLowerCase()).join(' ');
  return text.contains('dovi') || text.contains('dolby vision') || text.contains('dolbyvision');
}

int? jellyfinDolbyVisionProfile(Map<String, dynamic> videoStream) => flexibleInt(videoStream['DvProfile']);

bool jellyfinVideoStreamIsHdr(Map<String, dynamic> source, Map<String, dynamic> videoStream) {
  if (jellyfinVideoStreamIsDolbyVision(videoStream)) return true;
  final criteria = jellyfinDisplayCriteriaFromStream(source, videoStream);
  if (criteria?.isHdr == true) return true;

  final range = [
    videoStream['VideoRangeType'],
    videoStream['VideoRange'],
  ].whereType<Object>().map((value) => value.toString().toLowerCase()).join(' ');
  return range.contains('hdr') || range.contains('hlg');
}

({String? transfer, String? primaries, String? matrix}) _jellyfinDefaultDisplayColorTags({
  required String? videoRangeType,
  required String? videoRange,
  int? doviCompatibilityId,
  String? transfer,
  String? primaries,
  String? matrix,
}) {
  final range = '${videoRangeType ?? ''} ${videoRange ?? ''}';
  final colorTags = _normalizedDisplayColorTags(transfer, primaries, matrix);
  if (doviCompatibilityId == 4 || range.contains('hlg') || colorTags.contains('hlg') || colorTags.contains('arib')) {
    return (transfer: 'arib-std-b67', primaries: 'bt2020', matrix: 'bt2020nc');
  }
  if (doviCompatibilityId == 1 ||
      doviCompatibilityId == 6 ||
      range.contains('hdr') ||
      colorTags.contains('smpte2084') ||
      colorTags.contains('st2084') ||
      colorTags.contains('pq') ||
      colorTags.contains('bt2020')) {
    return (transfer: 'smpte2084', primaries: 'bt2020', matrix: 'bt2020nc');
  }
  if (doviCompatibilityId == 2 || range.trim().isEmpty || range.contains('sdr')) {
    return (transfer: 'bt709', primaries: 'bt709', matrix: 'bt709');
  }
  return (transfer: null, primaries: null, matrix: null);
}

String? _stringOrNull(Object? value) {
  final string = value?.toString().trim();
  return string == null || string.isEmpty ? null : string;
}

String _normalizedDisplayColorTags(String? transfer, String? primaries, String? matrix) =>
    [transfer, primaries, matrix].whereType<String>().join(' ').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
