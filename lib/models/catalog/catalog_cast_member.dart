/// One entry of a catalog item's cast section: an actor with their character
/// (Trakt) or an anime character with its role (MAL).
class CatalogCastMember {
  final String name;

  /// Character name (Trakt) or role such as `Main` / `Supporting` (MAL).
  final String? secondary;

  /// Absolute https headshot/portrait URL.
  final String? imageUrl;

  const CatalogCastMember({required this.name, this.secondary, this.imageUrl});
}
