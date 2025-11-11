import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_home_user.dart';
import '../providers/user_profile_provider.dart';
import '../utils/user_switching_utils.dart';
import 'profile_list_tile.dart';
import '../i18n/strings.g.dart';

class ProfileSwitchDialog extends StatelessWidget {
  const ProfileSwitchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UserProfileProvider>(
      builder: (context, userProvider, child) {
        final users = userProvider.home?.users ?? [];

        return AlertDialog(
          content: SizedBox(
            width: double.maxFinite,
            height: users.isEmpty ? 100 : (users.length * 72.0).clamp(100, 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userProvider.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (users.isEmpty)
                  Expanded(
                    child: Center(child: Text(t.profile.noUsersAvailable)),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isCurrentUser =
                            user.uuid == userProvider.currentUser?.uuid;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ProfileListTile(
                              user: user,
                              isCurrentUser: isCurrentUser,
                              onTap: () => _switchToUser(context, user),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                if (userProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      userProvider.error!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.cancel),
            ),
          ],
        );
      },
    );
  }

  void _switchToUser(BuildContext context, PlexHomeUser user) async {
    await UserSwitchingUtils.switchToUser(context, user, popOnSuccess: true);
  }
}
