import 'package:flutter/material.dart';
import '../models/plex_sort.dart';
import '../i18n/strings.g.dart';

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.onClear != null)
                    TextButton(
                      onPressed: _handleClear,
                      child: Text(t.common.clear),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RadioGroup<PlexSort>(
                groupValue: _currentSort,
                onChanged: (PlexSort? value) {
                  if (value != null) {
                    _handleSortChange(value, value.defaultDirection == 'desc');
                  }
                },
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widget.sortOptions.length,
                  itemBuilder: (context, index) {
                    final sort = widget.sortOptions[index];
                    final isSelected = _currentSort?.key == sort.key;

                    return ListTile(
                      title: Text(sort.title),
                      trailing: isSelected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SegmentedButton<bool>(
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
                                ),
                              ],
                            )
                          : null,
                      leading: Radio<PlexSort>(value: sort, toggleable: false),
                      onTap: () {
                        _handleSortChange(
                          sort,
                          sort.defaultDirection == 'desc',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
