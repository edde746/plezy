/// Deep link for selecting an existing Plezy profile from Android
/// automation, for example `plezy://profile?id=<profile-id>`.
class ProfileDeepLink {
  const ProfileDeepLink._(this.profileId);

  static const scheme = 'plezy';
  static const host = 'profile';

  final String profileId;

  static String forProfileId(String profileId) =>
      Uri(scheme: scheme, host: host, queryParameters: {'id': profileId}).toString();

  static ProfileDeepLink? tryParse(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    final id =
        (uri.queryParameters['id'] ??
                uri.queryParameters['profileId'] ??
                (uri.pathSegments.isEmpty ? null : uri.pathSegments.first))
            ?.trim();
    if (id == null || id.isEmpty || id.contains('/')) return null;
    return ProfileDeepLink._(id);
  }
}
