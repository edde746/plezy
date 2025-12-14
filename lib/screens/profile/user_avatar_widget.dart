import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/plex_home_user.dart';
import '../../i18n/strings.g.dart';

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
      child: AppIcon(
        Symbols.person_rounded,
        fill: 1,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Helper method to build a circular badge with an icon
  ///
  /// [icon] - The icon to display in the badge
  /// [color] - The background color of the badge
  /// [iconColor] - The color of the icon
  /// [position] - The position of the badge ('topRight' or 'bottomRight')
  /// [sizeRatio] - The size ratio relative to the avatar size (default 0.3)
  Widget _buildBadge({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String position,
    double sizeRatio = 0.3,
  }) {
    final badgeSize = size * sizeRatio;
    final iconSize =
        size * (sizeRatio * 0.67); // Approximately 2/3 of badge size

    return Positioned(
      top: position == 'topRight' ? 0 : null,
      bottom: position == 'bottomRight' ? 0 : null,
      right: 0,
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: 1,
          ),
        ),
        child: AppIcon(icon, fill: 1, size: iconSize, color: iconColor),
      ),
    );
  }

  /// Helper method to build a text label chip
  ///
  /// [text] - The text to display in the chip
  /// [backgroundColor] - The background color of the chip
  /// [textColor] - The color of the text
  Widget _buildLabelChip({
    required BuildContext context,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildTextLabels(BuildContext context, ThemeData theme) {
    if (!useTextLabels || !showIndicators) return [];

    final labels = <Widget>[];

    if (user.isAdminUser) {
      labels.add(
        _buildLabelChip(
          context: context,
          text: t.userStatus.admin,
          backgroundColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    if (user.isRestrictedUser && !user.isAdminUser) {
      labels.add(
        _buildLabelChip(
          context: context,
          text: t.userStatus.restricted,
          backgroundColor: theme.colorScheme.warning ?? Colors.orange,
          textColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    if (user.requiresPassword) {
      labels.add(
        _buildLabelChip(
          context: context,
          text: t.userStatus.protected,
          backgroundColor: theme.colorScheme.secondary,
          textColor: theme.colorScheme.onSecondary,
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

  Widget _buildAvatar(BuildContext context, ThemeData theme) {
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
              placeholder: (ctx, url) => _buildPlaceholderAvatar(theme),
              errorWidget: (ctx, url, error) => _buildPlaceholderAvatar(theme),
            ),
          ),

          // Indicators (only show icon indicators when not using text labels)
          if (showIndicators && !useTextLabels) ...[
            // Admin badge
            if (user.isAdminUser)
              _buildBadge(
                context: context,
                icon: Symbols.admin_panel_settings_rounded,
                color: theme.colorScheme.primary,
                iconColor: theme.colorScheme.onPrimary,
                position: 'topRight',
              ),

            // Restricted badge
            if (user.isRestrictedUser && !user.isAdminUser)
              _buildBadge(
                context: context,
                icon: Symbols.security_rounded,
                color: theme.colorScheme.warning ?? Colors.orange,
                iconColor: theme.colorScheme.onPrimary,
                position: 'topRight',
              ),

            // Password indicator
            if (user.requiresPassword)
              _buildBadge(
                context: context,
                icon: Symbols.lock_rounded,
                color: theme.colorScheme.secondary,
                iconColor: theme.colorScheme.onSecondary,
                position: 'bottomRight',
                sizeRatio: 0.25,
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
          children: [
            _buildAvatar(context, theme),
            ..._buildTextLabels(context, theme),
          ],
        ),
      );
    } else {
      // Return just the avatar (original behavior)
      return GestureDetector(onTap: onTap, child: _buildAvatar(context, theme));
    }
  }
}

// Extension to add warning color to ColorScheme if not available
extension ColorSchemeExtension on ColorScheme {
  Color? get warning => brightness == Brightness.light
      ? Colors.orange.shade600
      : Colors.orange.shade400;
}
