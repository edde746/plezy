import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_server_client.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../models/livetv_program.dart';
import '../../models/media_subscription.dart';
import '../../services/plex_constants.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/overlay_sheet.dart';
import 'livetv_recording_actions.dart';

/// Sub-page rendered inside the open program-details [OverlaySheetController].
/// Displays editable [SubscriptionSetting]s for the chosen template entry and
/// posts a `MediaSubscriptionCreateRequest` on Save.
///
/// Returns one of [RecordOutcome] when the page closes:
/// - [RecordOutcome.scheduled] on successful create
/// - [RecordOutcome.alreadyScheduled] on 409 (duplicate)
/// - [RecordOutcome.adminRequired] on 403
/// - [RecordOutcome.targetMissing] when the template lacks a target library
/// - [RecordOutcome.failed] on other errors
/// - [RecordOutcome.cancelled] when the user dismissed without saving
class RecordOptionsSheet {
  RecordOptionsSheet._();

  /// Push the options sheet in create mode, seeded by template entries.
  static Future<RecordOutcome?> push(
    BuildContext context, {
    required MediaServerClient client,
    required LiveTvProgram program,
    required List<MediaSubscription> entries,
  }) {
    return OverlaySheetController.pushAdaptive<RecordOutcome>(
      context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _RecordOptionsContent(client: client, headerTitle: program.displayTitle, entries: entries),
    );
  }

  /// Push the options sheet in edit mode against an existing rule. Save calls
  /// `updateRecordingRule(id, prefs)` instead of creating a new rule.
  static Future<RecordOutcome?> pushEdit(
    BuildContext context, {
    required MediaServerClient client,
    required MediaSubscription rule,
  }) {
    return OverlaySheetController.pushAdaptive<RecordOutcome>(
      context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RecordOptionsContent(
        client: client,
        headerTitle: rule.title ?? '',
        entries: [rule],
        isEdit: true,
        editingId: rule.key,
      ),
    );
  }
}

class _RecordOptionsContent extends StatefulWidget {
  final MediaServerClient client;
  final String headerTitle;
  final List<MediaSubscription> entries;
  final bool isEdit;
  final String? editingId;

  const _RecordOptionsContent({
    required this.client,
    required this.headerTitle,
    required this.entries,
    this.isEdit = false,
    this.editingId,
  });

  @override
  State<_RecordOptionsContent> createState() => _RecordOptionsContentState();
}

class _RecordOptionsContentState extends State<_RecordOptionsContent> {
  late MediaSubscription _entry;
  final Map<String, Object?> _dirtyPrefs = {};
  List<MediaLibrary> _libraries = const [];
  int? _selectedSectionId;
  bool _saving = false;
  final _saveFocusNode = FocusNode(debugLabel: 'record_options_save');

  @override
  void initState() {
    super.initState();
    _entry = widget.entries.firstWhere((e) => e.selected == true, orElse: () => widget.entries.first);
    if (!widget.isEdit) _loadLibraries();
  }

  @override
  void dispose() {
    _saveFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLibraries() async {
    try {
      final libraries = await widget.client.fetchLibraries();
      if (mounted) setState(() => _libraries = libraries);
    } catch (e) {
      // Non-fatal: the row degrades to a read-only template default.
      appLogger.w('Failed to fetch libraries for recording target picker', error: e);
    }
  }

  /// Library kind a recording of [_entry]'s type lands in, or null when no
  /// sensible mapping exists (no picker shown).
  MediaKind? get _entryLibraryKind => switch (_entry.type) {
    PlexMetadataType.movie => MediaKind.movie,
    PlexMetadataType.show || PlexMetadataType.season || PlexMetadataType.episode => MediaKind.show,
    _ => null,
  };

  /// Sections eligible as recording targets for the selected entry.
  List<MediaLibrary> get _eligibleLibraries {
    final kind = _entryLibraryKind;
    if (kind == null) return const [];
    return [
      for (final library in _libraries)
        if (library.kind == kind && !library.isShared && int.tryParse(library.id) != null) library,
    ];
  }

  /// Last explicitly picked target for this server + entry type, if it still
  /// refers to an eligible section.
  int? _savedSectionId(List<MediaLibrary> eligible) {
    final type = _entry.type;
    if (type == null) return null;
    final saved =
        SettingsService.instanceOrNull?.read(SettingsService.dvrTargetSectionPref(widget.client.serverId, type)) ?? 0;
    if (saved <= 0) return null;
    return eligible.any((library) => library.id == '$saved') ? saved : null;
  }

  int? _effectiveSectionId(List<MediaLibrary> eligible) =>
      _selectedSectionId ?? _savedSectionId(eligible) ?? _entry.targetLibrarySectionID;

  String _targetLibraryLabel(List<MediaLibrary> eligible) {
    final target = _effectiveSectionId(eligible);
    final match = eligible.where((library) => library.id == '$target').firstOrNull;
    return match?.title ?? _entry.librarySectionTitle ?? '';
  }

  void _selectEntry(MediaSubscription entry) {
    if (identical(entry, _entry)) return;
    setState(() {
      _entry = entry;
      _dirtyPrefs.clear();
      _selectedSectionId = null;
    });
  }

  void _setPref(String id, Object? baseline, Object? value) {
    setState(() {
      if (_compareValues(value, baseline)) {
        _dirtyPrefs.remove(id);
      } else {
        _dirtyPrefs[id] = value;
      }
    });
  }

  bool _compareValues(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  Object? _baselineFor(SubscriptionSetting setting) => setting.value ?? setting.defaultValue;

  Object? _currentValueFor(SubscriptionSetting setting) {
    if (_dirtyPrefs.containsKey(setting.id)) return _dirtyPrefs[setting.id];
    return setting.value ?? setting.defaultValue;
  }

  Future<void> _save() async {
    final dvr = widget.client.liveTvDvr;
    if (dvr == null) {
      _close(RecordOutcome.failed);
      return;
    }
    final targetSectionId = widget.isEdit ? null : _effectiveSectionId(_eligibleLibraries);
    if (!widget.isEdit && targetSectionId == null) {
      _close(RecordOutcome.targetMissing);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.isEdit) {
        final id = widget.editingId;
        if (id == null || id.isEmpty) {
          _close(RecordOutcome.failed);
          return;
        }
        await dvr.updateRecordingRule(id, Map.of(_dirtyPrefs));
        if (!mounted) return;
        _close(RecordOutcome.updated);
      } else {
        final request = MediaSubscriptionCreateRequest.fromTemplate(
          _entry,
          prefs: Map.of(_dirtyPrefs),
          targetLibrarySectionID: targetSectionId,
        );
        await dvr.createRecordingRule(request);
        _persistTargetPick();
        if (!mounted) return;
        _close(RecordOutcome.scheduled);
      }
    } catch (e) {
      appLogger.e('Failed to save recording rule', error: e);
      if (!mounted) return;
      final code = e is MediaServerHttpException ? e.statusCode : null;
      final outcome = switch (code) {
        403 => RecordOutcome.adminRequired,
        409 => RecordOutcome.alreadyScheduled,
        _ => RecordOutcome.failed,
      };
      _close(outcome);
    }
  }

  /// Remember an explicit library pick (never the template default, so the
  /// server default keeps applying until the user chooses).
  void _persistTargetPick() {
    final picked = _selectedSectionId;
    final type = _entry.type;
    if (picked == null || type == null) return;
    SettingsService.instanceOrNull?.write(SettingsService.dvrTargetSectionPref(widget.client.serverId, type), picked);
  }

  void _close([RecordOutcome? result]) {
    OverlaySheetController.popAdaptive(context, result ?? RecordOutcome.cancelled);
  }

  Future<void> _openTargetPicker(List<MediaLibrary> eligible) async {
    final selected = await showOptionPickerDialog<int>(
      context,
      title: t.liveTv.saveTo,
      options: [for (final library in eligible) (icon: null, label: library.title, value: int.parse(library.id))],
    );
    if (selected != null && mounted) setState(() => _selectedSectionId = selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSettings = _entry.settings.where((s) => !s.hidden && !s.advanced).toList();
    final eligibleLibraries = widget.isEdit ? const <MediaLibrary>[] : _eligibleLibraries;
    final targetLabel = widget.isEdit ? (_entry.librarySectionTitle ?? '') : _targetLibraryLabel(eligibleLibraries);
    final showTargetRow = targetLabel.isNotEmpty || eligibleLibraries.length > 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      widget.isEdit ? t.liveTv.editRule : t.liveTv.recordOptions,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.headerTitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.entries.length > 1) ...[
            const SizedBox(height: 12),
            _EntryChooser(entries: widget.entries, selected: _entry, onSelect: _selectEntry),
          ],
          if (showTargetRow) ...[
            const SizedBox(height: 8),
            _PickerRow(
              label: t.liveTv.saveTo,
              value: targetLabel,
              onTap: eligibleLibraries.length > 1 ? () => _openTargetPicker(eligibleLibraries) : null,
            ),
          ],
          const SizedBox(height: 8),
          Flexible(
            child: visibleSettings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _entry.airingsType ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: visibleSettings.length,
                    itemBuilder: (context, index) {
                      final setting = visibleSettings[index];
                      return _SettingRow(
                        setting: setting,
                        currentValue: _currentValueFor(setting),
                        autofocus: index == 0,
                        onChanged: (value) => _setPref(setting.id, _baselineFor(setting), value),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: .end,
            children: [
              FocusableButton(
                onPressed: _saving ? null : _close,
                child: TextButton(onPressed: _saving ? null : _close, child: Text(t.common.cancel)),
              ),
              const SizedBox(width: 8),
              FocusableButton(
                focusNode: _saveFocusNode,
                onPressed: _saving ? null : _save,
                useBackgroundFocus: true,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : AppIcon(widget.isEdit ? Symbols.save_rounded : Symbols.fiber_manual_record_rounded),
                  label: Text(widget.isEdit ? t.common.save : t.liveTv.record),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryChooser extends StatelessWidget {
  final List<MediaSubscription> entries;
  final MediaSubscription selected;
  final void Function(MediaSubscription) onSelect;

  const _EntryChooser({required this.entries, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in entries)
          FocusableButton(
            onPressed: () => onSelect(entry),
            child: ChoiceChip(
              label: Text(entry.title ?? ''),
              selected: identical(entry, selected),
              onSelected: (_) => onSelect(entry),
              labelStyle: TextStyle(
                color: identical(entry, selected) ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
              selectedColor: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final SubscriptionSetting setting;
  final Object? currentValue;
  final bool autofocus;
  final void Function(Object?) onChanged;

  const _SettingRow({
    required this.setting,
    required this.currentValue,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = setting.type;
    if (type == 'bool') {
      return _BoolSettingRow(setting: setting, currentValue: currentValue, autofocus: autofocus, onChanged: onChanged);
    }
    if (type == 'int' && setting.options.isNotEmpty) {
      return _EnumSettingRow(setting: setting, currentValue: currentValue, autofocus: autofocus, onChanged: onChanged);
    }
    if (type == 'int') {
      return _IntSettingRow(setting: setting, currentValue: currentValue, autofocus: autofocus, onChanged: onChanged);
    }
    return _TextSettingRow(setting: setting, currentValue: currentValue, autofocus: autofocus, onChanged: onChanged);
  }
}

bool _coerceBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

class _BoolSettingRow extends StatelessWidget {
  final SubscriptionSetting setting;
  final Object? currentValue;
  final bool autofocus;
  final void Function(Object?) onChanged;

  const _BoolSettingRow({
    required this.setting,
    required this.currentValue,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _coerceBool(currentValue);
    void toggle() => onChanged(!value);
    return FocusableWrapper(
      autofocus: autofocus,
      autoScroll: true,
      useBackgroundFocus: true,
      onSelect: toggle,
      child: InkWell(
        canRequestFocus: false,
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(setting.label ?? setting.id, style: theme.textTheme.bodyMedium),
                    if (setting.summary != null && setting.summary!.isNotEmpty)
                      Text(
                        setting.summary!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IgnorePointer(
                child: Switch(value: value, onChanged: (v) => onChanged(v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnumSettingRow extends StatelessWidget {
  final SubscriptionSetting setting;
  final Object? currentValue;
  final bool autofocus;
  final void Function(Object?) onChanged;

  const _EnumSettingRow({
    required this.setting,
    required this.currentValue,
    required this.autofocus,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showOptionPickerDialog<String>(
      context,
      title: setting.label ?? setting.id,
      options: [for (final option in setting.options) (icon: null, label: option.label, value: option.value)],
    );
    if (selected != null) onChanged(selected);
  }

  String _labelForValue(Object? value) {
    final str = value?.toString() ?? '';
    final match = setting.options.where((o) => o.value == str).firstOrNull;
    return match?.label ?? str;
  }

  @override
  Widget build(BuildContext context) {
    return _PickerRow(
      label: setting.label ?? setting.id,
      summary: setting.summary,
      value: _labelForValue(currentValue),
      autofocus: autofocus,
      onTap: () => _openPicker(context),
    );
  }
}

/// Label / value / chevron row that opens a picker on tap. Renders as a
/// static, non-focusable row when [onTap] is null.
class _PickerRow extends StatelessWidget {
  final String label;
  final String? summary;
  final String value;
  final bool autofocus;
  final VoidCallback? onTap;

  const _PickerRow({required this.label, this.summary, required this.value, this.autofocus = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTap = this.onTap;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (summary != null && summary!.isNotEmpty)
                  Text(summary!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: theme.textTheme.bodyMedium),
          if (onTap != null) ...[const SizedBox(width: 4), const AppIcon(Symbols.chevron_right_rounded)],
        ],
      ),
    );
    if (onTap == null) return row;
    return FocusableWrapper(
      autofocus: autofocus,
      autoScroll: true,
      useBackgroundFocus: true,
      onSelect: onTap,
      child: InkWell(canRequestFocus: false, onTap: onTap, child: row),
    );
  }
}

class _IntSettingRow extends StatefulWidget {
  final SubscriptionSetting setting;
  final Object? currentValue;
  final bool autofocus;
  final void Function(Object?) onChanged;

  const _IntSettingRow({
    required this.setting,
    required this.currentValue,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  State<_IntSettingRow> createState() => _IntSettingRowState();
}

class _IntSettingRowState extends State<_IntSettingRow> with ControllerDisposerMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createTextEditingController(text: widget.currentValue?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _IntSettingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.currentValue?.toString() ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(widget.setting.label ?? widget.setting.id, style: theme.textTheme.bodyMedium),
          if (widget.setting.summary != null && widget.setting.summary!.isNotEmpty)
            Text(
              widget.setting.summary!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          FocusableTextField(
            controller: _controller,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'-?\d*'))],
            onNavigateUp: () => FocusScope.of(context).previousFocus(),
            onNavigateDown: () => FocusScope.of(context).nextFocus(),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              widget.onChanged(parsed);
            },
          ),
        ],
      ),
    );
  }
}

class _TextSettingRow extends StatefulWidget {
  final SubscriptionSetting setting;
  final Object? currentValue;
  final bool autofocus;
  final void Function(Object?) onChanged;

  const _TextSettingRow({
    required this.setting,
    required this.currentValue,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  State<_TextSettingRow> createState() => _TextSettingRowState();
}

class _TextSettingRowState extends State<_TextSettingRow> with ControllerDisposerMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = createTextEditingController(text: widget.currentValue?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _TextSettingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.currentValue?.toString() ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(widget.setting.label ?? widget.setting.id, style: theme.textTheme.bodyMedium),
          if (widget.setting.summary != null && widget.setting.summary!.isNotEmpty)
            Text(
              widget.setting.summary!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          FocusableTextField(
            controller: _controller,
            autofocus: widget.autofocus,
            onNavigateUp: () => FocusScope.of(context).previousFocus(),
            onNavigateDown: () => FocusScope.of(context).nextFocus(),
            onChanged: (text) => widget.onChanged(text),
          ),
        ],
      ),
    );
  }
}
