import 'package:flutter/material.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/tv_number_spinner.dart';

/// Model for option selection dialogs.
class DialogOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const DialogOption({required this.value, required this.title, this.subtitle});
}

/// Shows an M3-conformant AlertDialog with RadioListTiles for multi-option selection.
/// Used for settings with 5+ options (language, buffer size, etc.).
Future<T?> showSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<DialogOption<T>> options,
  required T currentValue,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12, bottom: 24),
      content: SingleChildScrollView(
        child: RadioGroup<T>(
          groupValue: currentValue,
          onChanged: (value) => Navigator.pop(dialogContext, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((option) => RadioListTile<T>(
                      title: Text(option.title),
                      subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                      value: option.value,
                    ))
                .toList(),
          ),
        ),
      ),
    ),
  );
}

/// Generic numeric input dialog.
/// On TV/keyboard mode, uses a spinner widget with +/- buttons for D-pad navigation.
/// On other platforms, uses a TextField with focus management.
void showNumericInputDialog({
  required BuildContext context,
  required String title,
  required String labelText,
  required String suffixText,
  required int min,
  required int max,
  required int currentValue,
  required Future<void> Function(int value) onSave,
}) {
  final useDpadControls = InputModeTracker.isKeyboardMode(context);

  if (useDpadControls) {
    _showNumericInputDialogTV(
      context: context,
      title: title,
      suffixText: suffixText,
      min: min,
      max: max,
      currentValue: currentValue,
      onSave: onSave,
    );
  } else {
    _showNumericInputDialogStandard(
      context: context,
      title: title,
      labelText: labelText,
      suffixText: suffixText,
      min: min,
      max: max,
      currentValue: currentValue,
      onSave: onSave,
    );
  }
}

void _showNumericInputDialogTV({
  required BuildContext context,
  required String title,
  required String suffixText,
  required int min,
  required int max,
  required int currentValue,
  required Future<void> Function(int value) onSave,
}) {
  int spinnerValue = currentValue;
  final saveFocusNode = FocusNode();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TvNumberSpinner(
                  value: spinnerValue,
                  min: min,
                  max: max,
                  suffix: suffixText,
                  autofocus: true,
                  onChanged: (value) {
                    setDialogState(() {
                      spinnerValue = value;
                    });
                  },
                  onConfirm: () => saveFocusNode.requestFocus(),
                  onCancel: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(height: 8),
                Text(
                  t.settings.durationHint(min: min, max: max),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
              TextButton(
                focusNode: saveFocusNode,
                onPressed: () async {
                  await onSave(spinnerValue);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(t.common.save),
              ),
            ],
          );
        },
      );
    },
  ).then((_) => saveFocusNode.dispose());
}

void _showNumericInputDialogStandard({
  required BuildContext context,
  required String title,
  required String labelText,
  required String suffixText,
  required int min,
  required int max,
  required int currentValue,
  required Future<void> Function(int value) onSave,
}) {
  final controller = TextEditingController(text: currentValue.toString());
  String? errorText;
  final saveFocusNode = FocusNode();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: t.settings.durationHint(min: min, max: max),
                errorText: errorText,
                suffixText: suffixText,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                saveFocusNode.requestFocus();
              },
              onChanged: (value) {
                final parsed = int.tryParse(value);
                setDialogState(() {
                  if (parsed == null) {
                    errorText = t.settings.validationErrorEnterNumber;
                  } else if (parsed < min || parsed > max) {
                    errorText = t.settings.validationErrorDuration(min: min, max: max, unit: labelText.toLowerCase());
                  } else {
                    errorText = null;
                  }
                });
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
              TextButton(
                focusNode: saveFocusNode,
                onPressed: () async {
                  final parsed = int.tryParse(controller.text);
                  if (parsed != null && parsed >= min && parsed <= max) {
                    await onSave(parsed);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  }
                },
                child: Text(t.common.save),
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    saveFocusNode.dispose();
  });
}

/// Shows a text input dialog with regex validation and reset-to-default support.
void showTextInputDialog({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String defaultValue,
  required Future<void> Function(String value) onSave,
}) {
  final controller = TextEditingController(text: currentValue);
  String? errorText;
  final saveFocusNode = FocusNode();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Regex',
                errorText: errorText,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => saveFocusNode.requestFocus(),
              onChanged: (value) {
                setDialogState(() {
                  try {
                    RegExp(value, caseSensitive: false);
                    errorText = null;
                  } catch (_) {
                    errorText = t.settings.invalidRegex;
                  }
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.text = defaultValue;
                  setDialogState(() => errorText = null);
                },
                child: Text(t.settings.resetToDefault),
              ),
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
              TextButton(
                focusNode: saveFocusNode,
                onPressed: () async {
                  if (errorText != null) return;
                  await onSave(controller.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: Text(t.common.save),
              ),
            ],
          );
        },
      );
    },
  ).then((_) => saveFocusNode.dispose());
}
