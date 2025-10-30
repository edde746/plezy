import 'package:flutter/material.dart';
import '../models/plex_home_user.dart';
import 'user_avatar_widget.dart';

class ProfileListTile extends StatelessWidget {
  final PlexHomeUser user;
  final VoidCallback onTap;
  final bool isCurrentUser;
  final bool showTrailingIcon;

  const ProfileListTile({
    super.key,
    required this.user,
    required this.onTap,
    this.isCurrentUser = false,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: UserAvatarWidget(user: user, size: 40, showIndicators: false),
      title: Text(user.displayName),
      subtitle: _hasUserAttributes()
          ? Row(children: _buildUserAttributes(theme))
          : null,
      trailing: isCurrentUser
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : (showTrailingIcon ? const Icon(Icons.chevron_right) : null),
      onTap: isCurrentUser ? null : onTap,
      enabled: !isCurrentUser,
    );
  }

  bool _hasUserAttributes() {
    return user.isAdminUser || user.isRestrictedUser || user.requiresPassword;
  }

  List<Widget> _buildUserAttributes(ThemeData theme) {
    final attributes = <Widget>[];
    final labels = <String>[];

    if (user.isAdminUser) {
      labels.add('Admin');
    }

    if (user.isRestrictedUser && !user.isAdminUser) {
      labels.add('Restricted');
    }

    if (user.requiresPassword) {
      labels.add('Protected');
    }

    for (int i = 0; i < labels.length; i++) {
      if (i > 0) {
        attributes.addAll([
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
        ]);
      }

      attributes.add(
        Text(
          labels[i],
          style: TextStyle(
            fontSize: 12,
            color: _getAttributeColor(labels[i], theme),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return attributes;
  }

  Color _getAttributeColor(String attribute, ThemeData theme) {
    switch (attribute) {
      case 'Admin':
        return theme.colorScheme.primary;
      case 'Restricted':
        return theme.colorScheme.warning ?? Colors.orange;
      case 'Protected':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
