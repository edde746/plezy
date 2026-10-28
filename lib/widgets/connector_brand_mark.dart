import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_icons/simple_icons.dart';

/// Brand marks used for official provider hand-offs and connection actions.
///
/// The icon glyphs come from Simple Icons and are kept in their published
/// shapes and brand colors. When neither a bundled asset nor Simple Icons has
/// the provider's mark, the widget can hotlink its official-domain logo from
/// Brandfetch when the build has been configured with a public client ID.
class ConnectorBrandMark extends StatelessWidget {
  const ConnectorBrandMark({
    super.key,
    required this.providerId,
    required this.name,
    this.size = 24,
    this.logoDomain,
  });

  final String providerId;
  final String name;
  final double size;

  /// Curated official domain for directory entries whose provider ID is not
  /// itself a domain. Caller supplied values are validated before use.
  final String? logoDomain;

  /// Brandfetch documents this as a public client ID for its Logo API.
  static const String _brandfetchClientId = String.fromEnvironment('BRANDFETCH_CLIENT_ID');

  /// Some providers explicitly reserve reproduction rights in their terms.
  /// Their domains require a separate build-time approval after an agreement.
  static const String _brandfetchApprovedDomains = String.fromEnvironment('BRANDFETCH_APPROVED_DOMAINS');
  static const Set<String> _explicitApprovalDomains = {'alldebrid.com', 'torbox.app'};

  /// Official domains for connection-only providers without a directory host.
  static const Map<String, String> _logoDomains = {
    'hardcover': 'hardcover.app',
    'real-debrid': 'real-debrid.com',
    'all-debrid': 'alldebrid.com',
    'premiumize': 'premiumize.me',
    'torbox': 'torbox.app',
    'stremio': 'stremio.com',
    'plex': 'plex.tv',
    'plex-streaming': 'plex.tv',
    'jellyfin': 'jellyfin.org',
    'emby': 'emby.media',
    'seerr': 'seerr.dev',
    'komga': 'komga.org',
    'audiobookshelf': 'audiobookshelf.org',
    'discord': 'discord.com',
  };

  /// Provider IDs map to the corresponding Simple Icons slug. This is the
  /// shared mapping for title hand-offs, Watchmode results, and commerce links.
  static const Map<String, String> _iconNames = {
    'netflix': 'netflix',
    'max': 'max',
    'paramount-plus': 'paramountplus',
    'starz': 'starz',
    'apple-tv-plus': 'appletv',
    'apple-tv-store': 'appletv',
    'crunchyroll': 'crunchyroll',
    'mubi': 'mubi',
    'tubi': 'tubi',
    'cbc-gem': 'cbc',
    'plex-streaming': 'plex',
    'youtube': 'youtube',
    'itvx': 'itvx',
    'channel-4': 'channel4',
    'roku-channel': 'roku',
    'samsung-tv-plus': 'samsung',
    'dazn': 'dazn',
    'fubo': 'fubo',
    'youtube-movies': 'youtube',
    'fandango-at-home': 'fandango',
    'rakuten-tv': 'rakuten',
    'kobo': 'rakutenkobo',
    'kobo-audiobooks': 'rakutenkobo',
    'kobo-comics': 'rakutenkobo',
    'indigo': 'indigo',
    'google-play-books': 'googleplay',
    'apple-books': 'apple',
    'gutenberg': 'gutenberg',
    'audible': 'audible',
    'spotify-audiobooks': 'spotify',
    'humble-comics': 'humblebundle',
    'humble-store': 'humblebundle',
    'gumroad-comics': 'gumroad',
    'webtoon': 'webtoon',
    'apple-music': 'applemusic',
    'spotify': 'spotify',
    'tidal': 'tidal',
    'soundcloud': 'soundcloud',
    'bandcamp': 'bandcamp',
    'deezer': 'deezer',
    'youtube-music': 'youtubemusic',
    'pandora': 'pandora',
    'iheartradio': 'iheartradio',
    'steam-store': 'steam',
    'gog': 'gogdotcom',
    'epic-games': 'epicgames',
    'playstation-store': 'playstation',
    'itch': 'itchdotio',
    'plex': 'plex',
    'jellyfin': 'jellyfin',
    'emby': 'emby',
    'trakt': 'trakt',
    'myanimelist': 'myanimelist',
    'anilist': 'anilist',
    'simkl': 'simkl',
    'mdblist': 'mdblist',
    'discord': 'discord',
    'stremio': 'stremio',
    'google-drive': 'googledrive',
    'dropbox': 'dropbox',
  };

  static const Map<String, String> _assetNames = {
    'amazon-books': 'fontawesome_amazon.svg',
    'amazon-kindle': 'fontawesome_amazon.svg',
    'amazon-music': 'fontawesome_amazon.svg',
    'comixology': 'fontawesome_amazon.svg',
    'xbox-store': 'fontawesome_xbox.svg',
    'hardcover': 'selfhst_hardcover.svg',
    'real-debrid': 'selfhst_real_debrid.svg',
    'premiumize': 'dashboard_premiumize.svg',
    'hulu': 'dashboard_hulu.svg',
    'peacock': 'dashboard_peacock.svg',
  };

  String? get _resolvedIconName {
    final explicit = _iconNames[providerId];
    if (explicit != null) return explicit;
    final exactSlug = providerId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return SimpleIcons.values.containsKey(exactSlug) ? exactSlug : null;
  }

  String get _monogram {
    final words = name.trim().split(RegExp(r'[^A-Za-z0-9]+')).where((part) => part.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  String? get _brandfetchUrl {
    if (_brandfetchClientId.trim().isEmpty) return null;
    final domain = _normalizeDomain(logoDomain ?? _logoDomains[providerId]);
    if (domain == null) return null;

    final requiresApproval = _explicitApprovalDomains.any(
      (protectedDomain) => domain == protectedDomain || domain.endsWith('.$protectedDomain'),
    );
    final approvedDomains = _brandfetchApprovedDomains
        .split(',')
        .map((entry) => entry.trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    if (requiresApproval && !approvedDomains.contains(domain)) return null;

    return Uri.https('cdn.brandfetch.io', '/domain/$domain', {'c': _brandfetchClientId.trim()}).toString();
  }

  static String? _normalizeDomain(String? value) {
    if (value == null) return null;
    var domain = value.trim().toLowerCase();
    domain = domain.replaceFirst(RegExp(r'^https?://'), '').split('/').first;
    if (!RegExp(r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$').hasMatch(domain)) {
      return null;
    }
    return domain;
  }

  Widget _monogramMark(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Text(
        _monogram,
        maxLines: 1,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: size * .36,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
      ),
    );
  }

  Widget _brandfetchMark(BuildContext context, String url) {
    final placeholder = _monogramMark(context);
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetName = _assetNames[providerId];
    if (assetName != null) {
      return Semantics(
        label: name,
        image: true,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xfff4f4f4),
            borderRadius: BorderRadius.circular(size * .24),
          ),
          padding: EdgeInsets.all(size * .13),
          child: SvgPicture.asset(
            'assets/provider_marks/$assetName',
            fit: BoxFit.contain,
            theme: const SvgTheme(currentColor: Color(0xff111111)),
          ),
        ),
      );
    }

    final iconName = _resolvedIconName;
    final icon = iconName == null ? null : SimpleIcons.values[iconName];
    if (icon != null) {
      final brandColor = SimpleIconColors.values[iconName] ?? Theme.of(context).colorScheme.onSurface;
      final needsLightSurface = brandColor.computeLuminance() < .16;
      return Semantics(
        label: name,
        image: true,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: needsLightSurface ? const Color(0xfff4f4f4) : Colors.transparent,
            borderRadius: BorderRadius.circular(size * .24),
          ),
          child: Icon(icon, size: size * .74, color: brandColor),
        ),
      );
    }

    final brandfetchUrl = _brandfetchUrl;
    return Semantics(
      label: name,
      image: true,
      child: brandfetchUrl == null ? _monogramMark(context) : _brandfetchMark(context, brandfetchUrl),
    );
  }
}
