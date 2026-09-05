import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../media/library_query.dart';
import '../media/media_item.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../utils/media_server_http_client.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'focusable_list_tile.dart';
import 'pill_input_decoration.dart';

typedef _PickerPageLoader<T> = Future<LibraryPage<T>> Function(int start, int size, AbortController abort);

typedef _PickerItemBuilder<T> = Widget Function(BuildContext context, T item);

/// Shared loading, filtering, and TV focus shell for collection-style pickers.
class _PickerDialogScaffold<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final String emptyMessage;
  final _PickerPageLoader<T> loadPage;
  final String Function(T item) itemTitle;
  final _PickerItemBuilder<T> itemBuilder;

  const _PickerDialogScaffold({
    required this.title,
    required this.searchHint,
    required this.emptyMessage,
    required this.loadPage,
    required this.itemTitle,
    required this.itemBuilder,
  });

  @override
  State<_PickerDialogScaffold<T>> createState() => _PickerDialogScaffoldState<T>();
}

class _PickerDialogScaffoldState<T> extends State<_PickerDialogScaffold<T>> {
  static const int _pageSize = 100;
  static const int _filterThreshold = 10;

  final _filterController = TextEditingController();
  final _filterFocusNode = FocusNode(debugLabel: 'PickerFilter');
  final _firstItemFocusNode = FocusNode(debugLabel: 'PickerFirstItem');
  final _abortController = AbortController();
  final _scrollController = ScrollController();
  final List<T> _items = [];
  List<T> _filteredItems = [];
  bool _isLoading = false;
  bool _initialFocusRequested = false;
  String? _errorMessage;
  int? _totalCount;

  bool get _hasMore => _totalCount == null || _items.length < _totalCount!;
  bool get _showFilter => _items.length >= _filterThreshold;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadNextPage());
  }

  @override
  void dispose() {
    _abortController.abort();
    _scrollController.dispose();
    _filterController.dispose();
    _filterFocusNode.dispose();
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_loadNextPage());
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      while (mounted && _hasMore) {
        final page = await widget.loadPage(_items.length, _pageSize, _abortController);
        if (!mounted) return;
        setState(() {
          _items.addAll(page.items);
          _totalCount = page.totalCount;
          _applyFilter(_filterController.text);
        });
        if (_filterController.text.isEmpty || page.items.isEmpty) break;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
    _requestInitialFocus();
  }

  void _requestInitialFocus() {
    if (_initialFocusRequested) return;
    _initialFocusRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (_showFilter ? _filterFocusNode : _firstItemFocusNode).requestFocus();
    });
  }

  void _onFilterChanged(String query) {
    setState(() => _applyFilter(query));
    if (query.isNotEmpty && _hasMore) {
      unawaited(_loadNextPage());
    }
  }

  void _applyFilter(String query) {
    final lower = query.toLowerCase();
    _filteredItems = lower.isEmpty
        ? List.of(_items)
        : _items.where((item) => widget.itemTitle(item).toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showStatus = _hasMore || _isLoading || _errorMessage != null || _filteredItems.isEmpty;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: .min,
          children: [
            if (_showFilter) ...[
              FocusableTextField(
                controller: _filterController,
                focusNode: _filterFocusNode,
                tvTextInputPresentation: TvTextInputPresentation.flutterOverlay,
                tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.afterFirstFocus,
                onNavigateDown: _firstItemFocusNode.requestFocus,
                decoration: pillInputDecoration(
                  context,
                  hintText: widget.searchHint,
                  prefixIcon: const AppIcon(Symbols.search_rounded, size: 20),
                ),
                onChanged: _onFilterChanged,
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _filteredItems.length + 1 + (showStatus ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FocusableListTile(
                      focusNode: _firstItemFocusNode,
                      leading: const AppIcon(Symbols.add_rounded, fill: 1),
                      title: Text(t.common.createNew),
                      onTap: () => Navigator.pop(context, '_create_new'),
                    );
                  }

                  if (index <= _filteredItems.length) {
                    return widget.itemBuilder(context, _filteredItems[index - 1]);
                  }

                  if (_errorMessage != null) {
                    return FocusableListTile(
                      leading: const AppIcon(Symbols.error_rounded, fill: 1),
                      title: Text(t.messages.errorLoading(error: _errorMessage!)),
                      onTap: _loadNextPage,
                    );
                  }
                  if (_hasMore || _isLoading) {
                    if (_hasMore && !_isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) unawaited(_loadNextPage());
                      });
                    }
                    return const Padding(
                      padding: .all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Padding(
                    padding: const .all(16),
                    child: Text(widget.emptyMessage, textAlign: TextAlign.center),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel)],
    );
  }
}

/// Dialog to select a playlist or create a new one.
class PlaylistSelectionDialog extends StatelessWidget {
  final MediaServerClient client;

  const PlaylistSelectionDialog({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return _PickerDialogScaffold<MediaPlaylist>(
      title: t.playlists.selectPlaylist,
      searchHint: t.playlists.searchPlaylists,
      emptyMessage: t.playlists.noPlaylists,
      loadPage: (start, size, abort) =>
          client.fetchPlaylistsPage(playlistType: 'video', smart: false, start: start, size: size, abort: abort),
      itemTitle: (playlist) => playlist.title,
      itemBuilder: (context, playlist) {
        final leafCount = playlist.leafCount;
        final subtitleText = leafCount == 1 ? t.playlists.oneItem : t.playlists.itemCount(count: leafCount ?? 0);
        return FocusableListTile(
          leading: playlist.smart
              ? const AppIcon(Symbols.auto_awesome_rounded, fill: 1)
              : const AppIcon(Symbols.playlist_play_rounded, fill: 1),
          title: Text(playlist.title),
          subtitle: playlist.leafCount != null ? Text(subtitleText) : null,
          onTap: playlist.smart
              ? null // Disable smart playlists
              : () => Navigator.pop(context, playlist.id),
          enabled: !playlist.smart,
        );
      },
    );
  }
}

/// Dialog to select a collection or create a new one
class CollectionSelectionDialog extends StatelessWidget {
  final MediaServerClient client;
  final String libraryId;

  const CollectionSelectionDialog({super.key, required this.client, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return _PickerDialogScaffold<MediaItem>(
      title: t.collections.selectCollection,
      searchHint: t.collections.searchCollections,
      emptyMessage: t.libraries.noCollections,
      loadPage: (start, size, abort) => client.fetchCollectionsPage(libraryId, start: start, size: size, abort: abort),
      itemTitle: (collection) => collection.title ?? '',
      itemBuilder: (context, collection) => FocusableListTile(
        leading: const AppIcon(Symbols.collections_rounded, fill: 1),
        title: Text(collection.title ?? ''),
        subtitle: collection.childCount != null ? Text(t.playlists.itemCount(count: collection.childCount!)) : null,
        onTap: () => Navigator.pop(context, collection.id),
      ),
    );
  }
}
