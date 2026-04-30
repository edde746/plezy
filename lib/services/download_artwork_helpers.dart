import '../media/download_resolution.dart';
import '../media/media_item.dart';

/// Maps a per-item image path/URL to the actual downloadable URL.
/// Plex resolves paths through `getThumbnailUrl` (token-aware); Jellyfin
/// stores absolute URLs already and passes them through. Returning `null`
/// or an empty string skips the entry.
typedef ArtworkUrlResolver = String? Function(String path);

/// Stable storage key for artwork. Jellyfin image URLs carry `api_key` for
/// fetching, but persisted DB rows and hashed local filenames must not contain
/// long-lived tokens.
String artworkStorageKey(String pathOrUrl) {
  final uri = Uri.tryParse(pathOrUrl);
  if (uri == null || !uri.hasQuery) return pathOrUrl;
  final params = Map<String, String>.from(uri.queryParameters)..remove('api_key');
  return uri.replace(queryParameters: params.isEmpty ? null : params).toString();
}

/// Build [DownloadArtworkSpec]s for the four standard [MediaItem] image
/// fields (thumb, clearLogo, art, backgroundSquare). The four-field
/// enumeration is the same across backends; only the URL transformation
/// differs.
List<DownloadArtworkSpec> buildArtworkSpecs(MediaItem item, ArtworkUrlResolver resolveUrl) {
  final specs = <DownloadArtworkSpec>[];
  void addIfPresent(String? path) {
    if (path == null || path.isEmpty) return;
    final url = resolveUrl(path);
    if (url == null || url.isEmpty) return;
    specs.add(DownloadArtworkSpec(localKey: artworkStorageKey(path), url: url));
  }

  addIfPresent(item.thumbPath);
  addIfPresent(item.clearLogoPath);
  addIfPresent(item.artPath);
  addIfPresent(item.backgroundSquarePath);
  return specs;
}
