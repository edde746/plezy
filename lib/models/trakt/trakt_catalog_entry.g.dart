// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_catalog_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktCatalogEntry _$TraktCatalogEntryFromJson(Map<String, dynamic> json) =>
    TraktCatalogEntry(
      rank: (json['rank'] as num?)?.toInt(),
      listedAt: json['listed_at'] as String?,
      type: json['type'] as String?,
      watchers: (json['watchers'] as num?)?.toInt(),
      movie: json['movie'] == null
          ? null
          : TraktCatalogMedia.fromJson(json['movie'] as Map<String, dynamic>),
      show: json['show'] == null
          ? null
          : TraktCatalogMedia.fromJson(json['show'] as Map<String, dynamic>),
    );
