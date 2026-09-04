import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/account_preferences_target.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import '../libraries/state_messages.dart';
import 'account_preferences_detail_screen.dart';

/// Entry point for the Account preferences section: the preferences that live
/// on a media-server account rather than on this device.
///
/// With one account a picker would be a single row in front of the only
/// destination there is, so that account's rows are rendered here instead. With
/// several, the account has to be chosen first — a Plex profile and a Jellyfin
/// user store entirely separate values.
class AccountPreferencesScreen extends StatelessWidget {
  final List<AccountPreferenceTarget> targets;

  const AccountPreferencesScreen({super.key, required this.targets});

  @override
  Widget build(BuildContext context) {
    final title = Text(t.accountPreferences.sectionTitle);

    if (targets.isEmpty) {
      return SettingsPage.slivers(
        title: title,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Symbols.account_circle_rounded,
              message: t.accountPreferences.noAccounts,
              subtitle: t.accountPreferences.noAccountsHint,
            ),
          ),
        ],
      );
    }

    if (targets.length == 1) {
      return SettingsPage.slivers(
        title: title,
        slivers: [AccountPreferencesBody(target: targets.first)],
      );
    }

    // The account the user is browsing with is the one they came here for;
    // that is what AccountPreferenceTarget.isActiveProfileAccount is for. Both
    // halves keep the caller's order.
    final ordered = [
      ...targets.where((target) => target.isActiveProfileAccount),
      ...targets.where((target) => !target.isActiveProfileAccount),
    ];
    final theme = Theme.of(context);

    return SettingsPage(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            t.accountPreferences.pickAccount,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        SettingsGroup(
          children: [
            for (final target in ordered)
              FocusableListTile(
                key: ValueKey(target.ref.key),
                leading: BackendBadge(backend: target.backend, size: 24),
                title: Text(target.label),
                subtitle: target.subtitle != null ? Text(target.subtitle!) : null,
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AccountPreferencesDetailScreen(target: target)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
