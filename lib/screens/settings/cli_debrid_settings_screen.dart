import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/cli_debrid_account_provider.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/cli_debrid_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

/// Connected-state settings for the cli_debrid instance: which instance,
/// and disconnect. Mirrors [SeerrSettingsScreen] minus the auth-method row
/// (cli_debrid has exactly one: API token).
class CliDebridSettingsScreen extends StatelessWidget {
  const CliDebridSettingsScreen({super.key});

  Future<void> _disconnect(BuildContext context, CliDebridAccountProvider account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.cliDebrid.disconnectConfirm,
      message: t.cliDebrid.disconnectConfirmBody,
      confirmText: t.common.disconnect,
      isDestructive: true,
    );
    if (!confirmed) return;
    await account.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CliDebridAccountProvider>(
      builder: (context, account, _) {
        final session = account.session;
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return SettingsPage(title: Text(t.cliDebrid.title), children: const []);
        }

        return SettingsPage(
          title: Text(t.cliDebrid.title),
          children: [
            SettingsGroup(
              children: [
                ListTile(
                  leading: const CliDebridIcon(),
                  title: Text(t.cliDebrid.instance),
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
