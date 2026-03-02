import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/plex_filter.dart';
import '../../widgets/app_bar_back_button.dart';
import '../../widgets/bottom_sheet_header.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../../utils/provider_extensions.dart';
import '../../i18n/strings.g.dart';

class FiltersBottomSheet extends StatefulWidget {
  final List<PlexFilter> filters;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onFiltersChanged;
  final String serverId;
  final String libraryKey;

  const FiltersBottomSheet({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.serverId,
    required this.libraryKey,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  PlexFilter? _currentFilter;
  List<PlexFilterValue> _filterValues = [];
  bool _isLoadingValues = false;
  final Map<String, String> _tempSelectedFilters = {};
  static final Map<String, String> _filterDisplayNames = {}; // Cache for display names
  static const int _maxCachedDisplayNames = 1000;
  late List<PlexFilter> _sortedFilters;
  late final FocusNode _initialFocusNode;

  String _cacheKey(String filter, String value) => '${widget.serverId}:${widget.libraryKey}:$filter:$value';

  @override
  void initState() {
    super.initState();
    _tempSelectedFilters.addAll(widget.selectedFilters);
    _sortFilters();
    _initialFocusNode = FocusNode(debugLabel: 'FiltersBottomSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  void _sortFilters() {
    // Separate boolean filters (toggles) from regular filters
    final booleanFilters = widget.filters.where((f) => f.filterType == 'boolean').toList();
    final regularFilters = widget.filters.where((f) => f.filterType != 'boolean').toList();

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
      if (!mounted) return;
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    OverlaySheetController.of(context).close();
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
    if (_currentFilter != null) {
      // Show filter options view
      return Column(
        children: [
          // Header with back button
          BottomSheetHeader(
            title: _currentFilter!.title,
            leading: AppBarBackButton(style: BackButtonStyle.plain, onPressed: _goBack),
          ),

          // Filter options list
          if (_isLoadingValues)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filterValues.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = !_tempSelectedFilters.containsKey(_currentFilter!.filter);
                    return FocusableListTile(
                      focusNode: _initialFocusNode,
                      title: Text(t.libraries.all),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _tempSelectedFilters.remove(_currentFilter!.filter);
                        });
                        _applyFilters();
                      },
                    );
                  }

                  final value = _filterValues[index - 1];
                  final filterValue = _extractFilterValue(value.key, _currentFilter!.filter);
                  final isSelected = _tempSelectedFilters[_currentFilter!.filter] == filterValue;

                  return FocusableListTile(
                    title: Text(value.title),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _tempSelectedFilters[_currentFilter!.filter] = filterValue;
                        // Cache the display name for this filter value
                        if (_filterDisplayNames.length > _maxCachedDisplayNames) {
                          _filterDisplayNames.clear();
                        }
                        _filterDisplayNames[_cacheKey(_currentFilter!.filter, filterValue)] = value.title;
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
          leading: const AppIcon(Symbols.filter_alt_rounded, fill: 1),
          action: _tempSelectedFilters.isNotEmpty
              ? TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _tempSelectedFilters.clear();
                    });
                    _applyFilters();
                  },
                  icon: const AppIcon(Symbols.clear_all_rounded, fill: 1),
                  label: Text(t.libraries.clearAll),
                )
              : null,
        ),

        // All Filters (boolean toggles first, then regular filters)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _sortedFilters.length,
            itemBuilder: (context, index) {
              final filter = _sortedFilters[index];

              // Handle boolean filters as switches (unwatched, inProgress, unmatched, hdr, etc.)
              if (_isBooleanFilter(filter)) {
                final isActive =
                    _tempSelectedFilters.containsKey(filter.filter) && _tempSelectedFilters[filter.filter] == '1';
                return FocusableSwitchListTile(
                  focusNode: index == 0 ? _initialFocusNode : null,
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
                displayValue = _filterDisplayNames[_cacheKey(filter.filter, selectedValue)] ?? selectedValue;
              }

              return FocusableListTile(
                focusNode: index == 0 ? _initialFocusNode : null,
                title: Text(filter.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (displayValue != null)
                      Flexible(
                        child: Text(
                          displayValue,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (displayValue != null) const SizedBox(width: 8),
                    const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  ],
                ),
                onTap: () => _loadFilterValues(filter),
              );
            },
          ),
        ),
      ],
    );
  }
}
