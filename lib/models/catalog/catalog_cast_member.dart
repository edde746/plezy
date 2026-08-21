/// One entry of a catalog item's cast section: an actor with their character
/// (Trakt) or an anime character with its role (MAL).
class CatalogCastMember {
  final String name;

  /// Character name (Trakt) or role such as `Main` / `Supporting` (MAL).
  final String? secondary;

  /// Absolute https headshot/portrait URL.
  final String? imageUrl;

  const CatalogCastMember({required this.name, this.secondary, this.imageUrl});

  Map<String, Object?> toJson() => {
    'name': name,
    if (secondary != null) 'secondary': secondary,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  static CatalogCastMember? fromJson(Map<String, Object?> json) {
    final name = json['name'] as String?;
    if (name == null) return null;
    return CatalogCastMember(
      name: name,
      secondary: json['secondary'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
