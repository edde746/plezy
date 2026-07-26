import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_button.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'loading_indicator_box.dart';

/// Shell for the "waiting for out-of-band authorization" dialogs.
///
/// Shows [body], the service-specific [children], a button that launches [url]
/// in the browser, and a "waiting for authorization…" spinner while the poll
/// loop runs. Dismissing calls [onCancel] so the provider can abort the poll.
class PendingAuthDialog extends StatelessWidget {
  final String title;
  final String body;

  /// Sits between the body text and the launch button, and carries its own
  /// trailing spacing.
  final List<Widget> children;
  final String url;
  final String openLabel;
  final VoidCallback onCancel;

  const PendingAuthDialog({
    super.key,
    required this.title,
    required this.body,
    required this.children,
    required this.url,
    required this.openLabel,
    required this.onCancel,
  });

  Future<void> _open() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          ...children,
          SizedBox(
            width: double.infinity,
            child: FocusableButton(
              onPressed: _open,
              useBackgroundFocus: true,
              child: FilledButton.icon(
                icon: const AppIcon(Symbols.open_in_new_rounded),
                label: Text(openLabel),
                onPressed: _open,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const LoadingIndicatorBox(size: 16),
              const SizedBox(width: 12),
              Expanded(child: Text(t.services.deviceCode.waitingForAuthorization, style: theme.textTheme.bodySmall)),
            ],
          ),
        ],
      ),
      actions: [
        DialogActionButton(
          onPressed: () {
            onCancel();
            Navigator.of(context).pop();
          },
          label: t.common.cancel,
        ),
      ],
    );
  }
}

/// Tap/D-pad target that copies the value it displays to the clipboard.
class CopyTapRegion extends StatelessWidget {
  final VoidCallback onCopy;
  final String semanticLabel;
  final Widget child;

  const CopyTapRegion({super.key, required this.onCopy, required this.semanticLabel, required this.child});

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      onSelect: onCopy,
      semanticLabel: semanticLabel,
      descendantsAreFocusable: false,
      useBackgroundFocus: true,
      borderRadius: 8,
      child: InkWell(canRequestFocus: false, onTap: onCopy, borderRadius: BorderRadius.circular(8), child: child),
    );
  }
}
