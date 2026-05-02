import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/tv_color_picker.dart';
import '../../widgets/tv_number_spinner.dart';

/// Model for option selection dialogs.
class DialogOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const DialogOption({required this.value, required this.title, this.subtitle});
}

typedef _SettingsDialogContentBuilder =
    Widget Function(
      BuildContext dialogContext,
      BuildContext contentContext,
      StateSetter setDialogState,
      FocusNode saveFocusNode,
    );

typedef _SettingsDialogActionsBuilder = List<Widget> Function(BuildContext dialogContext, StateSetter setDialogState);

void _showSettingsInputDialog({
  required BuildContext context,
  required String title,
  required _SettingsDialogContentBuilder contentBuilder,
  required Future<bool> Function(BuildContext dialogContext) onSave,
  _SettingsDialogActionsBuilder? leadingActionsBuilder,
  VoidCallback? onDispose,
}) {
  final saveFocusNode = FocusNode();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: contentBuilder(dialogContext, context, setDialogState, saveFocusNode),
            actions: [
              ...?leadingActionsBuilder?.call(dialogContext, setDialogState),
              DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
              DialogActionButton(
                focusNode: saveFocusNode,
                onPressed: () async {
                  final shouldClose = await onSave(dialogContext);
                  if (shouldClose && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                label: t.common.save,
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    saveFocusNode.dispose();
    onDispose?.call();
  });
}

/// Shows a selection dialog with focusable rows for dpad/keyboard navigation.
/// Used for settings with 5+ options (language, buffer size, etc.).
Future<T?> showSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<DialogOption<T>> options,
  required T currentValue,
}) {
  final focusFirstItem = InputModeTracker.isKeyboardMode(context);
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12, bottom: 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final selected = option.value == currentValue;
            return FocusableListTile(
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Theme.of(dialogContext).colorScheme.primary : null,
              ),
              title: Text(option.title),
              subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
              selected: selected,
              autofocus: focusFirstItem && selected,
              onTap: () => Navigator.pop(dialogContext, option.value),
            );
          }).toList(),
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

  _showSettingsInputDialog(
    context: context,
    title: title,
    contentBuilder: (dialogContext, context, setDialogState, saveFocusNode) {
      return Column(
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      );
    },
    onSave: (_) async {
      await onSave(spinnerValue);
      return true;
    },
  );
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

  _showSettingsInputDialog(
    context: context,
    title: title,
    contentBuilder: (_, _, setDialogState, saveFocusNode) {
      return TextField(
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
      );
    },
    onSave: (_) async {
      final parsed = int.tryParse(controller.text);
      if (parsed == null || parsed < min || parsed > max) return false;
      await onSave(parsed);
      return true;
    },
    onDispose: controller.dispose,
  );
}

/// Convert `#RRGGBB` (or `#AARRGGBB`) hex to [Color]. Defaults to black on parse error.
Color hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xff000000);
}

/// Convert [Color] to `#RRGGBB` hex (uppercase). Drops alpha.
String colorToHex(Color color) {
  String two(num c) => ((c * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  return '#${two(color.r)}${two(color.g)}${two(color.b)}'.toUpperCase();
}

/// Shows a color picker dialog. Uses [TvColorPicker] in keyboard/D-pad mode,
/// otherwise the standard FlexColorPicker. Calls [onSave] with `#RRGGBB`.
void showColorInputDialog({
  required BuildContext context,
  required String title,
  required String currentHex,
  required Future<void> Function(String hex) onSave,
}) {
  if (InputModeTracker.isKeyboardMode(context)) {
    _showColorInputDialogTV(context: context, title: title, currentHex: currentHex, onSave: onSave);
  } else {
    _showColorInputDialogStandard(context: context, title: title, currentHex: currentHex, onSave: onSave);
  }
}

Future<void> _showColorInputDialogStandard({
  required BuildContext context,
  required String title,
  required String currentHex,
  required Future<void> Function(String hex) onSave,
}) async {
  final initial = hexToColor(currentHex);
  final selected = await showColorPickerDialog(
    context,
    initial,
    title: Text(title),
    barrierColor: Colors.black54,
    width: 40,
    height: 40,
    spacing: 0,
    runSpacing: 0,
    borderRadius: 4,
    wheelDiameter: 165,
    enableOpacity: false,
    showColorCode: true,
    colorCodeHasColor: true,
    pickersEnabled: const <ColorPickerType, bool>{
      ColorPickerType.both: false,
      ColorPickerType.primary: true,
      ColorPickerType.accent: false,
      ColorPickerType.wheel: true,
      ColorPickerType.custom: false,
    },
    actionButtons: const ColorPickerActionButtons(okButton: true, closeButton: true, dialogActionButtons: false),
  );
  if (selected != initial) await onSave(colorToHex(selected));
}

void _showColorInputDialogTV({
  required BuildContext context,
  required String title,
  required String currentHex,
  required Future<void> Function(String hex) onSave,
}) {
  Color picked = hexToColor(currentHex);
  _showSettingsInputDialog(
    context: context,
    title: title,
    contentBuilder: (_, _, setDialogState, saveFocusNode) {
      return TvColorPicker(
        initialColor: picked,
        onColorChanged: (c) => setDialogState(() => picked = c),
        onConfirm: () => saveFocusNode.requestFocus(),
      );
    },
    onSave: (_) async {
      await onSave(colorToHex(picked));
      return true;
    },
  );
}

/// Shows a text input dialog with regex validation and reset-to-default support.
void showRegexInputDialog({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String defaultValue,
  required Future<void> Function(String value) onSave,
}) {
  final controller = TextEditingController(text: currentValue);
  String? errorText;

  _showSettingsInputDialog(
    context: context,
    title: title,
    contentBuilder: (_, _, setDialogState, saveFocusNode) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(labelText: 'Regex', errorText: errorText),
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
      );
    },
    leadingActionsBuilder: (_, setDialogState) => [
      DialogActionButton(
        onPressed: () {
          controller.text = defaultValue;
          setDialogState(() => errorText = null);
        },
        label: t.settings.resetToDefault,
      ),
    ],
    onSave: (_) async {
      if (errorText != null) return false;
      await onSave(controller.text);
      return true;
    },
    onDispose: controller.dispose,
  );
}
