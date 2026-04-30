import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
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

class _ReorderFavoritesSheetState extends State<ReorderFavoritesSheet> {
  late List<FavoriteChannel> _tempFavorites;

  // Keyboard navigation state
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0 = row, 1 = remove button
  int? _movingIndex;
  int? _originalIndex;
  List<FavoriteChannel>? _originalOrder;
  final FocusNode _listFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _backKeyDownSeen = false;

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

  void _ensureFocusedVisible() {
    if (!_scrollController.hasClients) return;

    const double itemHeight = 72.0;
    const double listTopPadding = 8.0;
    final double targetTop = listTopPadding + (_focusedIndex * itemHeight);
    final double targetBottom = targetTop + itemHeight;

    final double viewportTop = _scrollController.offset;
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double viewportBottom = viewportTop + viewportHeight;

    if (targetTop >= viewportTop && targetBottom <= viewportBottom) return;

    final double destination = (targetTop - viewportHeight * 0.25).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(destination, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isBackKey) {
      if (event is KeyDownEvent) {
        _backKeyDownSeen = true;
      } else if (event is KeyUpEvent && !_backKeyDownSeen) {
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent) {
        _backKeyDownSeen = false;
      }
    }

    final backResult = handleBackKeyAction(event, () {
      if (_movingIndex != null) {
        setState(() {
          if (_originalOrder != null) {
            _tempFavorites = List.from(_originalOrder!);
          }
          _focusedIndex = _originalIndex ?? 0;
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
      } else {
        OverlaySheetController.popAdaptive(context);
      }
    });
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    if (_movingIndex != null) {
      if (key.isUpKey && _movingIndex! > 0) {
        setState(() {
          final item = _tempFavorites.removeAt(_movingIndex!);
          _tempFavorites.insert(_movingIndex! - 1, item);
          _movingIndex = _movingIndex! - 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _movingIndex! < _tempFavorites.length - 1) {
        setState(() {
          final item = _tempFavorites.removeAt(_movingIndex!);
          _tempFavorites.insert(_movingIndex! + 1, item);
          _movingIndex = _movingIndex! + 1;
          _focusedIndex = _movingIndex!;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        widget.onReorder(_tempFavorites);
        setState(() {
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
        return KeyEventResult.handled;
      }
    } else {
      if (key.isUpKey && _focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
          _focusedColumn = 0;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _focusedIndex < _tempFavorites.length - 1) {
        setState(() {
          _focusedIndex++;
          _focusedColumn = 0;
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isLeftKey && _focusedColumn > 0) {
        setState(() => _focusedColumn--);
        return KeyEventResult.handled;
      }
      if (key.isRightKey && _focusedColumn < 1) {
        setState(() => _focusedColumn++);
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        if (_focusedColumn == 0) {
          setState(() {
            _movingIndex = _focusedIndex;
            _originalIndex = _focusedIndex;
            _originalOrder = List.from(_tempFavorites);
          });
        } else if (_focusedColumn == 1) {
          _removeItem(_focusedIndex);
        }
        return KeyEventResult.handled;
      }
    }

    if (key.isDpadDirection) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tempFavorites.removeAt(oldIndex);
      _tempFavorites.insert(newIndex, item);
    });
    widget.onReorder(_tempFavorites);
  }

  void _removeItem(int index) {
    final removed = _tempFavorites[index];
    setState(() {
      _tempFavorites.removeAt(index);
      if (_focusedIndex >= _tempFavorites.length) {
        _focusedIndex = (_tempFavorites.length - 1).clamp(0, _tempFavorites.length);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        BottomSheetHeader(title: t.liveTv.reorderFavorites, icon: Symbols.swap_vert_rounded),
        Expanded(
          child: Focus(
            focusNode: _listFocusNode,
            autofocus: isKeyboardMode,
            onKeyEvent: _handleKeyEvent,
            child: ReorderableListView.builder(
              scrollController: _scrollController,
              onReorder: _onReorder,
              itemCount: _tempFavorites.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final fav = _tempFavorites[index];
                final channel = widget.channelMap[fav.stableKey];
                final isFocused = isKeyboardMode && index == _focusedIndex;
                final isMoving = index == _movingIndex;

                return _buildFavoriteTile(
                  key: ValueKey(fav.stableKey),
                  fav: fav,
                  channel: channel,
                  index: index,
                  isFocused: isFocused,
                  isMoving: isMoving,
                  focusedColumn: isFocused ? _focusedColumn : null,
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
    final client = multiServer.getClientForServer(channel?.serverId ?? '');

    Color? tileColor;
    if (isMoving) {
      tileColor = colorScheme.primaryContainer;
    } else if (isFocused && focusedColumn == 0) {
      tileColor = colorScheme.surfaceContainerHighest;
    }

    final isRemoveButtonFocused = isFocused && focusedColumn == 1;
    final displayName = channel?.displayName ?? fav.title ?? fav.id;
    final channelNumber = channel?.number ?? fav.vcn;

    return Container(
      key: key,
      decoration: BoxDecoration(color: tileColor),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
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
        title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
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
      ),
    );
  }
}
