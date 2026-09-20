import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../media/library_filter_selection.dart';
import '../../media/library_query.dart';
import '../../media/media_filter.dart';
import '../../utils/app_logger.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/bottom_sheet_page_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/overlay_sheet.dart';
import 'filters/filter_operator_row.dart';
import 'filters/filter_range_page.dart';
import 'filters/filter_summary.dart';
import 'filters/filter_text_page.dart';
import 'filters/filter_value_page.dart';
import 'state_messages.dart';

typedef FilterValuesLoader = Future<List<MediaFilterValue>> Function(MediaFilter filter);

/// Count of items the pending selection would show, or null when the backend
/// cannot answer cheaply.
typedef FilterCountLoader = Future<int?> Function(List<LibraryFilter> filters);

/// The library filter editor.
///
/// Two pages: the category list, and one editor per category chosen by the
/// field's [MediaFilter.editorKind]. Every edit is staged locally and pushed
/// to [onFiltersChanged] so the host can commit once on dismissal — a
/// multi-select page cannot apply-and-close on each tap, and reloading the
/// grid per checkbox would issue a request per keystroke.
///
/// Hosted by `OverlaySheetHost` on touch/TV and by `showAnchoredFilterPanel`
/// on pointer platforms; both paths render this same widget, so the surfaces
/// cannot drift apart.
class FiltersBottomSheet extends StatefulWidget {
  final List<MediaFilter> filters;
  final List<LibraryFilter> selectedFilters;
  final ValueChanged<List<LibraryFilter>> onFiltersChanged;
  final String serverId;
  final String libraryKey;
  final FilterValuesLoader loadFilterValues;
  final VoidCallback? onBack;

  /// Optional pre-fetched values per filter name. When non-null the editor
  /// reads from this instead of calling [loadFilterValues] — used for
  /// MediaBrowser libraries where values arrive with the category listing.
  final Map<String, List<MediaFilterValue>>? cachedValues;

  /// Resolves the "Show N" footer count. Omitted when the host cannot count
  /// (the offline downloads tab filters in memory).
  final FilterCountLoader? countLoader;

  /// Dismisses the editor. Defaults to [OverlaySheetController.closeAdaptive],
  /// which closes the sheet when hosted and pops the route otherwise.
  final VoidCallback? onRequestClose;

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
    this.countLoader,
    this.onRequestClose,
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
  late List<LibraryFilter> _selection;
  late List<MediaFilter> _sortedFilters;
  late final FocusNode _initialFocusNode;

  Timer? _countDebounce;
  int _countGeneration = 0;
  int? _count;
  bool _countPending = false;

  @override
  void initState() {
    super.initState();
    _selection = List<LibraryFilter>.of(widget.selectedFilters);
    _sortFilters();
    _initialFocusNode = FocusNode(debugLabel: 'FiltersBottomSheetInitialFocus');
    _scheduleCount();
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
      _selection = List<LibraryFilter>.of(widget.selectedFilters);
      _scheduleCount();
    }
    if (ownerChanged || !identical(oldWidget.filters, widget.filters)) {
      _sortFilters();
    }
  }

  @override
  void dispose() {
    _filterValuesLoadGeneration++;
    _countGeneration++;
    _countDebounce?.cancel();
    _initialFocusNode.dispose();
    super.dispose();
  }

  void _sortFilters() {
    // Booleans first: they are one-touch on the category list, so keeping
    // them above the drill-in rows puts the cheapest controls in reach.
    final booleanFilters = widget.filters.where((f) => f.isBoolean).toList();
    final regularFilters = widget.filters.where((f) => !f.isBoolean).toList();
    _sortedFilters = [...booleanFilters, ...regularFilters];
  }

  // ---------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------

  void _commitSelection(List<LibraryFilter> next) {
    setState(() => _selection = next);
    widget.onFiltersChanged(List<LibraryFilter>.of(next));
    _scheduleCount();
  }

  void _setField(String field, List<LibraryFilter> clauses) => _commitSelection(_selection.withField(field, clauses));

  void _clearFilters() {
    _filterValuesLoadGeneration++;
    _commitSelection(const []);
  }

  void _close() {
    final onRequestClose = widget.onRequestClose;
    if (onRequestClose != null) {
      onRequestClose();
      return;
    }
    // Adaptive: the editor is hosted in an overlay sheet on touch/TV and in a
    // routed panel on pointer platforms, and this resolves both.
    OverlaySheetController.closeAdaptive(context);
  }

  // ---------------------------------------------------------------------
  // Result count
  // ---------------------------------------------------------------------

  void _scheduleCount() {
    final loader = widget.countLoader;
    if (loader == null) return;
    _countDebounce?.cancel();
    final generation = ++_countGeneration;
    setState(() => _countPending = true);
    _countDebounce = Timer(const Duration(milliseconds: 350), () => unawaited(_loadCount(loader, generation)));
  }

  Future<void> _loadCount(FilterCountLoader loader, int generation) async {
    final pending = List<LibraryFilter>.of(_selection);
    try {
      final count = await loader(pending);
      if (!mounted || generation != _countGeneration) return;
      setState(() {
        _count = count;
        _countPending = false;
      });
    } catch (e, stackTrace) {
      if (!mounted || generation != _countGeneration) return;
      appLogger.d('Filter result count unavailable: $e', stackTrace: stackTrace);
      setState(() {
        _count = null;
        _countPending = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Values
  // ---------------------------------------------------------------------

  Future<void> _openFilter(MediaFilter filter) async {
    if (filter.editorKind != FilterEditorKind.valueList) {
      // Nothing to fetch; swap straight to the editor.
      _transitionMinHeight = _contentHeight();
      final generation = ++_filterValuesLoadGeneration;
      setState(() {
        _currentFilter = filter;
        _filterValues = [];
        _isLoadingValues = false;
        _filterValuesError = null;
      });
      // The free-text page owns its own entry focus: this node would have to
      // sit on its text field, and a focused text input opens the TV keyboard
      // on arrival, burying the sheet before the viewer asked to type.
      if (filter.editorKind != FilterEditorKind.text) {
        _requestInitialFocus(generation, widget.serverId, widget.libraryKey, filter.filter);
      }
      return;
    }
    await _loadFilterValues(filter);
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
      // Cached path (MediaBrowser) — the category listing carried the values.
      final cached = cachedValues?[filterKey];
      final values = cached ?? await loader(filter);
      if (!_isCurrentFilterValuesLoad(generation, serverId, libraryKey, filterKey)) return;
      setState(() {
        _filterValues = values;
        _isLoadingValues = false;
      });
      _requestInitialFocus(generation, serverId, libraryKey, filterKey);
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
    _transitionMinHeight = _contentHeight();
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

  /// Height held by the transient spinner when the outgoing page never
  /// reported one.
  static const double _fallbackTransitionHeight = 160;

  /// Height the content area currently occupies, used to hold the sheet steady
  /// across a page swap. Null before first layout.
  double? _contentHeight() {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.hasSize == true ? box!.size.height : null;
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentFilter = _currentFilter;
    return BottomSheetPageScaffold(
      title: currentFilter?.title ?? t.libraries.filters,
      icon: Symbols.filter_alt_rounded,
      onBack: currentFilter != null ? _goBack : widget.onBack,
      action: currentFilter == null && _selection.isNotEmpty
          ? FocusableButton(
              onPressed: _clearFilters,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const AppIcon(Symbols.clear_all_rounded, fill: 1),
                label: Text(t.libraries.clearAll),
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: KeyedSubtree(
              key: _contentKey,
              child: currentFilter != null ? _buildFilterPage(currentFilter) : _buildFiltersView(),
            ),
          ),
          if (widget.countLoader != null) _buildApplyFooter(),
        ],
      ),
    );
  }

  Widget _buildApplyFooter() {
    final count = _count;
    final label = count == null || _countPending
        ? t.libraries.advancedFilters.showResultsUnknown
        : t.libraries.advancedFilters.showResults(count: count.toString());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: FocusableButton(
          useBackgroundFocus: true,
          onPressed: _close,
          child: FilledButton(onPressed: _close, child: Text(label)),
        ),
      ),
    );
  }

  Widget _buildFilterPage(MediaFilter filter) {
    final error = _filterValuesError;
    if (error != null) {
      // The StateMessageWidget family is filling by design, so the unbounded
      // scroll axis is what lets its inner Center shrink to content instead of
      // stretching the sheet to the height cap for one line of text.
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
      // Held at the outgoing page's height (see [_loadFilterValues]) so the
      // transient spinner cannot move the header. Settled states below hug.
      // The fallback covers a drill-in before the outgoing page has been laid
      // out: an unsized box here would inflate the sheet to its cap and back.
      return Focus(
        autofocus: InputModeTracker.isKeyboardMode(context),
        child: SizedBox(
          height: _transitionMinHeight ?? _fallbackTransitionHeight,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final clauses = _selection.clausesFor(filter.filter);
    return switch (filter.editorKind) {
      FilterEditorKind.valueList => FilterValuePage(
        filter: filter,
        values: _filterValues,
        clause: clauses.firstOrNull,
        serverId: widget.serverId,
        libraryKey: widget.libraryKey,
        initialFocusNode: _initialFocusNode,
        onBack: _goBack,
        onChanged: (next) => _setField(filter.filter, next),
      ),
      FilterEditorKind.number => FilterNumberPage(
        filter: filter,
        clauses: clauses,
        initialFocusNode: _initialFocusNode,
        onBack: _goBack,
        onChanged: (next) => _setField(filter.filter, next),
      ),
      FilterEditorKind.date => FilterDatePage(
        filter: filter,
        clauses: clauses,
        initialFocusNode: _initialFocusNode,
        onBack: _goBack,
        onChanged: (next) => _setField(filter.filter, next),
      ),
      FilterEditorKind.text => FilterTextPage(
        filter: filter,
        clause: clauses.firstOrNull,
        initialFocusNode: _initialFocusNode,
        onBack: _goBack,
        onChanged: (next) => _setField(filter.filter, next),
      ),
      // Booleans are edited in place on the category list.
      FilterEditorKind.toggle => const SizedBox.shrink(),
    };
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
        final focusNode = index == 0 ? _initialFocusNode : null;
        final autofocus = index == 0 && autofocusFirst;

        if (filter.isBoolean) {
          final clause = _selection.clauseFor(filter.filter);
          return FilterBooleanRow(
            filter: filter,
            value: clause == null ? null : !clause.op.isNegated,
            focusNode: focusNode,
            autofocus: autofocus,
            onChanged: (value) => _setField(
              filter.filter,
              value == null
                  ? const []
                  : [
                      LibraryFilter(
                        field: filter.filter,
                        op: value ? LibraryFilterOperator.is_ : LibraryFilterOperator.isNot,
                        values: const ['1'],
                      ),
                    ],
            ),
          );
        }

        final summary = filterFieldSummary(
          filter: filter,
          clauses: _selection,
          serverId: widget.serverId,
          libraryKey: widget.libraryKey,
        );
        return FocusableListTile(
          focusNode: focusNode,
          autofocus: autofocus,
          title: Text(filter.title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summary != null)
                Flexible(
                  child: Text(
                    summary,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (summary != null) const SizedBox(width: 8),
              const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            ],
          ),
          onTap: () => unawaited(_openFilter(filter)),
        );
      },
    );
  }
}
