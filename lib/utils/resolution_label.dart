/// Map a video stream height (pixels) onto the canonical resolution label
/// the rest of the app uses (`'4k'`, `'1080'`, `'720'`, `'480'`, or the raw
/// height for non-standard sizes). Returns `null` when [height] is null.
///
/// Plex hands the label back already in its `Media.videoResolution` field;
/// Jellyfin only gives raw pixel dimensions, so the Jellyfin mapper and
/// playback path both call this to produce the same shape.
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
