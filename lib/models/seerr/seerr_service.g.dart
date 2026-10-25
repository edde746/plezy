// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seerr_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeerrServiceInstance _$SeerrServiceInstanceFromJson(
  Map<String, dynamic> json,
) => SeerrServiceInstance(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String?,
  is4k: json['is4k'] as bool? ?? false,
  isDefault: json['isDefault'] as bool? ?? false,
  activeDirectory: json['activeDirectory'] as String?,
  activeProfileId: (json['activeProfileId'] as num?)?.toInt(),
  activeLanguageProfileId: (json['activeLanguageProfileId'] as num?)?.toInt(),
  activeAnimeDirectory: json['activeAnimeDirectory'] as String?,
  activeAnimeProfileId: (json['activeAnimeProfileId'] as num?)?.toInt(),
  activeAnimeLanguageProfileId: (json['activeAnimeLanguageProfileId'] as num?)
      ?.toInt(),
  activeTags: (json['activeTags'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  activeAnimeTags: (json['activeAnimeTags'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
);

SeerrServiceDetail _$SeerrServiceDetailFromJson(Map<String, dynamic> json) =>
    SeerrServiceDetail(
      server: json['server'] == null
          ? null
          : SeerrServiceInstance.fromJson(
              json['server'] as Map<String, dynamic>,
            ),
      profiles: (json['profiles'] as List<dynamic>?)
          ?.map((e) => SeerrServiceProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      rootFolders: (json['rootFolders'] as List<dynamic>?)
          ?.map((e) => SeerrRootFolder.fromJson(e as Map<String, dynamic>))
          .toList(),
      languageProfiles: (json['languageProfiles'] as List<dynamic>?)
          ?.map((e) => SeerrServiceProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => SeerrServiceTag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

SeerrServiceProfile _$SeerrServiceProfileFromJson(Map<String, dynamic> json) =>
    SeerrServiceProfile(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
    );

SeerrRootFolder _$SeerrRootFolderFromJson(Map<String, dynamic> json) =>
    SeerrRootFolder(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String?,
    );

SeerrServiceTag _$SeerrServiceTagFromJson(Map<String, dynamic> json) =>
    SeerrServiceTag(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String?,
    );
