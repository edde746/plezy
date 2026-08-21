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

  factory AnimeIds.fromFribb(FribbMappingRow row) =>
      AnimeIds(mal: row.malId, anilist: row.anilistId, simkl: row.simklId);

  /// Round-trips through the persisted tracker write queue.
  Map<String, Object?> toJson() => {
    if (mal != null) 'mal': mal,
    if (anilist != null) 'anilist': anilist,
    if (simkl != null) 'simkl': simkl,
  };

  factory AnimeIds.fromJson(Map<String, Object?> json) => AnimeIds(
    mal: (json['mal'] as num?)?.toInt(),
    anilist: (json['anilist'] as num?)?.toInt(),
    simkl: (json['simkl'] as num?)?.toInt(),
  );
}
