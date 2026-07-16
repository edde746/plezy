import 'package:flutter/material.dart';

import '../focus/focusable_wrapper.dart';
import 'app_menu.dart';

/// An [AppMenuButton] that can be focused and opened with D-pad select.
class FocusablePopupMenuButton<T> extends StatefulWidget {
  final Widget? icon;
  final Widget? child;
  final String? tooltip;
  final bool enabled;
  final AppMenuEntryBuilder<T> itemBuilder;
  final ValueChanged<T>? onSelected;
  final GlobalKey<AppMenuButtonState<T>>? menuKey;
  final AppMenuAnchorAlignment anchorAlignment;
  final Offset alignmentOffset;
  final double minWidth;
  final double? maxWidth;
  final EdgeInsetsGeometry? childPadding;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final String? semanticLabel;
  final double borderRadius;
  final bool useBackgroundFocus;
  final bool enableLongPress;

  const FocusablePopupMenuButton({
    super.key,
    this.icon,
    this.child,
    this.tooltip,
    this.enabled = true,
    required this.itemBuilder,
    this.onSelected,
    this.menuKey,
    this.anchorAlignment = AppMenuAnchorAlignment.start,
    this.alignmentOffset = Offset.zero,
    this.minWidth = 220,
    this.maxWidth,
    this.childPadding,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.semanticLabel,
    this.borderRadius = 100,
    this.useBackgroundFocus = true,
    this.enableLongPress = true,
  }) : assert(icon != null || child != null, 'FocusablePopupMenuButton requires icon or child');

  @override
  State<FocusablePopupMenuButton<T>> createState() => _FocusablePopupMenuButtonState<T>();
}

class _FocusablePopupMenuButtonState<T> extends State<FocusablePopupMenuButton<T>> {
  final _ownedMenuKey = GlobalKey<AppMenuButtonState<T>>();

  GlobalKey<AppMenuButtonState<T>> get _menuKey => widget.menuKey ?? _ownedMenuKey;

  void _showMenu() => _menuKey.currentState?.showButtonMenu(focusFirstItem: true);

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: widget.focusNode,
      canRequestFocus: widget.enabled,
      disableScale: true,
      borderRadius: widget.borderRadius,
      useBackgroundFocus: widget.useBackgroundFocus,
      descendantsAreFocusable: false,
      semanticLabel: widget.semanticLabel ?? widget.tooltip,
      enableLongPress: widget.enableLongPress,
      onNavigateUp: widget.onNavigateUp,
      onNavigateDown: widget.onNavigateDown,
      onNavigateLeft: widget.onNavigateLeft,
      onNavigateRight: widget.onNavigateRight,
      onSelect: widget.enabled ? _showMenu : null,
      onLongPress: widget.enabled && widget.enableLongPress ? _showMenu : null,
      child: AppMenuButton<T>(
        key: _menuKey,
        icon: widget.icon,
        tooltip: widget.tooltip,
        enabled: widget.enabled,
        onSelected: widget.onSelected,
        entriesBuilder: widget.itemBuilder,
        anchorAlignment: widget.anchorAlignment,
        alignmentOffset: widget.alignmentOffset,
        minWidth: widget.minWidth,
        maxWidth: widget.maxWidth,
        childPadding: widget.childPadding,
        child: widget.child,
      ),
    );
  }
}
