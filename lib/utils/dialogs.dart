import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../focus/focusable_button.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_list_tile.dart';
import 'focus_utils.dart';

/// Utility functions for showing common dialogs

const _buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
const _buttonShape = StadiumBorder();

/// Shows a confirmation dialog with consistent button sizing and autofocus.
/// Returns true if user confirmed, false if cancelled.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  String? cancelText,
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FocusableButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
              child: Text(cancelText ?? t.common.cancel),
            ),
          ),
          FocusableButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: isDestructive
                  ? FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError)
                  : null,
              child: Text(confirmText),
            ),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

/// Shows a confirmation dialog with an optional checkbox (e.g. "Don't ask again").
/// Returns a record with [confirmed] and [checked] booleans.
Future<({bool confirmed, bool checked})> showConfirmDialogWithCheckbox(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
  required String checkboxLabel,
  String? cancelText,
}) async {
  var checked = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: checked,
                  onChanged: (v) => setDialogState(() => checked = v ?? false),
                  title: Text(checkboxLabel),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ],
            ),
            actions: [
              FocusableButton(
                autofocus: true,
                onPressed: () => Navigator.pop(dialogContext, false),
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
                  child: Text(cancelText ?? t.common.cancel),
                ),
              ),
              FocusableButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(confirmText),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return (confirmed: confirmed ?? false, checked: checked);
}

/// Shows a delete confirmation dialog.
/// Convenience wrapper around [showConfirmDialog] with destructive styling.
Future<bool> showDeleteConfirmation(BuildContext context, {required String title, required String message, String? confirmText}) {
  return showConfirmDialog(context, title: title, message: message, confirmText: confirmText ?? t.common.delete, isDestructive: true);
}

/// Shows a text input dialog for creating/naming items
/// Returns the entered text, or null if cancelled
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required String hintText,
  String? initialValue,
  String? confirmText,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      labelText: labelText,
      hintText: hintText,
      initialValue: initialValue,
      confirmText: confirmText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    ),
  );
}

/// Shows a multiline text input dialog for editing longer text like summaries.
/// Returns the entered text, or null if cancelled.
/// Allows empty text to be submitted (for clearing fields).
Future<String?> showMultilineTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _MultilineTextInputDialog(title: title, labelText: labelText, initialValue: initialValue),
  );
}

class _MultilineTextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? initialValue;

  const _MultilineTextInputDialog({required this.title, required this.labelText, this.initialValue});

  @override
  State<_MultilineTextInputDialog> createState() => _MultilineTextInputDialogState();
}

class _MultilineTextInputDialogState extends State<_MultilineTextInputDialog> {
  late final TextEditingController _controller;
  final _saveFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.labelText),
          maxLines: 8,
          minLines: 3,
        ),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
        FocusableButton(
          focusNode: _saveFocusNode,
          onPressed: () => Navigator.pop(context, _controller.text),
          child: TextButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(t.common.save),
          ),
        ),
      ],
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String hintText;
  final String? initialValue;
  final String? confirmText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String)? validator;

  const _TextInputDialog({
    required this.title,
    required this.labelText,
    required this.hintText,
    this.initialValue,
    this.confirmText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  final _saveFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    if (text.isEmpty) return;
    if (widget.validator != null && widget.validator!(text) != null) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.labelText, hintText: widget.hintText),
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _saveFocusNode.requestFocus(),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
        FocusableButton(
          focusNode: _saveFocusNode,
          onPressed: _submit,
          child: TextButton(onPressed: _submit, child: Text(widget.confirmText ?? t.common.save)),
        ),
      ],
    );
  }
}

/// Shows a simple option picker dialog with focusable items for TV/keyboard navigation.
/// Returns the selected value, or null if cancelled.
Future<T?> showOptionPickerDialog<T>(
  BuildContext context, {
  required String title,
  required List<({IconData icon, String label, T value})> options,
  Future<T?> Function(T value)? onBeforeClose,
}) {
  final focusFirstItem = InputModeTracker.isKeyboardMode(context);
  return showDialog<T>(
    context: context,
    builder: (context) => _OptionPickerDialog<T>(
      title: title,
      options: options,
      focusFirstItem: focusFirstItem,
      onBeforeClose: onBeforeClose,
    ),
  );
}

class _OptionPickerDialog<T> extends StatefulWidget {
  final String title;
  final List<({IconData icon, String label, T value})> options;
  final bool focusFirstItem;
  final Future<T?> Function(T value)? onBeforeClose;

  const _OptionPickerDialog({required this.title, required this.options, this.focusFirstItem = false, this.onBeforeClose});

  @override
  State<_OptionPickerDialog<T>> createState() => _OptionPickerDialogState<T>();
}

class _OptionPickerDialogState<T> extends State<_OptionPickerDialog<T>> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'OptionPickerInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      children: List.generate(widget.options.length, (index) {
        final option = widget.options[index];
        return FocusableListTile(
          focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
          leading: AppIcon(option.icon, fill: 1, size: 24),
          title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          onTap: () async {
            if (widget.onBeforeClose != null) {
              final result = await widget.onBeforeClose!(option.value);
              if (context.mounted) Navigator.pop(context, result);
            } else {
              Navigator.pop(context, option.value);
            }
          },
        );
      }),
    );
  }
}
