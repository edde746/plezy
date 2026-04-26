import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_action_bar.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_playlist.dart';
import '../../services/media_list_playback_launcher.dart';
import '../../services/playlist_items_loader.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import 'package:provider/provider.dart';
import 'playlist_item_card.dart';
import '../../i18n/strings.g.dart';
import '../../providers/download_provider.dart';
import '../../utils/platform_detector.dart';
import '../../utils/dialogs.dart';
import '../../utils/download_utils.dart';
import '../../utils/snackbar_helper.dart';
import '../base_media_list_detail_screen.dart';
import '../focusable_detail_screen_mixin.dart';
import '../../mixins/grid_focus_node_mixin.dart';

/// Screen to display the contents of a playlist
class PlaylistDetailScreen extends StatefulWidget {
  final MediaPlaylist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseMediaListDetailScreen<PlaylistDetailScreen>
    with
        StandardItemLoader<PlaylistDetailScreen>,
        GridFocusNodeMixin<PlaylistDetailScreen>,
        FocusableDetailScreenMixin<PlaylistDetailScreen> {
  @override
  Object get mediaItem => widget.playlist;

  @override
  String get title => widget.playlist.title;

  @override
  String get emptyMessage => t.playlists.emptyPlaylist;

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  @override
  bool get hasItems => items.isNotEmpty;

  /// True when the playlist can't be reordered or have items removed.
  /// Currently only Plex smart playlists (server-side rule-based; managed via
  /// filter rules, not direct edits). Jellyfin has no equivalent concept.
  bool get _isReadOnly => widget.playlist.smart;

  @override
  List<FocusableAction> getAppBarActions() {
    final isVideoPlaylist = widget.playlist.playlistType == 'video';
    final ruleKey = _playlistSyncRuleKey();
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the app bar.
    final hasRule = isVideoPlaylist && context.select<DownloadProvider, bool>((p) => p.hasSyncRule(ruleKey));

    return [
      if (items.isNotEmpty) ...[
        FocusableAction(icon: Symbols.play_arrow_rounded, tooltip: t.common.play, onPressed: playItems),
        FocusableAction(icon: Symbols.shuffle_rounded, tooltip: t.common.shuffle, onPressed: shufflePlayItems),
      ],
      if (!PlatformDetector.isAppleTV() && isVideoPlaylist && (items.isNotEmpty || hasRule))
        FocusableAction(
          icon: hasRule ? Symbols.sync_rounded : Symbols.download_rounded,
          tooltip: hasRule ? t.downloads.manageSyncRule : t.downloads.downloadNow,
          onPressed: hasRule ? _managePlaylistSyncRule : _downloadPlaylist,
          iconColor: hasRule ? Colors.teal : null,
        ),
      if (!PlatformDetector.isAppleTV() && hasRule)
        FocusableAction(
          icon: Symbols.sync_disabled_rounded,
          tooltip: t.downloads.removeSyncRule,
          onPressed: _removePlaylistSyncRule,
        ),
      // Delete works on both backends now (Jellyfin uses /Items/{id} DELETE,
      // wrapped in the neutral [MediaServerClient.deletePlaylist]). Smart
      // playlists are still skipped — they're a Plex concept and are
      // managed server-side via filter rules, not via DELETE.
      if (!widget.playlist.smart)
        FocusableAction(
          icon: Symbols.delete_rounded,
          tooltip: t.playlists.delete,
          onPressed: _deletePlaylist,
          iconColor: Colors.red,
        ),
    ];
  }

  /// Synthesise a [MediaItem] view of the current playlist for the
  /// download_utils helpers.
  MediaItem _playlistAsMetadata() => MediaItem(
    id: widget.playlist.id,
    backend: widget.playlist.backend,
    kind: MediaKind.playlist,
    title: widget.playlist.title,
    thumbPath: widget.playlist.thumbPath,
    serverId: widget.playlist.serverId ?? mediaClient.serverId,
    serverName: widget.playlist.serverName,
  );

  String _playlistSyncRuleKey() {
    final serverId = widget.playlist.serverId ?? mediaClient.serverId;
    return context.read<DownloadProvider>().syncRuleKeyForClient(mediaClient, widget.playlist.id, serverId: serverId);
  }

  Future<void> _managePlaylistSyncRule() =>
      manageSyncRule(context, downloadProvider: context.read<DownloadProvider>(), globalKey: _playlistSyncRuleKey());

  Future<void> _removePlaylistSyncRule() => removeSyncRuleAndSnack(
    context,
    downloadProvider: context.read<DownloadProvider>(),
    globalKey: _playlistSyncRuleKey(),
    displayTitle: widget.playlist.title,
  );

  // Focus management for regular (non-smart) reorderable lists
  final FocusNode _listFocusNode = FocusNode(debugLabel: 'playlist_list');

  // Navigation state for regular (non-smart) playlists
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0=content, 1=drag handle, 2=remove button

  // Move mode state
  int? _movingIndex;
  int? _originalIndex;
  List<MediaItem>? _originalOrder;

  // Estimated item height for scroll-into-view (card + vertical margins)
  static const double _estimatedItemHeight = 114.0;

  @override
  void dispose() {
    _listFocusNode.dispose();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<List<MediaItem>> fetchItems() async {
    return fetchAllPlaylistItems(mediaClient, widget.playlist.id);
  }

  @override
  Future<void> loadItems() async {
    await super.loadItems();

    // Auto-focus after load if in keyboard mode
    if (mounted && items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (InputModeTracker.isKeyboardMode(context)) {
          setState(() {
            isAppBarFocused = false;
            _focusedIndex = 0;
            _focusedColumn = 0;
          });
          if (_isReadOnly) {
            firstItemFocusNode.requestFocus();
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

  /// Navigate from app bar down to content - overridden to handle both grid and list
  @override
  void navigateToGrid() {
    if (!hasItems) return;

    if (_isReadOnly) {
      super.navigateToGrid();
    } else {
      setState(() {
        isAppBarFocused = false;
      });
      _listFocusNode.requestFocus();
    }
  }

  Future<void> _downloadPlaylist() async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

    try {
      final result = await showPlaylistDownloadOptionsAndQueue(
        context,
        playlistMetadata: _playlistAsMetadata(),
        items: items,
        client: mediaClient,
        downloadProvider: downloadProvider,
      );
      if (result == null || !mounted) return;

      showSuccessSnackBar(context, result.toSnackBarMessage());
    } on CellularDownloadBlockedException {
      if (mounted) {
        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.playlists.deleteConfirm,
      message: t.playlists.deleteMessage(name: widget.playlist.title),
    );

    if (!confirmed || !mounted) return;

    bool success = false;
    try {
      success = await mediaClient.deletePlaylist(widget.playlist);
    } catch (e) {
      appLogger.e('Failed to delete playlist', error: e);
    }

    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, t.playlists.deleted);
      Navigator.pop(context); // Return to playlists screen
    } else {
      showErrorSnackBar(context, t.playlists.errorDeleting);
    }
  }

  /// The item that should sit immediately before the moved item at [newIndex],
  /// or null when moving to position 0. Pushes per-backend id-extraction down
  /// into the client implementations.
  MediaItem? _afterItemForIndex(int newIndex) {
    if (newIndex == 0) return null;
    return items[newIndex - 1];
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // Adjust newIndex if moving down in the list
    if (newIndex > oldIndex) {
      newIndex--;
    }

    // Can't reorder if indices are the same
    if (oldIndex == newIndex) return;

    final movedItem = items[oldIndex];

    appLogger.d('Reordering item from $oldIndex to $newIndex');

    // Optimistically update UI
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });

    bool success = false;
    try {
      success = await mediaClient.movePlaylistItem(
        playlistId: widget.playlist.id,
        item: movedItem,
        newIndex: newIndex,
        afterItem: _afterItemForIndex(newIndex),
      );
    } catch (e) {
      appLogger.e('Failed to reorder playlist item', error: e);
    }

    if (!success) {
      // Revert on failure
      appLogger.e('Failed to reorder playlist item, reverting UI');
      if (mounted) {
        setState(() {
          final item = items.removeAt(newIndex);
          items.insert(oldIndex, item);
        });

        showErrorSnackBar(context, t.playlists.errorReordering);
      }
    }
  }

  /// Persist a move that was already done in the UI (during move mode).
  /// The item is already at newIndex in the items list.
  Future<void> _persistMoveToServer(int originalIndex, int newIndex) async {
    final movedItem = items[newIndex];

    appLogger.d('Persisting move from $originalIndex to $newIndex');

    bool success = false;
    try {
      success = await mediaClient.movePlaylistItem(
        playlistId: widget.playlist.id,
        item: movedItem,
        newIndex: newIndex,
        afterItem: _afterItemForIndex(newIndex),
      );
    } catch (e) {
      appLogger.e('Failed to persist move', error: e);
    }

    if (!success) {
      // Revert on failure
      appLogger.e('Failed to persist move, reverting UI');
      if (mounted) {
        _revertMove(newIndex, originalIndex);
        showErrorSnackBar(context, t.playlists.errorReordering);
      }
    }
  }

  /// Revert a move in the UI by moving item from [fromIndex] back to [toIndex].
  void _revertMove(int fromIndex, int toIndex) {
    setState(() {
      final item = items.removeAt(fromIndex);
      items.insert(toIndex, item);
      _focusedIndex = toIndex;
    });
  }

  Future<void> _removeItem(int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;
    final item = items[index];

    appLogger.d('Removing item ${item.title} from playlist');

    // Optimistically update UI
    setState(() {
      items.removeAt(index);
      if (_focusedIndex >= items.length) {
        _focusedIndex = (items.length - 1).clamp(0, items.length);
      }
      if (items.isEmpty) {
        _focusedColumn = 0;
      }
    });

    bool success = false;
    try {
      success = await mediaClient.removeFromPlaylist(playlistId: widget.playlist.id, item: item);
    } catch (e) {
      appLogger.e('Failed to remove playlist item', error: e);
    }

    if (mounted) {
      if (success) {
        showSuccessSnackBar(context, t.playlists.itemRemoved);
      } else {
        // Revert on failure
        appLogger.e('Failed to remove playlist item, reverting UI');
        setState(() {
          items.insert(index, item);
          _focusedIndex = index;
        });

        showErrorSnackBar(context, t.playlists.errorRemoving);
      }
    }
  }

  Future<void> _playFromItem(int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;

    final selectedItem = items[index];
    final launcher = MediaListPlaybackLauncher.forItem(context, widget.playlist);
    await launcher.launchFromCollectionOrPlaylist(
      item: widget.playlist,
      shuffle: false,
      startItem: selectedItem,
      showLoadingIndicator: true,
    );
  }

  /// Ensure the focused item is visible in the list using scroll arithmetic.
  /// Uses estimated item height instead of per-item GlobalKeys.
  void _ensureFocusedVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      final targetOffset = _focusedIndex * _estimatedItemHeight;
      final viewportHeight = scrollController.position.viewportDimension;
      final currentOffset = scrollController.offset;

      // Check if the item is outside the visible area (with some padding)
      if (targetOffset < currentOffset || targetOffset > currentOffset + viewportHeight - _estimatedItemHeight) {
        // Scroll so the item sits ~25% from the top of the viewport
        final scrollTo = (targetOffset - viewportHeight * 0.25).clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        );
        scrollController.animateTo(scrollTo, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  /// Handle key events for list navigation
  KeyEventResult _handleListKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    final backResult = handleBackKeyAction(event, () {
      if (_movingIndex != null) {
        // Cancel move mode, set flag to prevent PopScope exit
        backHandledByKeyEvent = true;
        _cancelMoveMode();
      } else {
        // Navigate to app bar on BACK, set flag to prevent PopScope exit
        handleBackFromContent();
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
          navigateToAppBar();
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
        if (_focusedColumn == 0 && !_isReadOnly) {
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
        if (_focusedColumn == 0 && !_isReadOnly) {
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
        } else if (_focusedColumn == 1 && !_isReadOnly) {
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

  /// Handle back navigation for PopScope - extends mixin with move mode support
  bool _handleBackNavigation() {
    // If BACK was already handled by a key event, don't pop
    if (backHandledByKeyEvent) {
      backHandledByKeyEvent = false;
      return false;
    }

    // If in move mode, cancel move instead of navigating
    if (_movingIndex != null) {
      _cancelMoveMode();
      return false;
    }

    return handleBackNavigation();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    // For regular playlists, wrap the scroll view with the Focus widget
    // (Focus is a RenderObject widget and cannot directly wrap a sliver)
    final needsListFocus = !_isReadOnly && items.isNotEmpty;

    Widget scrollView = CustomScrollView(
      controller: scrollController,
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
                    AppIcon(
                      Symbols.auto_awesome_rounded,
                      fill: 1,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.playlists.smartPlaylist,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: buildFocusableAppBarActions(),
        ),
        ...buildStateSlivers(),
        if (items.isNotEmpty)
          if (_isReadOnly)
            // Smart playlists / Jellyfin playlists: focusable grid view
            // (read-only, no reordering or removal)
            buildFocusableGrid(items: items, onRefresh: updateItem)
          else
            // Plex regular playlists: sliver reorderable list
            _buildReorderableList(isKeyboardMode),
      ],
    );

    if (needsListFocus) {
      scrollView = Focus(
        autofocus: isKeyboardMode && !isAppBarFocused,
        focusNode: _listFocusNode,
        onKeyEvent: _handleListKeyEvent,
        onFocusChange: (hasFocus) {
          if (hasFocus && mounted) {
            setState(() {
              isAppBarFocused = false;
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

  /// Build a reorderable list for regular playlists with focus support
  Widget _buildReorderableList(bool _) {
    return SliverReorderableList(
      onReorder: _onReorder,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        // Check keyboard mode directly to ensure we get latest value
        final inKeyboardMode = InputModeTracker.isKeyboardMode(context);
        final isFocused = inKeyboardMode && index == _focusedIndex && !isAppBarFocused;
        final isMoving = index == _movingIndex;

        // Both backends populate playlistItemId in playlist responses; the
        // backend prefix avoids collisions if the same numeric/uuid string
        // ever shows up across servers in the same key namespace.
        final keyId = switch (item) {
          PlexMediaItem(:final playlistItemId?) => 'p:$playlistItemId',
          JellyfinMediaItem(:final playlistItemId?) => 'j:$playlistItemId',
          _ => item.id,
        };
        return RepaintBoundary(
          key: ValueKey(keyId),
          child: PlaylistItemCard(
            item: item,
            index: index,
            onRemove: () => _removeItem(index),
            onTap: () => _playFromItem(index),
            onRefresh: updateItem,
            canReorder: !_isReadOnly,
            isFocused: isFocused,
            focusedColumn: isFocused ? _focusedColumn : null,
            isMoving: isMoving,
          ),
        );
      },
    );
  }
}
