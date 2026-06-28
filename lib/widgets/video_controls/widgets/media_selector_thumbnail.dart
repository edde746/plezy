import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_icon.dart';

class MediaSelectorThumbnail extends StatelessWidget {
  final double width;
  final double height;
  final Widget? thumbnail;
  final bool isCurrent;
  final double radius;
  final Color borderColor;
  final Color fallbackBackgroundColor;
  final Color fallbackIconColor;
  final double fallbackIconSize;
  final IconData fallbackIcon;
  final bool blurThumbnail;

  const MediaSelectorThumbnail({
    super.key,
    required this.width,
    required this.height,
    required this.thumbnail,
    required this.isCurrent,
    required this.borderColor,
    this.radius = 4,
    this.fallbackBackgroundColor = Colors.white10,
    this.fallbackIconColor = Colors.white38,
    this.fallbackIconSize = 28,
    this.fallbackIcon = Symbols.movie_rounded,
    this.blurThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.all(Radius.circular(radius));
    final child = thumbnail != null
        ? _maybeBlurThumbnail(thumbnail!)
        : Container(
            color: fallbackBackgroundColor,
            child: Center(
              child: AppIcon(fallbackIcon, fill: 1, color: fallbackIconColor, size: fallbackIconSize),
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          ClipRRect(borderRadius: borderRadius, child: child),
          if (isCurrent)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.fromBorderSide(BorderSide(color: borderColor, width: 2)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _maybeBlurThumbnail(Widget child) {
    if (!blurThumbnail) return child;
    return ClipRect(
      child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: child),
    );
  }
}
