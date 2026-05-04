import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../exceptions/media_server_exceptions.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_server_client.dart';
import '../../models/livetv_program.dart';
import '../../models/media_subscription.dart';
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
  bool _saving = false;
  final _saveFocusNode = FocusNode(debugLabel: 'record_options_save');

  @override
  void initState() {
    super.initState();
    _entry = widget.entries.firstWhere((e) => e.selected == true, orElse: () => widget.entries.first);
  }

  @override
  void dispose() {
    _saveFocusNode.dispose();
    super.dispose();
  }

  void _selectEntry(MediaSubscription entry) {
    if (identical(entry, _entry)) return;
    setState(() {
      _entry = entry;
      _dirtyPrefs.clear();
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
    if (!widget.isEdit && _entry.targetLibrarySectionID == null) {
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
        await widget.client.liveTv.updateRecordingRule(id, Map.of(_dirtyPrefs));
        if (!mounted) return;
        _close(RecordOutcome.updated);
      } else {
        final request = MediaSubscriptionCreateRequest.fromTemplate(_entry, prefs: Map.of(_dirtyPrefs));
        await widget.client.liveTv.createRecordingRule(request);
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

  void _close([RecordOutcome? result]) {
    OverlaySheetController.popAdaptive(context, result ?? RecordOutcome.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleSettings = _entry.settings.where((s) => !s.hidden && !s.advanced).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      overflow: TextOverflow.ellipsis,
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FocusableButton(
                onPressed: _saving ? null : _close,
                child: TextButton(onPressed: _saving ? null : _close, child: Text(t.common.cancel)),
              ),
              const SizedBox(width: 8),
              FocusableButton(
                focusNode: _saveFocusNode,
                onPressed: _saving ? null : _save,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    final theme = Theme.of(context);
    return FocusableWrapper(
      autofocus: autofocus,
      autoScroll: true,
      useBackgroundFocus: true,
      onSelect: () => _openPicker(context),
      child: InkWell(
        canRequestFocus: false,
        onTap: () => _openPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 12),
              Text(_labelForValue(currentValue), style: theme.textTheme.bodyMedium),
              const SizedBox(width: 4),
              const AppIcon(Symbols.chevron_right_rounded),
            ],
          ),
        ),
      ),
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

class _IntSettingRowState extends State<_IntSettingRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _IntSettingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.currentValue?.toString() ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _TextSettingRowState extends State<_TextSettingRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _TextSettingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.currentValue?.toString() ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            onChanged: (text) => widget.onChanged(text),
          ),
        ],
      ),
    );
  }
}
