import 'fribb_mapping_row.dart';

/// External IDs for matching a Plex item to MAL / AniList / Simkl catalogs.
///
/// Populated from a [FribbMappingRow] via the resolver. Each service's tracker
/// picks the ID it needs (MAL uses [mal], AniList uses [anilist], etc.) and
/// no-ops when its ID is missing.
class AnimeIds {
  final int? mal;
  final int? anilist;
  final int? simkl;

  const AnimeIds({this.mal, this.anilist, this.simkl});

  factory AnimeIds.fromFribb(FribbMappingRow row) => AnimeIds(
    mal: row.malId,
    anilist: row.anilistId,
    simkl: row.simklId,
  );
}
