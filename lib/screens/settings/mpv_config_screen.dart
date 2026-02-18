import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../i18n/strings.g.dart';
import '../../models/mpv_config_models.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/settings_service.dart';
import '../../focus/key_event_utils.dart';
import '../../widgets/desktop_app_bar.dart';

class MpvConfigScreen extends StatefulWidget {
  const MpvConfigScreen({super.key});

  @override
  State<MpvConfigScreen> createState() => _MpvConfigScreenState();
}

class _MpvConfigScreenState extends State<MpvConfigScreen> {
  late SettingsService _settingsService;
  bool _isLoading = true;

  List<MpvConfigEntry> _entries = [];
  List<MpvPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    if (!mounted) return;
    setState(() {
      _entries = _settingsService.getMpvConfigEntries();
      _presets = _settingsService.getMpvPresets();
      _isLoading = false;
    });
  }

  Future<void> _saveEntries() async {
    await _settingsService.setMpvConfigEntries(_entries);
  }

  void _toggleEntry(int index) {
    setState(() {
      _entries[index] = _entries[index].copyWith(isEnabled: !_entries[index].isEnabled);
    });
    _saveEntries();
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
    _saveEntries();
  }

  void _addEntry(MpvConfigEntry entry) {
    setState(() {
      _entries.add(entry);
    });
    _saveEntries();
  }

  void _updateEntry(int index, MpvConfigEntry entry) {
    setState(() {
      _entries[index] = entry;
    });
    _saveEntries();
  }

  Future<void> _showEntryDialog({int? editIndex}) async {
    final isEdit = editIndex != null;
    final existingEntry = isEdit ? _entries[editIndex] : null;

    final keyController = TextEditingController(text: existingEntry?.key ?? '');
    final valueController = TextEditingController(text: existingEntry?.value ?? '');
    final keyFocusNode = FocusNode();
    final valueFocusNode = FocusNode();
    final saveFocusNode = FocusNode();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? t.mpvConfig.editProperty : t.mpvConfig.addProperty),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              focusNode: keyFocusNode,
              decoration: InputDecoration(labelText: t.mpvConfig.propertyKey, hintText: t.mpvConfig.propertyKeyHint),
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => valueFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              focusNode: valueFocusNode,
              decoration: InputDecoration(
                labelText: t.mpvConfig.propertyValue,
                hintText: t.mpvConfig.propertyValueHint,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => saveFocusNode.requestFocus(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          TextButton(
            focusNode: saveFocusNode,
            onPressed: () {
              if (keyController.text.isNotEmpty && valueController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );

    if (result == true) {
      final entry = MpvConfigEntry(
        key: keyController.text.trim(),
        value: valueController.text.trim(),
        isEnabled: existingEntry?.isEnabled ?? true,
      );

      if (isEdit) {
        _updateEntry(editIndex, entry);
      } else {
        _addEntry(entry);
      }
    }

    keyController.dispose();
    valueController.dispose();
    keyFocusNode.dispose();
    valueFocusNode.dispose();
    saveFocusNode.dispose();
  }

  Future<bool> _showConfirmDeleteDialog({required String title, required String content}) {
    return showDeleteConfirmation(context, title: title, message: content);
  }

  Future<void> _showDeleteEntryDialog(int index) async {
    final confirmed = await _showConfirmDeleteDialog(
      title: t.mpvConfig.deleteProperty,
      content: t.mpvConfig.confirmDeleteProperty,
    );
    if (confirmed) {
      _deleteEntry(index);
    }
  }

  Future<void> _showSavePresetDialog() async {
    if (_entries.isEmpty) return;

    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mpvConfig.saveAsPreset),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: t.mpvConfig.presetName, hintText: t.mpvConfig.presetNameHint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );

    if (result == true) {
      await _settingsService.saveMpvPreset(nameController.text.trim(), _entries);
      if (!mounted) return;
      setState(() {
        _presets = _settingsService.getMpvPresets();
      });

      if (mounted) {
        showSuccessSnackBar(context, t.mpvConfig.presetSaved);
      }
    }

    nameController.dispose();
  }

  Future<void> _loadPreset(MpvPreset preset) async {
    await _settingsService.loadMpvPreset(preset.name);
    if (!mounted) return;
    setState(() {
      _entries = _settingsService.getMpvConfigEntries();
    });

    if (mounted) {
      showAppSnackBar(context, t.mpvConfig.presetLoaded);
    }
  }

  Future<void> _deletePreset(MpvPreset preset) async {
    final confirmed = await _showConfirmDeleteDialog(
      title: t.mpvConfig.deletePreset,
      content: t.mpvConfig.confirmDeletePreset,
    );

    if (confirmed) {
      await _settingsService.deleteMpvPreset(preset.name);
      if (!mounted) return;
      setState(() {
        _presets = _settingsService.getMpvPresets();
      });

      if (mounted) {
        showSuccessSnackBar(context, t.mpvConfig.presetDeleted);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Focus(
        autofocus: true,
        onKeyEvent: (_, event) => handleBackKeyNavigation(context, event),
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => handleBackKeyNavigation(context, event),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            CustomAppBar(title: Text(t.screens.mpvConfig), pinned: true),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPresetsCard(),
                  const SizedBox(height: 16),
                  _buildEntriesCard(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.mpvConfig.presets,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const AppIcon(Symbols.save_rounded, fill: 1),
            title: Text(t.mpvConfig.saveAsPreset),
            enabled: _entries.isNotEmpty,
            onTap: _entries.isNotEmpty ? _showSavePresetDialog : null,
          ),
          if (_presets.isNotEmpty) ...[
            const Divider(),
            ..._presets.map(
              (preset) => ListTile(
                leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                title: Text(preset.name),
                subtitle: Text(t.mpvConfig.entriesCount(count: preset.entries.length)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'load') {
                      _loadPreset(preset);
                    } else if (value == 'delete') {
                      _deletePreset(preset);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'load', child: Text(t.mpvConfig.loadPreset)),
                    PopupMenuItem(value: 'delete', child: Text(t.mpvConfig.deletePreset)),
                  ],
                ),
                onTap: () => _loadPreset(preset),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                t.mpvConfig.noPresets,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntriesCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.mpvConfig.properties,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const AppIcon(Symbols.add_rounded, fill: 1),
                  onPressed: () => _showEntryDialog(),
                  tooltip: t.mpvConfig.addProperty,
                ),
              ],
            ),
          ),
          if (_entries.isNotEmpty) ...[
            const Divider(height: 1),
            ...List.generate(_entries.length, (index) {
              final entry = _entries[index];
              return ListTile(
                leading: Switch(value: entry.isEnabled, onChanged: (_) => _toggleEntry(index)),
                title: Text(
                  entry.key,
                  style: TextStyle(color: entry.isEnabled ? null : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                subtitle: Text(
                  entry.value,
                  style: TextStyle(color: entry.isEnabled ? null : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEntryDialog(editIndex: index);
                    } else if (value == 'delete') {
                      _showDeleteEntryDialog(index);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(t.mpvConfig.editProperty)),
                    PopupMenuItem(value: 'delete', child: Text(t.mpvConfig.deleteProperty)),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                t.mpvConfig.noProperties,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
