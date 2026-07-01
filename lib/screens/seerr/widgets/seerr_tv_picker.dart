import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../focus/focusable_button.dart';
import '../../../focus/focusable_wrapper.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/overlay_sheet.dart';

/// Option entry for [SeerrTvPicker]. [value] is what gets returned to the
/// caller; [label] / [subtitle] drive the visual.
class SeerrTvPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SeerrTvPickerOption({required this.value, required this.label, this.subtitle});
}

/// A d-pad-friendly replacement for [DropdownButtonFormField]. Displays the
/// current selection in a labeled outlined box; tapping (or pressing SELECT
/// on TV) opens a focusable picker list as a sub-sheet via
/// [OverlaySheetController.pushAdaptive] (falls back to
/// [showModalBottomSheet] when no overlay host is in the tree).
///
/// Use anywhere a `<T>` picker is needed inside the request sheet.
class SeerrTvPicker<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<SeerrTvPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const SeerrTvPicker({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  String get _currentLabel {
    if (value == null) return '—';
    final match = options.where((o) => o.value == value).cast<SeerrTvPickerOption<T>?>().firstOrNull;
    return match?.label ?? '—';
  }

  Future<void> _open(BuildContext context) async {
    final picked = await OverlaySheetController.pushAdaptive<T>(
      context,
      builder: (sheetContext) => _SeerrTvPickerList<T>(label: label, options: options, currentValue: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.5);
    return FocusableButton(
      onPressed: enabled ? () => _open(context) : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
              isDense: true,
              suffixIcon: AppIcon(Symbols.expand_more_rounded, fill: 1, color: muted, size: 22),
            ),
            child: Text(_currentLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}

class _SeerrTvPickerList<T> extends StatelessWidget {
  final String label;
  final List<SeerrTvPickerOption<T>> options;
  final T? currentValue;

  const _SeerrTvPickerList({required this.label, required this.options, required this.currentValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(label, style: theme.textTheme.titleMedium),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final opt = options[i];
                final isSelected = opt.value == currentValue;
                return FocusableWrapper(
                  autofocus: isSelected || (currentValue == null && i == 0),
                  disableScale: true,
                  borderRadius: 0,
                  autoScroll: true,
                  onSelect: () => OverlaySheetController.popAdaptive(context, opt.value),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => OverlaySheetController.popAdaptive(context, opt.value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            AppIcon(
                              isSelected
                                  ? Symbols.radio_button_checked_rounded
                                  : Symbols.radio_button_unchecked_rounded,
                              fill: 1,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.label, style: theme.textTheme.bodyMedium),
                                  if (opt.subtitle != null && opt.subtitle!.isNotEmpty)
                                    Text(
                                      opt.subtitle!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on Iterable<dynamic> {
  dynamic get firstOrNull => isEmpty ? null : first;
}
