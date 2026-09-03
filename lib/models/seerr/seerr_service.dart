import 'package:json_annotation/json_annotation.dart';

part 'seerr_service.g.dart';

/// One configured Radarr/Sonarr instance (`GET /service/radarr|sonarr`).
@JsonSerializable(createToJson: false)
class SeerrServiceInstance {
  final int id;
  final String? name;
  final bool is4k;
  final bool isDefault;
  final String? activeDirectory;
  final int? activeProfileId;

  /// Sonarr only.
  final int? activeLanguageProfileId;

  /// Sonarr only: the defaults Seerr routes anime series to instead of the
  /// standard ones. Each is absent when the instance has no anime override.
  final String? activeAnimeDirectory;
  final int? activeAnimeProfileId;
  final int? activeAnimeLanguageProfileId;

  /// Tag ids applied by default. Only the detail endpoint reports the real
  /// values; the list endpoint reports `[]` for `activeTags` on Sonarr.
  final List<int>? activeTags;
  final List<int>? activeAnimeTags;

  const SeerrServiceInstance({
    required this.id,
    this.name,
    this.is4k = false,
    this.isDefault = false,
    this.activeDirectory,
    this.activeProfileId,
    this.activeLanguageProfileId,
    this.activeAnimeDirectory,
    this.activeAnimeProfileId,
    this.activeAnimeLanguageProfileId,
    this.activeTags,
    this.activeAnimeTags,
  });

  factory SeerrServiceInstance.fromJson(Map<String, dynamic> json) => _$SeerrServiceInstanceFromJson(json);
}

/// Quality profile / root folder / language profile / tag options of one
/// instance (`GET /service/radarr|sonarr/{id}`).
@JsonSerializable(createToJson: false)
class SeerrServiceDetail {
  final SeerrServiceInstance? server;
  final List<SeerrServiceProfile>? profiles;
  final List<SeerrRootFolder>? rootFolders;

  /// Sonarr v3 only; absent on Radarr and newer Sonarr.
  final List<SeerrServiceProfile>? languageProfiles;
  final List<SeerrServiceTag>? tags;

  const SeerrServiceDetail({this.server, this.profiles, this.rootFolders, this.languageProfiles, this.tags});

  factory SeerrServiceDetail.fromJson(Map<String, dynamic> json) => _$SeerrServiceDetailFromJson(json);
}

/// Quality or language profile option `{id, name}`.
@JsonSerializable(createToJson: false)
class SeerrServiceProfile {
  final int id;
  final String? name;

  const SeerrServiceProfile({required this.id, this.name});

  factory SeerrServiceProfile.fromJson(Map<String, dynamic> json) => _$SeerrServiceProfileFromJson(json);
}

@JsonSerializable(createToJson: false)
class SeerrRootFolder {
  final int id;
  final String? path;

  const SeerrRootFolder({required this.id, this.path});

  factory SeerrRootFolder.fromJson(Map<String, dynamic> json) => _$SeerrRootFolderFromJson(json);
}

/// Arr tag option `{id, label}`.
@JsonSerializable(createToJson: false)
class SeerrServiceTag {
  final int id;
  final String? label;

  const SeerrServiceTag({required this.id, this.label});

  factory SeerrServiceTag.fromJson(Map<String, dynamic> json) => _$SeerrServiceTagFromJson(json);
}
