import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/input_mode_tracker.dart';
import '../media/library_query.dart';
import '../media/media_filter.dart';
import '../media/media_sort.dart';
import '../screens/libraries/filters_bottom_sheet.dart';
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

/// Shows the filter editor in a popup anchored to the Filters chip.
///
/// Pointer platforms get the same [FiltersBottomSheet] the touch and TV
/// surfaces get, hosted in an anchored panel instead of an overlay sheet, so
/// multi-select, exclusion and range editing behave identically everywhere.
/// A popup menu could not host it: selecting a row pops the route.
///
/// Edits are reported through [onFiltersChanged] as they happen; the returned
/// future completes when the panel is dismissed, which is when the caller
/// commits. [cachedValues] answers value listings inline (MediaBrowser filter
/// discovery payloads); categories missing from it go through
/// [loadFilterValues].
Future<void> showAnchoredFilterPanel(
  BuildContext context, {
  required Rect anchorRect,
  required List<MediaFilter> filters,
  required List<LibraryFilter> selectedFilters,
  required ValueChanged<List<LibraryFilter>> onFiltersChanged,
  required String serverId,
  required String libraryKey,
  required FilterValuesLoader loadFilterValues,
  Map<String, List<MediaFilterValue>> cachedValues = const {},
  FilterCountLoader? countLoader,
}) {
  return showAnchoredPanel<void>(
    context,
    anchorRect: anchorRect,
    builder: (panelContext) => FiltersBottomSheet(
      filters: filters,
      selectedFilters: selectedFilters,
      onFiltersChanged: onFiltersChanged,
      serverId: serverId,
      libraryKey: libraryKey,
      loadFilterValues: loadFilterValues,
      cachedValues: cachedValues.isEmpty ? null : cachedValues,
      countLoader: countLoader,
      onRequestClose: () => Navigator.of(panelContext).pop(),
    ),
  );
}
