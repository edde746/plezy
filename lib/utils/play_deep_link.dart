import '../profiles/profile.dart';
import 'app_logger.dart';

/// A launcher shelf content ID or a `plezy://play` deep link.
///
/// Format: `plezy://play?content_id=<contentId>[&profile=<profile>]`
///
/// `profile` is a Plex Home user UUID or a profile ID.
class PlayDeepLink {
  const PlayDeepLink({required this.contentId, this.profile});

  static const scheme = 'plezy';
  static const host = 'play';

  final String contentId;
  final String? profile;

  /// Parse [payload]; anything but a `plezy://play` link is a bare content ID.
  factory PlayDeepLink.parse(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme != scheme || uri.host != host) return PlayDeepLink(contentId: payload);
    final profile = uri.queryParameters['profile']?.trim();
    return PlayDeepLink(
      contentId: uri.queryParameters['content_id']?.trim() ?? '',
      profile: profile == null || profile.isEmpty ? null : profile,
    );
  }
}

/// Find the profile with ID [profile], or else the one Plex Home user with that UUID.
Profile? resolveDeepLinkProfile(List<Profile> profiles, String profile) {
  for (final candidate in profiles) {
    if (candidate.id == profile) return candidate;
  }
  final wanted = profile.toLowerCase();
  final matches = profiles.where((p) => p.plexHomeUserUuid?.toLowerCase() == wanted).toList(growable: false);
  if (matches.length == 1) return matches.single;
  if (matches.length > 1) {
    appLogger.w('Deep link: profile "$profile" is ambiguous (${matches.length} matches)');
  }
  return null;
}
