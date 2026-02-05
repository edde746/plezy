import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/plex_friend.dart';
import '../../providers/friends_provider.dart';

/// Bottom sheet for selecting friends to invite to a Watch Together session
class FriendSelectionSheet extends StatefulWidget {
  final Function(List<PlexFriend>) onFriendsSelected;

  const FriendSelectionSheet({
    super.key,
    required this.onFriendsSelected,
  });

  @override
  State<FriendSelectionSheet> createState() => _FriendSelectionSheetState();
}

class _FriendSelectionSheetState extends State<FriendSelectionSheet> {
  final _searchController = TextEditingController();
  final Set<String> _selectedFriendUUIDs = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load friends when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().loadFriends();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Consumer<FriendsProvider>(
          builder: (context, friendsProvider, child) {
            final filteredFriends = friendsProvider.searchFriends(_searchQuery);

            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Symbols.group_add, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.watchTogether.inviteFriends,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (_selectedFriendUUIDs.isNotEmpty)
                        Badge(
                          label: Text('${_selectedFriendUUIDs.length}'),
                          child: const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: t.watchTogether.searchFriends,
                      prefixIcon: const Icon(Symbols.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Symbols.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),

                const SizedBox(height: 8),

                // Friends list
                Expanded(
                  child: _buildFriendsList(friendsProvider, filteredFriends, scrollController),
                ),

                // Action buttons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(t.common.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _selectedFriendUUIDs.isEmpty ? null : _onInvite,
                            icon: const Icon(Symbols.send),
                            label: Text(
                              _selectedFriendUUIDs.isEmpty
                                  ? t.watchTogether.inviteFriends
                                  : '${t.watchTogether.invite} (${_selectedFriendUUIDs.length})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsList(FriendsProvider provider, List<PlexFriend> friends, ScrollController scrollController) {
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.error, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(t.watchTogether.failedToLoadFriends),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => provider.loadFriends(forceRefresh: true),
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
    }

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.group_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? t.watchTogether.noFriends : t.watchTogether.noFriendsFound,
              style: theme.textTheme.bodyLarge,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t.watchTogether.noFriendsDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: friends.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final friend = friends[index];
        final isSelected = _selectedFriendUUIDs.contains(friend.uuid);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend.thumb.isNotEmpty ? CachedNetworkImageProvider(friend.thumb) : null,
            child: friend.thumb.isEmpty ? Text(friend.displayName[0].toUpperCase()) : null,
          ),
          title: Text(friend.displayName),
          subtitle: friend.username != null ? Text('@${friend.username}') : null,
          trailing: Checkbox(
            value: isSelected,
            onChanged: (value) => _toggleFriend(friend),
          ),
          onTap: () => _toggleFriend(friend),
          selected: isSelected,
        );
      },
    );
  }

  void _toggleFriend(PlexFriend friend) {
    setState(() {
      if (_selectedFriendUUIDs.contains(friend.uuid)) {
        _selectedFriendUUIDs.remove(friend.uuid);
      } else {
        _selectedFriendUUIDs.add(friend.uuid);
      }
    });
  }

  void _onInvite() {
    final friendsProvider = context.read<FriendsProvider>();
    final selectedFriends = friendsProvider.friends.where((f) => _selectedFriendUUIDs.contains(f.uuid)).toList();

    widget.onFriendsSelected(selectedFriends);
    Navigator.pop(context);
  }
}

/// Show the friend selection bottom sheet
Future<void> showFriendSelectionSheet(
  BuildContext context, {
  required Function(List<PlexFriend>) onFriendsSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FriendSelectionSheet(onFriendsSelected: onFriendsSelected),
  );
}
