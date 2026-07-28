import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/settings/settings_utils.dart';
import '../services/settings_service.dart';
import 'app_icon.dart';
import 'focusable_list_tile.dart';
import 'settings_section.dart';

/// Reactive setting tiles bound to a [Pref] via [SettingsService.listenable].
/// Eliminates the field-mirror + setState + manual reload pattern that used to
/// surround every settings row.

/// Shared commit path for every tile: persist [value] under [pref], then hand
/// it to the tile's optional [onAfterWrite] callback.
Future<void> _writeAndNotify<T>(Pref<T> pref, T value, FutureOr<void> Function(T)? onAfterWrite) async {
  await SettingsService.instance.write(pref, value);
  if (onAfterWrite != null) await onAfterWrite(value);
}

/// Shared scaffold for the tiles that render a tappable settings row: same
/// leading icon, title style and row density everywhere. [trailing] defaults
/// to the chevron used by every row that opens a dialog.
class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableListTile(
      focusNode: focusNode,
      leading: AppIcon(icon, fill: 1),
      title: Text(title),
      subtitle: subtitle,
      trailing: trailing ?? const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: onTap,
    );
  }
}

/// SwitchListTile bound to a [Pref<bool>].
class SettingSwitchTile extends StatelessWidget {
  final Pref<bool> pref;
  final IconData icon;
  final String title;
  final String? subtitle;
  final FutureOr<void> Function(bool)? onAfterWrite;
  final bool enabled;
  final FocusNode? focusNode;

  const SettingSwitchTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAfterWrite,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, value, _) => FocusableSwitchListTile(
        focusNode: focusNode,
        secondary: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: enabled ? (v) => _writeAndNotify(pref, v, onAfterWrite) : null,
      ),
    );
  }
}

/// Standard settings row that navigates to another screen.
class SettingNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final WidgetBuilder? destinationBuilder;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final IconData trailingIcon;

  const SettingNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.destinationBuilder,
    this.onTap,
    this.focusNode,
    this.trailingIcon = Symbols.chevron_right_rounded,
  }) : assert(destinationBuilder != null || onTap != null);

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      focusNode: focusNode,
      icon: icon,
      title: title,
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: AppIcon(trailingIcon, fill: 1),
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: destinationBuilder!)),
    );
  }
}

/// ListTile that opens [showNumericInputDialog] and writes back.
class SettingNumberTile extends StatelessWidget {
  final Pref<int> pref;
  final IconData icon;
  final String title;
  final String Function(int) subtitleBuilder;
  final String labelText;
  final String suffixText;
  final int min;
  final int max;
  final FutureOr<void> Function(int)? onAfterWrite;

  const SettingNumberTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitleBuilder,
    required this.labelText,
    required this.suffixText,
    required this.min,
    required this.max,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, value, _) => _SettingRow(
        icon: icon,
        title: title,
        subtitle: Text(subtitleBuilder(value)),
        onTap: () => showNumericInputDialog(
          context: context,
          title: title,
          labelText: labelText,
          suffixText: suffixText,
          min: min,
          max: max,
          currentValue: value,
          onSave: (v) => _writeAndNotify(pref, v, onAfterWrite),
        ),
      ),
    );
  }
}

/// ListTile that opens [showSelectionDialog] and writes the chosen value.
class SettingSelectionTile<T> extends StatelessWidget {
  final Pref<T> pref;
  final IconData icon;
  final String title;
  final String Function(T) subtitleBuilder;
  final List<DialogOption<T>> options;
  final FutureOr<void> Function(T)? onAfterWrite;

  const SettingSelectionTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitleBuilder,
    required this.options,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, value, _) => _SettingRow(
        icon: icon,
        title: title,
        subtitle: Text(subtitleBuilder(value)),
        onTap: () async {
          final picked = await showSelectionDialog<T>(
            context: context,
            title: title,
            options: options,
            currentValue: value,
          );
          if (picked == null) return;
          await _writeAndNotify(pref, picked, onAfterWrite);
        },
      ),
    );
  }
}

/// ListTile that opens [showRegexInputDialog] for a [Pref<String>].
class SettingRegexTile extends StatelessWidget {
  final Pref<String> pref;
  final IconData icon;
  final String title;
  final String subtitle;
  final String defaultValue;
  final FutureOr<void> Function(String)? onAfterWrite;

  const SettingRegexTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.defaultValue,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, value, _) => _SettingRow(
        icon: icon,
        title: title,
        subtitle: Text(subtitle),
        onTap: () => showRegexInputDialog(
          context: context,
          title: title,
          currentValue: value,
          defaultValue: defaultValue,
          onSave: (v) => _writeAndNotify(pref, v, onAfterWrite),
        ),
      ),
    );
  }
}

/// SegmentedSetting bound to a [Pref<T>].
class SettingSegmentedTile<T> extends StatelessWidget {
  final Pref<T> pref;
  final IconData icon;
  final String title;
  final List<ButtonSegment<T>> segments;
  final FutureOr<void> Function(T)? onAfterWrite;

  const SettingSegmentedTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.segments,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, value, _) => SegmentedSetting<T>(
        icon: icon,
        title: title,
        segments: segments,
        selected: value,
        onChanged: (v) => _writeAndNotify(pref, v, onAfterWrite),
      ),
    );
  }
}

/// ListTile that opens [showColorInputDialog] for a hex-string [Pref].
/// Trailing widget is a small color swatch.
class SettingColorTile extends StatelessWidget {
  final Pref<String> pref;
  final IconData icon;
  final String title;
  final String? subtitle;
  final FutureOr<void> Function(String hex)? onAfterWrite;

  const SettingColorTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.listenable(pref),
      builder: (_, hex, _) => _SettingRow(
        icon: icon,
        title: title,
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: hexToColor(hex),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        onTap: () => showColorInputDialog(
          context: context,
          title: title,
          currentHex: hex,
          onSave: (v) => _writeAndNotify(pref, v, onAfterWrite),
        ),
      ),
    );
  }
}
