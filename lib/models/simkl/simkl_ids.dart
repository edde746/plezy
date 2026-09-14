import 'package:json_annotation/json_annotation.dart';

import '../../utils/json_utils.dart';
import '../catalog/catalog_item.dart';

part 'simkl_ids.g.dart';

Object? _readSimklId(Map json, String key) => json['simkl'] ?? json['simkl_id'];

/// Simkl's identifier block. CDN feeds call the native key `simkl_id`, while
/// API responses and mutation bodies use `simkl`.
@JsonSerializable(includeIfNull: false)
class SimklIds {
  @JsonKey(readValue: _readSimklId, fromJson: flexibleInt)
  final int? simkl;

  /// Response-only according to Simkl's current API contract.
  @JsonKey(includeToJson: false)
  final String? slug;

  final String? imdb;
  @JsonKey(fromJson: flexibleInt)
  final int? tmdb;
  @JsonKey(fromJson: flexibleInt)
  final int? tvdb;
  @JsonKey(fromJson: flexibleInt)
  final int? mal;
  @JsonKey(fromJson: flexibleInt)
  final int? anilist;

  const SimklIds({this.simkl, this.slug, this.imdb, this.tmdb, this.tvdb, this.mal, this.anilist});

  bool get hasAny => simkl != null || imdb != null || tmdb != null || tvdb != null || mal != null || anilist != null;

  CatalogItemIds toCatalogItemIds() =>
      CatalogItemIds(simkl: simkl, slug: slug, imdb: imdb, tmdb: tmdb, tvdb: tvdb, mal: mal, anilist: anilist);

  factory SimklIds.fromCatalogItemIds(CatalogItemIds ids) => SimklIds(
    simkl: ids.simkl,
    slug: ids.slug,
    imdb: ids.imdb,
    tmdb: ids.tmdb,
    tvdb: ids.tvdb,
    mal: ids.mal,
    anilist: ids.anilist,
  );

  Map<String, dynamic> toJson() => _$SimklIdsToJson(this);

  factory SimklIds.fromJson(Map<String, dynamic> json) => _$SimklIdsFromJson(json);
}
