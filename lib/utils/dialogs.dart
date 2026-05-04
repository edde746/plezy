import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_text_field.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../mixins/controller_disposer_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/focusable_list_tile.dart';
import 'focus_utils.dart';

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

/// Shows a non-dismissible loading-spinner dialog. Caller is responsible for
/// closing it via `Navigator.pop(context)` when the work completes.
void showLoadingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

/// Shows the server-side 500 modal (bandwidth/transcoding limit rejection).
Future<void> showServerLimitDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t.messages.serverLimitTitle),
      content: Text(t.messages.serverLimitBody),
      actions: [
        FocusableButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
            child: Text(t.common.close),
          ),
        ),
      ],
    ),
  );
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
                child: FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(confirmText)),
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
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
}) {
  return showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmText: confirmText ?? t.common.delete,
    isDestructive: true,
  );
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

/// Shared lifecycle for the two private text-input dialogs below: a single
/// [TextEditingController] seeded from [initialValue], plus a focus node for
/// the save button.
mixin _TextInputDialogStateMixin<T extends StatefulWidget> on State<T>, ControllerDisposerMixin<T> {
  late final TextEditingController _controller;
  final _saveFocusNode = FocusNode();

  String? get initialValue;

  @override
  void initState() {
    super.initState();
    _controller = createTextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _saveFocusNode.dispose();
    super.dispose();
  }
}

class _MultilineTextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? initialValue;

  const _MultilineTextInputDialog({required this.title, required this.labelText, this.initialValue});

  @override
  State<_MultilineTextInputDialog> createState() => _MultilineTextInputDialogState();
}

class _MultilineTextInputDialogState extends State<_MultilineTextInputDialog>
    with ControllerDisposerMixin, _TextInputDialogStateMixin<_MultilineTextInputDialog> {
  @override
  String? get initialValue => widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: FocusableTextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.labelText),
          keyboardType: TextInputType.multiline,
          maxLines: 8,
          minLines: 3,
        ),
      ),
      actions: [
        DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel),
        DialogActionButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          label: t.common.save,
          focusNode: _saveFocusNode,
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

class _TextInputDialogState extends State<_TextInputDialog>
    with ControllerDisposerMixin, _TextInputDialogStateMixin<_TextInputDialog> {
  @override
  String? get initialValue => widget.initialValue;

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
      content: FocusableTextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.labelText, hintText: widget.hintText),
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _saveFocusNode.requestFocus(),
      ),
      actions: [
        DialogActionButton(onPressed: () => Navigator.pop(context), label: t.common.cancel),
        DialogActionButton(onPressed: _submit, label: widget.confirmText ?? t.common.save, focusNode: _saveFocusNode),
      ],
    );
  }
}

/// Shows a simple option picker dialog with focusable items for TV/keyboard navigation.
/// Returns the selected value, or null if cancelled. Each option's [icon] may
/// be `null` to render a label-only row (useful when the choices are variants
/// of the same thing and a repeated icon would just be noise).
Future<T?> showOptionPickerDialog<T>(
  BuildContext context, {
  required String title,
  required List<({IconData? icon, String label, T value})> options,
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
  final List<({IconData? icon, String label, T value})> options;
  final bool focusFirstItem;
  final Future<T?> Function(T value)? onBeforeClose;

  const _OptionPickerDialog({
    required this.title,
    required this.options,
    this.focusFirstItem = false,
    this.onBeforeClose,
  });

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
        final icon = option.icon;
        return FocusableListTile(
          focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
          leading: icon != null ? AppIcon(icon, fill: 1, size: 24) : null,
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
