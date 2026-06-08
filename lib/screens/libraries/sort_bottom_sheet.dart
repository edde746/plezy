import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_stream/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/focusable_button.dart';
import '../../focus/input_mode_tracker.dart';
import '../../media/media_sort.dart';
import '../../utils/scroll_utils.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../../i18n/strings.g.dart';

class SortBottomSheet extends StatefulWidget {
  final List<MediaSort> sortOptions;
  final MediaSort? selectedSort;
  final bool isSortDescending;
  final Function(MediaSort, bool) onSortChanged;
  final VoidCallback? onClear;
  final VoidCallback? onBack;

  const SortBottomSheet({
    super.key,
    required this.sortOptions,
    required this.selectedSort,
    required this.isSortDescending,
    required this.onSortChanged,
    this.onClear,
    this.onBack,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late MediaSort? _currentSort;
  late bool _currentDescending;
  late final FocusNode _initialFocusNode;
  final _firstItemKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentSort = widget.selectedSort;
    _currentDescending = widget.isSortDescending;
    _initialFocusNode = FocusNode(debugLabel: 'SortBottomSheetInitialFocus');

    // Scroll to selected item, then handle focus
    final selectedIndex = widget.selectedSort != null
        ? widget.sortOptions.indexWhere((s) => s.key == widget.selectedSort!.key)
        : -1;
    if (selectedIndex > 0) {
      scrollToCurrentItem(_scrollController, _firstItemKey, selectedIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer.run(() {
        if (!mounted) return;
        if (!InputModeTracker.isKeyboardMode(context)) return;
        final ctx = _initialFocusNode.context;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.5);
        }
        // Schedule after overlay's _autoFocus second callback so we override it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _initialFocusNode.requestFocus();
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _initialFocusNode.dispose();
    super.dispose();
  }

  void _handleSortSelect(MediaSort sort) {
    final descending = (_currentSort?.key == sort.key) ? _currentDescending : sort.isDefaultDescending;
    setState(() {
      _currentSort = sort;
      _currentDescending = descending;
    });
    widget.onSortChanged(sort, descending);
  }

  void _handleDirectionChange(MediaSort sort, bool descending) {
    widget.onSortChanged(sort, descending);
    OverlaySheetController.of(context).close();
  }

  void _handleClear() {
    widget.onClear?.call();
    OverlaySheetController.of(context).close();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        BottomSheetHeader(
          title: t.libraries.sortBy,
          onBack: widget.onBack,
          action: widget.onClear != null
              ? FocusableButton(
                  onPressed: _handleClear,
                  child: TextButton(onPressed: _handleClear, child: Text(t.common.clear)),
                )
              : null,
        ),
        Flexible(
          child: ListView.builder(
            controller: _scrollController,
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: widget.sortOptions.length,
            itemBuilder: (context, index) {
              final sort = widget.sortOptions[index];
              final isSelected = _currentSort?.key == sort.key;

              return Focus(
                key: index == 0 ? _firstItemKey : null,
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (node, event) {
                  if (!event.isActionable) return KeyEventResult.ignored;
                  if (!isSelected) return KeyEventResult.ignored;
                  if (event.logicalKey.isLeftKey) {
                    _handleDirectionChange(sort, false);
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey.isRightKey) {
                    _handleDirectionChange(sort, true);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: FocusableListTile(
                  focusNode: (widget.selectedSort?.key == sort.key || (widget.selectedSort == null && index == 0))
                      ? _initialFocusNode
                      : null,
                  leading: AppIcon(
                    isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                    fill: 1,
                  ),
                  title: Text(sort.title),
                  trailing: Visibility(
                    visible: isSelected,
                    maintainAnimation: true,
                    maintainSize: true,
                    maintainState: true,
                    child: SegmentedButton<bool>(
                      // Match FocusableListTile's dense visualDensity so the segment's min
                      // tap-target height equals ListTile's trailing-height cap. Without this
                      // the ~48dp button overflows the ~36dp cap from the top and the arrows
                      // render bottom-aligned instead of centered.
                      style: SegmentedButton.styleFrom(visualDensity: const VisualDensity(vertical: -3)),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: _SortDirectionIcon(upward: true)),
                        ButtonSegment(value: true, label: _SortDirectionIcon(upward: false)),
                      ],
                      selected: {_currentDescending},
                      onSelectionChanged: isSelected
                          ? (Set<bool> newSelection) {
                              _handleDirectionChange(sort, newSelection.first);
                            }
                          : null,
                    ),
                  ),
                  onTap: () => _handleSortSelect(sort),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SortDirectionIcon extends StatelessWidget {
  final bool upward;

  const _SortDirectionIcon({required this.upward});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 16,
      child: CustomPaint(
        painter: _SortDirectionArrowPainter(color: IconTheme.of(context).color, upward: upward),
      ),
    );
  }
}

class _SortDirectionArrowPainter extends CustomPainter {
  final Color? color;
  final bool upward;

  const _SortDirectionArrowPainter({required this.color, required this.upward});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.black
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final top = size.height * 0.14;
    final bottom = size.height * 0.86;
    final headY = upward ? top : bottom;
    final tailY = upward ? bottom : top;
    final wingY = upward ? top + size.height * 0.28 : bottom - size.height * 0.28;
    final wingOffset = size.width * 0.28;

    final path = Path()
      ..moveTo(centerX, tailY)
      ..lineTo(centerX, headY)
      ..moveTo(centerX - wingOffset, wingY)
      ..lineTo(centerX, headY)
      ..lineTo(centerX + wingOffset, wingY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SortDirectionArrowPainter oldDelegate) =>
      color != oldDelegate.color || upward != oldDelegate.upward;
}
