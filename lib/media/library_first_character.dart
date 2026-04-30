/// One entry in the alpha-jump bar — a letter (or `#` bucket for items
/// starting with a digit / non-letter) plus the count of items beginning
/// with it.
///
/// Plex's `/library/sections/{id}/firstCharacter` endpoint returns these
/// natively (counts let the UI scroll to a cumulative offset). Jellyfin
/// has no equivalent endpoint, so [JellyfinClient.fetchFirstCharacters]
/// synthesises a 27-letter alphabet with `size: 1` per entry — the bar
/// then acts as a name-prefix filter rather than a scroll affordance.
class LibraryFirstCharacter {
  final String key;
  final String title;
  final int size;

  const LibraryFirstCharacter({required this.key, required this.title, required this.size});
}
