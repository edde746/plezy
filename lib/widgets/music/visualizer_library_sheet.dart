import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/file_picker_service.dart';
import '../../services/visualization/visualizer_pack_store.dart';
import '../../theme/mono_tokens.dart';
import '../app_icon.dart';

/// In-app entry point for license-cleared pack downloads and user-owned imports.
/// Link-only historical collections are never rehosted by PlezyNG.
class VisualizerLibrarySheet extends StatefulWidget {
  const VisualizerLibrarySheet({super.key});

  @override
  State<VisualizerLibrarySheet> createState() => _VisualizerLibrarySheetState();
}

class _VisualizerLibrarySheetState extends State<VisualizerLibrarySheet> {
  final VisualizerPackStore _store = VisualizerPackStore();
  List<VisualizerInstalledPack> _installed = const [];
  List<String> _imports = const [];
  bool _loading = true;
  bool _busy = false;
  String? _workingPackId;
  VisualizerPackInstallCancellation? _installCancellation;
  double? _progress;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _installCancellation?.cancel();
    _store.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
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
      final results = await Future.wait([_store.installedPacks(), _store.importedPresets()]);
      if (!mounted) return;
      setState(() {
        _installed = results[0] as List<VisualizerInstalledPack>;
        _imports = results[1] as List<String>;
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
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final picked = result.files.single;
      if (picked.size > 1024 * 1024) {
        throw const VisualizerPackException('Preset files must be smaller than 1 MB.');
      }
      final sourcePath = picked.path;
      if (sourcePath == null) throw const VisualizerPackException('The selected file could not be read.');
      await _store.importPresetFile(picked.name, sourcePath, picked.size);
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
    final installedIds = _installed.map((pack) => pack.entry.id).toSet();
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
                          _sectionTitle(context, 'License-cleared downloads'),
                          for (final entry in VisualizerPackCatalogEntry.available)
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'Content notice: ${entry.contentNotice}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tk.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'The archive hash and included license notice are checked before installation. It is stored offline. MilkDrop playback is not enabled by PlezyNG yet.',
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
                                          OutlinedButton.icon(
                                            onPressed: _busy ? null : () => _remove(entry),
                                            icon: const AppIcon(Symbols.delete_rounded, size: 18),
                                            label: Text(t.common.delete),
                                          )
                                        else if (_workingPackId == entry.id)
                                          OutlinedButton.icon(
                                            onPressed: _installCancellation?.cancel,
                                            icon: const AppIcon(Symbols.close_rounded, size: 18),
                                            label: const Text('Cancel download'),
                                          )
                                        else
                                          FilledButton.icon(
                                            onPressed: _busy || !_store.isStorageSupported ? null : () => _install(entry),
                                            icon: const AppIcon(Symbols.download_rounded, size: 18),
                                            label: Text(_workingPackId == entry.id ? 'Downloading…' : t.downloads.downloadNow),
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
                          for (final source in _linkOnlySources)
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
                            for (final name in _imports)
                              ListTile(
                                dense: true,
                                leading: const AppIcon(Symbols.music_note_rounded, size: 18),
                                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: const Text('Saved on this device · playback pending engine integration'),
                                trailing: IconButton(
                                  tooltip: t.common.delete,
                                  onPressed: _busy ? null : () => _removeImported(name),
                                  icon: const AppIcon(Symbols.delete_rounded, size: 18),
                                ),
                              ),
                          const SizedBox(height: 12),
                          Text(
                            'Current PlezyNG playback continues to use its six original scenes. Preset downloads and imports are stored separately and cannot alter those scenes.',
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
