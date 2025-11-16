import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_home_user.dart';
import '../providers/user_profile_provider.dart';
import '../utils/provider_extensions.dart';
import '../widgets/profile_list_tile.dart';
import '../widgets/desktop_app_bar.dart';
import '../i18n/strings.g.dart';

class ProfileSwitchScreen extends StatelessWidget {
  const ProfileSwitchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(title: Text(t.screens.switchProfile)),
          SliverFillRemaining(
            child: Consumer<UserProfileProvider>(
              builder: (context, userProvider, child) {
                final users = userProvider.home?.users ?? [];

                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userProvider.error != null) {
                  return Center(
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
                  );
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No profiles available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact your Plex administrator to add profiles',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(16),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _switchToUser(BuildContext context, PlexHomeUser user) async {
    final userProvider = context.userProfile;
    final success = await userProvider.switchToUser(user, context);

    if (success && context.mounted) {
      Navigator.of(context).pop();
    } else if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.errors.failedToSwitchProfile(displayName: user.displayName),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
