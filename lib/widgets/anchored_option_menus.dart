import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/input_mode_tracker.dart';
import '../media/media_filter.dart';
import '../media/media_sort.dart';
import '../utils/app_logger.dart';
import 'app_icon.dart';
import 'app_menu.dart';

/// Whether chip menus should open as anchored popups rather than sheets.
///
/// Mirrors [showAdaptiveAppMenu]'s platform split: iOS and Android (which
/// also cover tvOS and Android TV) keep the bottom sheets; every other
/// platform anchors dropdown popups to the chips.
bool useAnchoredChipMenus(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform != TargetPlatform.iOS && platform != TargetPlatform.android;
}

/// Anchor rect for a chip popup, computed the way
/// [AppMenuButtonState.showButtonMenu] computes its anchor. Returns null when
/// the chip isn't laid out (hidden, or not yet built).
Rect? chipAnchorRect(GlobalKey key) {
  final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null || !renderBox.hasSize) return null;
  final topLeft = renderBox.localToGlobal(Offset.zero);
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, renderBox.size.width, renderBox.size.height);
}

/// Chip popups focus their first item only in keyboard/D-pad sessions.
bool _focusMenuFirstItem(BuildContext context) => InputModeTracker.isKeyboardMode(context, listen: false);

/// Shows a single-select anchored popup: one [AppMenuItem] per option with
/// the current selection marked. Returns the picked option, or null when the
/// menu is dismissed.
Future<T?> showAnchoredSelectionMenu<T>(
  BuildContext context, {
  required Rect anchorRect,
  required List<T> options,
  required String Function(T option) labelOf,
  required T? selected,
}) {
  return showAppMenu<T>(
    context,
    anchorRect: anchorRect,
    focusFirstItem: _focusMenuFirstItem(context),
    entries: [
      for (final option in options) AppMenuItem(value: option, label: labelOf(option), selected: option == selected),
    ],
  );
}

/// Outcome of [showAnchoredSortMenu]: the sort to apply, its direction, and
/// whether the user cleared the sort (in which case [sort] is null).
typedef AnchoredSortResult = ({MediaSort? sort, bool descending, bool cleared});

/// Sentinel for the Clear row in the sort popup (null means dismissed).
final Object _clearSortValue = Object();

/// Shows the sort anchored popup: one row per [MediaSort] with the active
/// field marked and carrying a direction arrow, plus a Clear row.
///
/// Selecting the active field toggles its direction (the popup has no
/// segmented direction control); selecting another field applies it with its
/// default direction. Returns null when the menu is dismissed.
Future<AnchoredSortResult?> showAnchoredSortMenu(
  BuildContext context, {
  required Rect anchorRect,
  required List<MediaSort> sortOptions,
  required MediaSort? selectedSort,
  required bool isSortDescending,
  required String clearLabel,
}) async {
  final selectedKey = selectedSort?.key;
  final directionIcon = isSortDescending ? Symbols.arrow_downward_rounded : Symbols.arrow_upward_rounded;
  final choice = await showAppMenu<Object>(
    context,
    anchorRect: anchorRect,
    focusFirstItem: _focusMenuFirstItem(context),
    entries: [
      for (final sort in sortOptions)
        AppMenuItem<Object>(
          value: sort,
          label: sort.title,
          selected: sort.key == selectedKey,
          trailing: sort.key == selectedKey ? AppIcon(directionIcon, fill: 1, size: 18) : null,
        ),
      const AppMenuDivider(),
      AppMenuItem(value: _clearSortValue, label: clearLabel),
    ],
  );
  if (!context.mounted || choice == null) return null;

  if (identical(choice, _clearSortValue)) {
    return (sort: null, descending: false, cleared: true);
  }
  final sort = choice as MediaSort;
  final descending = sort.key == selectedKey ? !isSortDescending : sort.isDefaultDescending;
  return (sort: sort, descending: descending, cleared: false);
}

/// Sentinel for the "All" row in the per-category values popup; a dismissed
/// menu returns null, so clearing needs its own value.
final Object _clearFilterValue = Object();

/// Shows the filters anchored popup: one popup listing the categories, then
/// a second popup at the same rect for the chosen category's values. Boolean
/// categories toggle and apply directly, mirroring the sheet's switches.
///
/// [cachedValues] answers value listings inline (MediaBrowser filter
/// discovery payloads); categories missing from it go through
/// [loadFilterValues]. [valueDisplayNames], when provided, caches picked
/// value titles so the category popup can echo them as subtitles (the raw
/// value can be an opaque server id); it is read for subtitles and written
/// on selection.
///
/// Returns the updated selection map to apply, or null when the menu was
/// dismissed or the value listing failed to load.
Future<Map<String, String>?> showAnchoredFiltersMenu(
  BuildContext context, {
  required Rect anchorRect,
  required List<MediaFilter> filters,
  required Map<String, String> selectedFilters,
  required Future<List<MediaFilterValue>> Function(MediaFilter filter) loadFilterValues,
  required String allLabel,
  Map<String, List<MediaFilterValue>> cachedValues = const {},
  Map<String, String>? valueDisplayNames,
}) async {
  // Boolean toggles first, mirroring FiltersBottomSheet._sortFilters.
  final ordered = [
    ...filters.where((f) => f.filterType == 'boolean'),
    ...filters.where((f) => f.filterType != 'boolean'),
  ];
  final filter = await showAppMenu<MediaFilter>(
    context,
    anchorRect: anchorRect,
    focusFirstItem: _focusMenuFirstItem(context),
    entries: [
      for (final filter in ordered)
        AppMenuItem(
          value: filter,
          label: filter.title,
          subtitle: _selectedFilterSubtitle(filter, selectedFilters, valueDisplayNames),
          selected: selectedFilters.containsKey(filter.filter),
        ),
    ],
  );
  if (!context.mounted || filter == null) return null;

  if (filter.filterType == 'boolean') {
    final updated = Map<String, String>.of(selectedFilters);
    if (updated[filter.filter] == '1') {
      updated.remove(filter.filter);
    } else {
      updated[filter.filter] = '1';
    }
    return updated;
  }

  return _showAnchoredFilterValuesMenu(
    context,
    anchorRect: anchorRect,
    filter: filter,
    selectedFilters: selectedFilters,
    cachedValues: cachedValues,
    loadFilterValues: loadFilterValues,
    allLabel: allLabel,
    valueDisplayNames: valueDisplayNames,
  );
}

/// Display name of the value applied to [filter], for the category popup's
/// subtitle. Falls back to the raw value when no display name is cached.
String? _selectedFilterSubtitle(
  MediaFilter filter,
  Map<String, String> selectedFilters,
  Map<String, String>? valueDisplayNames,
) {
  if (filter.filterType == 'boolean') return null;
  final value = selectedFilters[filter.filter];
  if (value == null) return null;
  return valueDisplayNames?['${filter.filter}:$value'] ?? value;
}

/// Second popup of [showAnchoredFiltersMenu]: the chosen category's values,
/// headed by an "All" row that clears the category.
Future<Map<String, String>?> _showAnchoredFilterValuesMenu(
  BuildContext context, {
  required Rect anchorRect,
  required MediaFilter filter,
  required Map<String, String> selectedFilters,
  required Map<String, List<MediaFilterValue>> cachedValues,
  required Future<List<MediaFilterValue>> Function(MediaFilter filter) loadFilterValues,
  required String allLabel,
  required Map<String, String>? valueDisplayNames,
}) async {
  List<MediaFilterValue> values;
  try {
    // Same cached-values seam the sheet uses: MediaBrowser payloads answer
    // inline, anything else goes through the lazy loader.
    values = cachedValues[filter.filter] ?? await loadFilterValues(filter);
  } catch (e, st) {
    appLogger.w('Failed to load values for filter ${filter.filter}', error: e, stackTrace: st);
    return null;
  }
  if (!context.mounted) return null;

  final selectedValue = selectedFilters[filter.filter];
  final choice = await showAppMenu<Object>(
    context,
    anchorRect: anchorRect,
    focusFirstItem: _focusMenuFirstItem(context),
    entries: [
      AppMenuItem(value: _clearFilterValue, label: allLabel, selected: selectedValue == null),
      if (values.isNotEmpty) const AppMenuDivider(),
      for (final value in values)
        AppMenuItem<Object>(
          value: value,
          label: value.title,
          selected: selectedValue != null && libraryFilterValueId(value.key, filter.filter) == selectedValue,
        ),
    ],
  );
  if (!context.mounted || choice == null) return null;

  final updated = Map<String, String>.of(selectedFilters);
  if (identical(choice, _clearFilterValue)) {
    updated.remove(filter.filter);
  } else {
    final value = choice as MediaFilterValue;
    final filterValue = libraryFilterValueId(value.key, filter.filter);
    updated[filter.filter] = filterValue;
    valueDisplayNames?['${filter.filter}:$filterValue'] = value.title;
  }
  return updated;
}
