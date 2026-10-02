import 'package:flutter/material.dart';

/// cli_debrid's brand mark. Unlike [CatalogSourceLogo]'s SVG marks, the
/// source asset is a raster (no SVG available) and is shown in its own
/// fixed colors rather than tinted to the surrounding icon color.
class CliDebridIcon extends StatelessWidget {
  final double size;

  const CliDebridIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/cli_debrid_icon.png', width: size, height: size);
  }
}
