import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../services/trackers/oauth_proxy_client.dart';
import 'pending_auth_dialog.dart';

/// Sign-in dialog for OAuth-proxy flows (MAL, AniList).
///
/// The [PendingAuthDialog] shell contributes everything this flow needs — QR
/// code, readable copyable URL, browser launch button, and the waiting
/// spinner — so it works uniformly on phones (user taps the button), desktops
/// (same), and TVs without a browser (user scans the QR with a phone).
class OAuthProxyDialog extends StatelessWidget {
  final OAuthProxyStart start;
  final String serviceName;
  final VoidCallback onCancel;

  const OAuthProxyDialog({super.key, required this.start, required this.serviceName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return PendingAuthDialog(
      title: t.services.oauthProxy.title(service: serviceName),
      body: t.services.oauthProxy.body,
      url: start.url,
      openLabel: t.services.oauthProxy.openToSignIn(service: serviceName),
      onCancel: onCancel,
      children: const [],
    );
  }
}
