import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../focus/dpad_navigator.dart';
import '../focus/dpad_select_long_press_controller.dart';
import '../focus/focusable_tile_mixin.dart';
import '../utils/platform_detector.dart';
import 'clickable_cursor.dart';

/// A ListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native ListTile focus support - no custom styling wrapper.
/// The focusNode allows programmatic focus control (e.g., auto-focus first item).
class FocusableListTile extends StatefulWidget {
  final Widget? title;

  final Widget? subtitle;

  final Widget? leading;

  final Widget? trailing;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  final bool dense;

  final bool enabled;

  final bool selected;

  /// Optional FocusNode for keyboard/controller navigation.
  final FocusNode? focusNode;

  final bool autofocus;

  final EdgeInsetsGeometry? contentPadding;

  final VisualDensity? visualDensity;

  final double? horizontalTitleGap;

  final double? minLeadingWidth;

  const FocusableListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.dense = true,
    this.enabled = true,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
    this.visualDensity = const VisualDensity(vertical: -3),
    this.horizontalTitleGap,
    this.minLeadingWidth,
  });

  @override
  State<FocusableListTile> createState() => _FocusableListTileState();
}

class _FocusableListTileState extends State<FocusableListTile> with FocusableTileStateMixin<FocusableListTile> {
  final _selectLongPress = DpadSelectLongPressController();

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  void dispose() {
    _selectLongPress.dispose();
    super.dispose();
  }

  /// Material's [ListTile.onLongPress] is touch-only, so a remote/keyboard
  /// could never reach it. When a long-press action exists, hold SELECT (or
  /// press the context-menu key) triggers it and a short SELECT still taps.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.onLongPress == null || !widget.enabled || !effectiveFocusNode.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }

    if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
      if (event is KeyUpEvent && event.logicalKey.isSelectKey) _selectLongPress.reset();
      return KeyEventResult.handled;
    }

    if (event.logicalKey.isSelectKey) {
      return _selectLongPress.handleKeyEvent(
        event,
        isOwnerActive: () => mounted,
        onShortPress: () => widget.onTap?.call(),
        // Read at fire time: the tile may have rebuilt (new selection state)
        // during the hold.
        onLongPress: () => widget.onLongPress?.call(),
      );
    }

    if (event.isActionable && event.logicalKey.isContextMenuKey) {
      _selectLongPress.reset();
      widget.onLongPress?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final automotive = PlatformDetector.isAutomotive();

    // Always mounted, even without onLongPress: adding/removing this wrapper
    // would remount the ListTile and drop its ink focus highlight.
    // _handleKeyEvent ignores events while onLongPress is null.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) {
        if (!hasFocus) _selectLongPress.reset();
      },
      onKeyEvent: _handleKeyEvent,
      child: _buildTile(automotive),
    );
  }

  Widget _buildTile(bool automotive) {
    return MouseRegion(
      cursor: widget.enabled && (widget.onTap != null || widget.onLongPress != null)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: ListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        leading: widget.leading,
        trailing: widget.trailing,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        dense: automotive ? false : widget.dense,
        enabled: widget.enabled,
        selected: widget.selected,
        contentPadding: widget.contentPadding,
        visualDensity: automotive ? VisualDensity.standard : widget.visualDensity,
        focusNode: effectiveFocusNode,
        autofocus: widget.autofocus,
        horizontalTitleGap: widget.horizontalTitleGap,
        minLeadingWidth: widget.minLeadingWidth,
      ),
    );
  }
}

/// A SwitchListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native SwitchListTile focus support - no custom styling wrapper.
class FocusableSwitchListTile extends StatefulWidget {
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

  /// Visual density for the list tile.
  final VisualDensity? visualDensity;

  /// Content padding, e.g. to align with sibling rows. Null uses the
  /// SwitchListTile default.
  final EdgeInsetsGeometry? contentPadding;

  /// Horizontal gap between the leading/secondary widget and title.
  final double? horizontalTitleGap;

  /// Minimum width reserved for the leading/secondary widget.
  final double? minLeadingWidth;

  const FocusableSwitchListTile({
    super.key,
    this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.dense = true,
    this.focusNode,
    this.autofocus = false,
    this.visualDensity = const VisualDensity(vertical: -3),
    this.contentPadding,
    this.horizontalTitleGap,
    this.minLeadingWidth,
  });

  @override
  State<FocusableSwitchListTile> createState() => _FocusableSwitchListTileState();
}

class _FocusableSwitchListTileState extends State<FocusableSwitchListTile>
    with FocusableTileStateMixin<FocusableSwitchListTile> {
  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    final automotive = PlatformDetector.isAutomotive();
    return ClickableCursor(
      enabled: widget.onChanged != null,
      child: SwitchListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        secondary: widget.secondary,
        value: widget.value,
        onChanged: widget.onChanged,
        dense: automotive ? false : widget.dense,
        visualDensity: automotive ? VisualDensity.standard : widget.visualDensity,
        contentPadding: widget.contentPadding,
        focusNode: effectiveFocusNode,
        autofocus: widget.autofocus,
        horizontalTitleGap: widget.horizontalTitleGap,
        minLeadingWidth: widget.minLeadingWidth,
      ),
    );
  }
}

/// A CheckboxListTile that accepts a FocusNode for keyboard/controller navigation.
///
/// Uses Flutter's native CheckboxListTile focus support - no custom styling wrapper.
class FocusableCheckboxListTile extends StatefulWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final bool dense;
  final FocusNode? focusNode;
  final bool autofocus;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? contentPadding;
  final ListTileControlAffinity controlAffinity;

  const FocusableCheckboxListTile({
    super.key,
    this.title,
    this.subtitle,
    this.secondary,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.dense = true,
    this.focusNode,
    this.autofocus = false,
    this.visualDensity = const VisualDensity(vertical: -3),
    this.contentPadding,
    this.controlAffinity = ListTileControlAffinity.platform,
  });

  @override
  State<FocusableCheckboxListTile> createState() => _FocusableCheckboxListTileState();
}

class _FocusableCheckboxListTileState extends State<FocusableCheckboxListTile>
    with FocusableTileStateMixin<FocusableCheckboxListTile> {
  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  Widget build(BuildContext context) {
    final automotive = PlatformDetector.isAutomotive();
    return ClickableCursor(
      enabled: widget.onChanged != null,
      child: CheckboxListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        secondary: widget.secondary,
        value: widget.value,
        onChanged: widget.onChanged,
        tristate: widget.tristate,
        dense: automotive ? false : widget.dense,
        visualDensity: automotive ? VisualDensity.standard : widget.visualDensity,
        contentPadding: widget.contentPadding,
        focusNode: effectiveFocusNode,
        autofocus: widget.autofocus,
        controlAffinity: widget.controlAffinity,
      ),
    );
  }
}
