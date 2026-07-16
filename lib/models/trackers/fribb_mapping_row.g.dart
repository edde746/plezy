// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fribb_mapping_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FribbMappingRow _$FribbMappingRowFromJson(Map<String, dynamic> json) =>
    FribbMappingRow(
      anidbId: flexibleInt(json['anidb_id']),
      anilistId: flexibleInt(json['anilist_id']),
      imdbIds: flexibleStringList(json['imdb_id']),
      malId: flexibleInt(json['mal_id']),
      simklId: flexibleInt(json['simkl_id']),
      tmdbIds: _flattenTmdbIds(json['themoviedb_id']),
      tvdbId: flexibleInt(json['tvdb_id']),
      tvdbSeason: flexibleInt(_readTvdbSeason(json, 'tvdbSeason')),
      tmdbSeason: flexibleInt(_readTmdbSeason(json, 'tmdbSeason')),
      type: _typeString(json['type']),
    );
