import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';

/// Dialog for joining a watch together session
class JoinSessionDialog extends StatefulWidget {
  const JoinSessionDialog({super.key});

  @override
  State<JoinSessionDialog> createState() => _JoinSessionDialogState();
}

class _JoinSessionDialogState extends State<JoinSessionDialog> with ControllerDisposerMixin {
  final _formKey = GlobalKey<FormState>();
  late final _sessionIdController = createTextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Symbols.group_add, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(t.watchTogether.joinWatchSession, style: theme.textTheme.titleLarge)),
                    FocusableWrapper(
                      useBackgroundFocus: true,
                      disableScale: true,
                      borderRadius: 20,
                      onSelect: () => Navigator.of(context).pop(),
                      child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Symbols.close)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Session ID input
                FocusableTextFormField(
                  controller: _sessionIdController,
                  decoration: InputDecoration(
                    labelText: t.watchTogether.sessionCode,
                    hintText: t.watchTogether.enterCodeHint,
                    prefixIcon: const Icon(Symbols.tag),
                    suffixIcon: IconButton(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Symbols.content_paste),
                      tooltip: t.watchTogether.pasteFromClipboard,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t.watchTogether.pleaseEnterCode;
                    }
                    if (value.length != 5) {
                      return t.watchTogether.codeMustBe5Chars;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _join(),
                  autofocus: true,
                ),

                const SizedBox(height: 16),

                // Instructions
                Text(
                  t.watchTogether.joinInstructions,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 24),

                // Join button
                FocusableButton(
                  onPressed: _join,
                  child: FilledButton.icon(
                    onPressed: _join,
                    icon: const Icon(Symbols.group_add),
                    label: Text(t.watchTogether.joinSession),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      // Clean the pasted text - extract alphanumeric characters and take first 8
      final cleaned = data!.text!.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (cleaned.isNotEmpty) {
        _sessionIdController.text = cleaned.substring(0, cleaned.length.clamp(0, 5));
        _sessionIdController.selection = TextSelection.collapsed(offset: _sessionIdController.text.length);
      }
    }
  }

  void _join() {
    if (_formKey.currentState!.validate()) {
      final sessionId = _sessionIdController.text.toUpperCase();
      Navigator.of(context).pop(sessionId);
    }
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Show the join session dialog
///
/// Returns the session ID if user confirms, null if cancelled
Future<String?> showJoinSessionDialog(BuildContext context) {
  return showDialog<String>(context: context, builder: (context) => const JoinSessionDialog());
}
