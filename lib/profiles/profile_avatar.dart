import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/image_cache_service.dart';
import '../utils/initials_palette.dart';
import '../widgets/app_icon.dart';
import 'profile.dart';

class ProfileAvatar extends StatelessWidget {
  final Profile? profile;
  final double size;
  final bool showLockBadge;

  const ProfileAvatar({super.key, required this.profile, this.size = 40, this.showLockBadge = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = profile;
    final lockBadgeSize = size * 0.34;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: SizedBox(width: size, height: size, child: _buildContent(theme, p)),
          ),
          if (showLockBadge && p != null && p.isPinProtected)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: lockBadgeSize,
                height: lockBadgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 1),
                ),
                child: AppIcon(
                  Symbols.lock_rounded,
                  fill: 1,
                  size: lockBadgeSize * 0.7,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Profile? p) {
    if (p == null) {
      return Container(color: theme.colorScheme.surfaceContainerHighest);
    }
    final thumb = p.avatarThumbUrl;
    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        cacheManager: PlexImageCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (_, _) => _initialFallback(theme, p),
        errorBuilder: (_, _, _) => _initialFallback(theme, p),
      );
    }
    return _initialFallback(theme, p);
  }

  Widget _initialFallback(ThemeData theme, Profile p) {
    return Container(
      color: colorForName(p.displayName, theme),
      alignment: Alignment.center,
      child: Text(
        initialOf(p.displayName),
        style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }
}
