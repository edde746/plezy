import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../focus/focusable_text_field.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/library_query.dart';
import '../../../media/media_filter.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import 'filter_operator_row.dart';
import 'filter_summary.dart';

/// Inclusive numeric bounds for a field Plex declares as an integer
/// (`year`, `mediaSize`, `duration`, …).
///
/// Each bound is its own clause — `year>>=2000` plus `year<<=2010` — because
/// that is exactly how the wire expresses a range: two clauses on one field,
/// ANDed by the server.
class FilterNumberPage extends StatefulWidget {
  final MediaFilter filter;
  final List<LibraryFilter> clauses;
  final ValueChanged<List<LibraryFilter>> onChanged;
  final FocusNode initialFocusNode;
  final VoidCallback onBack;

  const FilterNumberPage({
    super.key,
    required this.filter,
    required this.clauses,
    required this.onChanged,
    required this.initialFocusNode,
    required this.onBack,
  });

  @override
  State<FilterNumberPage> createState() => _FilterNumberPageState();
}

class _FilterNumberPageState extends State<FilterNumberPage> {
  late final TextEditingController _from;
  late final TextEditingController _to;

  @override
  void initState() {
    super.initState();
    _from = TextEditingController(text: _boundValue(LibraryFilterOperator.atLeast) ?? '');
    _to = TextEditingController(text: _boundValue(LibraryFilterOperator.atMost) ?? '');
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  String? _boundValue(LibraryFilterOperator op) {
    for (final clause in widget.clauses) {
      if (clause.op == op && clause.values.isNotEmpty) return clause.values.first;
    }
    return null;
  }

  void _emit() {
    final from = _from.text.trim();
    final to = _to.text.trim();
    widget.onChanged([
      if (from.isNotEmpty)
        LibraryFilter(field: widget.filter.filter, op: LibraryFilterOperator.atLeast, values: [from]),
      if (to.isNotEmpty) LibraryFilter(field: widget.filter.filter, op: LibraryFilterOperator.atMost, values: [to]),
    ]);
  }

  Widget _bound(String label, TextEditingController controller, {FocusNode? focusNode, bool autofocus = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: FocusableTextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        onChanged: (_) => _emit(),
        onBack: widget.onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final autofocusFirst = InputModeTracker.isKeyboardMode(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilterClearRow(
          selected: widget.clauses.isEmpty,
          focusNode: widget.initialFocusNode,
          autofocus: autofocusFirst,
          onPressed: () {
            _from.clear();
            _to.clear();
            widget.onChanged(const []);
          },
        ),
        _bound(t.libraries.advancedFilters.from, _from),
        _bound(t.libraries.advancedFilters.to, _to),
      ],
    );
  }
}

/// Relative date windows for a field Plex declares as a date (`addedAt`,
/// `originallyAvailableAt`, `lastViewedAt`).
///
/// Absolute dates are deliberately absent: a date picker is a poor D-pad
/// target, and Plex evaluates its own relative syntax (`-30d`) server-side,
/// which is what "added recently" actually means. Each window is one clause.
class FilterDatePage extends StatelessWidget {
  final MediaFilter filter;
  final List<LibraryFilter> clauses;
  final ValueChanged<List<LibraryFilter>> onChanged;
  final FocusNode initialFocusNode;
  final VoidCallback onBack;

  const FilterDatePage({
    super.key,
    required this.filter,
    required this.clauses,
    required this.onChanged,
    required this.initialFocusNode,
    required this.onBack,
  });

  ({LibraryFilterOperator op, String value})? get _current {
    for (final clause in clauses) {
      if (clause.values.isEmpty) continue;
      if (clause.op == LibraryFilterOperator.atLeast || clause.op == LibraryFilterOperator.atMost) {
        return (op: clause.op, value: clause.values.first);
      }
    }
    return null;
  }

  void _select(LibraryFilterOperator op, String value) {
    onChanged([
      LibraryFilter(field: filter.filter, op: op, values: [value]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final autofocusFirst = InputModeTracker.isKeyboardMode(context);
    final options = <({LibraryFilterOperator op, String value})>[
      for (final window in relativeDateWindows) (op: LibraryFilterOperator.atLeast, value: window),
      for (final window in relativeDateWindows) (op: LibraryFilterOperator.atMost, value: window),
    ];
    return ListView.builder(
      primary: false,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: options.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return FilterClearRow(
            selected: current == null,
            focusNode: initialFocusNode,
            autofocus: autofocusFirst,
            showRadio: true,
            onPressed: () => onChanged(const []),
          );
        }
        final option = options[index - 1];
        final selected = current != null && current.op == option.op && current.value == option.value;
        return FocusableListTile(
          leading: AppIcon(filterRadioIcon(selected), fill: 1),
          title: Text(relativeDateLabel(option.value, older: option.op == LibraryFilterOperator.atMost)),
          selected: selected,
          onTap: () => _select(option.op, option.value),
        );
      },
    );
  }
}
