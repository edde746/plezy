import 'package:flutter/material.dart';

import '../../services/visualization/visualizer_pack_store.dart';
import '../../services/visualization/visualizer_session.dart';

class VisualizerSelection {
  const VisualizerSelection(this.preset, this.playlist);
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

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await widget.store.favoriteIds();
      if (mounted) setState(() => _favorites = favorites);
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
            ? 'Classic .milk candidate for projectM. Visual fidelity is not yet qualified.'
            : 'MilkDrop 3 saved double presets require a renderer with full .milk2 blend support.',
        if (!widget.capability.available) widget.capability.reason,
        'Stored offline. Presets can contain rapid flashes and intense motion.',
      ].join('\n\n'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.presets.where((preset) =>
      (!_favoritesOnly || _favorites.contains(preset.id)) &&
      (!_playableOnly || preset.supportsProjectM) &&
      (_query.isEmpty || preset.searchText.contains(_query))).toList();
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
        ])),
        if (!widget.capability.available || _error != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_error ?? widget.capability.reason)),
        Expanded(child: visible.isEmpty
          ? const Center(child: Text('No matching presets.'))
          : ListView.builder(itemCount: visible.length, itemBuilder: (context, index) {
              final preset = visible[index];
              final canPlay = widget.capability.available && preset.supportsProjectM;
              return ListTile(
                leading: Icon(canPlay ? Icons.play_circle_outline : Icons.info_outline),
                title: Text(preset.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([preset.author, preset.packName,
                  if (!preset.supportsProjectM) '.milk2 playback unavailable',
                ].where((part) => part.isNotEmpty).join(' · ')),
                onTap: canPlay ? () => Navigator.pop(context, VisualizerSelection(preset,
                    visible.where((item) => item.supportsProjectM).toList())) : () => _details(preset),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
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
