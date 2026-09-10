import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/home_section_config.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_backend.dart';
import '../../media/ids.dart';
import '../../media/media_library.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../models/plex/plex_managed_hub.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

class HomeLayoutSettingsScreen extends StatefulWidget {
  const HomeLayoutSettingsScreen({super.key});

  @override
  State<HomeLayoutSettingsScreen> createState() => _HomeLayoutSettingsScreenState();
}

class _HomeLayoutSettingsScreenState extends State<HomeLayoutSettingsScreen> {
  List<HomeSectionConfig> _sections = [];
  bool _loaded = false;
  List<MediaItem> _collections = const [];
  Map<String, List<PlexManagedHub>> _managedRows = {};
  List<String> _rowOrder = [];
  String? _highlightedRowToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsService.getInstance();
    final sections = List.of(settings.read(SettingsService.homeSections));
    final rowOrder = List.of(settings.read(SettingsService.homeRowOrder));
    List<MediaItem> collections = const [];
    try {
      collections =
          (await context.read<MultiServerProvider>().aggregationService.getCollectionsFromAllServers()).collections;
    } catch (_) {
      // The editor remains usable when a server is temporarily offline.
    }
    final managedRows = <String, List<PlexManagedHub>>{};

    final libraryProvider = context.read<LibrariesProvider>();
    if (!libraryProvider.hasLibraries) await libraryProvider.loadLibraries();
    final plexLibraries = context
        .read<LibrariesProvider>()
        .libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    await Future.wait(
      plexLibraries.map((library) async {
        try {
          final client = context.read<MultiServerProvider>().getPlexClientForServer(ServerId(library.serverId!));
          if (client != null) managedRows[library.globalKey] = await client.fetchManagedHubs(library.id);
        } catch (_) {}
      }),
    );
    final normalizedOrder = _normalizeRowOrder(rowOrder, plexLibraries, sections, managedRows);
    // home_row_order is the only thing that decides what shows on Home
    // (see buildConfiguredHomeSections), so a newly-promoted Plex hub or a
    // row created outside the normal Add-row flow has to actually land in
    // the saved order the moment it's discovered here -- otherwise it stays
    // invisible on Home until some unrelated reorder happens to write it.
    if (!listEquals(normalizedOrder, rowOrder)) {
      await settings.write(SettingsService.homeRowOrder, normalizedOrder);
    }
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _collections = collections;
      _managedRows = managedRows;
      _rowOrder = normalizedOrder;
      _loaded = true;
    });
  }

  Future<void> _save(List<HomeSectionConfig> sections) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeSections, sections);
    final libraries = context
        .read<LibrariesProvider>()
        .libraries
        .where((library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null)
        .toList();
    final order = _normalizeRowOrder(settings.read(SettingsService.homeRowOrder), libraries, sections, _managedRows);
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted)
      setState(() {
        _sections = sections;
        _rowOrder = order;
      });
  }

  Future<void> _editSection(HomeSectionConfig current) async {
    final libraries = context.read<LibrariesProvider>().libraries.where((l) => !l.hidden).toList();
    final result = await showDialog<HomeSectionConfig>(
      context: context,
      builder: (_) => _HomeSectionDialog(libraries: libraries, collections: _collections, initial: current),
    );
    if (result != null) {
      final updated = _sections.map((s) => s.id == current.id ? result : s).toList();
      await _save(updated);
    }
  }

  Future<void> _addSection() async {
    final libraries = context.read<LibrariesProvider>().libraries.where((l) => !l.hidden).toList();
    final result = await showDialog<HomeSectionConfig>(
      context: context,
      builder: (_) => _HomeSectionDialog(libraries: libraries, collections: _collections),
    );
    if (result == null) return;
    await _save([..._sections, result]);
    if (result.showOnHome) await _moveTokenToTop('custom:${result.id}');
  }

  Future<void> _moveTokenToTop(String token) async {
    if (!_rowOrder.contains(token)) return;
    final order = List<String>.of(_rowOrder)..remove(token);
    order.insert(0, token);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeRowOrder, order);
    if (mounted) setState(() => _rowOrder = order);
  }

  Future<void> _deleteSection(HomeSectionConfig section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Home row?'),
        content: Text('"${section.title}" will be deleted. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _save(_sections.where((s) => s.id != section.id).toList());
  }

  String _hubToken(MediaLibrary library, PlexManagedHub hub) =>
      'plex:${library.serverId}:${library.id}:${hub.identifier}';

  List<String> _normalizeRowOrder(
    List<String> saved,
    List<MediaLibrary> libraries,
    List<HomeSectionConfig> sections,
    Map<String, List<PlexManagedHub>> managedRows,
  ) {
    final available = <String>[
      for (final library in libraries)
        for (final hub in managedRows[library.globalKey] ?? const <PlexManagedHub>[])
          if (hub.promotedToOwnHome) _hubToken(library, hub),
      for (final section in sections)
        if (section.enabled && section.showOnHome) 'custom:${section.id}',
    ];
    return [...saved.where(available.contains), ...available.where((entry) => !saved.contains(entry))];
  }

  Future<void> _moveRow(String token, int delta) async {
    final index = _rowOrder.indexOf(token);
    final next = index + delta;
    if (index < 0 || next < 0 || next >= _rowOrder.length) return;
    final order = List<String>.of(_rowOrder);
    final item = order.removeAt(index);
    order.insert(next, item);
    // Update and highlight immediately rather than after the settings write
    // completes: waiting made the row jump with no visible cue of which one
    // moved, since the highlight and the reorder landed in the same frame
    // only once the (imperceptibly fast, but still async) write returned.
    setState(() {
      _rowOrder = order;
      _highlightedRowToken = token;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _highlightedRowToken == token) setState(() => _highlightedRowToken = null);
    });
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.homeRowOrder, order);
  }

  Future<void> _removeRowFromHome(String token) async {
    if (token.startsWith('custom:')) {
      final id = token.substring('custom:'.length);
      await _save(_sections.map((s) => s.id == id ? s.copyWith(showOnHome: false) : s).toList());
      return;
    }
    if (!token.startsWith('plex:')) return;
    final parts = token.split(':');
    if (parts.length < 4) return;
    final serverId = parts[1];
    final libraryId = parts[2];
    final hubIdentifier = parts.sublist(3).join(':');
    final library = context
        .read<LibrariesProvider>()
        .libraries
        .where((l) => l.serverId == serverId && l.id == libraryId)
        .firstOrNull;
    if (library == null) return;
    final hub = (_managedRows[library.globalKey] ?? const <PlexManagedHub>[])
        .where((h) => h.identifier == hubIdentifier)
        .firstOrNull;
    if (hub == null) return;
    await _setManagedVisibility(library, hub, home: false);
  }

  List<MapEntry<String, String>> _organizerRows() {
    final libraries = context.read<LibrariesProvider>().libraries.where(
      (library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null,
    );
    final labels = <String, String>{};
    for (final library in libraries) {
      for (final hub in _managedRows[library.globalKey] ?? const <PlexManagedHub>[]) {
        if (hub.promotedToOwnHome) labels[_hubToken(library, hub)] = '${library.title}: ${hub.title}';
      }
    }
    for (final section in _sections) {
      if (section.enabled && section.showOnHome) labels['custom:${section.id}'] = 'Custom: ${section.title}';
    }
    return [
      for (final token in _rowOrder)
        if (labels[token] != null) MapEntry(token, labels[token]!),
    ];
  }

  List<Widget> _plexManagerGroups() {
    final libraries = context.read<LibrariesProvider>().libraries.where(
      (library) => !library.hidden && library.backend == MediaBackend.plex && library.serverId != null,
    );
    return [
      SettingsGroup(
        title: 'Plex Home manager',
        children: [
          ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Symbols.sync_rounded),
            title: const Text('Manage Plex rows in Plezy'),
            subtitle: const Text('Open to organize the Home-selected rows'),
            children: [
              for (final indexed in _organizerRows().indexed)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: indexed.$2.key == _highlightedRowToken
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                      : Colors.transparent,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Symbols.drag_indicator_rounded),
                    title: Text(indexed.$2.value),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Symbols.arrow_upward_rounded),
                          onPressed: indexed.$1 == 0 ? null : () => _moveRow(indexed.$2.key, -1),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.arrow_downward_rounded),
                          onPressed: indexed.$1 == _organizerRows().length - 1
                              ? null
                              : () => _moveRow(indexed.$2.key, 1),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.close_rounded),
                          tooltip: 'Remove from Home',
                          onPressed: () => _removeRowFromHome(indexed.$2.key),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_organizerRows().isEmpty) const ListTile(title: Text('Select Home rows below first.')),
            ],
          ),
          for (final library in libraries) _managedLibraryTile(library),
        ],
      ),
    ];
  }

  Future<void> _setManagedVisibility(
    MediaLibrary library,
    PlexManagedHub hub, {
    bool? recommended,
    bool? home,
    bool? friendsHome,
  }) async {
    final client = context.read<MultiServerProvider>().getPlexClientForServer(ServerId(library.serverId!));
    if (client == null) return;
    await client.updateManagedHubVisibility(
      library.id,
      hub.identifier,
      promotedToRecommended: recommended ?? hub.promotedToRecommended,
      promotedToOwnHome: home ?? hub.promotedToOwnHome,
      promotedToSharedHome: friendsHome ?? hub.promotedToSharedHome,
    );
    await _load();
  }

  Widget _managedLibraryTile(MediaLibrary library) {
    final rows = _managedRows[library.globalKey] ?? const <PlexManagedHub>[];
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Icon(library.kind == MediaKind.show ? Symbols.tv_rounded : Symbols.movie_rounded),
      title: Text(library.title),
      subtitle: Text('${rows.length} Plex-managed rows'),
      children: [
        for (var index = 0; index < rows.length; index++)
          ListTile(
            dense: true,
            title: Text(rows[index].title),
            subtitle: rows[index].deletable ? const Text('Custom Plex row') : null,
            trailing: Wrap(
              spacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Tooltip(
                  message: 'Show in Library Recommended',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: rows[index].promotedToRecommended,
                        onChanged: (v) => _setManagedVisibility(library, rows[index], recommended: v),
                      ),
                      const Text('Library'),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Show on Home screen',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: rows[index].promotedToOwnHome,
                        onChanged: (v) => _setManagedVisibility(library, rows[index], home: v),
                      ),
                      const Text('Home'),
                    ],
                  ),
                ),
                if (rows[index].deletable)
                  IconButton(
                    icon: const Icon(Symbols.delete_outline_rounded),
                    tooltip: 'Remove Hub',
                    onPressed: () async {
                      final client = context.read<MultiServerProvider>().getPlexClientForServer(
                        ServerId(library.serverId!),
                      );
                      if (client != null) {
                        await client.removeManagedHub(library.id, rows[index].identifier);
                        await _load();
                      }
                    },
                  ),
              ],
            ),
          ),
        if (rows.isEmpty) const ListTile(title: Text('No Plex-managed rows returned for this library.')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: const Text('Home layout'),
      children: [
        if (_loaded) ..._plexManagerGroups(),
        SettingsGroup(
          title: 'Custom rows',
          children: [
            if (!_loaded) const ListTile(title: Text('Loading home layout…')),
            if (_loaded && _sections.isEmpty)
              const ListTile(title: Text('No custom rows yet'), subtitle: Text('Use Add Home row to create one.')),
            for (final section in _sections)
              ListTile(
                leading: const Icon(Symbols.tune_rounded),
                title: Text(section.title),
                subtitle: Text(_label(section.kind)),
                onTap: () => _editSection(section),
                trailing: IconButton(
                  icon: const Icon(Symbols.delete_outline_rounded),
                  tooltip: 'Remove row',
                  onPressed: () => _deleteSection(section),
                ),
              ),
            ListTile(
              leading: const Icon(Symbols.add_rounded),
              title: const Text('Add Home row'),
              subtitle: const Text('Choose a category; the new row is added to Organizer automatically'),
              onTap: _addSection,
            ),
          ],
        ),
      ],
    );
  }
}

String _label(HomeSectionKind kind) => switch (kind) {
  HomeSectionKind.recentlyAdded => 'Recently Added',
  HomeSectionKind.recentlyReleased => 'Recently Released',
  HomeSectionKind.movieCollections => 'Movie Collections',
  HomeSectionKind.showCollections => 'Show Collections',
};

class _HomeSectionDialog extends StatefulWidget {
  const _HomeSectionDialog({required this.libraries, required this.collections, this.initial});
  final List<MediaLibrary> libraries;
  final List<MediaItem> collections;
  final HomeSectionConfig? initial;
  @override
  State<_HomeSectionDialog> createState() => _HomeSectionDialogState();
}

class _HomeSectionDialogState extends State<_HomeSectionDialog> {
  final _title = TextEditingController();
  HomeSectionKind _kind = HomeSectionKind.recentlyAdded;
  final _selected = <String>{};
  final _selectedCollections = <String>{};
  bool _allCollections = true;
  bool _showInLibraryRecommended = true;
  bool _showOnHome = true;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _kind = initial.kind;
      _selected.addAll(initial.libraryKeys);
      _selectedCollections.addAll(initial.collectionKeys);
      _allCollections = initial.collectionKeys.isEmpty;
      _showInLibraryRecommended = initial.showInLibraryRecommended;
      _showOnHome = initial.showOnHome;
    }
  }

  List<MediaItem> _filteredCollections() => widget.collections.where((item) {
    final isMovie = widget.libraries.any(
      (library) => library.globalKey == item.libraryGlobalKey && library.kind == MediaKind.movie,
    );
    final isShow = widget.libraries.any(
      (library) => library.globalKey == item.libraryGlobalKey && library.kind == MediaKind.show,
    );
    final matchesKind = _kind == HomeSectionKind.movieCollections ? isMovie : isShow;
    return matchesKind && (_selected.isEmpty || _selected.contains(item.libraryGlobalKey));
  }).toList();

  @override
  Widget build(BuildContext context) => AlertDialog(
    // Nudged above dead-center: on a shorter window the dialog's natural
    // content height (title + dropdown + both checklists) can exceed the
    // available height even after the cap below, and centering split the
    // overflow evenly above/below — the bottom half (Save/Cancel) was the
    // one actually getting clipped against the window edge.
    alignment: const Alignment(0, -0.3),
    title: Text(widget.initial == null ? 'Add Home row' : 'Edit Home row'),
    content: SizedBox(
      width: 560,
      // A shrink-wrapped ListView sizes to its content with no ceiling, so a
      // dialog with many libraries/collections checked could grow taller
      // than the window and get clipped at the bottom instead of scrolling.
      // Capping the height here and dropping shrinkWrap makes the list
      // scroll internally once it would otherwise overflow.
      height: (MediaQuery.sizeOf(context).height - 160).clamp(200, 640),
      child: ListView(
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Row title'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HomeSectionKind>(
            value: _kind,
            decoration: const InputDecoration(labelText: 'Content'),
            items: [
              for (final kind in HomeSectionKind.values) DropdownMenuItem(value: kind, child: Text(_label(kind))),
            ],
            onChanged: (value) => setState(() {
              _kind = value ?? _kind;
              _selectedCollections.clear();
              _allCollections = true;
            }),
          ),
          const SizedBox(height: 12),
          const Text('Show this row in:'),
          CheckboxListTile(
            dense: true,
            title: const Text('Library Recommended'),
            value: _showInLibraryRecommended,
            onChanged: (value) => setState(() => _showInLibraryRecommended = value ?? false),
          ),
          CheckboxListTile(
            dense: true,
            title: const Text('Home'),
            value: _showOnHome,
            onChanged: (value) => setState(() => _showOnHome = value ?? false),
          ),
          const SizedBox(height: 12),
          const Text('Libraries (leave all unchecked to include every library)'),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'Every library checked here is merged into this one row.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final library in widget.libraries)
            CheckboxListTile(
              dense: true,
              value: _selected.contains(library.globalKey),
              title: Text(library.title),
              subtitle: Text(library.serverName ?? ''),
              onChanged: (value) => setState(
                () => value == true ? _selected.add(library.globalKey) : _selected.remove(library.globalKey),
              ),
            ),
          if (_kind == HomeSectionKind.movieCollections || _kind == HomeSectionKind.showCollections) ...[
            const SizedBox(height: 12),
            Text(
              _kind == HomeSectionKind.movieCollections
                  ? 'Movie collections (leave all unchecked for every selected library)'
                  : 'Show collections (leave all unchecked for every selected library)',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                'If exactly one collection matches, its titles show directly in the '
                "row. If more than one matches, each collection shows as a single "
                'poster — tap it to open that collection.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            CheckboxListTile(
              dense: true,
              title: const Text('All collections'),
              value: _allCollections,
              onChanged: (value) => setState(() {
                _allCollections = value ?? true;
                if (_allCollections) _selectedCollections.clear();
              }),
            ),
            for (final collection in _filteredCollections())
              CheckboxListTile(
                dense: true,
                value: !_allCollections && _selectedCollections.contains(collection.globalKey),
                title: Text(collection.title ?? 'Untitled collection'),
                subtitle: Text(collection.libraryTitle ?? ''),
                onChanged: _allCollections
                    ? null
                    : (value) => setState(
                        () => value == true
                            ? _selectedCollections.add(collection.globalKey)
                            : _selectedCollections.remove(collection.globalKey),
                      ),
              ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          final title = _title.text.trim().isEmpty ? _label(_kind) : _title.text.trim();
          Navigator.pop(
            context,
            HomeSectionConfig(
              // Reuse the original id on an edit: it's also the row's identity
              // in home_row_order (as 'custom:<id>'), so minting a fresh one
              // here would orphan the saved position and the row would land
              // at the back of the Organizer instead of staying put.
              id: widget.initial?.id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}',
              title: title,
              kind: _kind,
              libraryKeys: _selected.toList(),
              collectionKeys: _selectedCollections.toList(),
              showInLibraryRecommended: _showInLibraryRecommended,
              showOnHome: _showOnHome,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}
