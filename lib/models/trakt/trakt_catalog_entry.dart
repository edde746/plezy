import 'package:json_annotation/json_annotation.dart';

import 'trakt_catalog_media.dart';

part 'trakt_catalog_entry.g.dart';

/// A wrapped catalog list entry holding a movie or show.
///
/// Covers both wrapper shapes Trakt returns:
/// - watchlist entries: `{rank, listed_at, type, movie|show}`
/// - trending entries: `{watchers, movie|show}`
@JsonSerializable(createToJson: false)
class TraktCatalogEntry {
  final int? rank;
  @JsonKey(name: 'listed_at')
  final String? listedAt;

  /// `movie` or `show` on watchlist entries; absent on trending entries.
  final String? type;
  final int? watchers;
  final TraktCatalogMedia? movie;
  final TraktCatalogMedia? show;

  const TraktCatalogEntry({this.rank, this.listedAt, this.type, this.watchers, this.movie, this.show});

  TraktCatalogMedia? get media => movie ?? show;

  bool get isShow => show != null;

  factory TraktCatalogEntry.fromJson(Map<String, dynamic> json) => _$TraktCatalogEntryFromJson(json);
}
