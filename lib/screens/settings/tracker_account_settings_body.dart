import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'tracker_library_filter_screen.dart';

class TrackerSettingsToggle {
  final Pref<bool> pref;
  final IconData icon;
  final String title;
  final String subtitle;
  final FutureOr<void> Function(bool)? onAfterWrite;

  const TrackerSettingsToggle({
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAfterWrite,
  });
}

class TrackerAccountSettingsBody extends StatelessWidget {
  final Widget title;
  final String accountTitle;
  final String? accountSubtitle;
  final TrackerService service;
  final List<TrackerSettingsToggle> toggles;
  final FutureOr<void> Function() onDisconnect;

  const TrackerAccountSettingsBody({
    super.key,
    required this.title,
    required this.accountTitle,
    this.accountSubtitle,
    required this.service,
    required this.toggles,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: title,
      children: [
        SettingsGroup(
          children: [
            ListTile(
              leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
              title: Text(accountTitle),
              subtitle: accountSubtitle != null ? Text(accountSubtitle!) : null,
            ),
          ],
        ),
        SettingsGroup(
          title: t.settings.behavior,
          children: [
            for (final toggle in toggles)
              SettingSwitchTile(
                pref: toggle.pref,
                icon: toggle.icon,
                title: toggle.title,
                subtitle: toggle.subtitle,
                onAfterWrite: toggle.onAfterWrite,
              ),
            SettingsBuilder(
              prefs: [SettingsService.trackerFilterModePref(service), SettingsService.trackerFilterIdsPref(service)],
              builder: (context) {
                final settings = SettingsService.instance;
                return ListTile(
                  leading: const AppIcon(Symbols.filter_list_rounded, fill: 1),
                  title: Text(t.trackers.libraryFilter.title),
                  subtitle: Text(TrackerLibraryFilterScreen.subtitleFor(settings, service)),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => TrackerLibraryFilterScreen(service: service))),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsGroup(
          children: [
            ListTile(
              leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
              title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => unawaited(Future<void>.sync(onDisconnect)),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
