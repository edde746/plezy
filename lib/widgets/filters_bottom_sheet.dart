import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plex_filter.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/bottom_sheet_header.dart';
import '../utils/provider_extensions.dart';
import '../utils/keyboard_utils.dart';
import '../i18n/strings.g.dart';

class FiltersBottomSheet extends StatefulWidget {
  final List<PlexFilter> filters;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onFiltersChanged;
  final String serverId;

  const FiltersBottomSheet({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.serverId,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  PlexFilter? _currentFilter;
  List<PlexFilterValue> _filterValues = [];
  bool _isLoadingValues = false;
  final Map<String, String> _tempSelectedFilters = {};
  final Map<String, String> _filterDisplayNames = {}; // Cache for display names
  late List<PlexFilter> _sortedFilters;
  final FocusNode _firstItemFocusNode = FocusNode(
    debugLabel: 'FilterFirstItem',
  );
  final FocusNode _filterValuesFocusNode = FocusNode(
    debugLabel: 'FilterValuesFirstItem',
  );

  @override
  void initState() {
    super.initState();
    _tempSelectedFilters.addAll(widget.selectedFilters);
    _sortFilters();
    // Focus the first item after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstItemFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    _filterValuesFocusNode.dispose();
    super.dispose();
  }

  void _sortFilters() {
    // Separate boolean filters (toggles) from regular filters
    final booleanFilters = widget.filters
        .where((f) => f.filterType == 'boolean')
        .toList();
    final regularFilters = widget.filters
        .where((f) => f.filterType != 'boolean')
        .toList();

    // Combine with boolean filters first
    _sortedFilters = [...booleanFilters, ...regularFilters];
  }

  bool _isBooleanFilter(PlexFilter filter) {
    return filter.filterType == 'boolean';
  }

  Future<void> _loadFilterValues(PlexFilter filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoadingValues = true;
    });

    try {
      final client = context.getClientForServer(widget.serverId);

      final values = await client.getFilterValues(filter.key);
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
      // Focus the first filter value after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterValuesFocusNode.requestFocus();
      });
    } catch (e) {
      setState(() {
        _filterValues = [];
        _isLoadingValues = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _currentFilter = null;
      _filterValues = [];
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempSelectedFilters);
    Navigator.pop(context);
  }

  /// Handle back key - go back to main view or close sheet
  KeyEventResult _handleBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      if (_currentFilter != null) {
        // Go back to main filters view
        _goBack();
      } else {
        // Close the bottom sheet
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _extractFilterValue(String key, String filterName) {
    if (key.contains('?')) {
      final queryStart = key.indexOf('?');
      final queryString = key.substring(queryStart + 1);
      final params = Uri.splitQueryString(queryString);
      return params[filterName] ?? key;
    } else if (key.startsWith('/')) {
      return key.split('/').last;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleBackKey,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          if (_currentFilter != null) {
            // Show filter options view
            return Column(
              children: [
                // Header with back button
                BottomSheetHeader(
                  title: _currentFilter!.title,
                  leading: AppBarBackButton(
                    style: BackButtonStyle.plain,
                    onPressed: _goBack,
                  ),
                ),

                // Filter options list
                if (_isLoadingValues)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filterValues.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = !_tempSelectedFilters.containsKey(
                            _currentFilter!.filter,
                          );
                          return ListTile(
                            focusNode: _filterValuesFocusNode,
                            title: Text(t.libraries.all),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _tempSelectedFilters.remove(
                                  _currentFilter!.filter,
                                );
                              });
                              _applyFilters();
                            },
                          );
                        }

                        final value = _filterValues[index - 1];
                        final filterValue = _extractFilterValue(
                          value.key,
                          _currentFilter!.filter,
                        );
                        final isSelected =
                            _tempSelectedFilters[_currentFilter!.filter] ==
                            filterValue;

                        return ListTile(
                          title: Text(value.title),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _tempSelectedFilters[_currentFilter!.filter] =
                                  filterValue;
                              // Cache the display name for this filter value
                              _filterDisplayNames['${_currentFilter!.filter}:$filterValue'] =
                                  value.title;
                            });
                            _applyFilters();
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          }

          // Show main filters view
          return Column(
            children: [
              // Header
              BottomSheetHeader(
                title: t.libraries.filters,
                leading: const Icon(Icons.filter_alt),
                action: _tempSelectedFilters.isNotEmpty
                    ? TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _tempSelectedFilters.clear();
                          });
                          _applyFilters();
                        },
                        icon: const Icon(Icons.clear_all),
                        label: Text(t.libraries.clearAll),
                      )
                    : null,
              ),

              // All Filters (boolean toggles first, then regular filters)
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sortedFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _sortedFilters[index];

                    // Handle boolean filters as switches (unwatched, inProgress, unmatched, hdr, etc.)
                    if (_isBooleanFilter(filter)) {
                      final isActive =
                          _tempSelectedFilters.containsKey(filter.filter) &&
                          _tempSelectedFilters[filter.filter] == '1';
                      return SwitchListTile(
                        focusNode: index == 0 ? _firstItemFocusNode : null,
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              _tempSelectedFilters[filter.filter] = '1';
                            } else {
                              _tempSelectedFilters.remove(filter.filter);
                            }
                          });
                          _applyFilters();
                        },
                        title: Text(filter.title),
                      );
                    }

                    // Regular navigable filters - show selected value instead of checkmark
                    final selectedValue = _tempSelectedFilters[filter.filter];
                    String? displayValue;
                    if (selectedValue != null) {
                      // Try to get the cached display name, fall back to the value itself
                      displayValue =
                          _filterDisplayNames['${filter.filter}:$selectedValue'] ??
                          selectedValue;
                    }

                    return ListTile(
                      focusNode: index == 0 ? _firstItemFocusNode : null,
                      title: Text(filter.title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (displayValue != null)
                            Flexible(
                              child: Text(
                                displayValue,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (displayValue != null) const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _loadFilterValues(filter),
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
