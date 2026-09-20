import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/library_query.dart';
import '../../../media/media_filter.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';

/// Segment styling for the editor's inline choices.
///
/// The mono theme maps `secondaryContainer` onto the sheet's own surface, so
/// M3's default selected-segment fill is invisible here — the selected state
/// has to be drawn explicitly or the control reads as "nothing chosen".
ButtonStyle _segmentStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return SegmentedButton.styleFrom(
    // Match FocusableListTile's dense visual density so the segments fit the
    // tile's trailing height cap.
    visualDensity: const VisualDensity(vertical: -3),
    foregroundColor: colors.onSurfaceVariant,
    selectedForegroundColor: colors.onSurface,
    selectedBackgroundColor: colors.onSurface.withValues(alpha: 0.18),
  );
}

/// Row that clears every clause on the field, marked selected while the field
/// is unset — the "no opinion" state of a multi-select page.
class FilterClearRow extends StatelessWidget {
  final bool selected;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback onPressed;

  /// Draw a radio mark. Set on pages where the rows are mutually exclusive
  /// (date windows), so "no filter" is as visibly selected as any window; a
  /// multi-select page conveys the same state through its empty checkboxes.
  final bool showRadio;

  const FilterClearRow({
    super.key,
    required this.selected,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.showRadio = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      focusNode: focusNode,
      autofocus: autofocus,
      leading: showRadio ? AppIcon(filterRadioIcon(selected), fill: 1) : null,
      title: Text(t.libraries.all),
      selected: selected,
      onTap: onPressed,
    );
  }
}

/// Radio glyph for the editor's mutually exclusive rows.
IconData filterRadioIcon(bool selected) =>
    selected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded;

/// Include/exclude switch for one field.
///
/// The segmented control is the pointer affordance; the row itself is the
/// single focus stop, and LEFT/RIGHT move between the two modes — the same
/// arrangement [SortBottomSheet] uses for sort direction, so a D-pad user
/// never has to step into a nested control.
class FilterIncludeExcludeRow extends StatelessWidget {
  final MediaFilter filter;
  final LibraryFilterOperator operator;
  final ValueChanged<LibraryFilterOperator> onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  const FilterIncludeExcludeRow({
    super.key,
    required this.filter,
    required this.operator,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  LibraryFilterOperator get _negated =>
      filter.operators.firstWhere((op) => op.isNegated, orElse: () => LibraryFilterOperator.isNot);

  LibraryFilterOperator get _plain =>
      filter.operators.firstWhere((op) => !op.isNegated, orElse: () => LibraryFilterOperator.is_);

  void _set(bool exclude) {
    final next = exclude ? _negated : _plain;
    if (next == operator) return;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final excluded = operator.isNegated;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (!event.isActionable) return KeyEventResult.ignored;
        if (event.logicalKey.isLeftKey) {
          _set(false);
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isRightKey) {
          _set(true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableListTile(
        focusNode: focusNode,
        autofocus: autofocus,
        leading: AppIcon(excluded ? Symbols.block_rounded : Symbols.check_circle_rounded, fill: 1),
        title: Text(excluded ? t.libraries.advancedFilters.exclude : t.libraries.advancedFilters.include),
        trailing: SegmentedButton<bool>(
          style: _segmentStyle(context),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, label: Text(t.libraries.advancedFilters.include)),
            ButtonSegment(value: true, label: Text(t.libraries.advancedFilters.exclude)),
          ],
          selected: {excluded},
          onSelectionChanged: (selection) => _set(selection.first),
        ),
        onTap: () => _set(!excluded),
      ),
    );
  }
}

/// Tri-state Any/Yes/No control for a boolean field, edited in place on the
/// category list. Select cycles forward, LEFT/RIGHT step the states, and the
/// segmented control handles pointer input.
class FilterBooleanRow extends StatelessWidget {
  final MediaFilter filter;

  /// null = Any, true = the field is set, false = the field is negated.
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  const FilterBooleanRow({
    super.key,
    required this.filter,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  static const List<bool?> _states = [null, true, false];

  List<bool?> get _available => filter.supportsExclusion ? _states : const [null, true];

  void _step(int delta) {
    final states = _available;
    final index = states.indexOf(value);
    final next = states[(index + delta + states.length) % states.length];
    if (next == value) return;
    onChanged(next);
  }

  String _label(bool? state) => switch (state) {
    null => t.libraries.advancedFilters.any,
    true => t.libraries.advancedFilters.yes,
    false => t.libraries.advancedFilters.no,
  };

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (!event.isActionable) return KeyEventResult.ignored;
        if (event.logicalKey.isLeftKey) {
          _step(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isRightKey) {
          _step(1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableListTile(
        focusNode: focusNode,
        autofocus: autofocus,
        title: Text(filter.title),
        trailing: SegmentedButton<bool?>(
          style: _segmentStyle(context),
          showSelectedIcon: false,
          segments: [for (final state in _available) ButtonSegment<bool?>(value: state, label: Text(_label(state)))],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
        onTap: () => _step(1),
      ),
    );
  }
}
