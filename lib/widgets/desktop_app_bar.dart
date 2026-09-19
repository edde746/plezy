import 'package:flutter/material.dart';
import '../utils/desktop_window_padding.dart';
import '../services/fullscreen_state_manager.dart';
import 'app_bar_back_button.dart';

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
  final bool snap;
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
    this.snap = false,
    this.expandedHeight,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLeading = DesktopAppBarHelper.buildAdjustedLeading(
      _impliedLeading(context),
      includeGestureDetector: true,
      context: context,
    );

    return SliverAppBar(
      title: title == null
          ? null
          : DesktopTitleBarPadding(leftPadding: effectiveLeading != null ? 0 : null, child: title!),
      actions: DesktopAppBarHelper.buildAdjustedActions(actions),
      leading: effectiveLeading,
      leadingWidth: DesktopAppBarHelper.calculateLeadingWidth(effectiveLeading, context: context),
      automaticallyImplyLeading: false, // Always false since we handle it manually
      elevation: elevation,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      scrolledUnderElevation: scrolledUnderElevation,
      floating: floating,
      pinned: pinned,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: DesktopAppBarHelper.buildAdjustedFlexibleSpace(flexibleSpace),
      bottom: bottom,
    );
  }

  /// [SliverAppBar]'s own implied back button bypasses the traffic-light padding,
  /// so imply it here and route it through [DesktopAppBarHelper] like any other leading.
  Widget? _impliedLeading(BuildContext context) {
    if (leading != null || !automaticallyImplyLeading) return leading;
    if (!(ModalRoute.of(context)?.canPop ?? false)) return null;
    return AppBarBackButton(style: BackButtonStyle.plain, onPressed: () => Navigator.of(context).pop());
  }
}

/// Convenience wrapper around [DesktopSliverAppBar] — the canonical desktop app bar —
/// that rebuilds when fullscreen state changes so window-control spacing stays correct.
/// For anything beyond title/actions/pinned, use [DesktopSliverAppBar] directly.
class CustomAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool pinned;
  final bool automaticallyImplyLeading;

  const CustomAppBar({super.key, this.title, this.actions, this.pinned = false, this.automaticallyImplyLeading = true});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;

        return DesktopSliverAppBar(
          key: ValueKey('desktop_top_bar_$isFullscreen'),
          title: title,
          actions: actions,
          pinned: pinned,
          automaticallyImplyLeading: automaticallyImplyLeading,
        );
      },
    );
  }
}
