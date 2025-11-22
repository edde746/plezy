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
    // Determine the effective leading widget
    Widget? effectiveLeading = leading;

    // If no leading is provided but automaticallyImplyLeading is true,
    // create a back button manually so it goes through our padding logic
    if (leading == null && automaticallyImplyLeading) {
      final parentRoute = ModalRoute.of(context);
      final canPop = parentRoute?.canPop ?? false;

      if (canPop) {
        effectiveLeading = IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        );
      }
    }

    return SliverAppBar(
      title: title != null
          ? DesktopTitleBarPadding(
              leftPadding: effectiveLeading != null ? 0 : null,
              child: title!,
            )
          : null,
      actions: DesktopAppBarHelper.buildAdjustedActions(actions),
      leading: DesktopAppBarHelper.buildAdjustedLeading(
        effectiveLeading,
        includeGestureDetector: true,
      ),
      leadingWidth: DesktopAppBarHelper.calculateLeadingWidth(effectiveLeading),
      automaticallyImplyLeading:
          false, // Always false since we handle it manually
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

/// Convenient wrapper for DesktopSliverAppBar with built-in back button handling
class CustomAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
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

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.onBackPressed,
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
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;

        return DesktopSliverAppBar(
          key: ValueKey('plex_sliver_app_bar_$isFullscreen'),
          title: title,
          actions: actions,
          leading: _shouldShowBackButton(context)
              ? AppBarBackButton(
                  style: BackButtonStyle.plain,
                  onPressed: onBackPressed,
                )
              : null,
          automaticallyImplyLeading: false,
          elevation: elevation,
          backgroundColor: backgroundColor,
          surfaceTintColor: surfaceTintColor,
          shadowColor: shadowColor,
          scrolledUnderElevation: scrolledUnderElevation,
          floating: floating,
          pinned: pinned,
          expandedHeight: expandedHeight,
          flexibleSpace: flexibleSpace,
          bottom: bottom,
        );
      },
    );
  }

  bool _shouldShowBackButton(BuildContext context) {
    final parentRoute = ModalRoute.of(context);
    return parentRoute?.canPop ?? false;
  }
}
