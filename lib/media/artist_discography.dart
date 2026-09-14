import 'media_item.dart';

/// Release-format sections of an artist's discography, mirroring how Plex's
/// own clients split an artist's music library into Albums, Singles & EPs,
/// Live, and Compilations. Declaration order is display order.
enum DiscographyGroupKind { albums, singlesAndEps, live, compilations }

/// One discography section: a [kind] plus the albums it contains, in server
/// order (newest first).
class ArtistDiscographyGroup {
  final DiscographyGroupKind kind;
  final List<MediaItem> items;

  const ArtistDiscographyGroup({required this.kind, required this.items});
}

/// Partitions [albums] into ordered discography sections using the per-album
/// [kindOf] classification. Album order is preserved within each section,
/// sections appear in [DiscographyGroupKind] declaration order, and empty
/// sections are dropped.
List<ArtistDiscographyGroup> buildArtistDiscographyGroups(
  List<MediaItem> albums,
  DiscographyGroupKind Function(MediaItem album) kindOf,
) {
  final buckets = {for (final kind in DiscographyGroupKind.values) kind: <MediaItem>[]};
  for (final album in albums) {
    buckets[kindOf(album)]!.add(album);
  }
  return [
    for (final kind in DiscographyGroupKind.values)
      if (buckets[kind]!.isNotEmpty) ArtistDiscographyGroup(kind: kind, items: buckets[kind]!),
  ];
}
