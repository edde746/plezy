import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../screens/settings/settings_utils.dart';
import '../services/settings_service.dart';
import 'app_icon.dart';
import 'settings_section.dart';

/// Reactive setting tiles bound to a [Pref] via [SettingsService.listenable].
/// Eliminates the field-mirror + setState + manual reload pattern that used to
/// surround every settings row.

class _TileBase {
  static SettingsService get _svc => SettingsService.instanceOrNull!;
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
    final svc = _TileBase._svc;
    return ValueListenableBuilder<bool>(
      valueListenable: svc.listenable(pref),
      builder: (_, value, _) => SwitchListTile(
        focusNode: focusNode,
        secondary: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: enabled
            ? (v) async {
                await svc.write(pref, v);
                final callback = onAfterWrite;
                if (callback != null) await callback(v);
              }
            : null,
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
    return ListTile(
      focusNode: focusNode,
      leading: AppIcon(icon, fill: 1),
      title: Text(title),
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
    final svc = _TileBase._svc;
    return ValueListenableBuilder<int>(
      valueListenable: svc.listenable(pref),
      builder: (_, value, _) => ListTile(
        leading: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: Text(subtitleBuilder(value)),
        trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
        onTap: () => showNumericInputDialog(
          context: context,
          title: title,
          labelText: labelText,
          suffixText: suffixText,
          min: min,
          max: max,
          currentValue: value,
          onSave: (v) async {
            await svc.write(pref, v);
            final callback = onAfterWrite;
            if (callback != null) await callback(v);
          },
        ),
      ),
    );
  }
}

/// ListTile that opens [showSelectionDialog] and writes the chosen value.
/// [encode]/[decode] map between the [Pref<S>] storage type and the option
/// type [T] (e.g. enum-stored-as-string preset → [TranscodeQualityPreset]).
class SettingSelectionTile<T, S> extends StatelessWidget {
  final Pref<S> pref;
  final IconData icon;
  final String title;
  final String Function(T) subtitleBuilder;
  final List<DialogOption<T>> options;
  final T Function(S) decode;
  final S Function(T) encode;
  final FutureOr<void> Function(T)? onAfterWrite;

  const SettingSelectionTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.subtitleBuilder,
    required this.options,
    required this.decode,
    required this.encode,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    final svc = _TileBase._svc;
    return ValueListenableBuilder<S>(
      valueListenable: svc.listenable(pref),
      builder: (_, raw, _) {
        final value = decode(raw);
        return ListTile(
          leading: AppIcon(icon, fill: 1),
          title: Text(title),
          subtitle: Text(subtitleBuilder(value)),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () async {
            final picked = await showSelectionDialog<T>(
              context: context,
              title: title,
              options: options,
              currentValue: value,
            );
            if (picked == null) return;
            await svc.write(pref, encode(picked));
            final callback = onAfterWrite;
            if (callback != null) await callback(picked);
          },
        );
      },
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
    final svc = _TileBase._svc;
    return ValueListenableBuilder<String>(
      valueListenable: svc.listenable(pref),
      builder: (_, value, _) => ListTile(
        leading: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
        onTap: () => showRegexInputDialog(
          context: context,
          title: title,
          currentValue: value,
          defaultValue: defaultValue,
          onSave: (v) async {
            await svc.write(pref, v);
            final callback = onAfterWrite;
            if (callback != null) await callback(v);
          },
        ),
      ),
    );
  }
}

/// SegmentedSetting bound to a [Pref<T>]. Use [encode]/[decode] when the
/// stored type differs from the segment type (e.g. bool stored, segments
/// over enum).
class SettingSegmentedTile<T, S> extends StatelessWidget {
  final Pref<S> pref;
  final IconData icon;
  final String title;
  final List<ButtonSegment<T>> segments;
  final T Function(S) decode;
  final S Function(T) encode;
  final FutureOr<void> Function(T)? onAfterWrite;

  const SettingSegmentedTile({
    super.key,
    required this.pref,
    required this.icon,
    required this.title,
    required this.segments,
    required this.decode,
    required this.encode,
    this.onAfterWrite,
  });

  @override
  Widget build(BuildContext context) {
    final svc = _TileBase._svc;
    return ValueListenableBuilder<S>(
      valueListenable: svc.listenable(pref),
      builder: (_, raw, _) {
        final value = decode(raw);
        return SegmentedSetting<T>(
          icon: icon,
          title: title,
          segments: segments,
          selected: value,
          onChanged: (v) async {
            await svc.write(pref, encode(v));
            final callback = onAfterWrite;
            if (callback != null) await callback(v);
          },
        );
      },
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
    final svc = _TileBase._svc;
    return ValueListenableBuilder<String>(
      valueListenable: svc.listenable(pref),
      builder: (_, hex, _) => ListTile(
        leading: AppIcon(icon, fill: 1),
        title: Text(title),
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
          onSave: (v) async {
            await svc.write(pref, v);
            final callback = onAfterWrite;
            if (callback != null) await callback(v);
          },
        ),
      ),
    );
  }
}
