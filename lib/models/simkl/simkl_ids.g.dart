// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simkl_ids.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SimklIds _$SimklIdsFromJson(Map<String, dynamic> json) => SimklIds(
  simkl: flexibleInt(_readSimklId(json, 'simkl')),
  slug: json['slug'] as String?,
  imdb: json['imdb'] as String?,
  tmdb: flexibleInt(json['tmdb']),
  tvdb: flexibleInt(json['tvdb']),
  mal: flexibleInt(json['mal']),
  anilist: flexibleInt(json['anilist']),
);

Map<String, dynamic> _$SimklIdsToJson(SimklIds instance) => <String, dynamic>{
  'simkl': ?instance.simkl,
  'imdb': ?instance.imdb,
  'tmdb': ?instance.tmdb,
  'tvdb': ?instance.tvdb,
  'mal': ?instance.mal,
  'anilist': ?instance.anilist,
};
