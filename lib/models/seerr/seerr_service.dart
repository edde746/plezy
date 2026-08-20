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

  const SeerrServiceInstance({
    required this.id,
    this.name,
    this.is4k = false,
    this.isDefault = false,
    this.activeDirectory,
    this.activeProfileId,
    this.activeLanguageProfileId,
  });

  factory SeerrServiceInstance.fromJson(Map<String, dynamic> json) => _$SeerrServiceInstanceFromJson(json);
}

/// Quality profile / root folder / language profile options of one instance
/// (`GET /service/radarr|sonarr/{id}`).
@JsonSerializable(createToJson: false)
class SeerrServiceDetail {
  final SeerrServiceInstance? server;
  final List<SeerrServiceProfile>? profiles;
  final List<SeerrRootFolder>? rootFolders;

  /// Sonarr v3 only; absent on Radarr and newer Sonarr.
  final List<SeerrServiceProfile>? languageProfiles;

  const SeerrServiceDetail({this.server, this.profiles, this.rootFolders, this.languageProfiles});

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
