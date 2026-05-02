import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_library.dart';
import '../../providers/libraries_provider.dart';
import '../../services/settings_service.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';

/// Per-provider library whitelist/blacklist screen. Toggling a switch
/// adds/removes the library from the filter set; "selected" means "in the
/// filter list" in both modes.
class TrackerLibraryFilterScreen extends StatelessWidget {
  final TrackerService service;

  const TrackerLibraryFilterScreen({super.key, required this.service});

  /// Human-readable summary of the current filter state for [service], used as
  /// the subtitle on the parent settings screen's "Library filter" tile.
  static String subtitleFor(SettingsService settings, TrackerService service) {
    final mode = settings.read(SettingsService.trackerFilterModePref(service));
    final ids = settings.read(SettingsService.trackerFilterIdsPref(service)).toSet();
    if (ids.isEmpty) {
      return mode == TrackerLibraryFilterMode.blacklist
          ? t.trackers.libraryFilter.subtitleAllSyncing
          : t.trackers.libraryFilter.subtitleNoneSyncing;
    }
    final count = ids.length.toString();
    return mode == TrackerLibraryFilterMode.blacklist
        ? t.trackers.libraryFilter.subtitleBlocked(count: count)
        : t.trackers.libraryFilter.subtitleAllowed(count: count);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(t.trackers.libraryFilter.title);
    final modePref = SettingsService.trackerFilterModePref(service);
    final idsPref = SettingsService.trackerFilterIdsPref(service);

    return SettingsBuilder(
      prefs: [modePref, idsPref],
      builder: (context) {
        final settings = SettingsService.instanceOrNull!;
        final mode = settings.read(modePref);
        final selectedIds = settings.read(idsPref).toSet();
        final theme = Theme.of(context);

        return Consumer<LibrariesProvider>(
          builder: (context, provider, _) {
            final libraries = provider.libraries;
            final grouped = _groupByServer(libraries);
            final showServerHeaders = grouped.length > 1;

            final children = <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  mode == TrackerLibraryFilterMode.blacklist
                      ? t.trackers.libraryFilter.modeHintBlacklist
                      : t.trackers.libraryFilter.modeHintWhitelist,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              SettingSegmentedTile<TrackerLibraryFilterMode, TrackerLibraryFilterMode>(
                pref: modePref,
                icon: Symbols.filter_list_rounded,
                title: t.trackers.libraryFilter.mode,
                segments: [
                  ButtonSegment(
                    value: TrackerLibraryFilterMode.blacklist,
                    label: Text(t.trackers.libraryFilter.modeBlacklist),
                  ),
                  ButtonSegment(
                    value: TrackerLibraryFilterMode.whitelist,
                    label: Text(t.trackers.libraryFilter.modeWhitelist),
                  ),
                ],
                decode: (v) => v,
                encode: (v) => v,
              ),
              SettingsSectionHeader(t.trackers.libraryFilter.libraries),
            ];

            if (libraries.isEmpty) {
              children.add(ListTile(title: Text(t.trackers.libraryFilter.noLibraries)));
            } else {
              for (final entry in grouped.entries) {
                if (showServerHeaders) {
                  children.add(SettingsSectionHeader(entry.value.first.serverName ?? entry.key));
                }
                for (final lib in entry.value) {
                  children.add(
                    FocusableSwitchListTile(
                      key: ValueKey('tracker-library-filter-${lib.globalKey}'),
                      secondary: const AppIcon(Symbols.folder_rounded, fill: 1),
                      title: Text(lib.title),
                      value: selectedIds.contains(lib.globalKey),
                      onChanged: (v) async {
                        final next = Set<String>.of(selectedIds);
                        if (v) {
                          next.add(lib.globalKey);
                        } else {
                          next.remove(lib.globalKey);
                        }
                        await settings.write(idsPref, next.toList());
                      },
                    ),
                  );
                }
              }
            }

            children.add(const SizedBox(height: 24));

            return FocusedScrollScaffold(
              title: title,
              slivers: [SliverList(delegate: SliverChildListDelegate(children))],
            );
          },
        );
      },
    );
  }

  static Map<String, List<MediaLibrary>> _groupByServer(List<MediaLibrary> libs) {
    final out = <String, List<MediaLibrary>>{};
    for (final lib in libs) {
      final serverId = lib.serverId;
      if (serverId == null) continue;
      out.putIfAbsent(serverId, () => <MediaLibrary>[]).add(lib);
    }
    return out;
  }
}
