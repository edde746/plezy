/// One genre of a library, as the library's Genres tab shows it.
///
/// [filterValue] is how the library's own `genre` filter names the genre —
/// Plex's opaque tag id (`239`), the genre name on Jellyfin and Emby — so
/// opening a genre makes the same selection the filter editor would.
class LibraryGenre {
  final String title;
  final String filterValue;

  /// Server-relative artwork for the tile, or null when the server has none.
  final String? artPath;

  /// The tile's tint as `0xRRGGBB`. Plex assigns one per genre; null where
  /// the backend has none.
  final int? accentRgb;

  const LibraryGenre({required this.title, required this.filterValue, this.artPath, this.accentRgb});
}
