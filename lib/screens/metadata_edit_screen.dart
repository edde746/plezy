import 'package:file_picker/file_picker.dart';
import '../media/ids.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/focusable_wrapper.dart';
import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../metadata_edit/metadata_edit_adapters.dart';
import '../metadata_edit/metadata_edit_models.dart';
import '../services/file_picker_service.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/dialog_action_button.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/tag_edit_dialog.dart';

class MetadataEditScreen extends StatefulWidget {
  final MediaItem metadata;

  const MetadataEditScreen({super.key, required this.metadata});

  @override
  State<MetadataEditScreen> createState() => _MetadataEditScreenState();
}

class _MetadataEditScreenState extends State<MetadataEditScreen> {
  MetadataEditAdapter? _adapter;
  MetadataEditDraft? _draft;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final client = context.getMediaClientWithFallback(serverIdOrNull(widget.metadata.serverId));
      final adapter = metadataEditAdapterFor(client);
      if (adapter == null || !adapter.supportsKind(widget.metadata.kind)) {
        if (!mounted) return;
        setState(() {
          _adapter = adapter;
          _isLoading = false;
        });
        return;
      }
      final draft = await adapter.load(widget.metadata);
      if (!mounted) return;
      setState(() {
        _adapter = adapter;
        _draft = draft;
        _isLoading = false;
      });
    } catch (e, st) {
      appLogger.e('Failed to load metadata editor', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, t.metadataEdit.metadataUpdateFailed);
    }
  }

  bool get _hasChanges {
    final adapter = _adapter;
    final draft = _draft;
    return adapter != null && draft != null && adapter.hasChanges(draft);
  }

  Future<void> _save() async {
    final adapter = _adapter;
    final draft = _draft;
    if (adapter == null || draft == null || !_hasChanges || _isSaving) return;

    setState(() => _isSaving = true);
    bool success = false;
    try {
      success = await adapter.save(draft);
    } catch (e, st) {
      appLogger.e('Failed to update metadata', error: e, stackTrace: st);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.metadataUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.metadataUpdateFailed);
    }
  }

  Future<void> _editTextField(MetadataEditField field, {bool multiline = false}) async {
    final draft = _draft;
    if (draft == null) return;
    final currentValue = draft.value<String>(field.id) ?? '';
    final result = multiline
        ? await showTextInputDialog(
            context,
            title: field.label,
            labelText: field.label,
            initialValue: currentValue,
            allowEmpty: true,
            multiline: true,
          )
        : await showTextInputDialog(
            context,
            title: field.label,
            labelText: field.label,
            hintText: '',
            initialValue: currentValue,
            allowEmpty: true,
          );

    if (result != null && mounted) {
      setState(() => draft.setValue(field.id, result));
    }
  }

  Future<void> _editDate(MetadataEditField field) async {
    final draft = _draft;
    if (draft == null) return;
    DateTime initial = DateTime.now();
    final current = draft.value<String>(field.id);
    if (current != null && current.isNotEmpty) {
      final parsed = DateTime.tryParse(current);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
      useRootNavigator: false,
    );

    if (picked != null && mounted) {
      setState(() {
        draft.setValue(field.id, '${picked.year}-${padNumber(picked.month, 2)}-${padNumber(picked.day, 2)}');
      });
    }
  }

  Future<void> _editStringList(MetadataEditField field) async {
    final draft = _draft;
    if (draft == null) return;
    final result = await showScopedDialog<List<String>>(
      context: context,
      builder: (context) => TagEditDialog(title: field.label, initialTags: metadataStringList(draft.values[field.id])),
    );
    if (result != null && mounted) {
      setState(() => draft.setValue(field.id, result));
    }
  }

  Future<void> _editChoice(MetadataEditField field) async {
    final adapter = _adapter;
    final draft = _draft;
    if (adapter == null || draft == null) return;
    final current = draft.value<String>(field.id) ?? '';
    final result = await showScopedDialog<String>(
      context: context,
      builder: (dialogContext) {
        String selected = current;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(field.label),
              content: SizedBox(
                width: double.maxFinite,
                child: RadioGroup<String>(
                  groupValue: field.options.any((option) => option.value == selected) ? selected : null,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selected = value);
                    Navigator.pop(dialogContext, value);
                  },
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in field.options)
                        FocusableRadioListTile<String>(
                          key: ValueKey(option.value),
                          title: Text(option.label),
                          value: option.value,
                        ),
                    ],
                  ),
                ),
              ),
              actions: [DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel)],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    if (field.saveMode == MetadataEditSaveMode.immediate) {
      final previous = draft.values[field.id];
      setState(() => draft.setValue(field.id, result));
      bool success = false;
      try {
        success = await adapter.saveImmediateField(draft, field, result);
      } catch (e, st) {
        appLogger.e('Failed to update metadata field', error: e, stackTrace: st);
      }
      if (!mounted) return;
      if (!success) {
        setState(() => draft.setValue(field.id, previous));
        showErrorSnackBar(context, t.metadataEdit.metadataUpdateFailed);
      }
    } else {
      setState(() => draft.setValue(field.id, result));
    }
  }

  Future<void> _openArtworkPicker(MetadataEditField field) async {
    final adapter = _adapter;
    final draft = _draft;
    if (adapter == null || draft == null) return;
    final result = await showScopedDialog<bool>(
      context: context,
      builder: (context) => ArtworkPickerDialog(adapter: adapter, draft: draft, field: field),
    );

    if (result == true && mounted) {
      await _reloadArtwork();
    }
  }

  Future<void> _reloadArtwork() async {
    final adapter = _adapter;
    final draft = _draft;
    if (adapter == null || draft == null) return;
    try {
      final item = await adapter.reloadItem(draft);
      if (!mounted) return;
      if (item != null) {
        setState(() => adapter.syncReloadedItem(draft, item));
      }
    } catch (_) {
      // Artwork was already saved by the picker; display will refresh next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FocusedScrollScaffold(title: Text(t.metadataEdit.screenTitle), slivers: [LoadingIndicatorBox.sliver]);
    }

    final adapter = _adapter;
    final draft = _draft;
    if (adapter == null || draft == null) {
      return FocusedScrollScaffold(
        title: Text(t.metadataEdit.screenTitle),
        slivers: [SliverFillRemaining(child: Center(child: Text(t.metadataEdit.metadataUpdateFailed)))],
      );
    }

    final sections = adapter.schemaFor(draft).where((section) => section.fields.isNotEmpty).toList();
    return FocusedScrollScaffold(
      title: Text(t.metadataEdit.screenTitle),
      focusableAppBarActions: true,
      actions: [
        if (_isSaving)
          const Padding(padding: .all(12), child: LoadingIndicatorBox(size: 24))
        else
          FocusableButton(
            onPressed: _hasChanges ? _save : null,
            child: IconButton(
              onPressed: _hasChanges ? _save : null,
              icon: const AppIcon(Symbols.check_rounded, fill: 1),
              tooltip: t.common.save,
            ),
          ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: sections.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildSectionCard(adapter, draft, sections[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(MetadataEditAdapter adapter, MetadataEditDraft draft, MetadataEditSection section) {
    return Card(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(section.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: .bold)),
          ),
          for (final field in section.fields) _buildField(adapter, draft, field),
        ],
      ),
    );
  }

  Widget _buildField(MetadataEditAdapter adapter, MetadataEditDraft draft, MetadataEditField field) {
    return switch (field.type) {
      MetadataEditFieldType.text => _buildFieldTile(
        label: field.label,
        value: draft.value<String>(field.id),
        onTap: () => _editTextField(field),
      ),
      MetadataEditFieldType.multilineText => _buildFieldTile(
        label: field.label,
        value: draft.value<String>(field.id),
        onTap: () => _editTextField(field, multiline: true),
      ),
      MetadataEditFieldType.date => _buildFieldTile(
        label: field.label,
        value: draft.value<String>(field.id),
        onTap: () => _editDate(field),
      ),
      MetadataEditFieldType.stringList => _buildFieldTile(
        label: field.label,
        value: metadataStringList(draft.values[field.id]).join(', '),
        onTap: () => _editStringList(field),
      ),
      MetadataEditFieldType.choice => _buildFieldTile(
        label: field.label,
        value: _choiceDisplayValue(field, draft.value<String>(field.id)),
        onTap: () => _editChoice(field),
      ),
      MetadataEditFieldType.artwork => _buildArtworkTile(adapter, draft, field),
    };
  }

  Widget _buildFieldTile({required String label, String? value, required VoidCallback onTap}) {
    final displayValue = (value == null || value.isEmpty) ? t.metadataEdit.notSet : value;
    final isNotSet = value == null || value.isEmpty;
    return FocusableListTile(
      title: Text(label),
      subtitle: Text(
        displayValue,
        maxLines: 2,
        overflow: .ellipsis,
        style: isNotSet
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))
            : null,
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: onTap,
      dense: false,
      visualDensity: VisualDensity.standard,
    );
  }

  Widget _buildArtworkTile(MetadataEditAdapter adapter, MetadataEditDraft draft, MetadataEditField field) {
    final artwork = field.artwork!;
    final imagePath = draft.value<String>(field.id);
    return FocusableListTile(
      leading: SizedBox(
        width: artwork.previewWidth,
        height: artwork.previewHeight,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: OptimizedMediaImage(
            client: adapter.mediaClient,
            imagePath: imagePath,
            width: artwork.previewWidth,
            height: artwork.previewHeight,
            fit: artwork.fit == MetadataArtworkFit.contain ? BoxFit.contain : BoxFit.cover,
            imageType: artwork.imageType,
          ),
        ),
      ),
      title: Text(field.label),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () => _openArtworkPicker(field),
      dense: false,
      visualDensity: VisualDensity.standard,
    );
  }

  String _choiceDisplayValue(MetadataEditField field, String? value) {
    for (final option in field.options) {
      if (option.value == value) return option.label;
    }
    return value == null || value.isEmpty ? t.metadataEdit.notSet : value;
  }
}

class ArtworkPickerDialog extends StatefulWidget {
  final MetadataEditAdapter adapter;
  final MetadataEditDraft draft;
  final MetadataEditField field;

  const ArtworkPickerDialog({super.key, required this.adapter, required this.draft, required this.field});

  @override
  State<ArtworkPickerDialog> createState() => _ArtworkPickerDialogState();
}

class _ArtworkPickerDialogState extends State<ArtworkPickerDialog> {
  List<MetadataArtworkOption>? _artworkList;
  bool _isLoading = true;
  bool _isApplying = false;

  MetadataArtworkConfig get _config => widget.field.artwork!;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    try {
      final artwork = await widget.adapter.fetchArtwork(widget.draft, widget.field);
      if (!mounted) return;
      setState(() {
        _artworkList = artwork;
        _isLoading = false;
      });
    } catch (e, st) {
      appLogger.e('Failed to load artwork', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _artworkList = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectArtwork(MetadataArtworkOption artwork) async {
    if (_isApplying) return;
    await _runArtworkUpdate(() => widget.adapter.applyArtworkOption(widget.draft, widget.field, artwork));
  }

  Future<void> _addFromUrl() async {
    final url = await showTextInputDialog(
      context,
      title: t.metadataEdit.fromUrl,
      labelText: t.metadataEdit.imageUrl,
      hintText: t.metadataEdit.enterImageUrl,
    );

    if (url == null || url.isEmpty || !mounted) return;
    await _runArtworkUpdate(() => widget.adapter.applyArtworkFromUrl(widget.draft, widget.field, url));
  }

  Future<void> _uploadFile() async {
    final result = await FilePickerService.instance.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty || !mounted) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    await _runArtworkUpdate(() => widget.adapter.uploadArtwork(widget.draft, widget.field, bytes, fileName: file.name));
  }

  Future<void> _runArtworkUpdate(Future<bool> Function() action) async {
    if (_isApplying) return;
    setState(() => _isApplying = true);
    bool success = false;
    try {
      success = await action();
    } catch (e, st) {
      appLogger.e('Artwork update failed', error: e, stackTrace: st);
    }
    if (!mounted) return;
    setState(() => _isApplying = false);
    if (success) {
      showSuccessSnackBar(context, t.metadataEdit.artworkUpdated);
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, t.metadataEdit.artworkUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_config.selectTitle),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildArtworkContent(),
      ),
      actions: [
        if (_isApplying) const Padding(padding: .all(8), child: LoadingIndicatorBox(size: 24)),
        DialogActionButton(
          onPressed: _addFromUrl,
          label: t.metadataEdit.fromUrl,
          icon: const AppIcon(Symbols.link_rounded, size: 18),
        ),
        DialogActionButton(
          onPressed: _uploadFile,
          label: t.metadataEdit.uploadFile,
          icon: const AppIcon(Symbols.upload_rounded, size: 18),
        ),
        DialogActionButton(autofocus: true, onPressed: () => Navigator.pop(context), label: t.common.cancel),
      ],
    );
  }

  Widget _buildArtworkContent() {
    if (_artworkList == null || _artworkList!.isEmpty) {
      return Center(child: Text(t.metadataEdit.noArtworkAvailable));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _config.gridColumns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: _config.gridAspectRatio,
      ),
      itemCount: _artworkList!.length,
      itemBuilder: (context, index) {
        final artwork = _artworkList![index];
        return FocusableWrapper(
          borderRadius: 8,
          semanticLabel: artwork.selected
              ? t.metadataEdit.selectedArtworkOption(index: index + 1)
              : t.metadataEdit.artworkOption(index: index + 1),
          onSelect: () => _selectArtwork(artwork),
          child: GestureDetector(
            onTap: () => _selectArtwork(artwork),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: OptimizedMediaImage(
                      client: widget.adapter.mediaClient,
                      imagePath: artwork.thumbnailPath,
                      fit: _config.fit == MetadataArtworkFit.contain ? BoxFit.contain : BoxFit.cover,
                      imageType: _config.imageType,
                    ),
                  ),
                ),
                if (artwork.selected)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                      child: AppIcon(Symbols.check_rounded, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
