import 'package:json_annotation/json_annotation.dart';

import 'seerr_session.dart';

part 'seerr_public_settings.g.dart';

/// `GET /settings/public` — unauthenticated instance metadata. The connect
/// flow keys the offered sign-in methods off it; the request sheet keys the
/// 4K toggle and per-season selection off it; catalog artwork keys its
/// image host off it ([tmdbImageProxyPath]).
@JsonSerializable(createToJson: false)
class SeerrPublicSettings {
  final bool initialized;
  final String? applicationTitle;

  /// Whether `/auth/local` is enabled.
  final bool localLogin;

  /// Whether signing in through the linked media server is enabled.
  final bool mediaServerLogin;

  /// `SeerrMediaServerType` of the linked media server.
  final int? mediaServerType;

  final bool movie4kEnabled;
  final bool series4kEnabled;

  /// Whether users may request individual seasons rather than whole shows.
  final bool partialRequestsEnabled;

  /// The admin's "Enable Image Caching": the web UI then loads TMDB artwork
  /// through the instance's `/imageproxy` route instead of from TMDB.
  final bool cacheImages;

  /// Trailer host override. Read only for its presence; see
  /// [tmdbImageProxyPath].
  final String? youtubeUrl;

  const SeerrPublicSettings({
    this.initialized = false,
    this.applicationTitle,
    this.localLogin = true,
    this.mediaServerLogin = true,
    this.mediaServerType,
    this.movie4kEnabled = false,
    this.series4kEnabled = false,
    this.partialRequestsEnabled = true,
    this.cacheImages = false,
    this.youtubeUrl,
  });

  String get instanceLabel => (applicationTitle?.isNotEmpty ?? false) ? applicationTitle! : 'Seerr';

  /// Which product answered the probe. Jellyseerr/Seerr always include a
  /// numeric `mediaServerType` (4 = NOT_CONFIGURED even before setup);
  /// Overseerr's `FullPublicSettings` has no such key, so key presence is the
  /// only trustworthy discriminator — titles and version strings are
  /// user-editable.
  SeerrProduct get product => mediaServerType != null ? SeerrProduct.jellyseerr : SeerrProduct.overseerr;

  /// Path under the instance base URL that serves `image.tmdb.org` artwork
  /// (append `/t/p/<size>/<file>`), or null when the admin left image caching
  /// off. The web UI then loads straight from TMDB, and so does Plezy: the
  /// route is mounted either way, but nothing says it works.
  ///
  /// Jellyseerr 2.6.0 moved the route from `/imageproxy/*` to
  /// `/imageproxy/:type/*`, which rejects the untyped form with a 400. The
  /// typed form reaches older servers only because TMDB's CDN ignores the
  /// stray `/tmdb` segment they forward, so each server gets its own form. No
  /// setting describes the route, so the release is read off a public key
  /// that first shipped in it: `youtubeUrl`, always sent ('' by default).
  /// Overseerr never adopted the typed form.
  String? get tmdbImageProxyPath {
    if (!cacheImages) return null;
    return product == SeerrProduct.jellyseerr && youtubeUrl != null ? '/imageproxy/tmdb' : '/imageproxy';
  }

  factory SeerrPublicSettings.fromJson(Map<String, dynamic> json) => _$SeerrPublicSettingsFromJson(json);
}
