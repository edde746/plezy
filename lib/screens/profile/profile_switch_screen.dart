import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../models/plex_home_user.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'profile_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

class ProfileSwitchScreen extends StatelessWidget {
  const ProfileSwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UserProfileProvider>(
      builder: (context, userProvider, child) {
        final users = userProvider.home?.users ?? [];

        return FocusedScrollScaffold(
          title: Text(t.screens.switchProfile),
          slivers: [
            if (userProvider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (userProvider.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userProvider.error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          userProvider.refreshCurrentUser();
                        },
                        child: Text(t.common.retry),
                      ),
                    ],
                  ),
                ),
              )
            else if (users.isEmpty)
              const SliverFillRemaining(
                child: EmptyStateWidget(
                  message: 'No profiles available',
                  subtitle: 'Contact your Plex administrator to add profiles',
                  icon: Symbols.person_off_rounded,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final user = users[index];
                  final isCurrentUser = user.uuid == userProvider.currentUser?.uuid;
                  final isFirstSelectable =
                      !isCurrentUser && !users.take(index).any((u) => u.uuid != userProvider.currentUser?.uuid);

                  return Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: index == 0 ? 16 : 0, bottom: 8),
                    child: Card(
                      child: ProfileListTile(
                        user: user,
                        isCurrentUser: isCurrentUser,
                        autofocus: isFirstSelectable,
                        onTap: () => _switchToUser(context, user),
                      ),
                    ),
                  );
                }, childCount: users.length),
              ),
          ],
        );
      },
    );
  }

  void _switchToUser(BuildContext context, PlexHomeUser user) async {
    final userProvider = context.userProfile;
    final navigator = Navigator.of(context);
    final success = await userProvider.switchToUser(user, context);

    if (success) {
      navigator.pop();
    } else if (context.mounted) {
      showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: user.displayName));
    }
  }
}
