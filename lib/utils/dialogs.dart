import 'package:flutter/material.dart';
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
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
            child: Text(cancelText ?? t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError)
                : null,
            child: Text(confirmText),
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
              TextButton(
                autofocus: true,
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
                child: Text(cancelText ?? t.common.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmText),
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
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
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        TextButton(onPressed: _submit, child: Text(t.common.save)),
      ],
    );
  }
}
