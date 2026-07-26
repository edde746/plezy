import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../models/trackers/device_code.dart';
import '../utils/snackbar_helper.dart';
import 'pending_auth_dialog.dart';

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

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code.userCode));
    if (!context.mounted) return;
    showAppSnackBar(context, t.services.deviceCode.codeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PendingAuthDialog(
      title: t.services.deviceCode.title(service: serviceName),
      body: t.services.deviceCode.body(url: code.verificationUrl),
      url: code.verificationUrlComplete ?? code.verificationUrl,
      openLabel: t.services.deviceCode.openToActivate(service: serviceName),
      onCancel: onCancel,
      children: [
        Center(
          child: CopyTapRegion(
            onCopy: () => _copy(context),
            semanticLabel: t.services.deviceCode.copyCode,
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
        const SizedBox(height: 16),
      ],
    );
  }
}
