import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plex_home_user.dart';
import '../i18n/strings.g.dart';

class UserAvatarWidget extends StatelessWidget {
  final PlexHomeUser user;
  final double size;
  final bool showIndicators;
  final bool useTextLabels;
  final VoidCallback? onTap;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.size = 40,
    this.showIndicators = true,
    this.useTextLabels = false,
    this.onTap,
  });

  Widget _buildPlaceholderAvatar(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<Widget> _buildTextLabels(ThemeData theme) {
    if (!useTextLabels || !showIndicators) return [];

    final labels = <Widget>[];

    if (user.isAdminUser) {
      labels.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            t.userStatus.admin,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (user.isRestrictedUser && !user.isAdminUser) {
      labels.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.warning ?? Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            t.userStatus.restricted,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (user.requiresPassword) {
      labels.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            t.userStatus.protected,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (labels.isEmpty) return [];

    return [
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        children: labels,
      ),
    ];
  }

  Widget _buildAvatar(ThemeData theme) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Avatar image
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.thumb,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholderAvatar(theme),
              errorWidget: (context, url, error) =>
                  _buildPlaceholderAvatar(theme),
            ),
          ),

          // Indicators (only show icon indicators when not using text labels)
          if (showIndicators && !useTextLabels) ...[
            // Admin badge
            if (user.isAdminUser)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: size * 0.2,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

            // Restricted badge
            if (user.isRestrictedUser && !user.isAdminUser)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.warning ?? Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.security,
                    size: size * 0.2,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),

            // Password indicator
            if (user.requiresPassword)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.lock,
                    size: size * 0.15,
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (useTextLabels) {
      // Return avatar with text labels below
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildAvatar(theme), ..._buildTextLabels(theme)],
        ),
      );
    } else {
      // Return just the avatar (original behavior)
      return GestureDetector(onTap: onTap, child: _buildAvatar(theme));
    }
  }
}

// Extension to add warning color to ColorScheme if not available
extension ColorSchemeExtension on ColorScheme {
  Color? get warning => brightness == Brightness.light
      ? Colors.orange.shade600
      : Colors.orange.shade400;
}
