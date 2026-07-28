import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/dpad_reorder_mixin.dart';
import '../../focus/focus_theme.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../models/livetv_channel.dart';
import '../../providers/multi_server_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/optimized_media_image.dart';

class ReorderFavoritesSheet extends StatefulWidget {
  final List<FavoriteChannel> favorites;
  final Map<String, LiveTvChannel> channelMap;
  final void Function(List<FavoriteChannel>) onReorder;
  final void Function(FavoriteChannel) onRemove;

  const ReorderFavoritesSheet({
    super.key,
    required this.favorites,
    required this.channelMap,
    required this.onReorder,
    required this.onRemove,
  });

  @override
  State<ReorderFavoritesSheet> createState() => _ReorderFavoritesSheetState();
}

class _ReorderFavoritesSheetState extends State<ReorderFavoritesSheet>
    with DpadReorderListMixin<FavoriteChannel, ReorderFavoritesSheet> {
  late List<FavoriteChannel> _tempFavorites;

  final FocusNode _listFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Keyboard navigation: column 0 = row, column 1 = remove button.
  @override
  List<FavoriteChannel> get reorderItems => _tempFavorites;

  @override
  set reorderItems(List<FavoriteChannel> value) => _tempFavorites = value;

  @override
  int get lastReorderColumn => 1;

  @override
  ScrollController? get reorderScrollController => _scrollController;

  @override
  void onReorderMoveConfirmed() => widget.onReorder(_tempFavorites);

  @override
  void onReorderColumnActivated(int column, int index) {
    if (column == 1) _removeItem(index);
  }

  @override
  void initState() {
    super.initState();
    _tempFavorites = List.from(widget.favorites);
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _tempFavorites.removeAt(oldIndex);
      _tempFavorites.insert(newIndex, item);
    });
    widget.onReorder(_tempFavorites);
  }

  void _removeItem(int index) {
    final removed = _tempFavorites[index];
    setState(() {
      _tempFavorites.removeAt(index);
      if (focusedIndex >= _tempFavorites.length) {
        focusedIndex = (_tempFavorites.length - 1).clamp(0, _tempFavorites.length);
      }
    });
    widget.onRemove(removed);

    if (_tempFavorites.isEmpty) {
      OverlaySheetController.popAdaptive(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return Column(
      mainAxisSize: .min,
      children: [
        BottomSheetHeader(title: t.liveTv.reorderFavorites, icon: Symbols.swap_vert_rounded),
        Expanded(
          child: Focus(
            focusNode: _listFocusNode,
            descendantsAreFocusable: false,
            autofocus: isKeyboardMode,
            onKeyEvent: handleReorderKeyEvent,
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              onReorderItem: _onReorder,
              itemCount: _tempFavorites.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final fav = _tempFavorites[index];
                final channel = widget.channelMap[fav.stableKey];
                final isFocused = isKeyboardMode && index == focusedIndex;
                final isMoving = index == movingIndex;

                return _buildFavoriteTile(
                  key: ValueKey(fav.stableKey),
                  fav: fav,
                  channel: channel,
                  index: index,
                  isFocused: isFocused,
                  isMoving: isMoving,
                  focusedColumn: isFocused ? focusedColumn : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteTile({
    required Key key,
    required FavoriteChannel fav,
    required LiveTvChannel? channel,
    required int index,
    required bool isFocused,
    required bool isMoving,
    int? focusedColumn,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final multiServer = context.read<MultiServerProvider>();
    final serverId = serverIdOrNull(channel?.serverId);
    final client = serverId == null ? null : multiServer.getClientForServer(serverId);

    Color? tileColor;
    if (isMoving) {
      tileColor = colorScheme.primaryContainer;
    } else if (isFocused && focusedColumn == 0) {
      tileColor = colorScheme.surfaceContainerHighest;
    }

    final isRemoveButtonFocused = isFocused && focusedColumn == 1;
    final displayName = channel?.displayName ?? fav.title ?? fav.id;
    final channelNumber = channel?.number ?? fav.vcn;

    return ListTile(
      key: key,
      tileColor: tileColor,
      leading: Row(
        mainAxisSize: .min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: AppIcon(
              isMoving ? Symbols.swap_vert_rounded : Symbols.drag_indicator_rounded,
              fill: 1,
              color: isMoving ? colorScheme.primary : IconTheme.of(context).color?.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: channel?.thumb != null && client != null
                ? OptimizedMediaImage.thumb(
                    client: client,
                    imagePath: channel!.thumb,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  )
                : Center(child: AppIcon(Symbols.live_tv_rounded, fill: 1, color: colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
      title: Text(displayName, maxLines: 1, overflow: .ellipsis),
      subtitle: channelNumber != null
          ? Text(
              channelNumber,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: Container(
        decoration: FocusTheme.focusBackgroundDecoration(isFocused: isRemoveButtonFocused, borderRadius: 20),
        child: IconButton(
          icon: const AppIcon(Symbols.close_rounded, fill: 1, size: 20),
          onPressed: () => _removeItem(index),
        ),
      ),
    );
  }
}
