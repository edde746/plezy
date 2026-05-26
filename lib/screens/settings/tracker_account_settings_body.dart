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
  /// Rendered immediately after the "Behavior" section header, before
  /// [toggles]. Used by per-tracker screens to surface their primary setting
  /// (e.g. Trakt's watch-state authority toggle) above the standard
  /// scrobble/sync toggles.
  final List<Widget> prefixChildren;
  final List<Widget> extraChildren;
  final FutureOr<void> Function() onDisconnect;

  const TrackerAccountSettingsBody({
    super.key,
    required this.title,
    required this.accountTitle,
    this.accountSubtitle,
    required this.service,
    required this.toggles,
    this.prefixChildren = const [],
    this.extraChildren = const [],
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: title,
      children: [
        ListTile(
          leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
          title: Text(accountTitle),
          subtitle: accountSubtitle != null ? Text(accountSubtitle!) : null,
        ),
        SettingsSectionHeader(t.settings.behavior),
        ...prefixChildren,
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
            final settings = SettingsService.instanceOrNull!;
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
        ...extraChildren,
        const Divider(height: 32),
        ListTile(
          leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
          title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: () => unawaited(Future<void>.sync(onDisconnect)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
