import 'package:flutter/material.dart';

/// Shared branding follows the actual surface, including custom app themes.
String _appearance(BuildContext context) =>
    ThemeData.estimateBrightnessForColor(Theme.of(context).colorScheme.surface) == Brightness.dark ? 'dark' : 'light';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 80, this.decorative = false});

  final double size;
  final bool decorative;

  @override
  Widget build(BuildContext context) => Image.asset(
    size <= 64 ? 'assets/branding/plezyng-compact.png' : 'assets/branding/plezyng-mark-${_appearance(context)}.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: decorative ? null : 'PlezyNG',
    excludeFromSemantics: decorative,
  );
}

class AppBrandWordmark extends StatelessWidget {
  const AppBrandWordmark({super.key, this.width = 220, this.height = 55});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/plezyng-wordmark-${_appearance(context)}.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    semanticLabel: 'PlezyNG',
  );
}
