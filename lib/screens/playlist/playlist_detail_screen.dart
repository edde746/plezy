import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_action_bar.dart';
import '../../media/library_query.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_playlist.dart';
import '../../services/media_list_playback_launcher.dart';
import '../../services/music/music_playback_service.dart';
import '../../services/playlist_items_loader.dart';
import '../../services/repeating_playlist_launcher.dart';
import '../../utils/app_logger.dart';
import '../../utils/content_utils.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/continuation_pagination_coordinator.dart';
import '../../utils/music_navigation.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import 'package:provider/provider.dart';
import 'playlist_item_card.dart';
import '../../i18n/strings.g.dart';
import '../../providers/download_provider.dart';
import '../../providers/playback_state_provider.dart';
import '../../utils/platform_detector.dart';
import '../../utils/dialogs.dart';
import '../../utils/download_utils.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../../widgets/listenable_selector.dart';
import '../base_media_list_detail_screen.dart';
import '../focusable_detail_screen_mixin.dart';
import '../libraries/content_state_builder.dart';
import '../../mixins/grid_focus_node_mixin.dart';
import '../../widgets/overlay_sheet.dart';

/// Screen to display the contents of a playlist
class PlaylistDetailScreen extends StatefulWidget {
  final MediaPlaylist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseMediaListDetailScreen<PlaylistDetailScreen>
    with GridFocusNodeMixin<PlaylistDetailScreen>, FocusableDetailScreenMixin<PlaylistDetailScreen> {
  static const int _pageSize = playlistItemsPageSize;

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

  String get _normalizedPlaylistType => widget.playlist.playlistType.trim().toLowerCase();

  /// Audio playlists play through the music session (mini-player /
  /// now-playing) instead of the video play-queue launcher.
  bool get _isAudioPlaylist => _normalizedPlaylistType == 'audio';

  bool get _supportsVideoRepeat {
    if (_normalizedPlaylistType == 'video') return true;
    if (_normalizedPlaylistType == 'audio' || _normalizedPlaylistType == 'photo') {
      return false;
    }
    return items.any((item) => item.kind.isVideo);
  }

  MusicPlayContext get _musicPlayContext =>
      MusicPlayContext(id: widget.playlist.id, title: widget.playlist.title, kind: MusicPlayContextKind.playlist);

  @override
  Future<void> playItems() =>
      _isAudioPlaylist ? _playAudioPlaylist(shuffle: false) : _playVideoPlaylist(shuffle: false);

  @override
  Future<void> shufflePlayItems() =>
      _isAudioPlaylist ? _playAudioPlaylist(shuffle: true) : _playVideoPlaylist(shuffle: true);

  /// Uses the already-loaded items when the playlist is fully paged in;
  /// otherwise fetches the full item list (one loader round-trip) so the
  /// queue isn't truncated to the first page.
  Future<void> _playAudioPlaylist({required bool shuffle, MediaItem? startTrack}) async {
    if (items.isEmpty) {
      showAppSnackBar(context, emptyMessage);
      return;
    }
    await playFetchedTracks(
      context,
      fetch: () async => _isPlaylistFullyLoaded ? items : await fetchAllPlaylistItems(mediaClient, widget.playlist.id),
      playContext: _musicPlayContext,
      onError: (e, stackTrace) =>
          showErrorSnackBar(context, localizedLoadErrorMessage(e, stackTrace, context: widget.playlist.title)),
      startTrack: startTrack,
      shuffle: shuffle,
    );
  }

  /// Starts a video playlist. Repeat-enabled playback uses a fully resident
  /// client-side queue on both Plex and Jellyfin. This makes the final-item to
  /// first-item transition index-based instead of depending on a Plex server
  /// window and opaque playQueueItemID values.
  Future<void> _playVideoPlaylist({required bool shuffle, int? startIndex}) async {
    if (items.isEmpty) {
      showAppSnackBar(context, emptyMessage);
      return;
    }

    final playbackState = context.read<PlaybackStateProvider>();
    final repeatEnabled = playbackState.isRepeatEnabledFor(widget.playlist.globalKey);

    if (!repeatEnabled) {
      if (startIndex == null) {
        if (shuffle) {
          await super.shufflePlayItems();
        } else {
          await super.playItems();
        }
        return;
      }

      if (startIndex < 0 || startIndex >= items.length) return;
      final launcher = MediaListPlaybackLauncher.forItem(context, widget.playlist);
      await launcher.launchFromCollectionOrPlaylist(
        item: widget.playlist,
        shuffle: false,
        startItem: items[startIndex],
        showLoadingIndicator: true,
      );
      return;
    }

    try {
      final allItems = _isPlaylistFullyLoaded
          ? List<MediaItem>.of(items)
          : await fetchAllPlaylistItems(mediaClient, widget.playlist.id);
      if (!mounted) return;
      if (allItems.isEmpty) {
        showAppSnackBar(context, emptyMessage);
        return;
      }

      await launchRepeatingVideoPlaylist(
        context: context,
        playlistContextKey: widget.playlist.globalKey,
        items: allItems,
        shuffle: shuffle,
        startIndex: startIndex,
      );
    } catch (e, stackTrace) {
      appLogger.e('Failed to launch repeating video playlist', error: e, stackTrace: stackTrace);
      if (mounted) {
        showErrorSnackBar(context, localizedLoadErrorMessage(e, stackTrace, context: widget.playlist.title));
      }
    }
  }

  void _toggleVideoPlaylistRepeat() {
    final playbackState = context.read<PlaybackStateProvider>();
    final playlistContextKey = widget.playlist.globalKey;
    playbackState.setRepeatForContext(playlistContextKey, !playbackState.isRepeatEnabledFor(playlistContextKey));
  }

  @override
  List<FocusableAction> getAppBarActions() {
    // Video AND audio playlists download (tracks queue through the same list
    // pipeline); photo/mixed playlists keep the affordance hidden.
    final isDownloadablePlaylist = _normalizedPlaylistType == 'video' || _isAudioPlaylist;
    final ruleKey = syncRuleKey;
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the app bar.
    final hasRule = isDownloadablePlaylist && context.select<DownloadProvider, bool>((p) => p.hasSyncRule(ruleKey));

    final repeatEnabled = context.select<PlaybackStateProvider, bool>(
      (provider) => provider.isRepeatEnabledFor(widget.playlist.globalKey),
    );
    return [
      if (items.isNotEmpty) ...[
        FocusableAction(
          debugLabel: 'playlist_play',
          icon: Symbols.play_arrow_rounded,
          tooltip: t.common.play,
          onPressed: playItems,
        ),
        FocusableAction(
          debugLabel: 'playlist_shuffle',
          icon: Symbols.shuffle_rounded,
          tooltip: t.common.shuffle,
          onPressed: shufflePlayItems,
        ),
        if (_supportsVideoRepeat)
          FocusableAction(
            debugLabel: 'playlist_repeat',
            icon: repeatEnabled ? Symbols.repeat_on_rounded : Symbols.repeat_rounded,
            tooltip: repeatEnabled ? t.music.repeatAll : t.music.repeat,
            onPressed: _toggleVideoPlaylistRepeat,
            iconColor: repeatEnabled ? Theme.of(context).colorScheme.primary : null,
          ),
      ],
      ...buildSyncRuleActions(
        context,
        ruleKey: ruleKey,
        displayTitle: widget.playlist.title,
        hasRule: hasRule,
        showDownload: isDownloadablePlaylist && (items.isNotEmpty || hasRule),
        onDownload: _downloadPlaylist,
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

  // Focus management for regular (non-smart) reorderable lists
  final FocusNode _listFocusNode = FocusNode(debugLabel: 'playlist_list');
  final FocusNode _continuationRetryFocusNode = FocusNode(debugLabel: 'playlist_continuation_retry');

  // Navigation state for regular (non-smart) playlists
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0=content, 1=drag handle, 2=remove button
  final ValueNotifier<int> _focusRevision = ValueNotifier<int>(0);

  void _notifyFocusChanged() => _focusRevision.value++;

  // Move mode state
  int? _movingIndex;
  int? _originalIndex;
  List<MediaItem>? _originalOrder;
  bool _isPlaylistMutationPending = false;

  late final ContinuationPaginationCoordinator<MediaItem> _continuation = ContinuationPaginationCoordinator<MediaItem>(
    loadPage: _fetchPlaylistContinuationPage,
    onPage: _applyPlaylistContinuationPage,
    onStateChanged: _handleContinuationStateChanged,
    onError: (error, stackTrace) =>
        appLogger.w('Failed to finish loading playlist items', error: error, stackTrace: stackTrace),
  );

  bool get _isPlaylistFullyLoaded => _continuation.totalCount != null && items.length >= _continuation.totalCount!;

  bool get _canEditPlaylist => !_isReadOnly && _isPlaylistFullyLoaded;
  bool get _canMutatePlaylist => _canEditPlaylist && !_isPlaylistMutationPending;

  // Estimated item height for scroll-into-view (card + vertical margins)
  static const double _estimatedItemHeight = 114.0;

  @override
  void dispose() {
    _continuation.dispose();
    _listFocusNode.dispose();
    _continuationRetryFocusNode.dispose();
    _focusRevision.dispose();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<void> loadItems() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        items = [];
        _focusedIndex = 0;
        _focusedColumn = 0;
        _movingIndex = null;
        _originalIndex = null;
        _originalOrder = null;
      });
    }

    try {
      LibraryPage<MediaItem>? firstPage;
      final applied = await _continuation.runNewGeneration(() async {
        firstPage = await mediaClient.fetchPlaylistPage(widget.playlist.id, start: 0, size: _pageSize);
      });
      if (!mounted || !applied) return;
      final page = firstPage!;

      _continuation.setContinuation(startIndex: page.items.length, totalCount: page.totalCount);

      setState(() {
        items = List.of(page.items);
        isLoading = false;
      });

      appLogger.d('Loaded ${page.items.length} of ${page.totalCount} items for playlist: ${widget.playlist.title}');
      _autoFocusAfterLoad();

      if (_continuation.hasMore) unawaited(_continuation.loadRemaining());
    } catch (e, stackTrace) {
      final message = localizedLoadErrorMessage(e, stackTrace, context: widget.playlist.title);
      if (!mounted) return;
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  Future<ContinuationPage<MediaItem>> _fetchPlaylistContinuationPage(int startIndex) async {
    final page = await mediaClient.fetchPlaylistPage(widget.playlist.id, start: startIndex, size: _pageSize);
    return ContinuationPage(items: page.items, totalCount: page.totalCount, consumedCount: page.items.length);
  }

  void _applyPlaylistContinuationPage(ContinuationPage<MediaItem> page) {
    if (!mounted) return;
    setState(() {
      items = List.of(items)..addAll(page.items);
    });
  }

  void _handleContinuationStateChanged() {
    if (!mounted) return;
    setState(() {
      if (!_continuation.isLoading && _focusedColumn != 0 && !_canMutatePlaylist) {
        _focusedColumn = 0;
      }
    });
  }

  void _retryPlaylistContinuation() => unawaited(_continuation.retry());

  void _autoFocusAfterLoad() {
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
      final allItems = await fetchAllPlaylistItems(mediaClient, widget.playlist.id);
      if (!mounted) return;
      final result = await showListDownloadOptionsAndQueue(
        context,
        rootMetadata: _playlistAsMetadata(),
        targetType: ContentTypes.playlist,
        items: allItems,
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
      Navigator.pop(context, true); // Signal the parent list to refresh.
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
    if (!_canMutatePlaylist) return;
    if (oldIndex < 0 || oldIndex >= items.length || newIndex < 0 || newIndex >= items.length) return;
    if (oldIndex == newIndex) return;

    final originalOrder = List<MediaItem>.of(items);
    final movedItem = items[oldIndex];
    appLogger.d('Reordering item from $oldIndex to $newIndex');

    setState(() {
      _isPlaylistMutationPending = true;
      _focusedColumn = 0;
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
    final afterItem = _afterItemForIndex(newIndex);

    await _persistMoveToServer(
      originalIndex: oldIndex,
      newIndex: newIndex,
      movedItem: movedItem,
      afterItem: afterItem,
      originalOrder: originalOrder,
    );
  }

  /// Persist a move that was already done in the UI (during move mode).
  /// The item is already at newIndex in the items list.
  Future<void> _persistMoveToServer({
    required int originalIndex,
    required int newIndex,
    required MediaItem movedItem,
    required MediaItem? afterItem,
    required List<MediaItem> originalOrder,
  }) async {
    appLogger.d('Persisting move from $originalIndex to $newIndex');
    Object? failure;
    var success = false;

    try {
      try {
        success = await mediaClient.movePlaylistItem(
          playlistId: widget.playlist.id,
          item: movedItem,
          newIndex: newIndex,
          afterItem: afterItem,
        );
      } catch (e, stackTrace) {
        failure = e;
        appLogger.e('Failed to persist move', error: e, stackTrace: stackTrace);
      }

      if (!mounted || success) return;
      appLogger.e('Failed to persist move, recovering UI');
      if (failure == null) {
        _restorePlaylistOrder(originalOrder, focusedIndex: originalIndex);
      } else {
        await loadItems();
      }
      if (mounted) showErrorSnackBar(context, t.playlists.errorReordering);
    } finally {
      if (mounted) {
        setState(() => _isPlaylistMutationPending = false);
      }
    }
  }

  Future<void> _removeItem(int index) async {
    if (!_canMutatePlaylist) return;
    if (items.isEmpty || index < 0 || index >= items.length) return;
    final originalOrder = List<MediaItem>.of(items);
    final item = items[index];
    appLogger.d('Removing item ${item.title} from playlist');

    setState(() {
      _isPlaylistMutationPending = true;
      _focusedColumn = 0;
      items.removeAt(index);
      if (_focusedIndex >= items.length) {
        _focusedIndex = (items.length - 1).clamp(0, items.length);
      }
    });

    Object? failure;
    var success = false;
    try {
      try {
        success = await mediaClient.removeFromPlaylist(playlistId: widget.playlist.id, item: item);
      } catch (e, stackTrace) {
        failure = e;
        appLogger.e('Failed to remove playlist item', error: e, stackTrace: stackTrace);
      }

      if (!mounted) return;
      if (success) {
        showSuccessSnackBar(context, t.playlists.itemRemoved);
        return;
      }

      appLogger.e('Failed to remove playlist item, recovering UI');
      if (failure == null) {
        _restorePlaylistOrder(originalOrder, focusedIndex: index);
      } else {
        await loadItems();
      }
      if (mounted) showErrorSnackBar(context, t.playlists.errorRemoving);
    } finally {
      if (mounted) {
        setState(() => _isPlaylistMutationPending = false);
      }
    }
  }

  void _restorePlaylistOrder(List<MediaItem> order, {required int focusedIndex}) {
    if (!mounted) return;
    setState(() {
      items = List<MediaItem>.of(order);
      _focusedIndex = items.isEmpty ? 0 : focusedIndex.clamp(0, items.length - 1);
      _focusedColumn = 0;
      _movingIndex = null;
      _originalIndex = null;
      _originalOrder = null;
    });
  }

  Future<void> _playFromItem(int index) async {
    if (items.isEmpty || index < 0 || index >= items.length) return;

    final selectedItem = items[index];
    if (_isAudioPlaylist) {
      await _playAudioPlaylist(shuffle: false, startTrack: selectedItem);
      return;
    }
    await _playVideoPlaylist(shuffle: false, startIndex: index);
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
        // Cancel move mode and suppress route-level back handling.
        backHandledByKeyEvent = true;
        _cancelMoveMode();
      } else {
        // Navigate to the app bar and suppress route-level back handling.
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
        final originalOrder = List<MediaItem>.of(_originalOrder!);
        final movedItem = items[newIndex];
        final afterItem = _afterItemForIndex(newIndex);
        setState(() {
          _isPlaylistMutationPending = true;
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
          // Keep focus on the moved item at its new position
          _focusedIndex = newIndex;
          _focusedColumn = 0;
        });
        unawaited(
          _persistMoveToServer(
            originalIndex: oldIndex,
            newIndex: newIndex,
            movedItem: movedItem,
            afterItem: afterItem,
            originalOrder: originalOrder,
          ),
        );
        return KeyEventResult.handled;
      }
    } else {
      // Navigation mode
      if (key.isUpKey) {
        if (_focusedIndex > 0) {
          _focusedIndex--;
          _focusedColumn = 0;
          _notifyFocusChanged();
          _ensureFocusedVisible();
        } else {
          // First item - navigate to app bar
          navigateToAppBar();
        }
        return KeyEventResult.handled;
      }
      if (key.isDownKey) {
        if (_focusedIndex < items.length - 1) {
          _focusedIndex++;
          _focusedColumn = 0;
          _notifyFocusChanged();
          _ensureFocusedVisible();
          return KeyEventResult.handled;
        }
        if (_continuation.error != null) {
          _continuationRetryFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      if (key.isLeftKey) {
        // Navigate left within columns
        if (_focusedColumn == 0 && _canMutatePlaylist) {
          // Go to drag handle (column 1)
          _focusedColumn = 1;
          _notifyFocusChanged();
          return KeyEventResult.handled;
        } else if (_focusedColumn == 2) {
          // Go back to content
          _focusedColumn = 0;
          _notifyFocusChanged();
          return KeyEventResult.handled;
        }
      }
      if (key.isRightKey) {
        // Navigate right within columns
        if (_focusedColumn == 0 && _canMutatePlaylist) {
          // Go to remove button (column 2)
          _focusedColumn = 2;
          _notifyFocusChanged();
          return KeyEventResult.handled;
        } else if (_focusedColumn == 1) {
          // Go to content from drag handle
          _focusedColumn = 0;
          _notifyFocusChanged();
          return KeyEventResult.handled;
        }
      }
      if (key.isSelectKey) {
        if (_focusedColumn == 0) {
          // Play from this item
          _playFromItem(_focusedIndex);
        } else if (_focusedColumn == 1 && _canMutatePlaylist) {
          // Enter move mode
          setState(() {
            _movingIndex = _focusedIndex;
            _originalIndex = _focusedIndex;
            _originalOrder = List.from(items);
          });
        } else if (_focusedColumn == 2 && _canMutatePlaylist) {
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

  /// Handle route back from [OverlaySheetHost], extending the mixin with move mode support.
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
    final allowsNativeBackGesture = PlatformDetector.isHandheldIOS(context);

    // For regular playlists, wrap the scroll view with the Focus widget
    // (Focus is a RenderObject widget and cannot directly wrap a sliver)
    final needsListFocus = !_isReadOnly && items.isNotEmpty;

    Widget scrollView = CustomScrollView(
      primary: true,
      slivers: [
        CustomAppBar(
          title: Column(
            crossAxisAlignment: .start,
            children: [
              Text(widget.playlist.title, style: const TextStyle(fontSize: 16)),
              if (widget.playlist.smart)
                Row(
                  mainAxisSize: .min,
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
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: .normal),
                    ),
                  ],
                ),
            ],
          ),
          actions: buildFocusableAppBarActions(),
        ),
        ...buildStateSlivers(),
        if (items.isNotEmpty) ...[
          if (_isReadOnly)
            // Smart playlists / Jellyfin playlists: focusable grid view
            // (read-only, no reordering or removal)
            buildFocusableGrid(items: items, onRefresh: updateItem, shape: _isAudioPlaylist ? CardShape.square : null)
          else
            // Plex regular playlists: sliver reorderable list
            _buildReorderableList(isKeyboardMode),
          if (_continuation.isLoading || _continuation.error != null)
            ContinuationStatusSliver(
              error: _continuation.error,
              onRetry: _retryPlaylistContinuation,
              retryFocusNode: _continuationRetryFocusNode,
              onNavigateUp: _isReadOnly ? navigateToGrid : _listFocusNode.requestFocus,
              onBack: handleBackFromContent,
            ),
        ],
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

    return OverlaySheetHost(
      canPop: allowsNativeBackGesture && _movingIndex == null,
      onSystemBack: () {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        final shouldPop = _handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: PrimaryScrollController(
        controller: scrollController,
        child: IosStatusBarTapScrollToTop(
          controller: scrollController,
          child: Scaffold(body: scrollView),
        ),
      ),
    );
  }

  /// Build a reorderable list for regular playlists with focus support
  Widget _buildReorderableList(bool _) {
    return SliverReorderableList(
      onReorderItem: _onReorder,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final keyId = switch (item) {
          PlexMediaItem(:final playlistItemId?) => 'p:$playlistItemId',
          JellyfinMediaItem(:final playlistItemId?) => 'j:$playlistItemId',
          _ => item.id,
        };
        return ListenableSelector<(bool, int?, bool)>(
          key: ValueKey(keyId),
          listenable: _focusRevision,
          selector: () {
            final focused = index == _focusedIndex && !isAppBarFocused;
            return (focused, focused ? _focusedColumn : null, index == _movingIndex);
          },
          builder: (context, focusState, _) {
            final inKeyboardMode = InputModeTracker.isKeyboardMode(context);
            final isFocused = inKeyboardMode && focusState.$1;
            return RepaintBoundary(
              child: PlaylistItemCard(
                item: item,
                index: index,
                onRemove: _canMutatePlaylist ? () => _removeItem(index) : null,
                onTap: () => _playFromItem(index),
                onRefresh: updateItem,
                canReorder: _canMutatePlaylist,
                isFocused: isFocused,
                focusedColumn: isFocused ? focusState.$2 : null,
                isMoving: focusState.$3,
              ),
            );
          },
        );
      },
    );
  }
}
