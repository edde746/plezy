import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../media/media_backend.dart';

/// Tiny SVG badge for a [MediaBackend] (Plex chevron / Jellyfin mark).
/// Both assets render in `currentColor` so they pick up whatever foreground
/// the parent provides — pass [color] to override, otherwise inherits from
/// [DefaultTextStyle] / `IconTheme`.
class BackendBadge extends StatelessWidget {
  final MediaBackend backend;
  final double size;
  final Color? color;

  const BackendBadge({super.key, required this.backend, this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    final tint =
        color ??
        DefaultTextStyle.of(context).style.color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final asset = switch (backend) {
      MediaBackend.plex => 'assets/plex_chevron.svg',
      MediaBackend.jellyfin => 'assets/jellyfin_icon.svg',
    };
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: tint),
    );
  }
}
