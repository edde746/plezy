import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../mixins/controller_disposer_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/focusable_filter_chip.dart';
import '../widgets/focusable_list_tile.dart';

class TagEditDialog extends StatefulWidget {
  final String title;
  final List<String> initialTags;

  /// Optional in-flight fetch of suggestion values (server tag facets merged
  /// with locally recorded recents). Chips render once it completes; a failure
  /// or null future simply shows no suggestions.
  final Future<List<String>>? suggestionsFuture;

  const TagEditDialog({super.key, required this.title, required this.initialTags, this.suggestionsFuture});

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> with ControllerDisposerMixin {
  late final TextEditingController _controller = createTextEditingController();
  late final FocusNode _textFieldFocusNode;
  late final List<String> _tags;
  final _saveFocusNode = FocusNode();
  final _firstChipFocusNode = FocusNode(debugLabel: 'tag_suggestion_first');
  List<String> _suggestions = const [];

  /// Suggestion chips cap so a large server tag list can't inflate the dialog.
  static const int _maxVisibleSuggestions = 12;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (!event.isActionable) return KeyEventResult.ignored;
        if (event.logicalKey.isDownKey) {
          // With suggestions visible, DOWN lands on the first (most-recent)
          // chip rather than the suffix add button — chips are the primary
          // action here and geometric traversal would skip or scatter them.
          if (_visibleSuggestions.isNotEmpty) {
            _firstChipFocusNode.requestFocus();
          } else {
            node.nextFocus();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _tags = List.of(widget.initialTags);
    _controller.addListener(_onTextChanged);
    final suggestionsFuture = widget.suggestionsFuture;
    if (suggestionsFuture != null) {
      unawaited(
        suggestionsFuture
            .then((suggestions) {
              if (mounted) setState(() => _suggestions = suggestions);
            })
            .catchError((_) {}),
      );
    }
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _saveFocusNode.dispose();
    _firstChipFocusNode.dispose();
    super.dispose();
  }

  void _addTag([String? value]) {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty || _tags.any((tag) => tag.toLowerCase() == text.toLowerCase())) return;
    setState(() {
      _tags.add(text);
      _controller.clear();
    });
    _textFieldFocusNode.requestFocus();
  }

  /// Suggestions not already applied, filtered by the in-progress input.
  List<String> get _visibleSuggestions {
    if (_suggestions.isEmpty) return const [];
    final query = _controller.text.trim().toLowerCase();
    final applied = {for (final tag in _tags) tag.toLowerCase()};
    final visible = [
      for (final suggestion in _suggestions)
        if (!applied.contains(suggestion.toLowerCase()) && (query.isEmpty || suggestion.toLowerCase().contains(query)))
          suggestion,
    ];
    return visible.length > _maxVisibleSuggestions ? visible.sublist(0, _maxVisibleSuggestions) : visible;
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
    _textFieldFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = _visibleSuggestions;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: .min,
          children: [
            FocusableTextField(
              controller: _controller,
              focusNode: _textFieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t.metadataEdit.addTag,
                suffixIcon: FocusableButton(
                  onPressed: _addTag,
                  child: IconButton(icon: const AppIcon(Symbols.add_rounded), onPressed: _addTag),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTag(),
            ),
            if (visibleSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < visibleSuggestions.length; i++)
                          FocusableFilterChip(
                            icon: Symbols.add_rounded,
                            label: visibleSuggestions[i],
                            focusNode: i == 0 ? _firstChipFocusNode : null,
                            // The chip mixin always consumes RIGHT and DOWN;
                            // without explicit escapes D-pad focus would be
                            // trapped on the chip row.
                            onNavigateRight: () =>
                                FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.right),
                            onNavigateDown: () =>
                                FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down),
                            onPressed: () => _addTag(visibleSuggestions[i]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tags.length,
                  itemBuilder: (context, index) => FocusableListTile(
                    title: Text(_tags[index]),
                    trailing: const AppIcon(Symbols.close_rounded),
                    onTap: () => _removeTag(index),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel),
        DialogActionButton(
          onPressed: () => Navigator.pop(context, _tags),
          label: t.common.save,
          focusNode: _saveFocusNode,
        ),
      ],
    );
  }
}
