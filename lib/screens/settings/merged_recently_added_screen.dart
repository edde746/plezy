import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../providers/libraries_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

/// Picks the libraries whose Recently Added rows Home merges into one (#1652).
class MergedRecentlyAddedScreen extends StatelessWidget {
  const MergedRecentlyAddedScreen({super.key});

  static const _pref = SettingsService.mergedRecentlyAddedLibraries;

  /// Subtitle for the tile that opens this screen.
  static String subtitleFor(SettingsService settings) {
    final count = settings.read(_pref).length;
    return count < 2 ? t.settings.mergeRecentlyAddedOff : t.settings.mergeRecentlyAddedCount(count: count.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: const [_pref],
      builder: (context) {
        final settings = SettingsService.instance;
        final selected = settings.read(_pref).toSet();
        final libraries = context
            .watch<LibrariesProvider>()
            .libraries
            .where((lib) => lib.kind == MediaKind.movie || lib.kind == MediaKind.show || lib.kind == MediaKind.clip)
            .toList();
        final showServerName = libraries.map((lib) => lib.serverId).toSet().length > 1;
        final theme = Theme.of(context);

        Widget libraryTile(MediaLibrary lib) => FocusableSwitchListTile(
          key: ValueKey('merged-recently-added-${lib.globalKey}'),
          secondary: const AppIcon(Symbols.folder_rounded, fill: 1),
          title: Text(lib.title),
          subtitle: showServerName && lib.serverName != null ? Text(lib.serverName!) : null,
          value: selected.contains(lib.globalKey),
          onChanged: (v) async {
            final next = Set<String>.of(selected);
            v ? next.add(lib.globalKey) : next.remove(lib.globalKey);
            await settings.write(_pref, next.toList());
          },
        );

        return SettingsPage(
          title: Text(t.settings.mergeRecentlyAdded),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                t.settings.mergeRecentlyAddedHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            SettingsGroup(
              title: t.services.libraryFilter.libraries,
              children: libraries.isEmpty
                  ? [ListTile(title: Text(t.services.libraryFilter.noLibraries))]
                  : [for (final lib in libraries) libraryTile(lib)],
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
