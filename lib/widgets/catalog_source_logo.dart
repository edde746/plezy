import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/catalog/catalog_item.dart';

/// Brand mark of a catalog source (Trakt circle, MAL square) — or any
/// service SVG via [CatalogSourceLogo.asset] — tinted with the ambient icon
/// color. Uses [SvgTheme.currentColor] so SVGs with multiple explicit fills
/// (AniList keeps its brand-blue L while the A follows the theme) render
/// correctly alongside single-color wordmarks.
class CatalogSourceLogo extends StatelessWidget {
  final CatalogSourceId? id;
  final String? assetPath;
  final double size;

  const CatalogSourceLogo(CatalogSourceId this.id, {super.key, this.size = 20}) : assetPath = null;

  /// For services that aren't catalog sources (AniList, Simkl).
  const CatalogSourceLogo.asset(String this.assetPath, {super.key, this.size = 20}) : id = null;

  @override
  Widget build(BuildContext context) {
    final asset =
        assetPath ??
        switch (id!) {
          CatalogSourceId.trakt => 'assets/trakt_circlemark.svg',
          CatalogSourceId.mal => 'assets/mal_mark.svg',
          CatalogSourceId.seerr => 'assets/seerr_mark.svg',
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
