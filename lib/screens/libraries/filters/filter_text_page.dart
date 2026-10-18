import 'package:flutter/material.dart';

import '../../../focus/focusable_text_field.dart';
import '../../../i18n/strings.g.dart';
import '../../../media/library_query.dart';
import '../../../media/media_filter.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import 'filter_operator_row.dart';

/// Free-text page for a field with no enumerable values: Plex's `title`,
/// `studio`, and the file-path field.
///
/// The match mode is a radio list rather than a segmented control: four
/// modes do not fit a phone-width trailing slot, and each row is a plain
/// focus stop on a D-pad.
class FilterTextPage extends StatefulWidget {
  final MediaFilter filter;
  final LibraryFilter? clause;
  final ValueChanged<List<LibraryFilter>> onChanged;
  final FocusNode initialFocusNode;
  final VoidCallback onBack;

  const FilterTextPage({
    super.key,
    required this.filter,
    required this.clause,
    required this.onChanged,
    required this.initialFocusNode,
    required this.onBack,
  });

  @override
  State<FilterTextPage> createState() => _FilterTextPageState();
}

class _FilterTextPageState extends State<FilterTextPage> {
  late final TextEditingController _controller;
  late LibraryFilterOperator _operator;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.clause?.values.firstOrNull ?? '');
    _operator = widget.clause?.op ?? _modes.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Match modes the backend declared for this field, in reading order.
  List<LibraryFilterOperator> get _modes {
    const preferred = [
      LibraryFilterOperator.is_,
      LibraryFilterOperator.isNot,
      LibraryFilterOperator.matches,
      LibraryFilterOperator.notMatches,
      LibraryFilterOperator.beginsWith,
      LibraryFilterOperator.endsWith,
    ];
    final available = preferred.where(widget.filter.operators.contains).toList();
    return available.isEmpty ? const [LibraryFilterOperator.is_] : available;
  }

  String _label(LibraryFilterOperator op) => switch (op) {
    LibraryFilterOperator.is_ => t.libraries.advancedFilters.matchContains,
    LibraryFilterOperator.isNot => t.libraries.advancedFilters.matchNotContains,
    LibraryFilterOperator.matches => t.libraries.advancedFilters.matchIs,
    LibraryFilterOperator.notMatches => t.libraries.advancedFilters.matchIsNot,
    LibraryFilterOperator.beginsWith => t.libraries.advancedFilters.matchBeginsWith,
    LibraryFilterOperator.endsWith => t.libraries.advancedFilters.matchEndsWith,
    // `_modes` only ever yields the six operators named above.
    _ => op.id,
  };

  void _emit() {
    final text = _controller.text.trim();
    widget.onChanged(
      text.isEmpty
          ? const []
          : [
              LibraryFilter(field: widget.filter.filter, op: _operator, values: [text]),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final modes = _modes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The sheet's entry focus lands here and never on the field below: a
        // focused text input opens the TV keyboard on arrival
        // (`TvTextInputAutoOpenBehavior.automatic`), burying the sheet before
        // the viewer asked to type.
        FilterClearRow(
          selected: _controller.text.trim().isEmpty,
          focusNode: widget.initialFocusNode,
          onPressed: () {
            _controller.clear();
            widget.onChanged(const []);
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FocusableTextField(
            controller: _controller,
            autofocus: false,
            decoration: InputDecoration(
              labelText: widget.filter.title,
              hintText: t.libraries.advancedFilters.textHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
            onSubmitted: (_) => _emit(),
            onBack: widget.onBack,
          ),
        ),
        if (modes.length > 1)
          Flexible(
            child: ListView.builder(
              primary: false,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: modes.length,
              itemBuilder: (context, index) {
                final mode = modes[index];
                return FocusableListTile(
                  leading: AppIcon(filterRadioIcon(mode == _operator), fill: 1),
                  title: Text(_label(mode)),
                  selected: mode == _operator,
                  onTap: () {
                    setState(() => _operator = mode);
                    _emit();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
