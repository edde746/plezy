import 'package:flutter/material.dart';
import 'focusable_wrapper.dart';

/// A focusable list item for settings screens and menus.
///
/// Wraps a ListTile with focus support for D-pad navigation.
///
/// Example:
/// ```dart
/// FocusableListItem(
///   leading: Icon(Icons.settings),
///   title: Text('Setting Name'),
///   subtitle: Text('Description'),
///   onTap: () => openSetting(),
/// )
/// ```
class FocusableListItem extends StatelessWidget {
  /// Leading widget (typically an icon).
  final Widget? leading;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Trailing widget.
  final Widget? trailing;

  /// Called when the item is tapped or selected.
  final VoidCallback? onTap;

  /// Optional external FocusNode.
  final FocusNode? focusNode;

  /// Whether this item should autofocus.
  final bool autofocus;

  /// Whether the item is enabled.
  final bool enabled;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Content padding.
  final EdgeInsetsGeometry? contentPadding;

  const FocusableListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: enabled ? onTap : null,
      borderRadius: borderRadius,
      canRequestFocus: enabled,
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        enabled: enabled,
        contentPadding: contentPadding,
      ),
    );
  }
}

/// A focusable switch list item for boolean settings.
///
/// Example:
/// ```dart
/// FocusableSwitchListItem(
///   secondary: Icon(Icons.dark_mode),
///   title: Text('Dark Mode'),
///   value: isDarkMode,
///   onChanged: (value) => setDarkMode(value),
/// )
/// ```
class FocusableSwitchListItem extends StatelessWidget {
  /// Secondary widget (typically an icon), displayed before the title.
  final Widget? secondary;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// The current value of the switch.
  final bool value;

  /// Called when the switch value changes.
  final ValueChanged<bool>? onChanged;

  /// Optional external FocusNode.
  final FocusNode? focusNode;

  /// Whether this item should autofocus.
  final bool autofocus;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Content padding.
  final EdgeInsetsGeometry? contentPadding;

  const FocusableSwitchListItem({
    super.key,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 12.0,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: onChanged != null ? () => onChanged!(!value) : null,
      borderRadius: borderRadius,
      canRequestFocus: onChanged != null,
      child: SwitchListTile(
        secondary: secondary,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        contentPadding: contentPadding,
      ),
    );
  }
}

/// A focusable checkbox list item.
///
/// Example:
/// ```dart
/// FocusableCheckboxListItem(
///   title: Text('Enable Feature'),
///   value: isEnabled,
///   onChanged: (value) => setEnabled(value ?? false),
/// )
/// ```
class FocusableCheckboxListItem extends StatelessWidget {
  /// Secondary widget (typically an icon).
  final Widget? secondary;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// The current value of the checkbox.
  final bool? value;

  /// Called when the checkbox value changes.
  final ValueChanged<bool?>? onChanged;

  /// Optional external FocusNode.
  final FocusNode? focusNode;

  /// Whether this item should autofocus.
  final bool autofocus;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Content padding.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the checkbox is tristate.
  final bool tristate;

  const FocusableCheckboxListItem({
    super.key,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 12.0,
    this.contentPadding,
    this.tristate = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: onChanged != null
          ? () {
              if (tristate) {
                // Cycle through: false -> true -> null -> false
                if (value == null) {
                  onChanged!(false);
                } else if (value!) {
                  onChanged!(null);
                } else {
                  onChanged!(true);
                }
              } else {
                onChanged!(!(value ?? false));
              }
            }
          : null,
      borderRadius: borderRadius,
      canRequestFocus: onChanged != null,
      child: CheckboxListTile(
        secondary: secondary,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        contentPadding: contentPadding,
        tristate: tristate,
      ),
    );
  }
}

/// A focusable radio list item.
///
/// Example:
/// ```dart
/// FocusableRadioListItem<String>(
///   title: Text('Option A'),
///   value: 'a',
///   groupValue: selectedValue,
///   onChanged: (value) => setSelected(value),
/// )
/// ```
class FocusableRadioListItem<T> extends StatelessWidget {
  /// Secondary widget (typically an icon).
  final Widget? secondary;

  /// Title widget.
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for the group.
  final T? groupValue;

  /// Called when this radio button is selected.
  final ValueChanged<T?>? onChanged;

  /// Optional external FocusNode.
  final FocusNode? focusNode;

  /// Whether this item should autofocus.
  final bool autofocus;

  /// Border radius for the focus indicator.
  final double borderRadius;

  /// Content padding.
  final EdgeInsetsGeometry? contentPadding;

  const FocusableRadioListItem({
    super.key,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius = 12.0,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: focusNode,
      autofocus: autofocus,
      onSelect: onChanged != null ? () => onChanged!(value) : null,
      borderRadius: borderRadius,
      canRequestFocus: onChanged != null,
      child: RadioListTile<T>(
        secondary: secondary,
        title: title,
        subtitle: subtitle,
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        contentPadding: contentPadding,
      ),
    );
  }
}
