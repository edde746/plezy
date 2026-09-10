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
