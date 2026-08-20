import 'package:flutter/material.dart';
import '../utils/desktop_window_padding.dart';
import '../services/fullscreen_state_manager.dart';
import 'app_bar_back_button.dart';

/// Helper class for building app bar sections with consistent desktop behavior.
class DesktopAppBarSections {
  /// Builds the leading section with proper padding and back button handling.
  static Widget? buildLeadingSection({
    Widget? leading,
    bool automaticallyImplyLeading = true,
    required BuildContext context,
  }) {
    Widget? effectiveLeading = leading;

    // If no leading is provided but automaticallyImplyLeading is true,
    // create a back button manually so it goes through our padding logic
    if (leading == null && automaticallyImplyLeading) {
      final parentRoute = ModalRoute.of(context);
      final canPop = parentRoute?.canPop ?? false;

      if (canPop) {
        effectiveLeading = AppBarBackButton(style: BackButtonStyle.plain, onPressed: () => Navigator.of(context).pop());
      }
    }

    return DesktopAppBarHelper.buildAdjustedLeading(effectiveLeading, includeGestureDetector: true, context: context);
  }

  /// Builds the title section with proper padding.
  static Widget? buildTitleSection({required Widget? title, required Widget? leading}) {
    if (title == null) return null;

    return DesktopTitleBarPadding(leftPadding: leading != null ? 0 : null, child: title);
  }

  /// Builds the actions section with proper padding.
  static List<Widget>? buildActionsSection(List<Widget>? actions) {
    return DesktopAppBarHelper.buildAdjustedActions(actions);
  }

  /// Calculates the leading width for the app bar.
  static double? calculateLeadingWidthForSection({required Widget? leading, required BuildContext context}) {
    return DesktopAppBarHelper.calculateLeadingWidth(leading, context: context);
  }

  /// Builds the flexible space section with gesture handling.
  static Widget? buildFlexibleSpaceSection(Widget? flexibleSpace) {
    return DesktopAppBarHelper.buildAdjustedFlexibleSpace(flexibleSpace);
  }
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
    final effectiveLeading = DesktopAppBarSections.buildLeadingSection(
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      context: context,
    );

    return SliverAppBar(
      title: DesktopAppBarSections.buildTitleSection(title: title, leading: effectiveLeading),
      actions: DesktopAppBarSections.buildActionsSection(actions),
      leading: effectiveLeading,
      leadingWidth: DesktopAppBarSections.calculateLeadingWidthForSection(leading: effectiveLeading, context: context),
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
      flexibleSpace: DesktopAppBarSections.buildFlexibleSpaceSection(flexibleSpace),
      bottom: bottom,
    );
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
