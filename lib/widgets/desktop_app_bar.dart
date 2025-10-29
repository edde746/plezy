import 'package:flutter/material.dart';
import '../utils/desktop_window_padding.dart';

/// A custom app bar that automatically handles desktop window controls spacing.
/// Use this instead of AppBar for consistent desktop platform behavior.
class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final double? scrolledUnderElevation;

  const DesktopAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.scrolledUnderElevation,
  });

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: title != null ? DesktopTitleBarPadding(child: title!) : null,
      actions: DesktopAppBarHelper.buildAdjustedActions(actions),
      leading: DesktopAppBarHelper.buildAdjustedLeading(leading),
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      scrolledUnderElevation: scrolledUnderElevation,
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(appBar);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A custom sliver app bar that automatically handles desktop window controls spacing.
/// Use this instead of SliverAppBar for consistent desktop platform behavior.
class DesktopSliverAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double? elevation;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final double? scrolledUnderElevation;
  final bool floating;
  final bool pinned;
  final double? expandedHeight;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const DesktopSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.elevation,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.scrolledUnderElevation,
    this.floating = false,
    this.pinned = false,
    this.expandedHeight,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: title != null ? DesktopTitleBarPadding(child: title!) : null,
      actions: DesktopAppBarHelper.buildAdjustedActions(actions),
      leading: DesktopAppBarHelper.buildAdjustedLeading(
        leading,
        includeGestureDetector: true,
      ),
      leadingWidth: DesktopAppBarHelper.calculateLeadingWidth(leading),
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      scrolledUnderElevation: scrolledUnderElevation,
      floating: floating,
      pinned: pinned,
      expandedHeight: expandedHeight,
      flexibleSpace: DesktopAppBarHelper.buildAdjustedFlexibleSpace(
        flexibleSpace,
      ),
      bottom: bottom,
    );
  }
}
