import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_icons/simple_icons.dart';

/// Brand marks used for official provider hand-offs and connection actions.
///
/// The icon glyphs come from Simple Icons and are kept in their published
/// shapes and brand colors. When that library has no mark for a provider, the
/// widget uses a neutral name monogram; it never substitutes another brand.
class ConnectorBrandMark extends StatelessWidget {
  const ConnectorBrandMark({
    super.key,
    required this.providerId,
    required this.name,
    this.size = 24,
  });

  final String providerId;
  final String name;
  final double size;

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
    if (icon == null) {
      final scheme = Theme.of(context).colorScheme;
      return Semantics(
        label: name,
        image: true,
        child: Container(
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
        ),
      );
    }

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
}
