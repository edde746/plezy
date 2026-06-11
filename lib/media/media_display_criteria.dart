import '../utils/json_utils.dart';

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

  bool get isHdr {
    if ((doviProfile ?? 0) > 0 && doviCompatibilityId != 2) return true;
    final tags = _normalizedColorTags(transfer, primaries, matrix);
    return tags.contains('hlg') ||
        tags.contains('arib') ||
        tags.contains('pq') ||
        tags.contains('smpte2084') ||
        tags.contains('st2084') ||
        tags.contains('bt2020');
  }

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

String _normalizedColorTags(String? transfer, String? primaries, String? matrix) =>
    [transfer, primaries, matrix].whereType<String>().join(' ').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
