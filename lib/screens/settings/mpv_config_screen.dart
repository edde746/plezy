import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../models/mpv_config_models.dart';
import '../../focus/focusable_button.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/settings_service.dart';
import '../../widgets/focused_scroll_scaffold.dart';

class MpvConfigScreen extends StatefulWidget {
  const MpvConfigScreen({super.key});

  @override
  State<MpvConfigScreen> createState() => _MpvConfigScreenState();
}

class _MpvConfigScreenState extends State<MpvConfigScreen> {
  late SettingsService _settingsService;
  bool _isLoading = true;

  late TextEditingController _textController;
  final _savePresetFocusNode = FocusNode();
  final _textFieldFocusNode = FocusNode();
  List<MpvPreset> _presets = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _textController.dispose();
    _savePresetFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _settingsService = await SettingsService.getInstance();

    if (!mounted) return;
    setState(() {
      _textController.text = _settingsService.getMpvConfigText();
      _presets = _settingsService.getMpvPresets();
      _isLoading = false;
    });
  }

  Future<void> _saveText() async {
    await _settingsService.setMpvConfigText(_textController.text);
  }

  Future<void> _showSavePresetDialog() async {
    if (_textController.text.trim().isEmpty) return;

    final nameController = TextEditingController();
    final saveFocusNode = FocusNode();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.mpvConfig.saveAsPreset),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: t.mpvConfig.presetName, hintText: t.mpvConfig.presetNameHint),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => saveFocusNode.requestFocus(),
        ),
        actions: [
          FocusableButton(
            onPressed: () => Navigator.pop(context, false),
            child: TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
          ),
          FocusableButton(
            focusNode: saveFocusNode,
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(t.common.save),
            ),
          ),
        ],
      ),
    );

    saveFocusNode.dispose();

    if (result == true) {
      await _settingsService.saveMpvPreset(nameController.text.trim(), _textController.text);
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
      _textController.text = _settingsService.getMpvConfigText();
    });

    if (mounted) {
      showAppSnackBar(context, t.mpvConfig.presetLoaded);
    }
  }

  Future<void> _deletePreset(MpvPreset preset) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.mpvConfig.deletePreset,
      message: t.mpvConfig.confirmDeletePreset,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (BackKeyCoordinator.consumeIfHandled()) return;
        BackKeyUpSuppressor.suppressBackUntilKeyUp();
        if (_textFieldFocusNode.hasFocus && _savePresetFocusNode.canRequestFocus) {
          _savePresetFocusNode.requestFocus();
        } else {
          Navigator.pop(context);
        }
      },
      child: FocusedScrollScaffold(
        title: Text(t.screens.mpvConfig),
        slivers: _isLoading
            ? [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]
            : [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildConfigEditor(),
                      const SizedBox(height: 16),
                      _buildPresetsCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildConfigEditor() {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        // Back/Escape: move focus to the save preset button instead of exiting.
        // Suppress the KeyUp so it doesn't reach handleBackKeyNavigation
        // on the new focus chain after focus moves away from the text field.
        if (event.logicalKey.isBackKey) {
          if (!_savePresetFocusNode.canRequestFocus) {
            return KeyEventResult.ignored;
          }
          if (event is KeyDownEvent) {
            BackKeyUpSuppressor.suppressBackUntilKeyUp();
            _savePresetFocusNode.requestFocus();
          }
          return KeyEventResult.handled;
        }
        // We must consume Enter to prevent parent handlers from unfocusing,
        // but that also blocks Flutter's text editing shortcuts (which are
        // higher in the focus tree). So we manually insert newlines here.
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final sel = _textController.selection;
            if (sel.isValid) {
              final text = _textController.text;
              _textController.value = TextEditingValue(
                text: text.replaceRange(sel.start, sel.end, '\n'),
                selection: TextSelection.collapsed(offset: sel.start + 1),
              );
              _saveText();
            }
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isSelectKey) {
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isDownKey && event.isActionable) {
          final sel = _textController.selection;
          if (sel.isValid &&
              _textController.text.indexOf('\n', sel.extentOffset) == -1) {
            _savePresetFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _textController,
        focusNode: _textFieldFocusNode,
        maxLines: null,
        minLines: 12,
        decoration: InputDecoration(
          hintText: t.mpvConfig.configPlaceholder,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        onChanged: (_) => _saveText(),
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
            focusNode: _savePresetFocusNode,
            leading: const AppIcon(Symbols.save_rounded, fill: 1),
            title: Text(t.mpvConfig.saveAsPreset),
            enabled: _textController.text.trim().isNotEmpty,
            onTap: _textController.text.trim().isNotEmpty ? _showSavePresetDialog : null,
          ),
          if (_presets.isNotEmpty) ...[
            const Divider(),
            ..._presets.map(
              (preset) => ListTile(
                leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                title: Text(preset.name),
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
}
