import 'package:flutter/material.dart';
import '../focus/dpad_navigator.dart';

/// A ListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native ListTile focus support - no custom styling wrapper.
/// The focusNode allows programmatic focus control (e.g., auto-focus first item).
class FocusableListTile extends StatefulWidget {
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

  /// If true, consumes the first select key event to avoid accidental activation.
  final bool suppressInitialSelect;

  /// An optional color to display behind the menu item when being hovered.
  final Color? hoverColor;

  /// An optional color for the text of the list tile.
  final Color? textColor;

  /// An optional color for the icon of the list tile.
  final Color? iconColor;

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
    this.suppressInitialSelect = false,
    this.hoverColor,
    this.textColor,
    this.iconColor,
  });

  @override
  State<FocusableListTile> createState() => _FocusableListTileState();
}

class _FocusableListTileState extends State<FocusableListTile> {
  bool _suppressionConsumed = false;
  bool _isHoveredOrFocused = false;

  @override
  Widget build(BuildContext context) {
    // When hovered/focused with a custom hoverColor, use onError-style foreground
    // to keep text readable against the colored background.
    final needsContrastSwap = _isHoveredOrFocused && widget.hoverColor != null && widget.textColor != null;
    final textColor = needsContrastSwap ? Theme.of(context).colorScheme.onError : widget.textColor;
    final iconColor = needsContrastSwap ? Theme.of(context).colorScheme.onError : widget.iconColor;

    Widget tile = MouseRegion(
      onEnter: widget.hoverColor != null ? (_) => setState(() => _isHoveredOrFocused = true) : null,
      onExit: widget.hoverColor != null ? (_) => setState(() => _isHoveredOrFocused = false) : null,
      child: ListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        leading: widget.leading,
        trailing: widget.trailing,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        dense: widget.dense,
        enabled: widget.enabled,
        selected: widget.selected,
        contentPadding: widget.contentPadding,
        focusNode: widget.suppressInitialSelect ? null : widget.focusNode,
        autofocus: widget.suppressInitialSelect ? false : widget.autofocus,
        hoverColor: widget.hoverColor,
        textColor: textColor,
        iconColor: iconColor,
      ),
    );

    if (!widget.suppressInitialSelect) {
      return tile;
    }

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
          return KeyEventResult.handled;
        }
        if (!_suppressionConsumed && event.logicalKey.isSelectKey) {
          _suppressionConsumed = true;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: tile,
    );
  }
}

/// A RadioListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native RadioListTile focus support - no custom styling wrapper.
/// Requires a [RadioGroup] ancestor to manage selection state.
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
