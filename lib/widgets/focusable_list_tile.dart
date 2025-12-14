import 'package:flutter/material.dart';

/// A ListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native ListTile focus support - no custom styling wrapper.
/// The focusNode allows programmatic focus control (e.g., auto-focus first item).
class FocusableListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget? title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// A widget to display before the title.
  final Widget? leading;

  /// A widget to display after the title.
  final Widget? trailing;

  /// Called when the user taps this list tile.
  final VoidCallback? onTap;

  /// Called when the user long-presses this list tile.
  final VoidCallback? onLongPress;

  /// Whether this list tile is part of a vertically dense list.
  final bool dense;

  /// Whether this list tile is interactive.
  final bool enabled;

  /// If true, the tile is rendered with a selected highlight.
  final bool selected;

  /// Optional FocusNode for keyboard/controller navigation.
  final FocusNode? focusNode;

  /// Whether this tile should autofocus when first built.
  final bool autofocus;

  /// The tile's internal padding.
  final EdgeInsetsGeometry? contentPadding;

  const FocusableListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.enabled = true,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      dense: dense,
      enabled: enabled,
      selected: selected,
      contentPadding: contentPadding,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// A RadioListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native RadioListTile focus support - no custom styling wrapper.
class FocusableRadioListTile<T> extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget? title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// A widget to display on the opposite side from the radio.
  final Widget? secondary;

  /// The value represented by this radio button.
  final T value;

  /// Whether this radio button is part of a vertically dense list.
  final bool dense;

  /// Optional FocusNode for keyboard/controller navigation.
  final FocusNode? focusNode;

  /// Whether this tile should autofocus when first built.
  final bool autofocus;

  /// Whether the radio tile is interactive.
  final bool? enabled;

  const FocusableRadioListTile({
    super.key,
    this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    this.dense = false,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      value: value,
      dense: dense,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
    );
  }
}

/// A SwitchListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native SwitchListTile focus support - no custom styling wrapper.
class FocusableSwitchListTile extends StatelessWidget {
  /// The primary content of the list tile.
  final Widget? title;

  /// Additional content displayed below the title.
  final Widget? subtitle;

  /// A widget to display on the opposite side from the switch.
  final Widget? secondary;

  /// Whether this switch is checked.
  final bool value;

  /// Called when the user toggles the switch.
  final ValueChanged<bool>? onChanged;

  /// Whether this switch is part of a vertically dense list.
  final bool dense;

  /// Optional FocusNode for keyboard/controller navigation.
  final FocusNode? focusNode;

  /// Whether this tile should autofocus when first built.
  final bool autofocus;

  const FocusableSwitchListTile({
    super.key,
    this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.dense = false,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      value: value,
      onChanged: onChanged,
      dense: dense,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}
