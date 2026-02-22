import 'package:flutter/material.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';

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
Future<bool> showDeleteConfirmation(BuildContext context, {required String title, required String message}) {
  return showConfirmDialog(context, title: title, message: message, confirmText: t.common.delete, isDestructive: true);
}

/// Shows a text input dialog for creating/naming items
/// Returns the entered text, or null if cancelled
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required String hintText,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _TextInputDialog(title: title, labelText: labelText, hintText: hintText, initialValue: initialValue),
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

  const _TextInputDialog({required this.title, required this.labelText, required this.hintText, this.initialValue});

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
    if (_controller.text.isNotEmpty) {
      Navigator.pop(context, _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.labelText, hintText: widget.hintText),
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
          child: TextButton(onPressed: _submit, child: Text(t.common.save)),
        ),
      ],
    );
  }
}
