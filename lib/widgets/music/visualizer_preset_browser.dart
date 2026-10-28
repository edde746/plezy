import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/file_picker_service.dart';
import '../../services/visualization/visualizer_pack_store.dart';
import '../../services/visualization/visualizer_session.dart';

class VisualizerSelection {
  const VisualizerSelection(this.preset, this.playlist, {this.engine});
  final String? engine;
  final VisualizerPresetFile preset;
  final List<VisualizerPresetFile> playlist;
}

/// Browses verified local files. Metadata and attribution remain available even
/// when the platform cannot play a format or lacks the native dependencies.
class VisualizerPresetBrowser extends StatefulWidget {
  const VisualizerPresetBrowser({super.key, required this.presets, required this.store, required this.capability});
  final List<VisualizerPresetFile> presets;
  final VisualizerPackStore store;
  final VisualizerCapabilities capability;
  @override
  State<VisualizerPresetBrowser> createState() => _VisualizerPresetBrowserState();
}

class _VisualizerPresetBrowserState extends State<VisualizerPresetBrowser> {
  Set<String> _favorites = {};
  String _query = '';
  bool _favoritesOnly = false, _playableOnly = false;
  String? _error;
  List<VisualizerPlaylist> _playlists = [];
  String? _playlist;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await widget.store.favoriteIds();
      final playlists = await widget.store.playlists();
      if (mounted) setState(() { _favorites = favorites; _playlists = playlists; });
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _savePlaylist(List<VisualizerPresetFile> visible) async {
    var entered = '';
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Save this preset list'),
      content: TextField(maxLength: 80, autofocus: true, decoration: const InputDecoration(labelText: 'Playlist name'),
        onChanged: (value) => entered = value,
        onSubmitted: (value) => Navigator.pop(context, value.trim())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, entered.trim()), child: const Text('Save'))],
    ));
    if (!mounted || name == null) return;
    try {
      if (_playlists.any((item) => item.name.toLowerCase() == name.toLowerCase())) {
        throw const VisualizerPackException('Choose a new playlist name.');
      }
      final next = [..._playlists, VisualizerPlaylist(name: name,
        entries: visible.map((preset) => preset.libraryPath).toList())];
      await widget.store.savePlaylists(next);
      if (mounted) setState(() { _playlists = next; _playlist = name; });
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _deletePlaylist() async {
    final next = _playlists.where((item) => item.name != _playlist).toList();
    try {
      await widget.store.savePlaylists(next);
      if (mounted) setState(() { _playlists = next; _playlist = null; });
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _move(VisualizerPresetFile preset, int offset) async {
    final selected = _playlists.firstWhere((item) => item.name == _playlist);
    final entries = [...selected.entries];
    final before = entries.indexOf(preset.libraryPath), after = before + offset;
    if (before < 0 || after < 0 || after >= entries.length) return;
    entries.removeAt(before); entries.insert(after, preset.libraryPath);
    final next = _playlists.map((item) => item.name == selected.name
        ? VisualizerPlaylist(name: item.name, entries: entries) : item).toList();
    try {
      await widget.store.savePlaylists(next);
      if (mounted) setState(() => _playlists = next);
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _exportPlaylists() async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'schemaVersion': 1,
        'kind': 'plezy-visualizer-playlists', 'playlists': _playlists.map((item) => item.toJson()).toList()})));
      await FilePickerService.instance.saveFile(dialogTitle: 'Export visualizer playlists',
        fileName: 'visualizer-playlists.json', bytes: bytes, type: FileType.custom, allowedExtensions: ['json']);
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _importPlaylists() async {
    try {
      final picked = await FilePickerService.instance.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (picked == null || picked.files.isEmpty || !mounted) return;
      final path = picked.files.single.path;
      if (path == null || picked.files.single.size > 512 * 1024) {
        throw const VisualizerPackException('Playlist files must be readable and at most 512 KB.');
      }
      final bytes = await File(path).openRead(0, 512 * 1024 + 1).fold<List<int>>([], (all, chunk) => all..addAll(chunk));
      if (bytes.length > 512 * 1024) throw const VisualizerPackException('Playlist file exceeds 512 KB.');
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map || value['kind'] != 'plezy-visualizer-playlists') throw const VisualizerPackException('Not a visualizer playlist export.');
      final imported = VisualizerPackStore.decodePlaylists(value);
      final names = _playlists.map((item) => item.name.toLowerCase()).toSet();
      if (imported.any((item) => names.contains(item.name.toLowerCase()))) {
        throw const VisualizerPackException('An imported playlist name already exists. Rename it in the file before importing.');
      }
      final next = [..._playlists, ...imported];
      await widget.store.savePlaylists(next);
      if (mounted) setState(() => _playlists = next);
    } on Object catch (error) { if (mounted) setState(() => _error = error.toString()); }
  }

  Future<void> _favorite(VisualizerPresetFile preset) async {
    setState(() { if (!_favorites.add(preset.id)) _favorites.remove(preset.id); });
    try { await widget.store.saveFavoriteIds({..._favorites}); }
    on Object catch (error) { if (mounted) setState(() => _error = 'Could not save favorites: $error'); }
  }

  void _details(VisualizerPresetFile preset) {
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(preset.title),
      content: SingleChildScrollView(child: SelectableText([
        if (preset.author.isNotEmpty) 'Author: ${preset.author}',
        if (preset.packName.isNotEmpty) 'Pack: ${preset.packName}',
        if (preset.license.isNotEmpty) 'License: ${preset.license}',
        if (preset.notice.isNotEmpty) 'Content notice: ${preset.notice}',
        if (preset.tags.isNotEmpty) 'Tags: ${preset.tags.join(', ')}',
        preset.supportsProjectM
            ? 'Classic .milk candidate. Rendering fidelity depends on the selected engine and is not yet qualified.'
            : 'Native MilkRust can attempt saved uniform Fade blends. Other .milk2 patterns remain unsupported.',
        if (!widget.capability.available) widget.capability.reason,
        'Stored offline. Presets can contain rapid flashes and intense motion.',
      ].join('\n\n'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _playlists.where((item) => item.name == _playlist).firstOrNull;
    final positions = {for (var i = 0; i < (selected?.entries.length ?? 0); i++) selected!.entries[i]: i};
    final visible = widget.presets.where((preset) =>
      (selected == null || positions.containsKey(preset.libraryPath)) &&
      (!_favoritesOnly || _favorites.contains(preset.id)) &&
      (!_playableOnly || widget.capability.accepts(preset)) &&
      (_query.isEmpty || preset.searchText.contains(_query))).toList();
    if (selected != null) visible.sort((a, b) => positions[a.libraryPath]!.compareTo(positions[b.libraryPath]!));
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(children: [
        ListTile(
          title: const Text('Installed presets'),
          subtitle: Text('${visible.length} of ${widget.presets.length} · stored offline'),
          trailing: IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
          autofocus: false,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Title, author, pack or tag'),
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        )),
        Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, children: [
          FilterChip(label: const Text('Favorites'), selected: _favoritesOnly,
            onSelected: (value) => setState(() => _favoritesOnly = value)),
          FilterChip(label: const Text('Classic .milk'), selected: _playableOnly,
            onSelected: (value) => setState(() => _playableOnly = value)),
          PopupMenuButton<String>(
            tooltip: 'Playlists',
            onSelected: (name) => setState(() => _playlist = name.isEmpty ? null : name),
            itemBuilder: (_) => [const PopupMenuItem(value: '', child: Text('All presets')),
              for (final list in _playlists) PopupMenuItem(value: list.name, child: Text(list.name))],
            child: Padding(padding: const EdgeInsets.all(8), child: Text(_playlist ?? 'All presets ▾')),
          ),
          IconButton(tooltip: 'Save filtered list as playlist', onPressed: visible.isEmpty ? null : () => _savePlaylist(visible),
            icon: const Icon(Icons.playlist_add)),
          if (_playlist != null) IconButton(tooltip: 'Delete playlist', onPressed: _deletePlaylist, icon: const Icon(Icons.playlist_remove)),
          IconButton(tooltip: 'Import playlists', onPressed: _importPlaylists, icon: const Icon(Icons.file_open_outlined)),
          IconButton(tooltip: 'Export playlists (references only)', onPressed: _playlists.isEmpty ? null : _exportPlaylists,
            icon: const Icon(Icons.ios_share)),
        ])),
        if (selected != null && positions.length > visible.length && _query.isEmpty && !_favoritesOnly && !_playableOnly)
          const Padding(padding: EdgeInsets.all(8), child: Text('Some playlist presets are not installed in this view. Downloads are managed separately.')),
        if (!widget.capability.available || _error != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_error ?? widget.capability.reason)),
        Expanded(child: visible.isEmpty
          ? const Center(child: Text('No matching presets.'))
          : ListView.builder(itemCount: visible.length, itemBuilder: (context, index) {
              final preset = visible[index];
              final canPlay = widget.capability.available && widget.capability.accepts(preset);
              return ListTile(
                leading: Icon(canPlay ? Icons.play_circle_outline : Icons.info_outline),
                title: Text(preset.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([preset.author, preset.packName,
                  if (!widget.capability.accepts(preset)) 'Format unavailable for this engine',
                ].where((part) => part.isNotEmpty).join(' · ')),
                onTap: canPlay ? () => Navigator.pop(context, VisualizerSelection(preset,
                    visible.where(widget.capability.accepts).toList(),
                    engine: widget.capability.engine.startsWith('milkrust') ? 'milkrust' : 'projectm')) : () => _details(preset),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (selected != null) PopupMenuButton<int>(
                    tooltip: 'Reorder in playlist', icon: const Icon(Icons.swap_vert, size: 18),
                    onSelected: (offset) => _move(preset, offset),
                    itemBuilder: (_) => [const PopupMenuItem(value: -1, child: Text('Move up')),
                      const PopupMenuItem(value: 1, child: Text('Move down'))],
                  ),
                  IconButton(tooltip: _favorites.contains(preset.id) ? 'Remove favorite' : 'Add favorite',
                    onPressed: () => _favorite(preset),
                    icon: Icon(_favorites.contains(preset.id) ? Icons.favorite : Icons.favorite_border)),
                  IconButton(tooltip: 'Preset details and notices', onPressed: () => _details(preset),
                    icon: const Icon(Icons.info_outline)),
                ]),
              );
            })),
      ]),
    ));
  }
}
