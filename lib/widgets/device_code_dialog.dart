import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_button.dart';
import '../focus/focusable_wrapper.dart';
import '../i18n/strings.g.dart';
import '../models/trackers/device_code.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'loading_indicator_box.dart';

/// Shared device-code activation dialog for Trakt and Simkl (RFC 8628).
///
/// Shows the `userCode` with copy-to-clipboard, a button to launch the
/// verification URL in the browser, and a "waiting for authorization…" spinner
/// while the poll loop runs. Dismissing calls [onCancel] so the provider can
/// abort the poll.
class DeviceCodeDialog extends StatelessWidget {
  final DeviceCode code;
  final String serviceName;
  final VoidCallback onCancel;

  const DeviceCodeDialog({super.key, required this.code, required this.serviceName, required this.onCancel});

  Future<void> _open() async {
    final url = code.verificationUrlComplete ?? code.verificationUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code.userCode));
    if (!context.mounted) return;
    showAppSnackBar(context, t.services.deviceCode.codeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(t.services.deviceCode.title(service: serviceName)),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(t.services.deviceCode.body(url: code.verificationUrl), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Center(
            child: FocusableWrapper(
              onSelect: () => _copy(context),
              semanticLabel: t.services.deviceCode.copyCode,
              descendantsAreFocusable: false,
              useBackgroundFocus: true,
              borderRadius: 8,
              child: InkWell(
                canRequestFocus: false,
                onTap: () => _copy(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    code.userCode,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 4,
                      fontWeight: .w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FocusableButton(
              onPressed: _open,
              useBackgroundFocus: true,
              child: FilledButton.icon(
                icon: const AppIcon(Symbols.open_in_new_rounded),
                label: Text(t.services.deviceCode.openToActivate(service: serviceName)),
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
