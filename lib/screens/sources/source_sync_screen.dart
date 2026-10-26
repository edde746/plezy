import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_text_field.dart';
import '../../i18n/strings.g.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/sync/publication_sync.dart';
import '../../sources/sync/sync_document.dart';
import '../../sources/sync/sync_store.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'add_source_screen.dart';
import 'source_widgets.dart';

class SourceSyncScreen extends StatefulWidget {
  const SourceSyncScreen({super.key});
  @override
  State<SourceSyncScreen> createState() => _SourceSyncScreenState();
}

class _SourceSyncScreenState extends State<SourceSyncScreen> {
  final _code = TextEditingController(), _folder = TextEditingController();
  String? _source;
  bool _busy = false, _reveal = false, _loaded = false;
  Object? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final config = context.read<SourceController>().syncConfig;
    _source = config?.sourceId;
    _code.text = config?.code ?? '';
    _folder.text = config?.folder ?? '.plezyng-sync';
  }

  @override
  void dispose() {
    _code.dispose();
    _folder.dispose();
    super.dispose();
  }

  Future<void> _action(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _choice(SyncVersion version) {
    final data = sourceMap(version.value['data']);
    final String choice;
    if (version.value['type'] == 'annotation') {
      choice = data['deleted'] == true
          ? t.audiobook.deletedBookmark
          : '${data['note'] ?? ''} ${data['quote'] ?? ''}'.trim();
    } else if (data['finished'] == true) {
      choice = t.audiobook.finished;
    } else if (data['mode'] == 'reading') {
      choice = t.audiobook.readingPosition(percent: ((data['fraction'] as num? ?? 0) * 100).round());
    } else {
      choice = sourceTime(sourceInt(data['positionMs']) ?? 0);
    }
    return choice;
  }

  String _device(SyncVersion version) {
    final actor = version.actor;
    final device = actor == null || actor.isEmpty
        ? t.audiobook.syncUnknownDevice
        : actor.substring(0, actor.length < 8 ? actor.length : 8);
    return t.audiobook.syncDevice(device: device);
  }

  Future<void> _addSource() async {
    await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddSourceScreen()));
    if (!mounted) return;
    final sources = context.read<SourceController>().sources.where((source) => ProviderSyncStore.supports(source.kind));
    setState(() => _source ??= sources.lastOrNull?.id);
  }

  Future<void> _confirmExclusiveSync(SourceController controller, PublicationSyncConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(t.audiobook.syncTitle),
        content: Text(t.audiobook.syncPrivacy),
        actions: [
          DialogActionButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            label: t.common.cancel,
          ),
          DialogActionButton(
            onPressed: () => Navigator.pop(context, true),
            label: t.audiobook.saveSync,
            isPrimary: true,
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _action(() => controller.configureCloudSync(config));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SourceController>();
    final sources = controller.sources.where((s) => ProviderSyncStore.supports(s.kind)).toList();
    final selected = sources.where((s) => s.id == _source).firstOrNull;
    final configured = controller.syncConfig != null;
    final sync = controller.cloudSync;
    return FocusedScrollScaffold(
      title: Text(t.audiobook.syncTitle),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(t.audiobook.syncHelp),
                    const SizedBox(height: 24),
                    if (sources.isEmpty) ...[
                      Text(t.audiobook.addSyncSource),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: _busy ? null : _addSource,
                          icon: const AppIcon(Symbols.add_rounded),
                          label: Text(t.fileSources.add),
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selected?.id,
                        decoration: InputDecoration(labelText: t.audiobook.syncDestination),
                        items: [
                          for (final s in sources)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} · ${sourceKindName(s.kind)}', overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _busy ? null : (v) => setState(() => _source = v),
                      ),
                      if (selected?.kind == FileSourceKind.webdav || selected?.kind == FileSourceKind.s3) ...[
                        const SizedBox(height: 16),
                        FocusableTextField(
                          controller: _folder,
                          enabled: !_busy,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.audiobook.syncFolder,
                            helperText: t.audiobook.syncFolderHelp,
                            helperMaxLines: 3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FocusableTextField(
                        controller: _code,
                        enabled: !_busy,
                        obscureText: !_reveal,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: t.audiobook.syncCode,
                          helperText: t.audiobook.syncCodeHelp,
                          helperMaxLines: 4,
                          suffixIcon: IconButton(
                            tooltip: t.audiobook.showCode,
                            onPressed: () => setState(() => _reveal = !_reveal),
                            icon: AppIcon(_reveal ? Symbols.visibility_off_rounded : Symbols.visibility_rounded),
                          ),
                        ),
                      ),
                      if (!configured)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _code.text = SyncCipher.newCode();
                                    _reveal = true;
                                  }),
                            icon: const AppIcon(Symbols.add_rounded),
                            label: Text(t.audiobook.newSyncCode),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy || selected == null
                            ? null
                            : () => _confirmExclusiveSync(
                                controller,
                                PublicationSyncConfig(
                                  sourceId: selected.id,
                                  code: _code.text.trim(),
                                  folder: _folder.text.trim(),
                                ),
                              ),
                        child: Text(t.audiobook.saveSync),
                      ),
                    ],
                    if (configured) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => _action(controller.sync),
                        icon: const AppIcon(Symbols.sync_rounded),
                        label: Text(t.fileSources.sync),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => _action(() => controller.configureCloudSync(null)),
                        child: Text(t.audiobook.disableSync),
                      ),
                    ],
                    if (_busy || sync.running) const LinearProgressIndicator(),
                    if (configured &&
                        selected != null &&
                        (sync.failure == SourceFailure.authentication || sync.failure == SourceFailure.permission))
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _action(() async {
                                final saved = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddSourceScreen(existing: selected)),
                                );
                                if (saved == true && controller.syncConfig?.sourceId == selected.id) {
                                  await controller.sync();
                                }
                              }),
                        icon: const AppIcon(Symbols.link_rounded),
                        label: Text(t.audiobook.syncReconnect),
                      ),
                    if (_error != null || sync.failure != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(sourceFailureText(_error ?? SourceException(sync.failure!))),
                      ),
                    if (sync.lastSuccess != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          t.audiobook.lastSynced(
                            time: MaterialLocalizations.of(
                              context,
                            ).formatTimeOfDay(TimeOfDay.fromDateTime(sync.lastSuccess!.toLocal())),
                          ),
                        ),
                      ),
                    Text(t.audiobook.syncPrivacy, style: Theme.of(context).textTheme.bodySmall),
                    if (sync.conflicts.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(t.audiobook.syncConflicts, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(t.audiobook.conflictHelp),
                      for (final conflict in sync.conflicts.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(conflict.entry.title, style: Theme.of(context).textTheme.titleMedium),
                              for (final (index, version) in conflict.values.indexed)
                                SourceTile(
                                  title: _device(version),
                                  subtitle: _choice(version).isEmpty ? t.fileSources.bookmark : _choice(version),
                                  icon: Symbols.sync_alt_rounded,
                                  index: index,
                                  count: conflict.values.length,
                                  onTap: _busy
                                      ? null
                                      : () => _action(() async {
                                          await controller.stopPlayback?.call();
                                          await controller.resolveCloudConflict(conflict.key, version);
                                        }),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

