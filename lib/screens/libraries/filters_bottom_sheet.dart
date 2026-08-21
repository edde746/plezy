import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_button.dart';
import '../../focus/input_mode_tracker.dart';
import '../../media/media_filter.dart';
import 'state_messages.dart';
import '../../utils/app_logger.dart';
import '../../utils/scroll_utils.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import '../../i18n/strings.g.dart';

typedef FilterValuesLoader = Future<List<MediaFilterValue>> Function(MediaFilter filter);

class FiltersBottomSheet extends StatefulWidget {
  final List<MediaFilter> filters;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onFiltersChanged;
  final String serverId;
  final String libraryKey;
  final FilterValuesLoader loadFilterValues;
  final VoidCallback? onBack;

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
    required this.loadFilterValues,
    this.onBack,
    this.cachedValues,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  MediaFilter? _currentFilter;
  List<MediaFilterValue> _filterValues = [];
  bool _isLoadingValues = false;
  String? _filterValuesError;
  int _filterValuesLoadGeneration = 0;
  final _contentKey = GlobalKey();
  double? _transitionMinHeight;
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
  void didUpdateWidget(covariant FiltersBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ownerChanged = oldWidget.serverId != widget.serverId || oldWidget.libraryKey != widget.libraryKey;
    if (ownerChanged) {
      _filterValuesLoadGeneration++;
      _currentFilter = null;
      _filterValues = [];
      _isLoadingValues = false;
      _filterValuesError = null;
      _tempSelectedFilters
        ..clear()
        ..addAll(widget.selectedFilters);
    }
    if (ownerChanged || !identical(oldWidget.filters, widget.filters)) {
      _sortFilters();
    }
  }

  @override
  void dispose() {
    _filterValuesLoadGeneration++;
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
    final generation = ++_filterValuesLoadGeneration;
    final filterKey = filter.filter;
    final serverId = widget.serverId;
    final libraryKey = widget.libraryKey;
    final cachedValues = widget.cachedValues;
    final loader = widget.loadFilterValues;
    // Drilling in is a setState page swap inside one sheet, and sheets are
    // bottom-anchored, so any height change during the load drags the header
    // and its Back button. Hold the outgoing page's height for the transient
    // spinner; the settled states below are free to hug again.
    _transitionMinHeight = _contentHeight();
    setState(() {
      _currentFilter = filter;
      _filterValues = [];
      _isLoadingValues = true;
      _filterValuesError = null;
    });

    try {
      // Cached path (Jellyfin) - `/Items/Filters` returned values inline.
      final cached = cachedValues?[filterKey];
      final values = cached ?? await loader(filter);
      if (!_isCurrentFilterValuesLoad(generation, serverId, libraryKey, filterKey)) return;

      final selectedValue = _tempSelectedFilters[filterKey];
      final selectedIndex = selectedValue == null
          ? -1
          : values.indexWhere((value) => _extractFilterValue(value.key, filterKey) == selectedValue);
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
      _requestInitialFocus(generation, serverId, libraryKey, filterKey);
      if (selectedIndex >= 0) {
        // +1 because index 0 is the "All" row.
        scrollToCurrentItem(
          _valuesScrollController,
          _valuesFirstItemKey,
          selectedIndex + 1,
          isCurrent: () => _isCurrentFilterValuesLoad(generation, serverId, libraryKey, filterKey),
        );
      }
    } catch (e, stackTrace) {
      if (!_isCurrentFilterValuesLoad(generation, serverId, libraryKey, filterKey)) return;
      appLogger.w('Failed to load values for filter $filterKey', error: e, stackTrace: stackTrace);
      setState(() {
        _filterValues = [];
        _isLoadingValues = false;
        _filterValuesError = t.errors.unableToLoad(context: filter.title);
      });
      _requestInitialFocus(generation, serverId, libraryKey, filterKey);
    }
  }

  bool _isCurrentFilterValuesLoad(int generation, String serverId, String libraryKey, String? filterKey) {
    return mounted &&
        generation == _filterValuesLoadGeneration &&
        widget.serverId == serverId &&
        widget.libraryKey == libraryKey &&
        _currentFilter?.filter == filterKey;
  }

  void _goBack() {
    final generation = ++_filterValuesLoadGeneration;
    final serverId = widget.serverId;
    final libraryKey = widget.libraryKey;
    setState(() {
      _currentFilter = null;
      _filterValues = [];
      _isLoadingValues = false;
      _filterValuesError = null;
    });
    _requestInitialFocus(generation, serverId, libraryKey, null);
  }

  void _requestInitialFocus(int generation, String serverId, String libraryKey, String? filterKey) {
    if (!InputModeTracker.isKeyboardMode(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCurrentFilterValuesLoad(generation, serverId, libraryKey, filterKey)) return;
      if (_initialFocusNode.context != null) {
        _initialFocusNode.requestFocus();
      } else {
        OverlaySheetController.maybeOf(context)?.refocus();
      }
    });
  }

  void _clearFilters() {
    _filterValuesLoadGeneration++;
    setState(() {
      _tempSelectedFilters.clear();
    });
    _applyFilters();
  }

  void _applyFilters() {
    _filterValuesLoadGeneration++;
    widget.onFiltersChanged(Map<String, String>.of(_tempSelectedFilters));
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
      onBack: currentFilter != null ? _goBack : widget.onBack,
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
      child: KeyedSubtree(
        key: _contentKey,
        child: currentFilter != null ? _buildFilterValuesView(currentFilter) : _buildFiltersView(),
      ),
    );
  }

  /// Height the content area currently occupies, used to hold the sheet steady
  /// across a page swap. Null before first layout.
  double? _contentHeight() {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.hasSize == true ? box!.size.height : null;
  }

  Widget _buildFilterValuesView(MediaFilter filter) {
    final error = _filterValuesError;
    if (error != null) {
      // The StateMessageWidget family is filling by design — 33 other sites
      // render it in page bodies and SliverFillRemaining. The unbounded scroll
      // axis here is what lets its inner Center shrink to content, so the sheet
      // does not stretch to the full height cap for one line of text.
      return SingleChildScrollView(
        primary: false,
        child: ErrorStateWidget(
          message: error,
          onRetry: () => _loadFilterValues(filter),
          actionFocusNode: _initialFocusNode,
          onActionBack: _goBack,
          actionAutofocus: InputModeTracker.isKeyboardMode(context),
          actionUseBackgroundFocus: true,
        ),
      );
    }
    if (_isLoadingValues) {
      assert(_transitionMinHeight != null, '_transitionMinHeight must be set before entering the loading state');
      // Held at the outgoing page's height (see [_loadFilterValues]) so the
      // transient spinner cannot move the header. Settled states below hug.
      return Focus(
        autofocus: InputModeTracker.isKeyboardMode(context),
        // Exactly the outgoing height, so the swap moves nothing.
        // [_loadFilterValues] assigns it immediately before setting
        // `_isLoadingValues`, so it is never null here.
        child: SizedBox(
          height: _transitionMinHeight,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final autofocusFirst = InputModeTracker.isKeyboardMode(context);
    return ListView.builder(
      controller: _valuesScrollController,
      primary: false,
      shrinkWrap: true,
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
      shrinkWrap: true,
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
