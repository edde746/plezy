import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_session.dart';
import '../../providers/seerr_account_provider.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

/// Connected-state settings for the Seerr instance: who is signed in,
/// which instance, and disconnect.
class SeerrSettingsScreen extends StatelessWidget {
  const SeerrSettingsScreen({super.key});

  Future<void> _disconnect(BuildContext context, SeerrAccountProvider account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.seerr.disconnectConfirm,
      message: t.seerr.disconnectConfirmBody,
      confirmText: t.common.disconnect,
      isDestructive: true,
    );
    if (!confirmed) return;
    await account.disconnect();
    // build()'s post-frame handler pops the screen once the provider rebuilds
    // with isConnected == false — don't pop here too.
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeerrAccountProvider>(
      builder: (context, account, _) {
        final session = account.session;
        // Safety net: if the session got invalidated in the background, bail
        // out — the Services hub row is the entry point for reconnecting.
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return SettingsPage(title: Text(t.seerr.title), children: const []);
        }

        final methodLabel = switch (session.method) {
          SeerrAuthMethod.plex => 'Plex',
          SeerrAuthMethod.jellyfin => 'Jellyfin',
          SeerrAuthMethod.emby => 'Emby',
          SeerrAuthMethod.local => t.seerr.email,
        };
        return SettingsPage(
          title: Text(t.seerr.title),
          children: [
            SettingsGroup(
              children: [
                ListTile(
                  leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
                  title: Text(t.services.connectedAs(username: session.displayName)),
                  subtitle: Text(methodLabel),
                ),
                ListTile(
                  leading: const AppIcon(Symbols.dns_rounded, fill: 1),
                  title: Text(session.instanceLabel.isNotEmpty ? session.instanceLabel : t.seerr.instance),
                  subtitle: Text(session.baseUrl),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsGroup(
              children: [
                FocusableListTile(
                  leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                  title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => unawaited(_disconnect(context, account)),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
