import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../models/trackers/device_code.dart';
import '../utils/snackbar_helper.dart';
import 'pending_auth_dialog.dart';

/// Shared device-code activation dialog for Trakt, Simkl, and MDBList
/// (RFC 8628).
///
/// The [PendingAuthDialog] shell contributes the QR code (encoding the
/// code-prefilled verification URL when the service provides one), the
/// readable copyable verification URL, the browser launch button, and the
/// "waiting for authorization…" spinner; this dialog adds the `userCode` with
/// copy-to-clipboard. Dismissing calls [onCancel] so the provider can abort
/// the poll.
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
      body: t.services.deviceCode.instructions,
      url: code.verificationUrlComplete ?? code.verificationUrl,
      displayUrl: code.verificationUrl,
      openLabel: t.services.deviceCode.openToActivate(service: serviceName),
      onCancel: onCancel,
      children: [
        Center(
          child: CopyTapRegion(
            onCopy: () => _copy(context),
            semanticLabel: t.services.deviceCode.copyCode,
            semanticValue: code.userCode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Scale down instead of wrapping: user codes vary in length and
              // a wrapped activation code reads as two codes.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  code.userCode,
                  maxLines: 1,
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
      ],
    );
  }
}
