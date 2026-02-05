import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/dpad_navigator.dart';
import '../../models/plex_sort.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/focusable_bottom_sheet.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../i18n/strings.g.dart';

class SortBottomSheet extends StatefulWidget {
  final List<PlexSort> sortOptions;
  final PlexSort? selectedSort;
  final bool isSortDescending;
  final Function(PlexSort, bool) onSortChanged;
  final VoidCallback? onClear;

  const SortBottomSheet({
    super.key,
    required this.sortOptions,
    required this.selectedSort,
    required this.isSortDescending,
    required this.onSortChanged,
    this.onClear,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late PlexSort? _currentSort;
  late bool _currentDescending;
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _currentSort = widget.selectedSort;
    _currentDescending = widget.isSortDescending;
    _initialFocusNode = FocusNode(debugLabel: 'SortBottomSheetInitialFocus');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _initialFocusNode.context;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5);
      }
    });
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  void _handleSortSelect(PlexSort sort) {
    final descending = (_currentSort?.key == sort.key) ? _currentDescending : sort.isDefaultDescending;
    setState(() {
      _currentSort = sort;
      _currentDescending = descending;
    });
    widget.onSortChanged(sort, descending);
  }

  void _handleDirectionChange(PlexSort sort, bool descending) {
    setState(() {
      _currentDescending = descending;
    });
    widget.onSortChanged(sort, descending);
    Navigator.pop(context);
  }

  void _handleClear() {
    setState(() {
      _currentSort = null;
      _currentDescending = false;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableBottomSheet(
      initialFocusNode: _initialFocusNode,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              BottomSheetHeader(
                title: t.libraries.sortBy,
                action: widget.onClear != null
                    ? TextButton(onPressed: _handleClear, child: Text(t.common.clear))
                    : null,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.sortOptions.length,
                  itemBuilder: (context, index) {
                    final sort = widget.sortOptions[index];
                    final isSelected = _currentSort?.key == sort.key;

                    return Focus(
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
                      child: FocusableRadioListTile<PlexSort>(
                        focusNode: (widget.selectedSort?.key == sort.key || (widget.selectedSort == null && index == 0))
                            ? _initialFocusNode
                            : null,
                        title: Text(sort.title),
                        value: sort,
                        groupValue: _currentSort,
                        onChanged: (value) {
                          if (value != null) _handleSortSelect(value);
                        },
                        secondary: isSelected
                            ? SegmentedButton<bool>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    icon: AppIcon(Symbols.arrow_upward_rounded, fill: 1, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    icon: AppIcon(Symbols.arrow_downward_rounded, fill: 1, size: 16),
                                  ),
                                ],
                                selected: {_currentDescending},
                                onSelectionChanged: (Set<bool> newSelection) {
                                  _handleDirectionChange(sort, newSelection.first);
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
