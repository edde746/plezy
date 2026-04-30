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

/// Convenience overload that takes width + height. Width is ignored — the
/// label is height-driven — but the signature matches earlier per-backend
/// helpers so callers don't have to drop a parameter on the floor.
String? resolutionLabelFromDimensions(int? width, int? height) => resolutionLabelFromHeight(height);
