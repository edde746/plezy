import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../widgets/dialog_action_button.dart';
import 'dialogs.dart';

/// Consent is for this exact endpoint, before sending a password, token, or
/// Quick Connect secret. Never use a failed TLS handshake as HTTP consent.
Future<bool> confirmInsecureConnection(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (uri.scheme == 'https') return true;
  if (uri.scheme != 'http') return false;
  return await showScopedDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(t.addServer.insecureTitle),
          content: Text(
            t.addServer.insecureDescription(
              url: uri.replace(userInfo: '', query: '', fragment: '').toString(),
            ),
          ),
          actions: [
            DialogActionButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(false),
              label: t.common.cancel,
            ),
            DialogActionButton(onPressed: () => Navigator.of(context).pop(true), label: t.addServer.allowHttp),
          ],
        ),
      ) ??
      false;
}
