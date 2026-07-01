/// Summary entry returned by `GET /api/v1/service/sonarr` or `/service/radarr`
/// — the list of configured Radarr/Sonarr instances on the Seerr backend.
class SeerrServiceInstance {
  final int id;
  final String name;
  final bool is4k;
  final bool isDefault;
  final int? activeProfileId;
  final String? activeDirectory;
  final int? activeLanguageProfileId;

  const SeerrServiceInstance({
    required this.id,
    required this.name,
    required this.is4k,
    required this.isDefault,
    this.activeProfileId,
    this.activeDirectory,
    this.activeLanguageProfileId,
  });

  factory SeerrServiceInstance.fromJson(Map<String, dynamic> json) {
    return SeerrServiceInstance(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      is4k: json['is4k'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
      activeProfileId: (json['activeProfileId'] as num?)?.toInt(),
      activeDirectory: json['activeDirectory'] as String?,
      activeLanguageProfileId: (json['activeLanguageProfileId'] as num?)?.toInt(),
    );
  }
}

class SeerrQualityProfile {
  final int id;
  final String name;

  const SeerrQualityProfile({required this.id, required this.name});

  factory SeerrQualityProfile.fromJson(Map<String, dynamic> json) =>
      SeerrQualityProfile(id: (json['id'] as num).toInt(), name: json['name'] as String? ?? '');
}

class SeerrRootFolder {
  final int id;
  final String path;

  const SeerrRootFolder({required this.id, required this.path});

  factory SeerrRootFolder.fromJson(Map<String, dynamic> json) =>
      SeerrRootFolder(id: (json['id'] as num?)?.toInt() ?? 0, path: json['path'] as String? ?? '');
}

class SeerrLanguageProfile {
  final int id;
  final String name;

  const SeerrLanguageProfile({required this.id, required this.name});

  factory SeerrLanguageProfile.fromJson(Map<String, dynamic> json) =>
      SeerrLanguageProfile(id: (json['id'] as num).toInt(), name: json['name'] as String? ?? '');
}

/// Full server detail returned by `GET /service/sonarr/{id}` or `/service/radarr/{id}`.
/// Includes the lists used to populate the advanced request form pickers.
class SeerrServiceDetail {
  final SeerrServiceInstance server;
  final List<SeerrQualityProfile> profiles;
  final List<SeerrRootFolder> rootFolders;
  final List<SeerrLanguageProfile> languageProfiles;

  const SeerrServiceDetail({
    required this.server,
    this.profiles = const [],
    this.rootFolders = const [],
    this.languageProfiles = const [],
  });

  factory SeerrServiceDetail.fromJson(Map<String, dynamic> json) {
    final serverJson = json['server'];
    final server = serverJson is Map<String, dynamic>
        ? SeerrServiceInstance.fromJson(serverJson)
        : const SeerrServiceInstance(id: 0, name: '', is4k: false, isDefault: false);
    final profilesRaw = json['profiles'];
    final rootsRaw = json['rootFolders'];
    final langsRaw = json['languageProfiles'];
    final profiles = <SeerrQualityProfile>[];
    if (profilesRaw is List) {
      for (final p in profilesRaw) {
        if (p is Map<String, dynamic>) profiles.add(SeerrQualityProfile.fromJson(p));
      }
    }
    final rootFolders = <SeerrRootFolder>[];
    if (rootsRaw is List) {
      for (final r in rootsRaw) {
        if (r is Map<String, dynamic>) rootFolders.add(SeerrRootFolder.fromJson(r));
      }
    }
    final languageProfiles = <SeerrLanguageProfile>[];
    if (langsRaw is List) {
      for (final l in langsRaw) {
        if (l is Map<String, dynamic>) languageProfiles.add(SeerrLanguageProfile.fromJson(l));
      }
    }
    return SeerrServiceDetail(
      server: server,
      profiles: profiles,
      rootFolders: rootFolders,
      languageProfiles: languageProfiles,
    );
  }
}
