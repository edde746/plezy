import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/fullscreen_state_manager.dart';

class DesktopWindowPadding {
  /// Left padding for macOS traffic lights (normal window mode)
  static const double macOSLeft = 80.0;

  /// Left padding for macOS in fullscreen (reduced since traffic lights auto-hide)
  static const double macOSLeftFullscreen = 0.0;

  /// Right padding for macOS to prevent actions from being too close to edge
  static const double macOSRight = 16.0;
}

/// A widget that adds padding to account for desktop window controls.
/// On macOS, adds left padding for traffic lights (reduced in fullscreen).
class DesktopTitleBarPadding extends StatelessWidget {
  final Widget child;
  final double? leftPadding;
  final double? rightPadding;

  const DesktopTitleBarPadding({
    super.key,
    required this.child,
    this.leftPadding,
    this.rightPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        double left = 0.0;
        double right = 0.0;

        if (Platform.isMacOS) {
          final isFullscreen = FullscreenStateManager().isFullscreen;
          // In fullscreen, use minimal padding since traffic lights auto-hide
          left =
              leftPadding ??
              (isFullscreen
                  ? DesktopWindowPadding.macOSLeftFullscreen
                  : DesktopWindowPadding.macOSLeft);
        }

        if (left == 0.0 && right == 0.0) {
          return child;
        }

        return Padding(
          padding: EdgeInsets.only(left: left, right: right),
          child: child,
        );
      },
    );
  }
}

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
    // Add right padding for desktop platforms
    List<Widget>? adjustedActions = actions;

    if (Platform.isMacOS) {
      // macOS: Add padding to keep actions away from edge
      if (actions != null) {
        adjustedActions = [
          ...actions!,
          SizedBox(width: DesktopWindowPadding.macOSRight),
        ];
      } else {
        adjustedActions = [SizedBox(width: DesktopWindowPadding.macOSRight)];
      }
    }

    // Wrap leading widget with padding on macOS to avoid traffic lights
    Widget? adjustedLeading = leading;
    if (Platform.isMacOS && leading != null) {
      adjustedLeading = ListenableBuilder(
        listenable: FullscreenStateManager(),
        builder: (context, _) {
          final isFullscreen = FullscreenStateManager().isFullscreen;
          final leftPadding = isFullscreen
              ? DesktopWindowPadding.macOSLeftFullscreen
              : DesktopWindowPadding.macOSLeft;
          return Padding(
            padding: EdgeInsets.only(left: leftPadding),
            child: leading,
          );
        },
      );
    }

    final appBar = AppBar(
      title: title != null ? DesktopTitleBarPadding(child: title!) : null,
      actions: adjustedActions,
      leading: adjustedLeading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      scrolledUnderElevation: scrolledUnderElevation,
    );

    // On macOS with transparent titlebar, wrap in GestureDetector to prevent
    // window dragging and allow buttons to be clickable
    if (Platform.isMacOS) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
        child: appBar,
      );
    }

    return appBar;
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
    // Add right padding for desktop platforms
    List<Widget>? adjustedActions = actions;

    if (Platform.isMacOS) {
      // macOS: Add padding to keep actions away from edge
      if (actions != null) {
        adjustedActions = [
          ...actions!,
          SizedBox(width: DesktopWindowPadding.macOSRight),
        ];
      } else {
        adjustedActions = [SizedBox(width: DesktopWindowPadding.macOSRight)];
      }
    }

    // Wrap leading widget with gesture detector and padding on macOS
    Widget? adjustedLeading = leading;
    if (Platform.isMacOS && leading != null) {
      adjustedLeading = ListenableBuilder(
        listenable: FullscreenStateManager(),
        builder: (context, _) {
          final isFullscreen = FullscreenStateManager().isFullscreen;
          final leftPadding = isFullscreen
              ? DesktopWindowPadding.macOSLeftFullscreen
              : DesktopWindowPadding.macOSLeft;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown:
                (_) {}, // Consume pan gestures to prevent window dragging
            child: Padding(
              padding: EdgeInsets.only(left: leftPadding),
              child: leading,
            ),
          );
        },
      );
    }

    // Wrap flexible space with gesture detector on macOS to prevent window dragging
    Widget? adjustedFlexibleSpace = flexibleSpace;
    if (Platform.isMacOS && flexibleSpace != null) {
      adjustedFlexibleSpace = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
        child: flexibleSpace,
      );
    }

    // On macOS, increase leading width to account for traffic light spacing
    double? leadingWidth;
    if (Platform.isMacOS && leading != null) {
      final isFullscreen = FullscreenStateManager().isFullscreen;
      final leftPadding = isFullscreen
          ? DesktopWindowPadding.macOSLeftFullscreen
          : DesktopWindowPadding.macOSLeft;
      leadingWidth = leftPadding + kToolbarHeight;
    }

    return SliverAppBar(
      title: title != null ? DesktopTitleBarPadding(child: title!) : null,
      actions: adjustedActions,
      leading: adjustedLeading,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      surfaceTintColor: surfaceTintColor,
      shadowColor: shadowColor,
      scrolledUnderElevation: scrolledUnderElevation,
      floating: floating,
      pinned: pinned,
      expandedHeight: expandedHeight,
      flexibleSpace: adjustedFlexibleSpace,
      bottom: bottom,
    );
  }
}
