import 'package:flutter/material.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../services/companion_remote/remote_pairing_store.dart';
import '../../utils/dialogs.dart';
import '../dialog_action_button.dart';

/// The host's random capability is entered locally, never sent in plaintext.
class RemotePairingDialog extends StatefulWidget {
  const RemotePairingDialog({super.key});

  static Future<String?> show(BuildContext context) =>
      showScopedDialog<String>(context: context, builder: (_) => const RemotePairingDialog());

  @override
  State<RemotePairingDialog> createState() => _RemotePairingDialogState();
}

class _RemotePairingDialogState extends State<RemotePairingDialog> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(RemotePairingStore.normalizeCode(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.companionRemote.pairing.codeTitle),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.companionRemote.pairing.codeDescription),
          const SizedBox(height: 16),
          FocusableTextFormField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: t.companionRemote.pairing.codeTitle),
            validator: (value) =>
                RemotePairingStore.normalizeCode(value ?? '') == null ? t.companionRemote.pairing.codeInvalid : null,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],
      ),
    ),
    actions: [
      DialogActionButton(onPressed: () => Navigator.of(context).pop(), label: t.common.cancel),
      DialogActionButton(onPressed: _submit, label: t.common.connect, isPrimary: true),
    ],
  );
}
