import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_button.dart';
import '../../focus/input_mode_tracker.dart';
import '../../media/media_filter.dart';
import '../../services/plex_client.dart';
import '../../utils/scroll_utils.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../../utils/provider_extensions.dart';
import '../../i18n/strings.g.dart';

class FiltersBottomSheet extends StatefulWidget {
  final List<MediaFilter> filters;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onFiltersChanged;
  final String serverId;
  final String libraryKey;

  /// Optional pre-fetched values per filter name. When non-null the sheet
  /// reads from this instead of calling `client.getFilterValues` — used
  /// for Jellyfin libraries where values come back in the same call that
  /// lists the categories.
  final Map<String, List<MediaFilterValue>>? cachedValues;

  const FiltersBottomSheet({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFiltersChanged,
    required this.serverId,
    required this.libraryKey,
    this.cachedValues,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  MediaFilter? _currentFilter;
  List<MediaFilterValue> _filterValues = [];
  bool _isLoadingValues = false;
  final Map<String, String> _tempSelectedFilters = {};
  static final Map<String, String> _filterDisplayNames = {}; // Cache for display names
  static const int _maxCachedDisplayNames = 1000;
  late List<MediaFilter> _sortedFilters;
  late final FocusNode _initialFocusNode;
  final _valuesFirstItemKey = GlobalKey();
  final _valuesScrollController = ScrollController();

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
    _valuesScrollController.dispose();
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

  bool _isBooleanFilter(MediaFilter filter) {
    return filter.filterType == 'boolean';
  }

  Future<void> _loadFilterValues(MediaFilter filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoadingValues = true;
    });

    try {
      // Cached path (Jellyfin) — `/Items/Filters` returned values inline.
      final cached = widget.cachedValues?[filter.filter];
      // Backend-neutral lookup so a Jellyfin server with an empty/missing
      // cache row doesn't throw from `getPlexClientForServer`. Jellyfin's
      // canonical filter values come from the cached `/Items/Filters`
      // payload; if that's unavailable, an empty list is the honest answer
      // until a `getFilterValues` lands on [MediaServerClient].
      final List<MediaFilterValue> values;
      if (cached != null) {
        values = cached;
      } else {
        final client = context.tryGetMediaClientForServer(ServerId(widget.serverId));
        if (client is PlexClient) {
          values = await client.getFilterValues(filter.key);
        } else {
          values = const [];
        }
      }
      if (!mounted) return;
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
      _requestInitialFocus();
      // Scroll to selected value if any
      final selectedValue = _tempSelectedFilters[filter.filter];
      if (selectedValue != null) {
        // +1 because index 0 is the "All" row
        final idx = values.indexWhere((v) => _extractFilterValue(v.key, filter.filter) == selectedValue) + 1;
        if (idx > 0) {
          scrollToCurrentItem(_valuesScrollController, _valuesFirstItemKey, idx);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _filterValues = [];
        _isLoadingValues = false;
      });
      _requestInitialFocus();
    }
  }

  void _goBack() {
    setState(() {
      _currentFilter = null;
      _filterValues = [];
    });
    _requestInitialFocus();
  }

  void _requestInitialFocus() {
    if (!InputModeTracker.isKeyboardMode(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_initialFocusNode.context != null) {
        _initialFocusNode.requestFocus();
      } else {
        OverlaySheetController.maybeOf(context)?.refocus();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _tempSelectedFilters.clear();
    });
    _applyFilters();
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
    final currentFilter = _currentFilter;
    return BottomSheetPageScaffold(
      title: currentFilter?.title ?? t.libraries.filters,
      icon: Symbols.filter_alt_rounded,
      onBack: currentFilter != null ? _goBack : null,
      action: currentFilter == null && _tempSelectedFilters.isNotEmpty
          ? FocusableButton(
              onPressed: _clearFilters,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const AppIcon(Symbols.clear_all_rounded, fill: 1),
                label: Text(t.libraries.clearAll),
              ),
            )
          : null,
      child: currentFilter != null ? _buildFilterValuesView(currentFilter) : _buildFiltersView(),
    );
  }

  Widget _buildFilterValuesView(MediaFilter filter) {
    if (_isLoadingValues) {
      return Focus(
        autofocus: InputModeTracker.isKeyboardMode(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final autofocusFirst = InputModeTracker.isKeyboardMode(context);
    return ListView.builder(
      controller: _valuesScrollController,
      primary: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filterValues.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isSelected = !_tempSelectedFilters.containsKey(filter.filter);
          return FocusableListTile(
            key: _valuesFirstItemKey,
            focusNode: _initialFocusNode,
            autofocus: autofocusFirst,
            title: Text(t.libraries.all),
            selected: isSelected,
            onTap: () {
              setState(() {
                _tempSelectedFilters.remove(filter.filter);
              });
              _applyFilters();
            },
          );
        }

        final value = _filterValues[index - 1];
        final filterValue = _extractFilterValue(value.key, filter.filter);
        final isSelected = _tempSelectedFilters[filter.filter] == filterValue;

        return FocusableListTile(
          title: Text(value.title),
          selected: isSelected,
          onTap: () {
            setState(() {
              _tempSelectedFilters[filter.filter] = filterValue;
              // Cache the display name for this filter value.
              if (_filterDisplayNames.length > _maxCachedDisplayNames) {
                _filterDisplayNames.clear();
              }
              _filterDisplayNames[_cacheKey(filter.filter, filterValue)] = value.title;
            });
            _applyFilters();
          },
        );
      },
    );
  }

  Widget _buildFiltersView() {
    final autofocusFirst = InputModeTracker.isKeyboardMode(context);
    return ListView.builder(
      primary: false,
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
            autofocus: index == 0 && autofocusFirst,
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
          autofocus: index == 0 && autofocusFirst,
          title: Text(filter.title),
          trailing: Row(
            mainAxisSize: .min,
            children: [
              if (displayValue != null)
                Flexible(
                  child: Text(
                    displayValue,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: .w500),
                    overflow: .ellipsis,
                  ),
                ),
              if (displayValue != null) const SizedBox(width: 8),
              const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            ],
          ),
          onTap: () => _loadFilterValues(filter),
        );
      },
    );
  }
}
