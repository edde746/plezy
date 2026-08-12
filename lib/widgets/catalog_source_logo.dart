import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/catalog/catalog_item.dart';

/// Brand mark of a service, tinted with the ambient icon color. The single
/// table of brand asset paths: every surface that shows a service logo goes
/// through here, including services that do not participate in the Explore
/// catalog. Uses [SvgTheme.currentColor] so SVGs with multiple explicit fills
/// (AniList keeps its brand-blue L while the A follows the theme) render
/// correctly alongside single-color wordmarks.
class CatalogSourceLogo extends StatelessWidget {
  final CatalogSourceId id;
  final double size;

  const CatalogSourceLogo(this.id, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final asset = switch (id) {
      CatalogSourceId.plex => 'assets/plex_chevron.svg',
      CatalogSourceId.trakt => 'assets/trakt_circlemark.svg',
      CatalogSourceId.mal => 'assets/mal_mark.svg',
      CatalogSourceId.anilist => 'assets/anilist_mark.svg',
      CatalogSourceId.simkl => 'assets/simkl_mark.svg',
      CatalogSourceId.seerr => 'assets/seerr_mark.svg',
      CatalogSourceId.mdblist => 'assets/mdblist_mark.svg',
      CatalogSourceId.theIntroDb => 'assets/theintrodb_mark.svg',
    };
    final color = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}
