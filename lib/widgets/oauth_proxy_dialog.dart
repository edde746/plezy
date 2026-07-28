import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../i18n/strings.g.dart';
import '../services/trackers/oauth_proxy_client.dart';
import '../utils/snackbar_helper.dart';
import 'pending_auth_dialog.dart';

/// Sign-in dialog for OAuth-proxy flows (MAL, AniList).
///
/// Shows a QR code plus a "open in browser" button — works uniformly on
/// phones (user taps the button), desktops (same), and TVs without a browser
/// (user scans the QR with a phone).
class OAuthProxyDialog extends StatelessWidget {
  final OAuthProxyStart start;
  final String serviceName;
  final VoidCallback onCancel;

  const OAuthProxyDialog({super.key, required this.start, required this.serviceName, required this.onCancel});

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: start.url));
    if (!context.mounted) return;
    showAppSnackBar(context, t.services.oauthProxy.urlCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PendingAuthDialog(
      title: t.services.oauthProxy.title(service: serviceName),
      body: t.services.oauthProxy.body,
      url: start.url,
      openLabel: t.services.oauthProxy.openToSignIn(service: serviceName),
      onCancel: onCancel,
      children: [
        // QrImageView doesn't support intrinsic sizing; wrap in SizedBox so
        // AlertDialog's IntrinsicWidth walk sees a concrete width.
        Center(
          child: SizedBox.square(
            dimension: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: QrImageView(data: start.url, size: 220, version: QrVersions.auto, backgroundColor: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CopyTapRegion(
          onCopy: () => _copyUrl(context),
          semanticLabel: t.services.oauthProxy.copyUrl,
          semanticValue: start.url,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              start.url,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
