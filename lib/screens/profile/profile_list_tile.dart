import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../i18n/strings.g.dart';
import '../../models/plex_home_user.dart';
import 'user_avatar_widget.dart';

enum UserAttribute { admin, restricted, protected }

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
                t.userStatus.current,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            )
          : (showTrailingIcon ? const AppIcon(Symbols.chevron_right_rounded, fill: 1) : null),
      onTap: isCurrentUser ? null : onTap,
      enabled: !isCurrentUser,
    );
  }

  bool _hasUserAttributes() {
    return user.isAdminUser || user.isRestrictedUser || user.requiresPassword;
  }

  List<Widget> _buildUserAttributes(ThemeData theme) {
    final attributes = <Widget>[];
    final List<UserAttribute> userAttributes = [];

    if (user.isAdminUser) {
      userAttributes.add(UserAttribute.admin);
    }

    if (user.isRestrictedUser && !user.isAdminUser) {
      userAttributes.add(UserAttribute.restricted);
    }

    if (user.requiresPassword) {
      userAttributes.add(UserAttribute.protected);
    }

    for (int i = 0; i < userAttributes.length; i++) {
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

      final attribute = userAttributes[i];

      attributes.add(
        Text(
          _getAttributeLabel(attribute),
          style: TextStyle(
            fontSize: 12,
            color: _getAttributeColor(attribute, theme),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return attributes;
  }

  String _getAttributeLabel(UserAttribute attribute) {
    switch (attribute) {
      case UserAttribute.admin:
        return t.userStatus.admin;
      case UserAttribute.restricted:
        return t.userStatus.restricted;
      case UserAttribute.protected:
        return t.userStatus.protected;
    }
  }

  Color _getAttributeColor(UserAttribute attribute, ThemeData theme) {
    switch (attribute) {
      case UserAttribute.admin:
        return theme.colorScheme.primary;
      case UserAttribute.restricted:
        return theme.colorScheme.warning ?? Colors.orange;
      case UserAttribute.protected:
        return theme.colorScheme.secondary;
    }
  }
}
