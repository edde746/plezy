import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Shows a dialog on the nearest navigator instead of Flutter's default root
/// navigator. Use this for profile/session-owned modal routes so they are
/// disposed when the active profile session is replaced.
Future<T?> showScopedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    useRootNavigator: false,
  );
}

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
  final confirmed = await showScopedDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          DialogActionButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            label: cancelText ?? t.common.cancel,
            style: TextButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
          ),
          DialogActionButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            label: confirmText,
            isPrimary: true,
            style: isDestructive
                ? FilledButton.styleFrom(
                    padding: _buttonPadding,
                    shape: _buttonShape,
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : FilledButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
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
  showScopedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

/// Shows the server-side 500 modal (bandwidth/transcoding limit rejection).
Future<void> showServerLimitDialog(BuildContext context) async {
  await showScopedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t.messages.serverLimitTitle),
      content: Text(t.messages.serverLimitBody),
      actions: [
        DialogActionButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(),
          label: t.common.close,
          isPrimary: true,
          style: FilledButton.styleFrom(padding: _buttonPadding, shape: _buttonShape),
        ),
      ],
    ),
  );
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

/// Shows a text input dialog and returns validated submitted text.
///
/// Returns `null` when the dialog is cancelled or dismissed. Validation errors
/// are shown in the field and keep the dialog open, so a non-null result always
/// represents an explicit, valid submission.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  String? hintText,
  String? initialValue,
  String? confirmText,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String)? validator,
  bool allowEmpty = false,
  bool multiline = false,
  bool obscureText = false,
}) {
  return showScopedDialog<String>(
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
      allowEmpty: allowEmpty,
      multiline: multiline,
      obscureText: obscureText,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? hintText;
  final String? initialValue;
  final String? confirmText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String)? validator;
  final bool allowEmpty;
  final bool multiline;
  final bool obscureText;

  const _TextInputDialog({
    required this.title,
    required this.labelText,
    required this.hintText,
    this.initialValue,
    this.confirmText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.allowEmpty = false,
    this.multiline = false,
    this.obscureText = false,
  }) : assert(!multiline || !obscureText, 'A text input dialog cannot be both multiline and obscure.');

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> with ControllerDisposerMixin {
  late final TextEditingController _controller;
  final _fieldFocusNode = FocusNode(debugLabel: 'TextInputField');
  final _cancelFocusNode = FocusNode(debugLabel: 'TextInputCancel');
  final _saveFocusNode = FocusNode(debugLabel: 'TextInputSave');
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = createTextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _fieldFocusNode.dispose();
    _cancelFocusNode.dispose();
    _saveFocusNode.dispose();
    super.dispose();
  }

  String? _validate(String text) {
    if (text.isEmpty && !widget.allowEmpty) return t.addServer.required;
    return widget.validator?.call(text);
  }

  void _submit() {
    final text = _controller.text;
    final errorText = _validate(text);
    if (errorText != null) {
      setState(() => _errorText = errorText);
      return;
    }
    Navigator.pop(context, text);
  }

  void _handleChanged(String text) {
    if (_errorText == null) return;
    setState(() => _errorText = _validate(text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: widget.multiline ? SizedBox(width: 400, child: textField) : textField,
      actions: [
        DialogActionButton(
          focusNode: _cancelFocusNode,
          onPressed: () => Navigator.pop(context),
          onNavigateRight: _saveFocusNode.requestFocus,
          label: t.common.cancel,
        ),
        DialogActionButton(
          onPressed: _submit,
          label: widget.confirmText ?? t.common.save,
          focusNode: _saveFocusNode,
          onNavigateLeft: _cancelFocusNode.requestFocus,
        ),
      ],
    );
  }

  Widget get textField {
    return FocusableTextField(
      controller: _controller,
      focusNode: _fieldFocusNode,
      autofocus: true,
      decoration: InputDecoration(labelText: widget.labelText, hintText: widget.hintText, errorText: _errorText),
      keyboardType: widget.keyboardType ?? (widget.multiline ? TextInputType.multiline : null),
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.multiline ? TextInputAction.newline : TextInputAction.done,
      obscureText: widget.obscureText,
      maxLines: widget.multiline ? 8 : 1,
      minLines: widget.multiline ? 3 : 1,
      onChanged: _handleChanged,
      onNavigateDown: _saveFocusNode.requestFocus,
      onSubmitted: widget.multiline ? null : (_) => _saveFocusNode.requestFocus(),
    );
  }
}

/// Shows a simple option picker dialog with focusable items for TV/keyboard navigation.
/// Returns the selected value, or null if cancelled. Each option's [icon] may
/// be `null` to render a label-only row (useful when the choices are variants
/// of the same thing and a repeated icon would just be noise).
/// Optional persistent toggle rendered above the option rows. Its state is held
/// by the dialog (toggling does not pop), and [onChanged] mirrors the new value
/// out so the caller can read it once an option row is picked.
typedef OptionPickerToggle = ({String label, IconData? icon, bool value, ValueChanged<bool> onChanged});

Future<T?> showOptionPickerDialog<T>(
  BuildContext context, {
  required String title,
  required List<({IconData? icon, String label, T value})> options,
  Future<T?> Function(T value)? onBeforeClose,
  OptionPickerToggle? toggle,
}) {
  final focusFirstItem = InputModeTracker.isKeyboardMode(context, listen: false);
  return showScopedDialog<T>(
    context: context,
    builder: (context) => _OptionPickerDialog<T>(
      title: title,
      options: options,
      focusFirstItem: focusFirstItem,
      onBeforeClose: onBeforeClose,
      toggle: toggle,
    ),
  );
}

class _OptionPickerDialog<T> extends StatefulWidget {
  final String title;
  final List<({IconData? icon, String label, T value})> options;
  final bool focusFirstItem;
  final Future<T?> Function(T value)? onBeforeClose;
  final OptionPickerToggle? toggle;

  const _OptionPickerDialog({
    required this.title,
    required this.options,
    this.focusFirstItem = false,
    this.onBeforeClose,
    this.toggle,
  });

  @override
  State<_OptionPickerDialog<T>> createState() => _OptionPickerDialogState<T>();
}

class _OptionPickerDialogState<T> extends State<_OptionPickerDialog<T>> {
  late final FocusNode _initialFocusNode;
  late bool _toggleValue;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'OptionPickerInitialFocus');
    _toggleValue = widget.toggle?.value ?? false;
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
    const rowPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
    const rowHorizontalTitleGap = 8.0;
    const rowMinLeadingWidth = 24.0;
    final toggle = widget.toggle;
    void updateToggle(bool value) {
      setState(() => _toggleValue = value);
      toggle?.onChanged(value);
    }

    return SimpleDialog(
      title: Text(widget.title),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      constraints: const BoxConstraints(minWidth: 304),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (toggle != null)
          MergeSemantics(
            child: FocusableListTile(
              title: Row(
                children: [
                  if (toggle.icon != null) ...[
                    AppIcon(toggle.icon!, fill: 1, size: 24),
                    const SizedBox(width: rowHorizontalTitleGap),
                  ],
                  Expanded(
                    child: Text(
                      toggle.label,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: rowHorizontalTitleGap),
                  ExcludeFocus(
                    child: Switch(value: _toggleValue, onChanged: updateToggle),
                  ),
                ],
              ),
              contentPadding: rowPadding,
              onTap: () => updateToggle(!_toggleValue),
            ),
          ),
        ...List.generate(widget.options.length, (index) {
          final option = widget.options[index];
          final icon = option.icon;
          return FocusableListTile(
            focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
            leading: icon != null ? AppIcon(icon, fill: 1, size: 24) : null,
            title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge),
            contentPadding: rowPadding,
            horizontalTitleGap: rowHorizontalTitleGap,
            minLeadingWidth: rowMinLeadingWidth,
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
      ],
    );
  }
}
