import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/media_library.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

const _noScreensaverLibraries = '__none__';

class ContentScreensaverLibrariesScreen extends StatefulWidget {
  const ContentScreensaverLibrariesScreen({super.key});

  @override
  State<ContentScreensaverLibrariesScreen> createState() => _ContentScreensaverLibrariesScreenState();
}

class _ContentScreensaverLibrariesScreenState extends State<ContentScreensaverLibrariesScreen> {
  Future<List<MediaLibrary>>? _librariesFuture;
  List<MediaLibrary> _libraries = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _librariesFuture ??= _loadLibraries();
  }

  Future<List<MediaLibrary>> _loadLibraries() async {
    final servers = context.read<MultiServerProvider>();
    final libraries = <MediaLibrary>[];
    for (final serverId in servers.onlineServerIds) {
      final client = servers.getClientForServer(ServerId(serverId));
      if (client == null) continue;
      try {
        libraries.addAll(await client.fetchLibraries());
      } catch (error, stackTrace) {
        // Other servers may still provide usable library options.
        appLogger.w('Could not list screensaver libraries for $serverId', error: error, stackTrace: stackTrace);
      }
    }
    libraries.sort((a, b) {
      final server = (a.serverName ?? '').compareTo(b.serverName ?? '');
      return server != 0 ? server : a.title.compareTo(b.title);
    });
    _libraries = libraries;
    return libraries;
  }

  Future<void> _writeSelection(List<String> current, String libraryKey, bool selected) async {
    final allKeys = _libraries.map((library) => library.globalKey).toSet();
    final selection = current.contains(_noScreensaverLibraries)
        ? <String>{}
        : current.isEmpty
        ? Set<String>.of(allKeys)
        : current.toSet();
    if (selected) {
      selection.add(libraryKey);
    } else {
      selection.remove(libraryKey);
    }
    final List<String> next;
    if (selection.isEmpty) {
      next = [_noScreensaverLibraries];
    } else if (selection.containsAll(allKeys)) {
      next = const [];
    } else {
      next = selection.toList()..sort();
    }
    await SettingsService.instance.write(SettingsService.contentScreensaverLibraryKeys, next);
  }

  Widget _description(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Text(
        t.settings.contentScreensaverLibrariesDescription,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaLibrary>>(
      future: _librariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SettingsPage(
            title: Text(t.settings.contentScreensaverLibraries),
            children: [
              _description(context),
              const Center(
                child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
              ),
            ],
          );
        }
        final libraries = snapshot.data ?? const <MediaLibrary>[];
        if (libraries.isEmpty) {
          return SettingsPage(
            title: Text(t.settings.contentScreensaverLibraries),
            children: [
              _description(context),
              SettingsGroup(children: [FocusableListTile(title: Text(t.settings.contentScreensaverNoLibraries))]),
            ],
          );
        }

        final groups = <String, List<MediaLibrary>>{};
        for (final library in libraries) {
          groups.putIfAbsent(library.serverName ?? t.common.unknown, () => []).add(library);
        }
        return SettingValueBuilder<List<String>>(
          pref: SettingsService.contentScreensaverLibraryKeys,
          builder: (context, selectedKeys, _) {
            final allSelected = selectedKeys.isEmpty;
            final noneSelected = selectedKeys.contains(_noScreensaverLibraries);
            final selected = selectedKeys.toSet();
            return SettingsPage(
              title: Text(t.settings.contentScreensaverLibraries),
              children: [
                _description(context),
                for (final group in groups.entries)
                  SettingsGroup(
                    title: group.key,
                    children: [
                      for (final library in group.value)
                        FocusableCheckboxListTile(
                          title: Text(library.title),
                          subtitle: Text(library.kind.label),
                          value: allSelected || (!noneSelected && selected.contains(library.globalKey)),
                          onChanged: (value) =>
                              unawaited(_writeSelection(selectedKeys, library.globalKey, value ?? false)),
                        ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
