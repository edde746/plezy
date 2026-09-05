import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/back_press.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/mpv_config_models.dart';
import '../../utils/dialogs.dart';
import '../../utils/app_logger.dart';
import '../../utils/debouncer.dart';
import '../../utils/platform_detector.dart';
import '../../utils/snackbar_helper.dart';
import '../../mixins/settings_effect_mixin.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_popup_menu_button.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import 'mpv_config_line_editor.dart';

class MpvConfigScreen extends StatefulWidget {
  const MpvConfigScreen({super.key});

  @override
  State<MpvConfigScreen> createState() => _MpvConfigScreenState();
}

class _MpvConfigScreenState extends State<MpvConfigScreen> with SettingsEffectMixin, ControllerDisposerMixin {
  SettingsService get _settingsService => SettingsService.instance;

  late final TextEditingController _textController = createTextEditingController(
    text: _settingsService.read(SettingsService.mpvConfigText),
  );
  final _savePresetFocusNode = FocusNode();
  final _textFieldFocusNode = FocusNode();
  final _editorBackGate = BackPressGate();
  final _saveDebouncer = Debouncer(const Duration(milliseconds: 400));
  String _persistedText = '';
  int _revision = 0;
  int _persistedRevision = 0;
  _QueuedMpvConfig? _pendingSave;
  _QueuedMpvConfig? _activeSave;
  Future<bool>? _drainFuture;
  bool _isLeaving = false;
  bool _allowPop = false;
  bool _disposing = false;

  @override
  void initState() {
    super.initState();
    _persistedText = _textController.text;
    _textFieldFocusNode.addListener(_handleTextFieldFocusChanged);
    // Keep a clean editor synchronized with imports, reset, and other
    // settings producers without allowing a completed local write to replace
    // a newer queued edit.
    bindEffect<String>(SettingsService.mpvConfigText, _handlePersistedText, fireImmediately: false);
  }

  @override
  void dispose() {
    _disposing = true;
    _saveDebouncer.dispose();
    _textFieldFocusNode.removeListener(_handleTextFieldFocusChanged);
    if (_pendingSave != null || _drainFuture != null) {
      unawaited(_flushPending());
    }
    _savePresetFocusNode.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  bool get _hasUnsavedWork => _pendingSave != null || _activeSave != null || _drainFuture != null;

  void _handleTextFieldFocusChanged() {
    if (!_textFieldFocusNode.hasFocus) {
      unawaited(_flushPending());
    }
  }

  void _handlePersistedText(String value) {
    final active = _activeSave;
    if (active != null && active.text == value) return;
    if (active == null && _pendingSave == null && _textController.text == value) {
      _persistedText = value;
      return;
    }

    // An import/reset/other producer wins when observed. An in-flight local
    // write cannot be cancelled, so queue the external value behind it to
    // ensure that obsolete write cannot become the final persisted value.
    _saveDebouncer.cancel();
    final revision = ++_revision;
    _persistedText = value;
    _persistedRevision = revision;
    _pendingSave = active == null ? null : _QueuedMpvConfig(text: value, revision: revision);
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _notifySaveStateChanged();
  }

  void _queueTextSave(String text) {
    if (_disposing) return;
    if (_activeSave == null && _pendingSave == null && text == _persistedText) {
      _notifySaveStateChanged();
      return;
    }

    _pendingSave = _QueuedMpvConfig(text: text, revision: ++_revision);
    _saveDebouncer.run(() => unawaited(_flushPending()));
    _notifySaveStateChanged();
  }

  Future<bool> _flushPending() {
    _saveDebouncer.cancel();
    final existing = _drainFuture;
    if (existing != null) return existing;

    late final Future<bool> drain;
    drain = _drainPending().whenComplete(() {
      if (identical(_drainFuture, drain)) {
        _drainFuture = null;
        _notifySaveStateChanged();
      }
    });
    _drainFuture = drain;
    _notifySaveStateChanged();
    return drain;
  }

  Future<bool> _drainPending() async {
    while (true) {
      final next = _pendingSave;
      if (next == null) return true;

      _pendingSave = null;
      _activeSave = next;
      try {
        await _settingsService.write(SettingsService.mpvConfigText, next.text);
      } catch (error, stackTrace) {
        _pendingSave ??= next;
        _activeSave = null;
        appLogger.e('MPV configuration save failed', error: error, stackTrace: stackTrace);
        if (mounted && !_disposing) showErrorSnackBar(context, t.settings.saveFailed);
        return false;
      }

      _activeSave = null;
      if (next.revision >= _persistedRevision) {
        _persistedRevision = next.revision;
        _persistedText = next.text;
      }
    }
  }

  void _notifySaveStateChanged() {
    if (mounted && !_disposing) setState(() {});
  }

  Future<void> _flushAndPop() async {
    if (_isLeaving) return;
    _isLeaving = true;
    _notifySaveStateChanged();

    final saved = await _flushPending();
    if (!mounted || _disposing) return;
    if (!saved || _hasUnsavedWork) {
      _isLeaving = false;
      _notifySaveStateChanged();
      return;
    }

    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _showSavePresetDialog() async {
    if (_textController.text.trim().isEmpty) return;

    final name = await showTextInputDialog(
      context,
      title: t.mpvConfig.saveAsPreset,
      labelText: t.mpvConfig.presetName,
      hintText: t.mpvConfig.presetNameHint,
    );

    if (name == null || name.trim().isEmpty) return;
    if (!await _flushPending() || !mounted) return;

    await _settingsService.saveMpvPreset(name.trim(), _textController.text);
    if (mounted) showSuccessSnackBar(context, t.mpvConfig.presetSaved);
  }

  Future<void> _loadPreset(MpvPreset preset) async {
    _textController.value = TextEditingValue(
      text: preset.text,
      selection: TextSelection.collapsed(offset: preset.text.length),
    );
    _queueTextSave(preset.text);
    final saved = await _flushPending();
    if (mounted && saved) showAppSnackBar(context, t.mpvConfig.presetLoaded);
  }

  Future<void> _deletePreset(MpvPreset preset) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.mpvConfig.deletePreset,
      message: t.mpvConfig.confirmDeletePreset,
    );
    if (!confirmed) return;
    await _settingsService.deleteMpvPreset(preset.name);
    if (mounted) showSuccessSnackBar(context, t.mpvConfig.presetDeleted);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _textFieldFocusNode,
      builder: (context, _) {
        return PopScope(
          canPop:
              _allowPop ||
              (PlatformDetector.isHandheldIOS(context) &&
                  !_textFieldFocusNode.hasFocus &&
                  !_hasUnsavedWork &&
                  !_isLeaving),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || _isLeaving) return;
            if (_textFieldFocusNode.hasFocus && _savePresetFocusNode.canRequestFocus) {
              _savePresetFocusNode.requestFocus();
            } else {
              unawaited(_flushAndPop());
            }
          },
          child: FocusedScrollScaffold(
            title: Text(t.screens.mpvConfig),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildConfigEditor(),
                    if (Platform.isLinux) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          t.mpvConfig.embeddedVoHint,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildPresetsCard(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const _editorStyle = TextStyle(fontFamily: 'monospace', fontSize: 13);

  void _handleLineEditorChanged(String text) {
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _queueTextSave(text);
  }

  Widget _buildConfigEditor() {
    // TV keyboards cannot host a multiline field (#2232): one row per line.
    if (PlatformDetector.isTV()) {
      return MpvConfigLineEditor(text: _textController.text, onChanged: _handleLineEditorChanged, style: _editorStyle);
    }
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        // Back/Escape: move focus to the save preset button instead of
        // exiting. Acts on KeyDown because a native IME closing on Back may
        // swallow the KeyUp; the gate makes the press act exactly once.
        if (event.logicalKey.isBackKey) {
          if (!_savePresetFocusNode.canRequestFocus) {
            return KeyEventResult.ignored;
          }
          return _editorBackGate.handle(event, _savePresetFocusNode.requestFocus, phase: BackPhase.keyDown);
        }
        // We must consume Enter to prevent parent handlers from unfocusing,
        // but that also blocks Flutter's text editing shortcuts (which are
        // higher in the focus tree). So we manually insert newlines here.
        if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final sel = _textController.selection;
            if (sel.isValid) {
              final text = _textController.text;
              final value = TextEditingValue(
                text: text.replaceRange(sel.start, sel.end, '\n'),
                selection: TextSelection.collapsed(offset: sel.start + 1),
              );
              _textController.value = value;
              _queueTextSave(value.text);
            }
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isSelectKey) {
          return KeyEventResult.handled;
        }
        if (event.logicalKey.isDownKey && event.isActionable) {
          final sel = _textController.selection;
          if (sel.isValid && _textController.text.indexOf('\n', sel.extentOffset) == -1) {
            _savePresetFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: FocusableTextField(
        controller: _textController,
        focusNode: _textFieldFocusNode,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        minLines: 12,
        decoration: InputDecoration(
          hintText: t.mpvConfig.configPlaceholder,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
        style: _editorStyle,
        onChanged: _queueTextSave,
      ),
    );
  }

  Widget _buildPresetsCard() {
    return SettingValueBuilder<List<MpvPreset>>(
      pref: SettingsService.mpvPresets,
      builder: (context, presets, _) => SettingsGroup(
        title: t.mpvConfig.presets,
        // The page already pads its slivers by 16.
        margin: EdgeInsets.zero,
        children: [
          FocusableListTile(
            focusNode: _savePresetFocusNode,
            leading: const AppIcon(Symbols.save_rounded, fill: 1),
            title: Text(t.mpvConfig.saveAsPreset),
            enabled: _textController.text.trim().isNotEmpty,
            onTap: _textController.text.trim().isNotEmpty ? _showSavePresetDialog : null,
          ),
          if (presets.isNotEmpty)
            ...presets.map(
              (preset) => FocusableListTile(
                leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                title: Text(preset.name),
                trailing: FocusablePopupMenuButton<String>(
                  icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                  onSelected: (value) {
                    if (value == 'load') {
                      _loadPreset(preset);
                    } else if (value == 'delete') {
                      _deletePreset(preset);
                    }
                  },
                  itemBuilder: (context) => [
                    AppMenuItem(value: 'load', label: t.mpvConfig.loadPreset),
                    AppMenuItem(value: 'delete', label: t.mpvConfig.deletePreset),
                  ],
                ),
                onTap: () => _loadPreset(preset),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
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

class _QueuedMpvConfig {
  const _QueuedMpvConfig({required this.text, required this.revision});

  final String text;
  final int revision;
}
