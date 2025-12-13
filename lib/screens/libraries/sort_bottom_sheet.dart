import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
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
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  void _handleSortChange(PlexSort sort, bool descending) {
    setState(() {
      _currentSort = sort;
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
    Navigator.pop(context);
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
                    ? TextButton(
                        onPressed: _handleClear,
                        child: Text(t.common.clear),
                      )
                    : null,
              ),
              Expanded(
                child: RadioGroup<PlexSort>(
                  groupValue: _currentSort,
                  onChanged: (value) {
                    if (value != null) {
                      _handleSortChange(value, value.isDefaultDescending);
                    }
                  },
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.sortOptions.length,
                    itemBuilder: (context, index) {
                      final sort = widget.sortOptions[index];
                      final isSelected = _currentSort?.key == sort.key;

                      return FocusableRadioListTile<PlexSort>(
                        focusNode: index == 0 ? _initialFocusNode : null,
                        title: Text(sort.title),
                        value: sort,
                        secondary: isSelected
                            ? SegmentedButton<bool>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    icon: AppIcon(
                                      Symbols.arrow_upward_rounded,
                                      fill: 1,
                                      size: 16,
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    icon: AppIcon(
                                      Symbols.arrow_downward_rounded,
                                      fill: 1,
                                      size: 16,
                                    ),
                                  ),
                                ],
                                selected: {_currentDescending},
                                onSelectionChanged: (Set<bool> newSelection) {
                                  _handleSortChange(sort, newSelection.first);
                                },
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
