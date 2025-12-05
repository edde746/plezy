import 'package:flutter/material.dart';
import '../../models/plex_sort.dart';
import '../../widgets/bottom_sheet_header.dart';
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

  @override
  void initState() {
    super.initState();
    _currentSort = widget.selectedSort;
    _currentDescending = widget.isSortDescending;
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
    return DraggableScrollableSheet(
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
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.sortOptions.length,
                itemBuilder: (context, index) {
                  final sort = widget.sortOptions[index];
                  final isSelected = _currentSort?.key == sort.key;

                  return RadioListTile<PlexSort>(
                    title: Text(sort.title),
                    value: sort,
                    groupValue: _currentSort,
                    onChanged: (value) {
                      if (value != null) {
                        _handleSortChange(value, value.isDefaultDescending);
                      }
                    },
                    secondary: isSelected
                        ? SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.arrow_upward, size: 16),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(
                                  Icons.arrow_downward,
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
          ],
        );
      },
    );
  }
}
