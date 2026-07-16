import '../utils/json_utils.dart';

typedef MediaDisplayColorTags = ({String? transfer, String? primaries, String? matrix});

enum MediaDisplayColorType {
  dolbyVision(true),
  hlg(true),
  pq(true),
  sdr(false),
  unknown(false);

  const MediaDisplayColorType(this.isHdr);

  final bool isHdr;

  MediaDisplayColorTags get defaultTags => _defaultDisplayColorTags[this]!;
}

const _defaultDisplayColorTags = <MediaDisplayColorType, MediaDisplayColorTags>{
  MediaDisplayColorType.dolbyVision: (transfer: null, primaries: null, matrix: null),
  MediaDisplayColorType.hlg: (transfer: 'arib-std-b67', primaries: 'bt2020', matrix: 'bt2020nc'),
  MediaDisplayColorType.pq: (transfer: 'smpte2084', primaries: 'bt2020', matrix: 'bt2020nc'),
  MediaDisplayColorType.sdr: (transfer: 'bt709', primaries: 'bt709', matrix: 'bt709'),
  MediaDisplayColorType.unknown: (transfer: null, primaries: null, matrix: null),
};

/// Classifies already-extracted display metadata without relying on a backend
/// JSON shape. Compatibility IDs describe the Dolby Vision base layer.
MediaDisplayColorType classifyMediaDisplayColor({
  bool isDolbyVision = false,
  int? doviCompatibilityId,
  String? range,
  String? transfer,
  String? primaries,
  String? matrix,
  bool assumeSdr = false,
}) {
  final tags = _normalizedColorTags(range, transfer, primaries, matrix);
  if (doviCompatibilityId == 4 || tags.contains('hlg') || tags.contains('arib')) {
    return MediaDisplayColorType.hlg;
  }
  if (doviCompatibilityId == 1 ||
      doviCompatibilityId == 6 ||
      tags.contains('hdr') ||
      tags.contains('pq') ||
      tags.contains('smpte2084') ||
      tags.contains('st2084') ||
      tags.contains('bt2020')) {
    return MediaDisplayColorType.pq;
  }
  if (doviCompatibilityId == 2) {
    return MediaDisplayColorType.sdr;
  }
  if (isDolbyVision) return MediaDisplayColorType.dolbyVision;
  if (tags.contains('sdr') || tags.contains('bt709') || assumeSdr) {
    return MediaDisplayColorType.sdr;
  }
  return MediaDisplayColorType.unknown;
}

/// Backend-neutral display metadata used to prime native display matching
/// before the decoder has emitted mpv/video properties.
class MediaDisplayCriteria {
  final double? fps;
  final int? width;
  final int? height;
  final int? doviProfile;
  final int? doviLevel;
  final int? doviCompatibilityId;
  final String? transfer;
  final String? primaries;
  final String? matrix;

  const MediaDisplayCriteria({
    this.fps,
    this.width,
    this.height,
    this.doviProfile,
    this.doviLevel,
    this.doviCompatibilityId,
    this.transfer,
    this.primaries,
    this.matrix,
  });

  factory MediaDisplayCriteria.fromRaw({
    Object? fps,
    Object? width,
    Object? height,
    Object? doviProfile,
    Object? doviLevel,
    Object? doviCompatibilityId,
    Object? transfer,
    Object? primaries,
    Object? matrix,
  }) {
    return MediaDisplayCriteria(
      fps: flexibleDouble(fps),
      width: flexibleInt(width),
      height: flexibleInt(height),
      doviProfile: flexibleInt(doviProfile),
      doviLevel: flexibleInt(doviLevel),
      doviCompatibilityId: flexibleInt(doviCompatibilityId),
      transfer: _stringOrNull(transfer),
      primaries: _stringOrNull(primaries),
      matrix: _stringOrNull(matrix),
    );
  }

  bool get hasDimensions => (width ?? 0) > 0 && (height ?? 0) > 0;

  bool get hasFrameRate => (fps ?? 0) > 0;

  bool get hasDisplayMetadata =>
      (doviProfile ?? 0) > 0 || _hasValue(transfer) || _hasValue(primaries) || _hasValue(matrix);

  bool get canPrimeNativeDisplayCriteria => hasDimensions && (hasDisplayMetadata || hasFrameRate);

  MediaDisplayColorType get colorType => classifyMediaDisplayColor(
    isDolbyVision: (doviProfile ?? 0) > 0,
    doviCompatibilityId: doviCompatibilityId,
    transfer: transfer,
    primaries: primaries,
    matrix: matrix,
  );

  bool get isHdr => colorType.isHdr;

  bool get isUsable => hasFrameRate || canPrimeNativeDisplayCriteria;

  Map<String, Object> toJson() {
    final json = <String, Object>{};
    void put(String key, Object? value) {
      if (value != null) json[key] = value;
    }

    put('fps', fps);
    put('width', width);
    put('height', height);
    put('doviProfile', doviProfile);
    put('doviLevel', doviLevel);
    put('doviCompatibilityId', doviCompatibilityId);
    put('transfer', transfer);
    put('primaries', primaries);
    put('matrix', matrix);
    return json;
  }
}

String? _stringOrNull(Object? value) {
  final string = value?.toString().trim();
  return string == null || string.isEmpty ? null : string;
}

bool _hasValue(String? value) => value != null && value.isNotEmpty;

String _normalizedColorTags(String? range, String? transfer, String? primaries, String? matrix) => [
  range,
  transfer,
  primaries,
  matrix,
].whereType<String>().join(' ').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
