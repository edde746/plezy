import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/strings.g.dart';
import '../focus/focusable_button.dart';
import '../focus/focusable_wrapper.dart';
import '../services/trackers/oauth_proxy_client.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'dialog_action_button.dart';
import 'loading_indicator_box.dart';

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

  Future<void> _open() async {
    await launchUrl(Uri.parse(start.url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: start.url));
    if (!context.mounted) return;
    showAppSnackBar(context, t.services.oauthProxy.urlCopied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(t.services.oauthProxy.title(service: serviceName)),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(t.services.oauthProxy.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
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
          FocusableWrapper(
            onSelect: () => _copyUrl(context),
            semanticLabel: t.services.oauthProxy.copyUrl,
            descendantsAreFocusable: false,
            borderRadius: 8,
            useBackgroundFocus: true,
            child: InkWell(
              canRequestFocus: false,
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
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FocusableButton(
              onPressed: _open,
              useBackgroundFocus: true,
              child: FilledButton.icon(
                icon: const AppIcon(Symbols.open_in_new_rounded),
                label: Text(t.services.oauthProxy.openToSignIn(service: serviceName)),
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
