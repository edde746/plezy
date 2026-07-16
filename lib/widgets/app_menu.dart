import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focusable_tile_mixin.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../theme/mono_tokens.dart';
import '../utils/focus_utils.dart';
import 'app_icon.dart';
import 'clickable_cursor.dart';
import 'overlay_sheet.dart';

typedef AppMenuEntryBuilder<T> = List<AppMenuEntry<T>> Function(BuildContext context);

enum AppMenuAnchorAlignment { start, end, center }

abstract class AppMenuEntry<T> {
  const AppMenuEntry();
}

class AppMenuItem<T> extends AppMenuEntry<T> {
  final T value;
  final String? label;
  final Widget? child;
  final String? subtitle;
  final Widget? subtitleWidget;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;
  final bool selected;
  final bool destructive;
  final Color? foregroundColor;
  final Color? stateLayerColor;
  final String? semanticLabel;

  const AppMenuItem({
    required this.value,
    this.label,
    this.child,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.selected = false,
    this.destructive = false,
    this.foregroundColor,
    this.stateLayerColor,
    this.semanticLabel,
  }) : assert(label != null || child != null, 'AppMenuItem requires either label or child'),
       assert(subtitle == null || subtitleWidget == null, 'Provide subtitle or subtitleWidget, not both'),
       assert(icon == null || leading == null, 'Provide icon or leading, not both');
}

class AppMenuDivider<T> extends AppMenuEntry<T> {
  const AppMenuDivider();
}

class AppMenuHeader<T> extends AppMenuEntry<T> {
  final String? label;
  final Widget? child;

  const AppMenuHeader({this.label, this.child})
    : assert(label != null || child != null, 'AppMenuHeader requires either label or child');
}

Future<T?> showAppMenu<T>(
  BuildContext context, {
  required List<AppMenuEntry<T>> entries,
  Offset? position,
  Rect? anchorRect,
  AppMenuAnchorAlignment anchorAlignment = AppMenuAnchorAlignment.start,
  bool focusFirstItem = false,
  double minWidth = 220,
  double? maxWidth,
}) {
  assert(position != null || anchorRect != null, 'showAppMenu requires a position or anchorRect');

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (dialogContext, _, _) => _AppMenuPopup<T>(
      entries: entries,
      position: position,
      anchorRect: anchorRect,
      anchorAlignment: anchorAlignment,
      focusFirstItem: focusFirstItem,
      minWidth: minWidth,
      maxWidth: maxWidth,
    ),
    transitionBuilder: (dialogContext, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      final alignment = _transitionAlignment(dialogContext, position: position, anchorRect: anchorRect);

      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform.scale(
            scale: 0.96 + curved.value * 0.04,
            alignment: alignment,
            transformHitTests: false,
            child: child,
          ),
        ),
      );
    },
  );
}

Future<T?> showAdaptiveAppMenu<T>(
  BuildContext context, {
  required List<AppMenuEntry<T>> entries,
  String? title,
  Offset? position,
  Rect? anchorRect,
  AppMenuAnchorAlignment anchorAlignment = AppMenuAnchorAlignment.start,
  bool focusFirstItem = false,
  double minWidth = 220,
  double? maxWidth,
  bool isScrollControlled = false,
}) {
  // ThemeData.platform follows the real target platform by default, including
  // Android TV and tvOS, while remaining overrideable in widget tests.
  final platform = Theme.of(context).platform;
  if (platform == TargetPlatform.iOS || platform == TargetPlatform.android) {
    return OverlaySheetController.showAdaptive<T>(
      context,
      showDragHandle: true,
      isScrollControlled: isScrollControlled,
      builder: (context) => AppMenuSheet<T>(title: title, entries: entries, focusFirstItem: focusFirstItem),
    );
  }

  return showAppMenu<T>(
    context,
    entries: entries,
    position: position,
    anchorRect: anchorRect,
    anchorAlignment: anchorAlignment,
    focusFirstItem: focusFirstItem,
    minWidth: minWidth,
    maxWidth: maxWidth,
  );
}

Alignment _transitionAlignment(BuildContext context, {Offset? position, Rect? anchorRect}) {
  final size = MediaQuery.sizeOf(context);
  final origin = position ?? anchorRect?.center ?? Offset(size.width / 2, size.height / 2);
  return Alignment(
    size.width <= 0 ? 0 : ((origin.dx / size.width) * 2 - 1).clamp(-1.0, 1.0).toDouble(),
    size.height <= 0 ? 0 : ((origin.dy / size.height) * 2 - 1).clamp(-1.0, 1.0).toDouble(),
  );
}

class AppMenuButton<T> extends StatefulWidget {
  final Widget? icon;
  final Widget? child;
  final String? tooltip;
  final bool enabled;
  final AppMenuEntryBuilder<T> entriesBuilder;
  final ValueChanged<T>? onSelected;
  final AppMenuAnchorAlignment anchorAlignment;
  final Offset alignmentOffset;
  final double minWidth;
  final double? maxWidth;
  final EdgeInsetsGeometry? childPadding;

  const AppMenuButton({
    super.key,
    this.icon,
    this.child,
    this.tooltip,
    this.enabled = true,
    required this.entriesBuilder,
    this.onSelected,
    this.anchorAlignment = AppMenuAnchorAlignment.start,
    this.alignmentOffset = Offset.zero,
    this.minWidth = 220,
    this.maxWidth,
    this.childPadding,
  }) : assert(icon != null || child != null, 'AppMenuButton requires icon or child');

  @override
  State<AppMenuButton<T>> createState() => AppMenuButtonState<T>();
}

class AppMenuButtonState<T> extends State<AppMenuButton<T>> {
  Future<T?> showButtonMenu({bool focusFirstItem = true}) async {
    if (!widget.enabled) return null;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final topLeft = renderBox.localToGlobal(Offset.zero) + widget.alignmentOffset;
    final anchorRect = Rect.fromLTWH(topLeft.dx, topLeft.dy, renderBox.size.width, renderBox.size.height);
    final selected = await showAppMenu<T>(
      context,
      entries: widget.entriesBuilder(context),
      anchorRect: anchorRect,
      anchorAlignment: widget.anchorAlignment,
      focusFirstItem: focusFirstItem,
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
    );
    if (!mounted || selected == null) return selected;
    widget.onSelected?.call(selected);
    return selected;
  }

  Future<void> _handlePressed() async {
    await showButtonMenu(focusFirstItem: InputModeTracker.isKeyboardMode(context, listen: false));
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child != null) {
      final content = Padding(padding: widget.childPadding ?? EdgeInsets.zero, child: child);
      final button = ClickableCursor(
        enabled: widget.enabled,
        child: InkWell(
          onTap: widget.enabled ? _handlePressed : null,
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          child: content,
        ),
      );
      final tooltip = widget.tooltip;
      return tooltip == null ? button : Tooltip(message: tooltip, child: button);
    }

    return IconButton(icon: widget.icon!, tooltip: widget.tooltip, onPressed: widget.enabled ? _handlePressed : null);
  }
}

class AppMenuSheet<T> extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<AppMenuEntry<T>> entries;
  final bool focusFirstItem;
  final ValueChanged<T>? onSelected;
  final bool closeOnSelected;

  const AppMenuSheet({
    super.key,
    this.title,
    this.titleWidget,
    required this.entries,
    this.focusFirstItem = false,
    this.onSelected,
    this.closeOnSelected = true,
  }) : assert(title == null || titleWidget == null, 'Provide title or titleWidget, not both');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (titleWidget != null || title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child:
                titleWidget ??
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        Flexible(
          child: SingleChildScrollView(
            child: AppMenuList<T>(
              entries: entries,
              focusFirstItem: focusFirstItem,
              onSelected: (value) {
                if (closeOnSelected) OverlaySheetController.closeAdaptive(context, value);
                onSelected?.call(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class AppMenuList<T> extends StatefulWidget {
  final List<AppMenuEntry<T>> entries;
  final bool focusFirstItem;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const AppMenuList({
    super.key,
    required this.entries,
    required this.onSelected,
    this.focusFirstItem = false,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
  });

  @override
  State<AppMenuList<T>> createState() => _AppMenuListState<T>();
}

class _AppMenuListState<T> extends State<AppMenuList<T>> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'AppMenuInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var initialFocusAssigned = false;
    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in widget.entries)
            switch (entry) {
              AppMenuItem<T>() => _buildItem(
                entry,
                initialFocusAssigned: () {
                  if (initialFocusAssigned || !entry.enabled) return false;
                  initialFocusAssigned = true;
                  return widget.focusFirstItem;
                }(),
              ),
              AppMenuDivider<T>() => const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
              AppMenuHeader<T>() => _AppMenuHeaderTile(entry: entry),
              _ => const SizedBox.shrink(),
            },
        ],
      ),
    );
  }

  Widget _buildItem(AppMenuItem<T> item, {required bool initialFocusAssigned}) {
    return AppMenuItemTile<T>(
      item: item,
      focusNode: initialFocusAssigned ? _initialFocusNode : null,
      onPressed: item.enabled ? () => widget.onSelected(item.value) : null,
    );
  }
}

class AppMenuItemTile<T> extends StatefulWidget {
  final AppMenuItem<T> item;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;

  const AppMenuItemTile({super.key, required this.item, this.onPressed, this.focusNode});

  @override
  State<AppMenuItemTile<T>> createState() => _AppMenuItemTileState<T>();
}

class _AppMenuItemTileState<T> extends State<AppMenuItemTile<T>> with FocusableTileStateMixin<AppMenuItemTile<T>> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  FocusNode? get widgetFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    initFocusNode();
    effectiveFocusNode.addListener(_updateFocusedState);
  }

  @override
  void didUpdateWidget(AppMenuItemTile<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      effectiveFocusNode.removeListener(_updateFocusedState);
      updateFocusNode(oldWidget.focusNode);
      effectiveFocusNode.addListener(_updateFocusedState);
      _isFocused = effectiveFocusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    effectiveFocusNode.removeListener(_updateFocusedState);
    disposeFocusNode();
    super.dispose();
  }

  void _updateFocusedState() {
    final focused = effectiveFocusNode.hasFocus;
    if (_isFocused != focused) setState(() => _isFocused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = item.enabled && widget.onPressed != null;
    final active = enabled && ((_isFocused && InputModeTracker.isKeyboardMode(context)) || _isHovered);
    final foreground = _foregroundColor(context, active: active);
    final subtitleColor = foreground.withValues(alpha: active && item.stateLayerColor != null ? 0.86 : 0.68);
    final background = _backgroundColor(context, active: active);

    final leading = item.leading ?? (item.icon != null ? AppIcon(item.icon!, fill: 1, size: 20) : null);
    final trailing = item.trailing ?? (item.selected ? AppIcon(Symbols.check_rounded, size: 18) : null);
    final subtitle = item.subtitleWidget ?? (item.subtitle != null ? Text(item.subtitle!) : null);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: item.selected,
      label: item.semanticLabel,
      child: Focus(
        focusNode: effectiveFocusNode,
        canRequestFocus: enabled,
        onKeyEvent: (node, event) {
          if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) return KeyEventResult.handled;
          return dpadKeyHandler(onSelect: enabled ? widget.onPressed : null, trapHorizontalEdges: true)(node, event);
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: enabled ? (_) => setState(() => _isHovered = true) : null,
          onExit: enabled ? (_) => setState(() => _isHovered = false) : null,
          child: ClickableCursor(
            enabled: enabled,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? widget.onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: AnimatedContainer(
                  duration: tokens(context).fast,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                  ),
                  constraints: BoxConstraints(minHeight: subtitle == null ? 40 : 52),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        SizedBox(
                          width: 24,
                          child: IconTheme.merge(
                            data: IconThemeData(color: foreground),
                            child: leading,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DefaultTextStyle.merge(
                              style: textTheme.bodyMedium?.copyWith(
                                color: enabled ? foreground : colorScheme.onSurface.withValues(alpha: 0.38),
                                fontWeight: item.selected ? FontWeight.w600 : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: item.child ?? Text(item.label!),
                            ),
                            if (subtitle != null)
                              DefaultTextStyle.merge(
                                style: textTheme.labelSmall?.copyWith(
                                  color: enabled ? subtitleColor : colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: subtitle,
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        IconTheme.merge(
                          data: IconThemeData(color: foreground),
                          child: trailing,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _foregroundColor(BuildContext context, {required bool active}) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;
    if (active && item.stateLayerColor != null) return colorScheme.onError;
    if (item.foregroundColor != null) return item.foregroundColor!;
    if (item.destructive) return _destructiveMenuForeground(context);
    if (item.selected) return colorScheme.primary;
    return colorScheme.onSurface;
  }

  Color _backgroundColor(BuildContext context, {required bool active}) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;
    if (active && item.stateLayerColor != null) return item.stateLayerColor!;
    if (active) return colorScheme.onSurface.withValues(alpha: 0.08);
    if (item.selected) return colorScheme.primary.withValues(alpha: 0.12);
    return Colors.transparent;
  }
}

class _AppMenuHeaderTile<T> extends StatelessWidget {
  final AppMenuHeader<T> entry;

  const _AppMenuHeaderTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DefaultTextStyle.merge(
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: entry.child ?? Text(entry.label!),
      ),
    );
  }
}

class _AppMenuPopup<T> extends StatefulWidget {
  final List<AppMenuEntry<T>> entries;
  final Offset? position;
  final Rect? anchorRect;
  final AppMenuAnchorAlignment anchorAlignment;
  final bool focusFirstItem;
  final double minWidth;
  final double? maxWidth;

  const _AppMenuPopup({
    required this.entries,
    required this.position,
    required this.anchorRect,
    required this.anchorAlignment,
    required this.focusFirstItem,
    required this.minWidth,
    required this.maxWidth,
  });

  @override
  State<_AppMenuPopup<T>> createState() => _AppMenuPopupState<T>();
}

class _AppMenuPopupState<T> extends State<_AppMenuPopup<T>> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    const edgePadding = 8.0;
    final desiredWidth = widget.maxWidth ?? math.max(widget.minWidth, _estimateMenuWidth(context));
    final menuWidth = desiredWidth.clamp(
      widget.minWidth,
      math.max(widget.minWidth, screenSize.width - edgePadding * 2),
    );
    final estimatedHeight = _estimateMenuHeight(widget.entries);
    final availableHeight = math.max(0.0, screenSize.height - edgePadding * 2);
    final menuHeight = estimatedHeight.clamp(0.0, availableHeight).toDouble();
    final (:left, :top) = _resolvePosition(screenSize, menuWidth.toDouble(), menuHeight, edgePadding);

    return FocusScope(
      autofocus: false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) return KeyEventResult.handled;
          if (BackKeyUpSuppressor.consumeIfSuppressed(event)) return KeyEventResult.handled;
          if (event.logicalKey.isBackKey) return handleBackKeyAction(event, () => Navigator.pop(context));
          return KeyEventResult.ignored;
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if ((event.buttons & kSecondaryMouseButton) != 0) Navigator.pop(context);
          },
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: _AppMenuSurface<T>(
                  width: menuWidth.toDouble(),
                  maxHeight: menuHeight,
                  entries: widget.entries,
                  focusFirstItem: widget.focusFirstItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({double left, double top}) _resolvePosition(
    Size screenSize,
    double menuWidth,
    double menuHeight,
    double edgePadding,
  ) {
    final anchorRect = widget.anchorRect;
    if (anchorRect != null) {
      final leftCandidate = switch (widget.anchorAlignment) {
        AppMenuAnchorAlignment.start => anchorRect.left,
        AppMenuAnchorAlignment.end => anchorRect.right - menuWidth,
        AppMenuAnchorAlignment.center => anchorRect.center.dx - menuWidth / 2,
      };
      final maxLeft = screenSize.width - menuWidth - edgePadding;
      final left = leftCandidate.clamp(edgePadding, maxLeft < edgePadding ? edgePadding : maxLeft).toDouble();

      const gap = 4.0;
      final below = anchorRect.bottom + gap;
      final above = anchorRect.top - menuHeight - gap;
      final fitsBelow = below + menuHeight <= screenSize.height - edgePadding;
      final topCandidate = fitsBelow ? below : above;
      final maxTop = screenSize.height - menuHeight - edgePadding;
      final top = topCandidate.clamp(edgePadding, maxTop < edgePadding ? edgePadding : maxTop).toDouble();
      return (left: left, top: top);
    }

    final position = widget.position ?? Offset(screenSize.width / 2, screenSize.height / 2);
    final maxLeft = screenSize.width - menuWidth - edgePadding;
    final left = (position.dx - menuWidth / 2)
        .clamp(edgePadding, maxLeft < edgePadding ? edgePadding : maxLeft)
        .toDouble();
    final maxTop = screenSize.height - menuHeight - edgePadding;
    final top = (position.dy - menuHeight / 2)
        .clamp(edgePadding, maxTop < edgePadding ? edgePadding : maxTop)
        .toDouble();
    return (left: left, top: top);
  }

  double _estimateMenuWidth(BuildContext context) {
    var longest = 0;
    for (final entry in widget.entries) {
      if (entry is AppMenuItem<T>) {
        longest = math.max(longest, entry.label?.length ?? 0);
      } else if (entry is AppMenuHeader<T>) {
        longest = math.max(longest, entry.label?.length ?? 0);
      }
    }
    return math.min(360, math.max(widget.minWidth, 96 + longest * 7.5));
  }
}

class _AppMenuSurface<T> extends StatelessWidget {
  final double width;
  final double maxHeight;
  final List<AppMenuEntry<T>> entries;
  final bool focusFirstItem;

  const _AppMenuSurface({
    required this.width,
    required this.maxHeight,
    required this.entries,
    required this.focusFirstItem,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = Color.alphaBlend(colorScheme.onSurface.withValues(alpha: 0.08), colorScheme.surface);
    return Material(
      elevation: 3,
      shadowColor: colorScheme.shadow,
      color: surface,
      borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxHeight),
        child: PrimaryScrollController.none(
          child: SingleChildScrollView(
            child: AppMenuList<T>(
              entries: entries,
              focusFirstItem: focusFirstItem,
              onSelected: (value) => Navigator.pop(context, value),
            ),
          ),
        ),
      ),
    );
  }
}

double _estimateMenuHeight<T>(List<AppMenuEntry<T>> entries) {
  var height = 10.0;
  for (final entry in entries) {
    switch (entry) {
      case AppMenuItem<T>():
        height += entry.subtitle != null || entry.subtitleWidget != null ? 54 : 42;
      case AppMenuDivider<T>():
        height += 9;
      case AppMenuHeader<T>():
        height += 32;
      default:
        break;
    }
  }
  return height;
}

Color _destructiveMenuForeground(BuildContext context) {
  return Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFFFF453A)
      : const Color(0xFFFF3B30);
}
