import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../models/plex_home_user.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'profile_list_tile.dart';
import '../../focus/focusable_wrapper.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

class ProfileSwitchScreen extends StatefulWidget {
  final bool requireSelection;

  const ProfileSwitchScreen({super.key, this.requireSelection = false});

  @override
  State<ProfileSwitchScreen> createState() => _ProfileSwitchScreenState();
}

class _ProfileSwitchScreenState extends State<ProfileSwitchScreen> {
  bool _allowPop = false;
  final FocusNode _firstSelectableFocusNode = FocusNode();
  bool _focusRequested = false;

  @override
  void dispose() {
    _firstSelectableFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !widget.requireSelection || _allowPop,
      child: Consumer<UserProfileProvider>(
        builder: (context, userProvider, child) {
          final users = userProvider.home?.users ?? [];

          return FocusedScrollScaffold(
            title: Text(t.screens.switchProfile),
            automaticallyImplyLeading: !widget.requireSelection,
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

                    if (isFirstSelectable && !_focusRequested) {
                      _focusRequested = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _firstSelectableFocusNode.requestFocus();
                      });
                    }

                    return Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, top: index == 0 ? 16 : 0, bottom: 8),
                      child: FocusableWrapper(
                        autofocus: isFirstSelectable,
                        focusNode: isFirstSelectable ? _firstSelectableFocusNode : null,
                        disableScale: true,
                        onSelect: isCurrentUser ? null : () => _switchToUser(context, user),
                        child: Card(
                          child: ProfileListTile(
                            user: user,
                            isCurrentUser: isCurrentUser,
                            onTap: () => _switchToUser(context, user),
                          ),
                        ),
                      ),
                    );
                  }, childCount: users.length),
                ),
            ],
          );
        },
      ),
    );
  }

  void _switchToUser(BuildContext context, PlexHomeUser user) async {
    final userProvider = context.userProfile;
    final navigator = Navigator.of(context);
    final success = await userProvider.switchToUser(user, context);

    if (success) {
      if (widget.requireSelection) {
        if (!mounted) return;
        setState(() => _allowPop = true);
      }
      navigator.pop(true);
    } else if (context.mounted) {
      showErrorSnackBar(context, t.errors.failedToSwitchProfile(displayName: user.displayName));
    }
  }
}
