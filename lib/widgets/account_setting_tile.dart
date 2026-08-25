import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/settings/settings_utils.dart';
import 'app_icon.dart';
import 'focusable_list_tile.dart';

/// Settings rows for values stored on a media-server account instead of in
/// `SettingsService`.
///
/// The `Pref`-bound tiles in `setting_tile.dart` write to local storage and
/// rebuild from a [ValueListenable]; an account preference costs a request that
/// can be rejected. These twins therefore own three things the `Pref` tiles do
/// not: they show the picked value immediately, they ignore a second change
/// while the first is still in flight, and they fall back to the previous value
/// and report the failure when the write fails.
///
/// Presentation, row density and focus behaviour are otherwise identical,
/// because account rows sit in the same `SettingsGroup`s as `Pref` rows — and
/// on TV a row that focuses differently from its neighbours reads as a bug.

/// Optimistic-write plumbing shared by the account tiles.
///
/// [V] is the row's value type; `null` means "the account has no value", which
/// is why an optimistic value is tracked separately instead of overwriting a
/// nullable field.
mixin _AccountWriteState<W extends StatefulWidget, V extends Object> on State<W> {
  V? _pending;
  bool _writing = false;

  /// The value the enclosing widget was built with.
  V? get serverValue;

  /// What the row renders: the optimistic value while one is outstanding,
  /// otherwise the account's own.
  V? get shownValue => _pending ?? serverValue;

  /// Whether a write is still in flight. Rows stay visually enabled — only the
  /// change is dropped — so a slow server does not make the row flicker.
  bool get isWriting => _writing;

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A rebuild carries a fresh account value, which outranks the optimistic
    // copy. Never while writing: the picked value must stay on screen until
    // the request that carries it resolves.
    if (!_writing) _pending = null;
  }

  /// Shows [next] at once, awaits [write], and restores the previous value with
  /// the shared settings-failure snackbar when the write is rejected.
  ///
  /// Errors that are not [Exception]s — programming errors — are not reported
  /// as recoverable and keep propagating.
  Future<void> commit(V next, Future<void> Function(V value) write) async {
    if (_writing) return;
    setState(() {
      _pending = next;
      _writing = true;
    });
    try {
      await write(next);
      // The optimistic value deliberately stays: the caller rebuilds this row
      // from the write's result and [didUpdateWidget] drops the copy then.
      // Clearing it here would flash the old value for a frame whenever that
      // rebuild has not landed yet.
    } on Exception catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _pending = null);
      showSettingsFailure(context, operation: 'Account preference write', error: error, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }
}

/// [FocusableSwitchListTile] bound to a boolean account preference.
class AccountSettingSwitchTile extends StatefulWidget {
  /// The account's current value. `null` — unset — renders as off, so pass the
  /// backend's own default when that default is on.
  final bool? value;

  final String title;
  final String? subtitle;
  final IconData icon;

  /// Performs the write. Must complete with an error when the write failed:
  /// the row reverts and reports the failure on any [Exception].
  final Future<void> Function(bool value) onChanged;

  final bool enabled;
  final FocusNode? focusNode;

  const AccountSettingSwitchTile({
    super.key,
    required this.value,
    required this.title,
    required this.icon,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<AccountSettingSwitchTile> createState() => _AccountSettingSwitchTileState();
}

class _AccountSettingSwitchTileState extends State<AccountSettingSwitchTile>
    with _AccountWriteState<AccountSettingSwitchTile, bool> {
  @override
  bool? get serverValue => widget.value;

  @override
  Widget build(BuildContext context) {
    return FocusableSwitchListTile(
      focusNode: widget.focusNode,
      secondary: AppIcon(widget.icon, fill: 1),
      title: Text(widget.title),
      subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
      value: shownValue ?? false,
      onChanged: widget.enabled ? (next) => commit(next, widget.onChanged) : null,
    );
  }
}

/// Row that opens [showSelectionDialog] and writes the chosen value to the
/// account. The subtitle shows the current value, as on `SettingSelectionTile`.
class AccountSettingSelectionTile<T extends Object> extends StatefulWidget {
  /// The account's current value, or `null` when it has none.
  final T? value;

  final IconData icon;
  final String title;

  /// Builds the row subtitle. Receives `null` when the account has no value.
  final String Function(T? value) subtitleBuilder;

  final List<DialogOption<T>> options;

  /// Performs the write. Must complete with an error when the write failed.
  final Future<void> Function(T value) onChanged;

  final FocusNode? focusNode;

  const AccountSettingSelectionTile({
    super.key,
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitleBuilder,
    required this.options,
    required this.onChanged,
    this.focusNode,
  });

  @override
  State<AccountSettingSelectionTile<T>> createState() => _AccountSettingSelectionTileState<T>();
}

class _AccountSettingSelectionTileState<T extends Object> extends State<AccountSettingSelectionTile<T>>
    with _AccountWriteState<AccountSettingSelectionTile<T>, T> {
  @override
  T? get serverValue => widget.value;

  Future<void> _pick() async {
    if (isWriting) return;
    final current = shownValue;
    // Every option value is non-null (T extends Object), so a null result can
    // only mean the dialog was dismissed. The option list is passed straight
    // through: List<DialogOption<T>> is a List<DialogOption<T?>>, and the
    // dialog only reads it.
    final picked = await showSelectionDialog<T?>(
      context: context,
      title: widget.title,
      options: widget.options,
      currentValue: current,
    );
    if (picked == null || picked == current || !mounted) return;
    await commit(picked, widget.onChanged);
  }

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      focusNode: widget.focusNode,
      leading: AppIcon(widget.icon, fill: 1),
      title: Text(widget.title),
      subtitle: Text(widget.subtitleBuilder(shownValue)),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: _pick,
    );
  }
}
