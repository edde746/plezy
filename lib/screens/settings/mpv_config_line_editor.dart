import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/app_icon.dart';

/// TV editor for `mpv.conf`: one single-line system-keyboard field per line.
///
/// TV IMEs cannot host a multiline editor — FireTVIME has no newline key and
/// treats a pre-filled multiline field as empty (#2232) — so every line is its
/// own field and the platform keyboard (Gboard, FireTVIME, tvOS) edits one
/// line at a time. Rows open their keyboard on Select only; D-pad traversal
/// through the list must not raise it. A pasted value containing newlines is
/// split into rows, so a whole conf pasted from a phone remote lands as lines.
///
/// The keyboard's action key deliberately does not insert a row. The app only
/// sees "editing complete", never which action the IME sent, and FireTVIME
/// reports Back as `TextInputAction.previous` — an insert-on-action editor
/// would open a fresh row on every Back and the keyboard could never be
/// dismissed. Completion therefore hands focus down (next row, or the Add
/// line button after the last row), the native field's default.
///
/// [text] is the joined document; [onChanged] reports the joined document.
/// An external [text] that differs from the rows (preset load, settings
/// import) replaces them.
class MpvConfigLineEditor extends StatefulWidget {
  const MpvConfigLineEditor({super.key, required this.text, required this.onChanged, required this.style});

  final String text;
  final ValueChanged<String> onChanged;
  final TextStyle style;

  @override
  State<MpvConfigLineEditor> createState() => _MpvConfigLineEditorState();
}

class _MpvConfigLineEditorState extends State<MpvConfigLineEditor> {
  final List<_LineEntry> _lines = [];
  final FocusNode _addLineFocusNode = FocusNode(debugLabel: 'mpv_config_add_line');

  @override
  void initState() {
    super.initState();
    _replaceLines(_splitLines(widget.text));
  }

  @override
  void didUpdateWidget(MpvConfigLineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _joinedText) _replaceLines(_splitLines(widget.text));
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _addLineFocusNode.dispose();
    super.dispose();
  }

  static List<String> _splitLines(String text) => text.split('\n');

  String get _joinedText => _lines.map((line) => line.controller.text).join('\n');

  /// Reuse rows by index so an external replacement keeps focus and
  /// keyboard state on rows that survive it.
  void _replaceLines(List<String> texts) {
    for (var i = 0; i < texts.length; i++) {
      if (i < _lines.length) {
        _lines[i].setText(texts[i]);
      } else {
        _lines.add(_LineEntry(texts[i]));
      }
    }
    if (_lines.length > texts.length) {
      final removed = _lines.sublist(texts.length);
      _lines.removeRange(texts.length, _lines.length);
      if (removed.any((line) => line.focusNode.hasFocus)) _lines.last.focusNode.requestFocus();
      _disposeAfterFrame(removed);
    }
  }

  void _disposeAfterFrame(List<_LineEntry> entries) {
    // Nodes may still be attached to widgets being unmounted this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in entries) {
        entry.dispose();
      }
    });
  }

  void _notifyChanged() => widget.onChanged(_joinedText);

  void _handleLineChanged(int index, String value) {
    if (!value.contains('\n') && !value.contains('\r')) {
      _notifyChanged();
      return;
    }
    // A paste carrying newlines: keep the first segment on this row and give
    // the rest their own rows, then continue typing on the last one.
    final parts = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final inserted = [for (final part in parts.skip(1)) _LineEntry(part)];
    setState(() {
      _lines[index].setText(parts.first);
      _lines.insertAll(index + 1, inserted);
    });
    _notifyChanged();
    _openAfterFrame(inserted.last);
  }

  void _addLine() {
    final entry = _LineEntry('');
    setState(() => _lines.add(entry));
    _notifyChanged();
    _openAfterFrame(entry);
  }

  void _removeLine(int index) {
    if (_lines.length == 1) {
      // The document is never rowless; clearing the last row is the same edit.
      setState(() => _lines.single.setText(''));
      _notifyChanged();
      _lines.single.focusNode.requestFocus();
      return;
    }
    final removed = _lines[index];
    setState(() => _lines.removeAt(index));
    _notifyChanged();
    _lines[index.clamp(0, _lines.length - 1)].focusNode.requestFocus();
    _disposeAfterFrame([removed]);
  }

  void _openAfterFrame(_LineEntry entry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lines.contains(entry)) entry.tvInput.focusAndOpenTextInput();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutterStyle = widget.style.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final removeLabel = t.mpvConfig.removeLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _lines.length; i++)
          Padding(
            // Element identity follows the entry: an insert above a row must
            // not hand that row's text-input host a different focus node.
            key: ObjectKey(_lines[i]),
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('${i + 1}', textAlign: TextAlign.end, style: gutterStyle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FocusableTextField(
                    controller: _lines[i].controller,
                    focusNode: _lines[i].focusNode,
                    tvTextInputController: _lines[i].tvInput,
                    tvTextInputAutoOpenBehavior: TvTextInputAutoOpenBehavior.never,
                    // maxLines null rather than 1: Flutter prepends
                    // singleLineFormatter to every maxLines == 1 field, which
                    // would strip pasted newlines before onChanged can split
                    // them. The plain keyboardType keeps the IME single-line.
                    keyboardType: TextInputType.text,
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: widget.style,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: t.mpvConfig.lineHint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) => _handleLineChanged(i, value),
                    onNavigateUp: i > 0 ? _lines[i - 1].focusNode.requestFocus : null,
                    onNavigateDown: i < _lines.length - 1
                        ? _lines[i + 1].focusNode.requestFocus
                        : _addLineFocusNode.requestFocus,
                  ),
                ),
                const SizedBox(width: 4),
                FocusableButton(
                  onPressed: () => _removeLine(i),
                  autoScroll: false,
                  child: IconButton(
                    tooltip: removeLabel,
                    icon: const AppIcon(Symbols.close_rounded, fill: 1, size: 20),
                    onPressed: () => _removeLine(i),
                  ),
                ),
              ],
            ),
          ),
        FocusableButton(
          focusNode: _addLineFocusNode,
          useBackgroundFocus: true,
          onPressed: _addLine,
          child: TextButton.icon(
            onPressed: _addLine,
            icon: const AppIcon(Symbols.add_rounded, fill: 1),
            label: Text(t.mpvConfig.addLine),
          ),
        ),
      ],
    );
  }
}

class _LineEntry {
  _LineEntry(String text)
    : controller = TextEditingController(text: text),
      focusNode = FocusNode(debugLabel: 'mpv_config_line');

  final TextEditingController controller;
  final FocusNode focusNode;
  final TvTextInputController tvInput = TvTextInputController();

  void setText(String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}
