import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_home_user.dart';
import '../providers/user_profile_provider.dart';
import '../utils/user_switching_utils.dart';
import 'user_avatar_widget.dart';
import '../screens/profile_switch_screen.dart';

class ProfileSelector extends StatelessWidget {
  final double avatarSize;
  final bool showCurrentUserOnly;

  const ProfileSelector({
    super.key,
    this.avatarSize = 32,
    this.showCurrentUserOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.currentUser == null) {
          return const SizedBox.shrink();
        }

        if (showCurrentUserOnly || !userProvider.hasMultipleUsers) {
          // Show only current user avatar
          return UserAvatarWidget(
            user: userProvider.currentUser!,
            size: avatarSize,
            onTap: userProvider.hasMultipleUsers
                ? () => _showProfileSwitchDialog(context)
                : null,
          );
        }

        // Show horizontal list of users
        return SizedBox(
          height: avatarSize + 8,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: userProvider.home?.users.length ?? 0,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final users = userProvider.home!.users;
              final user = users[index];
              final isCurrentUser = user.uuid == userProvider.currentUser?.uuid;

              return Container(
                decoration: isCurrentUser
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
                child: Padding(
                  padding: EdgeInsets.all(isCurrentUser ? 2 : 0),
                  child: UserAvatarWidget(
                    user: user,
                    size: avatarSize - (isCurrentUser ? 4 : 0),
                    onTap: isCurrentUser
                        ? () => _showProfileSwitchDialog(context)
                        : () => _switchToUser(context, user),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showProfileSwitchDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()),
    );
  }

  void _switchToUser(BuildContext context, PlexHomeUser user) async {
    await UserSwitchingUtils.switchToUser(context, user);
  }
}
