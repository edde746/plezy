import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/plex_library.dart';
import '../../providers/libraries_provider.dart';
import '../../services/settings_service.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';

/// Per-provider library whitelist/blacklist screen. Toggling a switch
/// adds/removes the library from the filter set; "selected" means "in the
/// filter list" in both modes.
class TrackerLibraryFilterScreen extends StatefulWidget {
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
  State<TrackerLibraryFilterScreen> createState() => _TrackerLibraryFilterScreenState();
}

class _TrackerLibraryFilterScreenState extends State<TrackerLibraryFilterScreen> {
  late SettingsService _settings;
  TrackerLibraryFilterMode _mode = TrackerLibraryFilterMode.blacklist;
  final Set<String> _selectedIds = <String>{};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _mode = s.read(SettingsService.trackerFilterModePref(widget.service));
      _selectedIds
        ..clear()
        ..addAll(s.read(SettingsService.trackerFilterIdsPref(widget.service)).toSet());
      _loaded = true;
    });
  }

  Future<void> _setMode(TrackerLibraryFilterMode mode) async {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    await _settings.write(SettingsService.trackerFilterModePref(widget.service), mode);
  }

  Future<void> _toggleLibrary(String globalKey, bool value) async {
    setState(() {
      if (value) {
        _selectedIds.add(globalKey);
      } else {
        _selectedIds.remove(globalKey);
      }
    });
    await _settings.write(SettingsService.trackerFilterIdsPref(widget.service), _selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(t.trackers.libraryFilter.title);
    if (!_loaded) {
      return FocusedScrollScaffold(
        title: title,
        slivers: const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

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
              _mode == TrackerLibraryFilterMode.blacklist
                  ? t.trackers.libraryFilter.modeHintBlacklist
                  : t.trackers.libraryFilter.modeHintWhitelist,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          SegmentedSetting<TrackerLibraryFilterMode>(
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
            selected: _mode,
            onChanged: _setMode,
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
                  value: _selectedIds.contains(lib.globalKey),
                  onChanged: (v) => _toggleLibrary(lib.globalKey, v),
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
  }

  static Map<String, List<PlexLibrary>> _groupByServer(List<PlexLibrary> libs) {
    final out = <String, List<PlexLibrary>>{};
    for (final lib in libs) {
      final serverId = lib.serverId;
      if (serverId == null) continue;
      out.putIfAbsent(serverId, () => <PlexLibrary>[]).add(lib);
    }
    return out;
  }
}
