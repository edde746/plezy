import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../services/trackers/oauth_proxy_client.dart';
import '../utils/snackbar_helper.dart';
import 'dialog_action_button.dart';

/// Sign-in dialog for OAuth-proxy flows (MAL, AniList).
///
/// Shows a QR code plus a "open in browser" button — works uniformly on
/// phones (user taps the button), desktops (same), and TVs without a browser
/// (user scans the QR with a phone).
class OAuthProxyDialog extends StatelessWidget {
  final OAuthProxyStart start;
  final String serviceName;
  final VoidCallback onCancel;

  const OAuthProxyDialog({
    super.key,
    required this.start,
    required this.serviceName,
    required this.onCancel,
  });

  Future<void> _open() async {
    await launchUrl(Uri.parse(start.url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: start.url));
    if (!context.mounted) return;
    showAppSnackBar(context, t.trackers.oauthProxy.urlCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(t.trackers.oauthProxy.title(service: serviceName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.trackers.oauthProxy.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          // QrImageView doesn't support intrinsic sizing; wrap in SizedBox so
          // AlertDialog's IntrinsicWidth walk sees a concrete width.
          Center(
            child: SizedBox.square(
              dimension: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: QrImageView(
                  data: start.url,
                  size: 220,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _copyUrl(context),
            borderRadius: BorderRadius.circular(8),
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(t.trackers.oauthProxy.openToSignIn(service: serviceName)),
              onPressed: _open,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.trackers.deviceCode.waitingForAuthorization, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ],
      ),
      actions: [
        DialogActionButton(
          onPressed: () {
            onCancel();
            Navigator.of(context, rootNavigator: true).pop();
          },
          label: t.common.cancel,
        ),
      ],
    );
  }
}
