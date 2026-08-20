/// Map a video stream height (pixels) onto the canonical resolution label
/// the rest of the app uses (`'4k'`, `'1080'`, `'720'`, `'480'`, or the raw
/// height for non-standard sizes). Returns `null` when [height] is null.
///
/// Plex hands the label back already in its `Media.videoResolution` field;
/// Jellyfin only gives raw pixel dimensions, which the Jellyfin mapper feeds
/// through [resolutionLabelFromDimensions] to produce the same shape.
String? resolutionLabelFromHeight(int? height) {
  if (height == null) return null;
  if (height >= 2160) return '4k';
  if (height >= 1080) return '1080';
  if (height >= 720) return '720';
  if (height >= 480) return '480';
  return height.toString();
}

/// Convenience overload that takes width + height. Width is considered first
/// for scope-cropped files, e.g. `3840x1608` should still be labeled `4k`.
String? resolutionLabelFromDimensions(int? width, int? height) {
  if ((width != null && width >= 3840) || (height != null && height >= 2160)) return '4k';
  if ((width != null && width >= 1920) || (height != null && height >= 1080)) return '1080';
  if ((width != null && width >= 1280) || (height != null && height >= 720)) return '720';
  if ((width != null && width >= 854) || (height != null && height >= 480)) return '480';
  return resolutionLabelFromHeight(height);
}

final _numericResolutionValue = RegExp(r'^(\d+)(?:p)?$');

/// Format a canonical resolution label — or a raw numeric height, with or
/// without a trailing `p` — for display: `'1080'`/`'1080p'` → `'1080p'`,
/// `'4k'`/`'uhd'`/heights ≥ 2160 → `'4K'`, `'sd'` → `'SD'`; anything else is
/// uppercased verbatim.
String resolutionDisplayLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == '4k' || normalized == 'uhd') return '4K';
  if (normalized == 'sd') return 'SD';

  final numeric = _numericResolutionValue.firstMatch(normalized);
  if (numeric != null) {
    final height = int.tryParse(numeric.group(1)!);
    if (height != null && height >= 2160) return '4K';
    return '${numeric.group(1)}p';
  }

  return value.trim().toUpperCase();
}
