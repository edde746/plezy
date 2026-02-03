import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../../services/play_queue_launcher.dart';
import '../../models/plex_playlist.dart';
import '../../models/plex_metadata.dart';
import '../../utils/app_logger.dart';
import '../../utils/provider_extensions.dart';
import '../../widgets/focusable_media_card.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../utils/grid_size_calculator.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../providers/settings_provider.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import 'playlist_item_card.dart';
import '../../i18n/strings.g.dart';
import '../../utils/dialogs.dart';
import '../base_media_list_detail_screen.dart';

/// Screen to display the contents of a playlist
class PlaylistDetailScreen extends StatefulWidget {
  final PlexPlaylist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseMediaListDetailScreen<PlaylistDetailScreen>
    with StandardItemLoader<PlaylistDetailScreen> {
  @override
  dynamic get mediaItem => widget.playlist;

  @override
  String get title => widget.playlist.title;

  @override
  String get emptyMessage => t.playlists.emptyPlaylist;

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  // Scroll controller for scrolling to top when app bar is focused
  final ScrollController _scrollController = ScrollController();

  // Focus management
  final FocusNode _listFocusNode = FocusNode(debugLabel: 'playlist_list');
  final FocusNode _playButtonFocusNode = FocusNode(debugLabel: 'playlist_play');
  final FocusNode _shuffleButtonFocusNode = FocusNode(debugLabel: 'playlist_shuffle');
  final FocusNode _deleteButtonFocusNode = FocusNode(debugLabel: 'playlist_delete');

  // Navigation state for regular (non-smart) playlists
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0=content, 1=drag handle, 2=remove button

  // Move mode state
  int? _movingIndex;
  int? _originalIndex;
  List<PlexMetadata>? _originalOrder;

  // Estimated item height for scroll-into-view (card + vertical margins)
  static const double _estimatedItemHeight = 114.0;

  // App bar focus state
  bool _isAppBarFocused = false;
  int _appBarFocusedButton = 0; // 0=play, 1=shuffle, 2=delete

  // Flag to prevent PopScope from exiting when BACK was handled by a key handler
  bool _backHandledByKeyEvent = false;

  // Grid focus for smart playlists
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'playlist_first_item');
  final Map<int, FocusNode> _gridItemFocusNodes = {};
  int? _lastFocusedGridIndex;
  int _contentVersion = 0;
  int _lastFocusedContentVersion = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _listFocusNode.dispose();
    _playButtonFocusNode.dispose();
    _shuffleButtonFocusNode.dispose();
    _deleteButtonFocusNode.dispose();
    _firstItemFocusNode.dispose();
    for (final node in _gridItemFocusNodes.values) {
      node.dispose();
    }
    _gridItemFocusNodes.clear();
    super.dispose();
  }

  /// Get or create a focus node for a grid item at the given index
  FocusNode _getGridItemFocusNode(int index) {
    return _gridItemFocusNodes.putIfAbsent(index, () => FocusNode(debugLabel: 'playlist_grid_item_$index'));
  }

  @override
  Future<List<PlexMetadata>> fetchItems() async {
    return await client.getPlaylist(widget.playlist.ratingKey);
  }

  @override
  Future<void> loadItems() async {
    // Increment content version when loading fresh content
    _contentVersion++;
    await super.loadItems();

    // Auto-focus after load if in keyboard mode
    if (mounted && items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (InputModeTracker.isKeyboardMode(context)) {
          setState(() {
            _isAppBarFocused = false;
            _focusedIndex = 0;
            _focusedColumn = 0;
          });
          if (widget.playlist.smart) {
            _firstItemFocusNode.requestFocus();
          } else {
            _listFocusNode.requestFocus();
          }
        }
      });
    }
  }

  @override
  String getLoadSuccessMessage(int itemCount) {
    return 'Loaded $itemCount items for playlist: ${widget.playlist.title}';
  }

  /// Get the correct PlexClient for this playlist's server
  PlexClient _getClientForPlaylist() {
    return context.getClientForServer(widget.playlist.serverId!);
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.playlists.deleteConfirm,
      message: t.playlists.deleteMessage(name: widget.playlist.title),
    );

    if (confirmed == true && mounted) {
      final success = await client.deletePlaylist(widget.playlist.ratingKey);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.deleted)));
          Navigator.pop(context); // Return to playlists screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorDeleting)));
        }
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // Adjust newIndex if moving down in the list
    if (newIndex > oldIndex) {
      newIndex--;
    }

    // Can't reorder if indices are the same
    if (oldIndex == newIndex) return;

    final movedItem = items[oldIndex];

    // Check if item has playlistItemID (required for reordering)
    if (movedItem.playlistItemID == null) {
      appLogger.e('Cannot reorder: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
      return;
    }

    // Determine the "after" item ID
    // If moving to position 0, afterPlaylistItemId should be 0 (move to top)
    // Otherwise, use the playlistItemID of the item before the new position
    final int afterPlaylistItemId;
    if (newIndex == 0) {
      afterPlaylistItemId = 0; // Move to top
    } else {
      final afterItem = items[newIndex - 1];
      if (afterItem.playlistItemID == null) {
        appLogger.e('Cannot reorder: after item missing playlistItemID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
        }
        return;
      }
      afterPlaylistItemId = afterItem.playlistItemID!;
    }

    appLogger.d('Reordering item from $oldIndex to $newIndex (after ID: $afterPlaylistItemId)');

    // Optimistically update UI
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });

    // Call API to persist the change
    final success = await client.movePlaylistItem(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: movedItem.playlistItemID!,
      afterPlaylistItemId: afterPlaylistItemId,
    );

    if (!success) {
      // Revert on failure
      appLogger.e('Failed to reorder playlist item, reverting UI');
      if (mounted) {
        setState(() {
          final item = items.removeAt(newIndex);
          items.insert(oldIndex, item);
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
    }
  }

  /// Persist a move that was already done in the UI (during move mode).
  /// The item is already at newIndex in the items list.
  Future<void> _persistMoveToServer(int originalIndex, int newIndex) async {
    // Item is already at newIndex in the list
    final movedItem = items[newIndex];

    // Check if item has playlistItemID (required for reordering)
    if (movedItem.playlistItemID == null) {
      appLogger.e('Cannot persist move: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
        // Revert the UI change
        setState(() {
          final item = items.removeAt(newIndex);
          items.insert(originalIndex, item);
          _focusedIndex = originalIndex;
        });
      }
      return;
    }

    // Determine the "after" item ID based on where the item is now
    final int afterPlaylistItemId;
    if (newIndex == 0) {
      afterPlaylistItemId = 0; // Move to top
    } else {
      final afterItem = items[newIndex - 1];
      if (afterItem.playlistItemID == null) {
        appLogger.e('Cannot persist move: after item missing playlistItemID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
          // Revert the UI change
          setState(() {
            final item = items.removeAt(newIndex);
            items.insert(originalIndex, item);
            _focusedIndex = originalIndex;
          });
        }
        return;
      }
      afterPlaylistItemId = afterItem.playlistItemID!;
    }

    appLogger.d('Persisting move from $originalIndex to $newIndex (after ID: $afterPlaylistItemId)');

    // Call API to persist the change (UI is already updated)
    final success = await client.movePlaylistItem(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: movedItem.playlistItemID!,
      afterPlaylistItemId: afterPlaylistItemId,
    );

    if (!success) {
      // Revert on failure
      appLogger.e('Failed to persist move, reverting UI');
      if (mounted) {
        setState(() {
          final item = items.removeAt(newIndex);
          items.insert(originalIndex, item);
          _focusedIndex = originalIndex;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorReordering)));
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final item = items[index];

    // Check if item has playlistItemID (required for removal)
    if (item.playlistItemID == null) {
      appLogger.e('Cannot remove: item missing playlistItemID');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
      return;
    }

    appLogger.d('Removing item ${item.title} (playlistItemID: ${item.playlistItemID}) from playlist');

    // Optimistically update UI
    setState(() {
      items.removeAt(index);
    });

    // Call API to persist the change
    final success = await client.removeFromPlaylist(
      playlistId: widget.playlist.ratingKey,
      playlistItemId: item.playlistItemID.toString(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.itemRemoved)));
      } else {
        // Revert on failure
        appLogger.e('Failed to remove playlist item, reverting UI');
        setState(() {
          items.insert(index, item);
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.playlists.errorRemoving)));
      }
    }
  }

  Future<void> _playFromItem(int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;

    final plexClient = _getClientForPlaylist();
    final selectedItem = items[index];

    final launcher = PlayQueueLauncher(
      context: context,
      client: plexClient,
      serverId: widget.playlist.serverId,
      serverName: widget.playlist.serverName,
    );

    await launcher.launchFromPlaylistItem(
      playlist: widget.playlist,
      selectedItem: selectedItem,
      showLoadingIndicator: true,
    );
  }

  /// Ensure the focused item is visible in the list using scroll arithmetic.
  /// Uses estimated item height instead of per-item GlobalKeys.
  void _ensureFocusedVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final targetOffset = _focusedIndex * _estimatedItemHeight;
      final viewportHeight = _scrollController.position.viewportDimension;
      final currentOffset = _scrollController.offset;

      // Check if the item is outside the visible area (with some padding)
      if (targetOffset < currentOffset || targetOffset > currentOffset + viewportHeight - _estimatedItemHeight) {
        // Scroll so the item sits ~25% from the top of the viewport
        final scrollTo = (targetOffset - viewportHeight * 0.25).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(scrollTo, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  /// Handle key events for list navigation
  KeyEventResult _handleListKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    final backResult = handleBackKeyAction(event, () {
      if (_movingIndex != null) {
        // Cancel move mode, set flag to prevent PopScope exit
        _backHandledByKeyEvent = true;
        _cancelMoveMode();
      } else {
        // Navigate to app bar on BACK, set flag to prevent PopScope exit
        _handleBackFromContent();
      }
    });
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_movingIndex != null) {
      // Move mode - arrows reorder the item
      if (key.isUpKey && _movingIndex! > 0) {
        setState(() {
          final item = items.removeAt(_movingIndex!);
          items.insert(_movingIndex! - 1, item);
          _movingIndex = _movingIndex! - 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _movingIndex! < items.length - 1) {
        setState(() {
          final item = items.removeAt(_movingIndex!);
          items.insert(_movingIndex! + 1, item);
          _movingIndex = _movingIndex! + 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        // Confirm move - persist to server (UI is already updated during move)
        final oldIndex = _originalIndex!;
        final newIndex = _movingIndex!;
        setState(() {
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
          // Keep focus on the moved item at its new position
          _focusedIndex = newIndex;
          _focusedColumn = 0;
        });
        // Persist the change via API (list is already in correct order)
        _persistMoveToServer(oldIndex, newIndex);
        return KeyEventResult.handled;
      }
    } else {
      // Navigation mode
      if (key.isUpKey) {
        if (_focusedIndex > 0) {
          setState(() {
            _focusedIndex--;
            _focusedColumn = 0; // Reset to row when changing rows
          });
          _ensureFocusedVisible();
        } else {
          // First item - navigate to app bar
          _navigateToAppBar();
        }
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _focusedIndex < items.length - 1) {
        setState(() {
          _focusedIndex++;
          _focusedColumn = 0; // Reset to row when changing rows
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isLeftKey) {
        // Navigate left within columns
        if (_focusedColumn == 0 && widget.playlist.smart == false) {
          // Go to drag handle (column 1)
          setState(() => _focusedColumn = 1);
          return KeyEventResult.handled;
        } else if (_focusedColumn == 2) {
          // Go back to content
          setState(() => _focusedColumn = 0);
          return KeyEventResult.handled;
        }
      }
      if (key.isRightKey) {
        // Navigate right within columns
        if (_focusedColumn == 0) {
          // Go to remove button (column 2)
          setState(() => _focusedColumn = 2);
          return KeyEventResult.handled;
        } else if (_focusedColumn == 1) {
          // Go to content from drag handle
          setState(() => _focusedColumn = 0);
          return KeyEventResult.handled;
        }
      }
      if (key.isSelectKey) {
        if (_focusedColumn == 0) {
          // Play from this item
          _playFromItem(_focusedIndex);
        } else if (_focusedColumn == 1 && !widget.playlist.smart) {
          // Enter move mode
          setState(() {
            _movingIndex = _focusedIndex;
            _originalIndex = _focusedIndex;
            _originalOrder = List.from(items);
          });
        } else if (_focusedColumn == 2) {
          // Remove item
          _removeItem(_focusedIndex);
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events when app bar is focused
  KeyEventResult _handleAppBarKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final hasDelete = !widget.playlist.smart;
    final maxButton = hasDelete ? 2 : 1;

    final backResult = handleBackKeyAction(event, () => Navigator.pop(context));
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (key.isLeftKey && _appBarFocusedButton > 0) {
      setState(() => _appBarFocusedButton--);
      _focusAppBarButton(_appBarFocusedButton);
      return KeyEventResult.handled;
    }
    if (key.isRightKey && _appBarFocusedButton < maxButton) {
      setState(() => _appBarFocusedButton++);
      _focusAppBarButton(_appBarFocusedButton);
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      // Return focus to list/grid
      setState(() => _isAppBarFocused = false);
      if (items.isNotEmpty) {
        if (widget.playlist.smart) {
          _navigateToGrid();
        } else {
          _listFocusNode.requestFocus();
        }
      }
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      _triggerAppBarButton(_appBarFocusedButton);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _focusAppBarButton(int index) {
    switch (index) {
      case 0:
        _playButtonFocusNode.requestFocus();
        break;
      case 1:
        _shuffleButtonFocusNode.requestFocus();
        break;
      case 2:
        _deleteButtonFocusNode.requestFocus();
        break;
    }
  }

  void _triggerAppBarButton(int index) {
    switch (index) {
      case 0:
        playItems();
        break;
      case 1:
        shufflePlayItems();
        break;
      case 2:
        if (!widget.playlist.smart) _deletePlaylist();
        break;
    }
  }

  /// Navigate focus from app bar down to the grid
  void _navigateToGrid() {
    if (items.isEmpty) return;

    // Check if we should restore focus to the last focused item
    final shouldRestoreFocus =
        _lastFocusedGridIndex != null &&
        _lastFocusedContentVersion == _contentVersion &&
        _lastFocusedGridIndex! < items.length;

    final targetIndex = shouldRestoreFocus ? _lastFocusedGridIndex! : 0;

    if (targetIndex == 0) {
      _firstItemFocusNode.requestFocus();
    } else {
      _getGridItemFocusNode(targetIndex).requestFocus();
    }
  }

  /// Navigate from grid to app bar
  void _navigateToAppBar() {
    setState(() {
      _isAppBarFocused = true;
      _appBarFocusedButton = 0;
    });
    _playButtonFocusNode.requestFocus();
    // Scroll to top to show the app bar
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  /// Handle BACK key from grid/list - navigate to app bar and set flag to prevent PopScope exit
  void _handleBackFromContent() {
    _backHandledByKeyEvent = true;
    _navigateToAppBar();
  }

  /// Handle back navigation for PopScope
  bool _handleBackNavigation() {
    // If BACK was already handled by a key event, don't pop
    if (_backHandledByKeyEvent) {
      _backHandledByKeyEvent = false;
      return false;
    }

    // If in move mode, cancel move instead of navigating
    if (_movingIndex != null) {
      _cancelMoveMode();
      return false;
    }

    if (_isAppBarFocused) {
      // Already on app bar, allow exit
      return true;
    } else {
      // Focus app bar first
      _navigateToAppBar();
      return false;
    }
  }

  /// Build focusable app bar actions
  List<Widget> _buildFocusableAppBarActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    Widget buildFocusableButton({
      required FocusNode focusNode,
      required int buttonIndex,
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      Color? color,
    }) {
      final isFocused = isKeyboardMode && _isAppBarFocused && _appBarFocusedButton == buttonIndex;
      return Focus(
        focusNode: focusNode,
        onKeyEvent: _handleAppBarKeyEvent,
        child: Container(
          decoration: isFocused
              ? BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20))
              : null,
          child: IconButton(icon: AppIcon(icon, fill: 1), tooltip: tooltip, onPressed: onPressed, color: color),
        ),
      );
    }

    return [
      if (items.isNotEmpty)
        buildFocusableButton(
          focusNode: _playButtonFocusNode,
          buttonIndex: 0,
          icon: Symbols.play_arrow_rounded,
          tooltip: t.discover.play,
          onPressed: playItems,
        ),
      if (items.isNotEmpty)
        buildFocusableButton(
          focusNode: _shuffleButtonFocusNode,
          buttonIndex: 1,
          icon: Symbols.shuffle_rounded,
          tooltip: t.common.shuffle,
          onPressed: shufflePlayItems,
        ),
      if (!widget.playlist.smart)
        buildFocusableButton(
          focusNode: _deleteButtonFocusNode,
          buttonIndex: 2,
          icon: Symbols.delete_rounded,
          tooltip: t.playlists.delete,
          onPressed: _deletePlaylist,
          color: Colors.red,
        ),
    ];
  }

  /// Cancel move mode if active, returns true if cancelled
  bool _cancelMoveMode() {
    if (_movingIndex != null) {
      setState(() {
        if (_originalOrder != null) {
          items = List.from(_originalOrder!);
        }
        _focusedIndex = _originalIndex ?? 0;
        _movingIndex = null;
        _originalIndex = null;
        _originalOrder = null;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    // For regular playlists, wrap the scroll view with the Focus widget
    // (Focus is a RenderObject widget and cannot directly wrap a sliver)
    final needsListFocus = !widget.playlist.smart && items.isNotEmpty;

    Widget scrollView = CustomScrollView(
      controller: _scrollController,
      slivers: [
        CustomAppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.playlist.title, style: const TextStyle(fontSize: 16)),
              if (widget.playlist.smart)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(Symbols.auto_awesome_rounded, fill: 1, size: 12, color: Colors.blue[300]),
                    const SizedBox(width: 4),
                    Text(
                      t.playlists.smartPlaylist,
                      style: TextStyle(fontSize: 11, color: Colors.blue[300], fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
            ],
          ),
          actions: _buildFocusableAppBarActions(),
        ),
        ...buildStateSlivers(),
        if (items.isNotEmpty)
          if (widget.playlist.smart)
            // Smart playlists: Use focusable grid view (cannot be reordered)
            _buildSmartPlaylistGrid(isKeyboardMode)
          else
            // Regular playlists: Use sliver reorderable list
            _buildReorderableList(isKeyboardMode),
      ],
    );

    if (needsListFocus) {
      scrollView = Focus(
        autofocus: isKeyboardMode && !_isAppBarFocused,
        focusNode: _listFocusNode,
        onKeyEvent: _handleListKeyEvent,
        onFocusChange: (hasFocus) {
          if (hasFocus && mounted) {
            setState(() {
              _isAppBarFocused = false;
            });
          }
        },
        child: scrollView,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        if (didPop) return;
        final shouldPop = _handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(body: scrollView),
    );
  }

  /// Build a focusable grid for smart playlists
  Widget _buildSmartPlaylistGrid(bool isKeyboardMode) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final columnCount = GridSizeCalculator.getColumnCount(context, settingsProvider.libraryDensity);
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          sliver: SliverGrid.builder(
            gridDelegate: MediaGridDelegate.createDelegate(context: context, density: settingsProvider.libraryDensity),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isFirstRow = GridSizeCalculator.isFirstRow(index, columnCount);
              final focusNode = index == 0 ? _firstItemFocusNode : _getGridItemFocusNode(index);

              return FocusableMediaCard(
                key: Key(item.ratingKey),
                item: item,
                focusNode: focusNode,
                onRefresh: updateItem,
                onNavigateUp: isFirstRow ? _navigateToAppBar : null,
                onBack: _handleBackFromContent,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _lastFocusedGridIndex = index;
                    _lastFocusedContentVersion = _contentVersion;
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Build a reorderable list for regular playlists with focus support
  Widget _buildReorderableList(bool isKeyboardMode) {
    return SliverReorderableList(
      onReorder: _onReorder,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Check keyboard mode directly to ensure we get latest value
        final inKeyboardMode = InputModeTracker.isKeyboardMode(context);
        final isFocused = inKeyboardMode && index == _focusedIndex && !_isAppBarFocused;
        final isMoving = index == _movingIndex;

        return RepaintBoundary(
          key: ValueKey(item.playlistItemID ?? item.ratingKey),
          child: PlaylistItemCard(
            item: item,
            index: index,
            onRemove: () => _removeItem(index),
            onTap: () => _playFromItem(index),
            onRefresh: updateItem,
            canReorder: !widget.playlist.smart,
            isFocused: isFocused,
            focusedColumn: isFocused ? _focusedColumn : null,
            isMoving: isMoving,
          ),
        );
      },
    );
  }
}
