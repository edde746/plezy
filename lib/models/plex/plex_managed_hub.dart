/// A recommendation row returned by Plex's Home manager endpoint.
class PlexManagedHub {
  final String identifier;
  final String title;
  final String? hubKey;
  final String? metadataItemId;
  final bool promoted;
  final bool promotedToRecommended;
  final bool promotedToOwnHome;
  final bool promotedToSharedHome;
  final bool deletable;

  const PlexManagedHub({
    required this.identifier,
    required this.title,
    this.hubKey,
    this.metadataItemId,
    this.promoted = false,
    this.promotedToRecommended = false,
    this.promotedToOwnHome = false,
    this.promotedToSharedHome = false,
    this.deletable = false,
  });

  factory PlexManagedHub.fromJson(Map<String, dynamic> json) {
    bool flag(String key) {
      final value = json[key];
      return value == true || value == 1 || value == '1' || value == 'true';
    }

    final identifier = '${json['identifier'] ?? json['hubIdentifier'] ?? json['key'] ?? ''}';
    return PlexManagedHub(
      identifier: identifier,
      title: '${json['title'] ?? json['name'] ?? identifier}',
      hubKey: json['hubKey']?.toString() ?? json['key']?.toString(),
      metadataItemId: json['metadataItemId']?.toString() ?? json['ratingKey']?.toString(),
      promoted: flag('promoted'),
      promotedToRecommended: flag('promotedToRecommended'),
      promotedToOwnHome: flag('promotedToOwnHome'),
      promotedToSharedHome: flag('promotedToSharedHome'),
      deletable: flag('deletable'),
    );
  }
}

/// Plezy-local hero/trailer preference for one native Plex-managed hub.
///
/// Unlike [PlexManagedHub] itself, Plex has no concept of "hero style" or
/// "trailer preview" — there is nothing to fetch this from or write it back
/// to on the server, so it lives entirely in local settings
/// (`SettingsService.managedHubHeroOverrides`), keyed by
/// `'${library.globalKey}::${hub.identifier}'`.
class ManagedHubHeroOverride {
  const ManagedHubHeroOverride({this.heroStyle = false, this.heroTrailerPreview = false});

  final bool heroStyle;
  final bool heroTrailerPreview;

  ManagedHubHeroOverride copyWith({bool? heroStyle, bool? heroTrailerPreview}) => ManagedHubHeroOverride(
    heroStyle: heroStyle ?? this.heroStyle,
    heroTrailerPreview: heroTrailerPreview ?? this.heroTrailerPreview,
  );

  Map<String, dynamic> toJson() => {'heroStyle': heroStyle, 'heroTrailerPreview': heroTrailerPreview};

  static ManagedHubHeroOverride fromJson(Map<String, dynamic> json) => ManagedHubHeroOverride(
    heroStyle: json['heroStyle'] as bool? ?? false,
    heroTrailerPreview: json['heroTrailerPreview'] as bool? ?? false,
  );
}
