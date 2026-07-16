// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_cast_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktPersonImages _$TraktPersonImagesFromJson(Map<String, dynamic> json) =>
    TraktPersonImages(
      headshot: (json['headshot'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

TraktPerson _$TraktPersonFromJson(Map<String, dynamic> json) => TraktPerson(
  name: json['name'] as String?,
  images: json['images'] == null
      ? null
      : TraktPersonImages.fromJson(json['images'] as Map<String, dynamic>),
);

TraktCastEntry _$TraktCastEntryFromJson(Map<String, dynamic> json) =>
    TraktCastEntry(
      characters: (json['characters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      person: json['person'] == null
          ? null
          : TraktPerson.fromJson(json['person'] as Map<String, dynamic>),
    );
