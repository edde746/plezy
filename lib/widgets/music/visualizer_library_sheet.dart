import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/file_picker_service.dart';
import '../../services/visualization/visualizer_pack_store.dart';
import '../../services/visualization/visualizer_session.dart';
import '../../theme/mono_tokens.dart';
import '../app_icon.dart';
import 'visualizer_preset_browser.dart';

/// In-app entry point for license-cleared pack downloads and user-owned imports.
/// Link-only historical collections are never rehosted by PlezyNG.
class VisualizerLibrarySheet extends StatefulWidget {
  const VisualizerLibrarySheet({super.key, this.profileId, this.hasMusicPcmSource = false});
  final String? profileId;
  final bool hasMusicPcmSource;

  @override
  State<VisualizerLibrarySheet> createState() => _VisualizerLibrarySheetState();
}

class _VisualizerLibrarySheetState extends State<VisualizerLibrarySheet> {
  late final VisualizerPackStore _store;
  VisualizerCapabilities _capability = const VisualizerCapabilities(available: false, reason: 'Checking native renderer…');
  List<VisualizerInstalledPack> _installed = const [];
  List<VisualizerImportedPack> _communityPacks = const [];
  List<String> _imports = const [];
  Set<String> _favorites = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _favoritesOnly = false;
  bool _loading = true;
  bool _busy = false;
  String? _workingPackId;
  VisualizerPackInstallCancellation? _installCancellation;
  double? _progress;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _store = VisualizerPackStore(profileId: widget.profileId);
    _checkRenderer();
    _refresh();
  }

  Future<void> _checkRenderer() async {
    final capability = widget.hasMusicPcmSource ? await VisualizerSession.capabilities()
        : const VisualizerCapabilities(available: false, reason: 'This music playback source has no native visualization audio.');
    if (mounted) setState(() => _capability = capability);
  }

  Future<void> _browse({String? packPath, String? importedName}) async {
    try {
      final presets = packPath != null ? await _store.presetsForPack(packPath)
          : importedName != null ? [await _store.importedPreset(importedName)] : await _store.allPresets();
      if (!mounted) return;
      final selection = await showModalBottomSheet<VisualizerSelection>(
        context: context, isScrollControlled: true, useSafeArea: true,
        builder: (_) => VisualizerPresetBrowser(presets: presets, store: _store, capability: _capability),
      );
      if (!mounted) return;
      if (selection != null) Navigator.pop(context, selection);
      else await _refresh(); // Per-preset favorites may have changed.
    } on Object catch (error) { if (mounted) setState(() => _failure = error.toString()); }
  }

  @override
  void dispose() {
    _installCancellation?.cancel();
    _searchController.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    if (!_store.isStorageSupported) {
      if (!mounted) return;
      setState(() {
        _failure = 'Downloads and local preset storage are not available in the web build.';
        _loading = false;
      });
      return;
    }
    try {
      await _store.ensureStarterPack();
      final results = await Future.wait([
        _store.installedPacks(),
        _store.importedPresets(),
        _store.importedPacks(),
        _store.favoriteIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _installed = results[0] as List<VisualizerInstalledPack>;
        _imports = results[1] as List<String>;
        _communityPacks = results[2] as List<VisualizerImportedPack>;
        _favorites = results[3] as Set<String>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = error.toString();
        _loading = false;
      });
    }
  }

  bool _matches(String value) =>
      _searchQuery.isEmpty || value.toLowerCase().contains(_searchQuery);

  String _packFavoriteKey(String id, String version) => 'pack:$id@$version';

  String _presetFavoriteKey(String name) => 'preset:$name';

  Future<void> _toggleFavorite(String key) async {
    final next = {..._favorites};
    if (!next.add(key)) next.remove(key);
    setState(() => _favorites = next);
    try {
      await _store.saveFavoriteIds(next);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _failure = 'Could not save library favorites: $error');
    }
  }

  Future<void> _checkPackUpdates() async {
    setState(() { _busy = true; _failure = null; });
    try {
      await _store.refreshCatalog();
      await _refresh();
    } on Object catch (error) {
      if (mounted) setState(() => _failure = 'Could not update pack catalog: $error');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _install(VisualizerPackCatalogEntry entry) async {
    final cancellation = VisualizerPackInstallCancellation();
    setState(() {
      _busy = true;
      _workingPackId = entry.id;
      _installCancellation = cancellation;
      _progress = 0;
      _failure = null;
    });
    try {
      await _store.install(entry, cancellation: cancellation, onProgress: (value) {
        if (mounted) setState(() => _progress = value.clamp(0.0, 1.0).toDouble());
      });
      await _refresh();
    } on VisualizerPackCanceledException {
      if (mounted) setState(() => _failure = null);
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() {
        _busy = false;
        _workingPackId = null;
        _installCancellation = null;
        _progress = null;
      });
    }
  }

  Future<void> _remove(VisualizerPackCatalogEntry entry) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await _store.remove(entry);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeImported(String name) async {
    try {
      await _store.removeImportedPreset(name);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    }
  }

  Future<void> _import() async {
    final result = await FilePickerService.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['milk', 'milk2'],
      allowMultiple: true,
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    if (result.files.length > VisualizerPackStore.maxPresetImportCount) {
      setState(() => _failure = 'Choose at most ${VisualizerPackStore.maxPresetImportCount} preset files at a time.');
      return;
    }
    final announcedBytes = result.files.fold<int>(0, (sum, file) => sum + file.size);
    if (announcedBytes > VisualizerPackStore.maxPresetImportBatchBytes) {
      setState(() => _failure = 'The selected preset files exceed the 64 MB batch limit.');
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      var imported = 0;
      final failures = <String>[];
      for (final picked in result.files) {
        if (picked.size > 1024 * 1024) {
          failures.add('${picked.name}: exceeds 1 MB');
          continue;
        }
        final sourcePath = picked.path;
        if (sourcePath == null) {
          failures.add('${picked.name}: file could not be read');
          continue;
        }
        try {
          await _store.importPresetFile(picked.name, sourcePath, picked.size);
          imported++;
        } catch (error) {
          failures.add('${picked.name}: $error');
        }
      }
      await _refresh();
      if (!mounted) return;
      final skipped = failures.isEmpty
          ? ''
          : '; skipped ${failures.length}: ${failures.take(2).join(' · ')}${failures.length > 2 ? ' · …' : ''}';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Imported $imported of ${result.files.length} preset files$skipped.')),
      );
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importCommunityPack() async {
    final result = await FilePickerService.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['rmpack'],
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final picked = result.files.first;
    if (picked.size <= 0 || picked.size > VisualizerPackStore.maxLocalPackArchiveBytes) {
      setState(() => _failure = 'Community pack archives must be 32 MB or smaller.');
      return;
    }
    final sourcePath = picked.path;
    if (sourcePath == null) {
      setState(() => _failure = 'The selected community pack could not be read from device storage.');
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final pack = await _store.importPackFile(sourcePath, picked.size);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Imported ${pack.name} ${pack.version}.')),
      );
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFolder() async {
    final cancellation = VisualizerPackInstallCancellation();
    setState(() { _busy = true; _failure = null; });
    try {
      final path = await FilePickerService.instance.getDirectoryPath(dialogTitle: 'Import a preset folder with textures and notices');
      if (path == null || !mounted) return;
      setState(() { _busy = true; _failure = null; _installCancellation = cancellation; });
      final pack = await _store.importPresetFolder(path, cancellation: cancellation);
      await _refresh();
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Imported ${pack.presetCount} presets from ${pack.name}.')),
      );
    } on VisualizerPackCanceledException { /* The staging directory is discarded. */ }
    on Object catch (error) { if (mounted) setState(() => _failure = error.toString()); }
    finally {
      if (mounted) setState(() { _busy = false; _installCancellation = null; });
    }
  }

  Future<void> _removeCommunityPack(VisualizerImportedPack pack) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await _store.removeImportedPack(pack);
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _failure = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      setState(() => _failure = 'Could not open the source page.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tk = tokens(context);
    final installedIds = _installed.where((pack) => pack.isCurrent).map((pack) => pack.entry.id).toSet();
    final olderIds = _installed.where((pack) => !pack.isCurrent).map((pack) => pack.entry.id).toSet();
    final entries = {for (final pack in _installed) pack.entry.id: pack.entry,
      for (final entry in _store.catalogEntries) entry.id: entry};
    final visibleEntries = entries.values.where((entry) {
      final favorite = _favorites.contains(_packFavoriteKey(entry.id, entry.version));
      return (!_favoritesOnly || favorite) &&
          _matches('${entry.name} ${entry.searchText} ${entry.version} ${entry.license} ${entry.description} ${entry.contentNotice}');
    }).toList();
    final visibleLinks = _linkOnlySources
        .where((source) => !_favoritesOnly && _matches('${source.name} ${source.status}'))
        .toList();
    final visibleCommunityPacks = _communityPacks.where((pack) {
      final favorite = _favorites.contains(_packFavoriteKey(pack.id, pack.version));
      return (!_favoritesOnly || favorite) &&
          _matches('${pack.name} ${pack.authors} ${pack.presetSearchText} ${pack.version} ${pack.license} ${pack.contentNotice}');
    }).toList();
    final visibleImports = _imports.where((name) {
      final favorite = _favorites.contains(_presetFavoriteKey(name));
      return (!_favoritesOnly || favorite) && _matches(name);
    }).toList();
    final hasMatches = visibleEntries.isNotEmpty ||
        visibleLinks.isNotEmpty ||
        visibleCommunityPacks.isNotEmpty ||
        visibleImports.isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: tk.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(tk.radiusLg)),
          border: Border.all(color: tk.outline.withValues(alpha: 0.48)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visualizer library', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Download cleared packs or import preset files you already have.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t.common.close,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const AppIcon(Symbols.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search packs, presets, authors, or licenses',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Favorites'),
                      selected: _favoritesOnly,
                      onSelected: (value) => setState(() => _favoritesOnly = value),
                    ),
                  ],
                ),
              ),
              if (_failure != null)
                MaterialBanner(
                  content: Text(_failure!),
                  leading: Icon(Symbols.error_rounded, color: Theme.of(context).colorScheme.error),
                  actions: [
                    TextButton(onPressed: () => setState(() => _failure = null), child: Text(t.common.close)),
                  ],
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 20 + bottomInset),
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : () => _browse(),
                            icon: const Icon(Icons.grid_view_rounded),
                            label: const Text('Browse installed presets'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(_capability.available
                                ? 'Classic .milk playback uses projectM and live music audio. Visual fidelity is not yet qualified.'
                                : _capability.reason),
                          ),
                          if ((_searchQuery.isNotEmpty || _favoritesOnly) && !hasMatches)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Text('No matching packs or imported presets.'),
                            ),
                          _sectionTitle(context, 'Included packs and downloads'),
                          Text(_store.catalogStatus, style: Theme.of(context).textTheme.bodySmall),
                          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                            onPressed: _busy || !_store.catalogConfigured ? null : _checkPackUpdates,
                            icon: const Icon(Icons.refresh_rounded), label: const Text('Check for pack updates'),
                          )),
                          for (final entry in visibleEntries)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const AppIcon(Symbols.graphic_eq_rounded, size: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
                                              Text(
                                                '${entry.version} · ${entry.license} · ${entry.presetCount} presets',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(entry.description, style: Theme.of(context).textTheme.bodyMedium),
                                    if (entry.bundledAsset != null)
                                      const Text('Included with the app. Installation and restoration work offline.'),
                                    if (!_store.canDownload(entry))
                                      const Text('Download unavailable. Installed presets can still be browsed and removed.'),
                                    if (_store.canDownload(entry) && olderIds.contains(entry.id) && !installedIds.contains(entry.id))
                                      const Text('Update available. Previous versions stay available in Installed presets.'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Content notice: ${entry.contentNotice}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'The archive hash and included license notice are checked before installation. Presets are stored offline; playback depends on the native renderer and preset format.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                                    ),
                                    if (_workingPackId == entry.id && _progress != null) ...[
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(value: _progress),
                                    ],
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (installedIds.contains(entry.id))
                                          FilledButton.icon(
                                            onPressed: _busy ? null : () => _browse(packPath:
                                                _installed.firstWhere((pack) => pack.entry.id == entry.id && pack.isCurrent).path),
                                            icon: const Icon(Icons.grid_view_rounded, size: 18),
                                            label: const Text('Browse presets'),
                                          ),
                                        if (installedIds.contains(entry.id) || olderIds.contains(entry.id))
                                          OutlinedButton.icon(
                                            onPressed: _busy ? null : () => _remove(entry),
                                            icon: const AppIcon(Symbols.delete_rounded, size: 18),
                                            label: Text(t.common.delete),
                                          ),
                                        if (!installedIds.contains(entry.id) && _workingPackId == entry.id)
                                          OutlinedButton.icon(
                                            onPressed: _installCancellation?.cancel,
                                            icon: const AppIcon(Symbols.close_rounded, size: 18),
                                            label: const Text('Cancel installation'),
                                          )
                                        else if (!installedIds.contains(entry.id))
                                          FilledButton.icon(
                                            onPressed: _busy || !_store.isStorageSupported || !_store.canDownload(entry) ? null : () => _install(entry),
                                            icon: const AppIcon(Symbols.download_rounded, size: 18),
                                            label: Text(entry.bundledAsset != null ? 'Restore included pack'
                                                : olderIds.contains(entry.id) ? 'Download update' : t.downloads.downloadNow),
                                          ),
                                        IconButton(
                                          tooltip: _favorites.contains(_packFavoriteKey(entry.id, entry.version))
                                              ? 'Remove from favorites'
                                              : 'Add to favorites',
                                          onPressed: () => _toggleFavorite(_packFavoriteKey(entry.id, entry.version)),
                                          icon: Icon(
                                            _favorites.contains(_packFavoriteKey(entry.id, entry.version))
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _openSource(entry.sourceUrl),
                                          icon: const AppIcon(Symbols.open_in_new_rounded, size: 18),
                                          label: const Text('Source'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          _sectionTitle(context, 'Community sources'),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'Historical preset collections without an explicit redistribution license stay link-only. Open their source and import a local copy; this app does not rehost those files.',
                            ),
                          ),
                          for (final source in visibleLinks)
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(source.name),
                              subtitle: Text(source.status),
                              trailing: TextButton(
                                onPressed: () => _openSource(source.url),
                                child: const Text('Open source'),
                              ),
                            ),
                          _sectionTitle(context, 'Local presets'),
                          OutlinedButton.icon(
                            onPressed: _busy || !_store.isStorageSupported ? null : _importFolder,
                            icon: const AppIcon(Symbols.folder_open_rounded, size: 18),
                            label: const Text('Import folder with textures and notices'),
                          ),
                          if (_busy && _installCancellation != null && _workingPackId == null)
                            TextButton.icon(onPressed: _installCancellation!.cancel,
                              icon: const Icon(Icons.close), label: const Text('Cancel folder import')),
                          OutlinedButton.icon(
                            onPressed: _busy || !_store.isStorageSupported ? null : _importCommunityPack,
                            icon: const AppIcon(Symbols.folder_open_rounded, size: 18),
                            label: const Text('Import .rmpack (check files and notices)'),
                          ),
                          if (_communityPacks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No local collections imported. Folder imports stay private and preserve original notices. Pack archives need license records, attribution and an integrity index.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                              ),
                            )
                          else
                            for (final pack in visibleCommunityPacks)
                              Card(
                                child: ListTile(
                                  leading: AppIcon(
                                    pack.isDamaged ? Symbols.error_rounded : Symbols.graphic_eq_rounded,
                                    size: 20,
                                  ),
                                  title: Text(pack.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  onTap: _busy || pack.isDamaged ? null : () => _browse(packPath: pack.path),
                                  subtitle: Text(pack.isDamaged
                                      ? '${pack.version} · metadata unavailable\n${pack.contentNotice}'
                                      : '${pack.version} · ${pack.license} · ${pack.presetCount} presets\n'
                                            'Content notice: ${pack.contentNotice}\n'
                                            '${pack.localOnly ? 'Local folder snapshot · no redistribution rights asserted' : 'File hashes checked at import · rights claims are self-declared'} · browse presets'),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: _favorites.contains(_packFavoriteKey(pack.id, pack.version))
                                            ? 'Remove from favorites'
                                            : 'Add to favorites',
                                        onPressed: () => _toggleFavorite(_packFavoriteKey(pack.id, pack.version)),
                                        icon: Icon(
                                          _favorites.contains(_packFavoriteKey(pack.id, pack.version))
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: t.common.delete,
                                        onPressed: _busy ? null : () => _removeCommunityPack(pack),
                                        icon: const AppIcon(Symbols.delete_rounded, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          OutlinedButton.icon(
                            onPressed: _busy || !_store.isStorageSupported ? null : _import,
                            icon: const AppIcon(Symbols.file_open_rounded, size: 18),
                            label: const Text('Import .milk or .milk2 files'),
                          ),
                          if (_imports.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('No local presets imported.', style: TextStyle(color: tk.textMuted)),
                            )
                          else
                            for (final name in visibleImports)
                              ListTile(
                                dense: true,
                                leading: const AppIcon(Symbols.music_note_rounded, size: 18),
                                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: _busy ? null : () => _browse(importedName: name),
                                subtitle: Text(name.toLowerCase().endsWith('.milk2')
                                    ? 'Stored offline · .milk2 playback unavailable' : 'Stored offline · browse to play or view details'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: _favorites.contains(_presetFavoriteKey(name))
                                          ? 'Remove from favorites'
                                          : 'Add to favorites',
                                      onPressed: () => _toggleFavorite(_presetFavoriteKey(name)),
                                      icon: Icon(
                                        _favorites.contains(_presetFavoriteKey(name))
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: t.common.delete,
                                      onPressed: _busy ? null : () => _removeImported(name),
                                      icon: const AppIcon(Symbols.delete_rounded, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                          const SizedBox(height: 12),
                          Text(
                            'The six original scenes remain available. Native preset playback is optional. Imported files can contain rapid flashes and intense motion; reduced motion pauses the native renderer.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _LinkOnlySource {
  const _LinkOnlySource(this.name, this.url, this.status);

  final String name;
  final String url;
  final String status;
}

const _linkOnlySources = <_LinkOnlySource>[
  _LinkOnlySource(
    'Original MilkDrop Preset Pack',
    'https://github.com/projectM-visualizer/presets-milkdrop-original',
    'NOASSERTION · upstream link only',
  ),
  _LinkOnlySource(
    'MilkDrop Cream of the Crop Presets',
    'https://github.com/projectM-visualizer/presets-cream-of-the-crop',
    'NOASSERTION · upstream link only',
  ),
  _LinkOnlySource(
    'Classic projectM Presets',
    'https://github.com/projectM-visualizer/presets-projectm-classic',
    'NOASSERTION · upstream link only',
  ),
  _LinkOnlySource(
    'En D Presets',
    'https://github.com/projectM-visualizer/presets-en-d',
    'NOASSERTION · upstream link only',
  ),
  _LinkOnlySource(
    'MilkDrop Texture Pack',
    'https://github.com/projectM-visualizer/presets-milkdrop-texture-pack',
    'NOASSERTION · upstream link only',
  ),
];
