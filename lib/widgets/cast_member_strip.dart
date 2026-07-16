import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/card_focus_scope.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../media/media_server_client.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/media_image_helper.dart';
import '../utils/scroll_utils.dart';
import 'focus_builders.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'optimized_media_image.dart';

/// One person in a [CastMemberStrip]: display name, secondary line
/// (character/role), and an image path — server-relative (resolved through
/// [CastMemberStrip.imageClient]) or an absolute URL.
typedef CastStripMember = ({String name, String? secondary, String? imagePath});

/// Horizontal cast/character strip shared by detail screens.
///
/// Owns the locked-focus row model — focus node, highlighted index, horizontal
/// scrolling, and D-pad handling — while its parent only defines which section
/// comes before and after it.
class CastMemberStrip extends StatefulWidget {
  static const double _innerPadding = 3;

  final List<CastStripMember> members;

  /// Resolves server-relative image paths; null when [members] carry
  /// absolute URLs.
  final MediaServerClient? imageClient;
  final void Function(int index)? onMemberTap;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final String debugLabel;

  const CastMemberStrip({
    super.key,
    required this.members,
    this.imageClient,
    this.onMemberTap,
    this.onNavigateUp,
    this.onNavigateDown,
    this.debugLabel = 'cast_row',
  });

  /// Card width matching the poster grids' cell width for the user's
  /// density setting.
  static double responsiveCardWidth(BuildContext context) {
    final density = SettingsService.instance.read(SettingsService.libraryDensity);
    final availableWidth = MediaQuery.sizeOf(context).width;
    return GridSizeCalculator.getCellWidth(availableWidth, context, density);
  }

  /// The strip's fixed height for a given card width:
  /// image + inner padding + text area + list padding + focus scale headroom.
  static double heightForCardWidth(double cardWidth) => cardWidth + _innerPadding * 2 + 66 + 10;

  static double _itemExtentForCardWidth(double cardWidth) => cardWidth + _innerPadding * 2 + 4;

  @override
  State<CastMemberStrip> createState() => CastMemberStripState();
}

class CastMemberStripState extends State<CastMemberStrip> {
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: widget.debugLabel)..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CastMemberStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.debugLabel != oldWidget.debugLabel) {
      _focusNode.debugLabel = widget.debugLabel;
    }
    if (widget.members.isEmpty) {
      _focusedIndex = 0;
    } else if (_focusedIndex >= widget.members.length) {
      _focusedIndex = widget.members.length - 1;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void requestFocus() {
    if (widget.members.isEmpty) return;
    _focusNode.requestFocus();
    _scrollToFocusedMember();
  }

  void _scrollToFocusedMember() {
    scrollListToIndex(
      _scrollController,
      _focusedIndex,
      itemExtent: CastMemberStrip._itemExtentForCardWidth(CastMemberStrip.responsiveCardWidth(context)),
      leadingPadding: 0,
    );
  }

  void _moveFocus(int delta) {
    if (widget.members.isEmpty) return;
    final target = (_focusedIndex + delta).clamp(0, widget.members.length - 1).toInt();
    if (target == _focusedIndex) return;
    setState(() => _focusedIndex = target);
    _scrollToFocusedMember();
  }

  void _activateMember(int index) {
    if (_focusedIndex != index) setState(() => _focusedIndex = index);
    _focusNode.requestFocus();
    widget.onMemberTap?.call(index);
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isBackKey || widget.members.isEmpty) return KeyEventResult.ignored;

    final onMemberTap = widget.onMemberTap;
    if (onMemberTap != null) {
      final selectResult = handleOneShotSelect(event, () => onMemberTap(_focusedIndex));
      if (selectResult != KeyEventResult.ignored) return selectResult;
    }
    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isLeftKey) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (key.isRightKey) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (key.isUpKey && widget.onNavigateUp != null) {
      widget.onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (key.isDownKey && widget.onNavigateDown != null) {
      widget.onNavigateDown!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final cardWidth = CastMemberStrip.responsiveCardWidth(context);
    final imageSize = cardWidth;

    return Focus(
      focusNode: _focusNode,
      descendantsAreFocusable: false,
      onKeyEvent: _handleKeyEvent,
      child: SizedBox(
        height: CastMemberStrip.heightForCardWidth(cardWidth),
        child: HorizontalScrollWithArrows(
          controller: _scrollController,
          builder: (scrollController) => ListView.builder(
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 5),
            itemCount: widget.members.length,
            itemBuilder: (context, index) {
              final member = widget.members[index];

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FocusBuilders.buildLockedFocusWrapper(
                  context: context,
                  isFocused: _focusNode.hasFocus && index == _focusedIndex,
                  borderRadius: tokens(context).radiusSm,
                  onTap: widget.onMemberTap == null ? null : () => _activateMember(index),
                  delegateFocusBorder: true,
                  child: Padding(
                    padding: const EdgeInsets.all(CastMemberStrip._innerPadding),
                    child: SizedBox(
                      width: cardWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardFocusBorder(
                            borderRadius: tokens(context).radiusSm,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                              child: OptimizedMediaImage(
                                client: widget.imageClient,
                                imagePath: member.imagePath,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                imageType: ImageType.avatar,
                                fallbackIcon: Symbols.person_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: nameStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (member.secondary != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    member.secondary!,
                                    style: secondaryStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
