import 'platform_helper.dart';
import 'package:flutter/material.dart';
import '../services/fullscreen_state_manager.dart';

/// InheritedWidget to indicate that a side navigation is present in the widget tree.
/// When present, app bars should skip their left padding since the side nav
/// already handles the macOS traffic lights area.
class SideNavigationScope extends InheritedWidget {
  const SideNavigationScope({super.key, required super.child});

  static bool isPresent(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SideNavigationScope>() != null;
  }

  @override
  bool updateShouldNotify(SideNavigationScope oldWidget) => false;
}

/// Padding values for desktop window controls
class DesktopWindowPadding {
  /// Left padding for macOS traffic lights (normal window mode)
  static const double macOSLeft = 80.0;

  /// Left padding for macOS in fullscreen (reduced since traffic lights auto-hide)
  static const double macOSLeftFullscreen = 0.0;

  /// Right padding for macOS to prevent actions from being too close to edge
  static const double macOSRight = 16.0;

  /// Right padding for mobile devices to prevent actions from being too close to edge
  static const double mobileRight = 6.0;
}

/// Helper class for adjusting app bar widgets to account for desktop window controls
class DesktopAppBarHelper {
  /// Builds actions list with appropriate right padding for macOS and mobile
  static List<Widget>? buildAdjustedActions(List<Widget>? actions) {
    double? rightPadding;

    if (AppPlatform.isMacOS) {
      rightPadding = DesktopWindowPadding.macOSRight;
    } else if (AppPlatform.isIOS || AppPlatform.isAndroid) {
      rightPadding = DesktopWindowPadding.mobileRight;
    }

    // If no platform-specific padding needed, return original actions
    if (rightPadding == null) {
      return actions;
    }

    // Add padding to keep actions away from edge
    if (actions != null) {
      return [...actions, SizedBox(width: rightPadding)];
    } else {
      return [SizedBox(width: rightPadding)];
    }
  }

  /// Builds leading widget with appropriate left padding for macOS traffic lights
  ///
  /// [includeGestureDetector] - If true, wraps in GestureDetector to prevent window dragging
  /// [context] - Required to check if side navigation is visible
  static Widget? buildAdjustedLeading(Widget? leading, {bool includeGestureDetector = false, BuildContext? context}) {
    if (!AppPlatform.isMacOS || leading == null) {
      return leading;
    }

    // Skip left padding when side navigation scope is present in widget tree
    if (context != null && SideNavigationScope.isPresent(context)) {
      if (includeGestureDetector) {
        return GestureDetector(behavior: HitTestBehavior.opaque, onPanDown: (_) {}, child: leading);
      }
      return leading;
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        final leftPadding = isFullscreen ? DesktopWindowPadding.macOSLeftFullscreen : DesktopWindowPadding.macOSLeft;

        final paddedWidget = Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: leading,
        );

        if (includeGestureDetector) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
            child: paddedWidget,
          );
        }

        return paddedWidget;
      },
    );
  }

  /// Builds flexible space with gesture detector on macOS to prevent window dragging
  static Widget? buildAdjustedFlexibleSpace(Widget? flexibleSpace) {
    if (!AppPlatform.isMacOS || flexibleSpace == null) {
      return flexibleSpace;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
      child: flexibleSpace,
    );
  }

  /// Calculates the leading width for SliverAppBar to account for macOS traffic lights
  /// [context] - Required to check if side navigation is visible
  static double? calculateLeadingWidth(Widget? leading, {BuildContext? context}) {
    if (!AppPlatform.isMacOS || leading == null) {
      return null;
    }

    // Skip extra width when side navigation scope is present in widget tree
    if (context != null && SideNavigationScope.isPresent(context)) {
      return null;
    }

    final isFullscreen = FullscreenStateManager().isFullscreen;
    final leftPadding = isFullscreen ? DesktopWindowPadding.macOSLeftFullscreen : DesktopWindowPadding.macOSLeft;
    return leftPadding + kToolbarHeight;
  }

  /// Wraps a widget with GestureDetector on macOS to prevent window dragging
  ///
  /// [opaque] - If true, uses HitTestBehavior.opaque to fully consume gestures.
  ///            If false (default), uses HitTestBehavior.translucent.
  static Widget wrapWithGestureDetector(Widget child, {bool opaque = false}) {
    if (!AppPlatform.isMacOS) {
      return child;
    }

    return GestureDetector(
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
      child: child,
    );
  }
}

/// A widget that adds padding to account for desktop window controls.
/// On macOS, adds left padding for traffic lights (reduced in fullscreen).
/// When side navigation is visible, left padding is skipped as the side nav
/// already occupies the traffic lights area.
class DesktopTitleBarPadding extends StatelessWidget {
  final Widget child;
  final double? leftPadding;
  final double? rightPadding;

  const DesktopTitleBarPadding({super.key, required this.child, this.leftPadding, this.rightPadding});

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isMacOS) {
      return child;
    }

    // Skip left padding when side navigation scope is present in widget tree
    // (side nav already handles the traffic lights area)
    if (SideNavigationScope.isPresent(context)) {
      final right = rightPadding ?? 0.0;
      if (right == 0.0) {
        return child;
      }
      return Padding(
        padding: EdgeInsets.only(right: right),
        child: child,
      );
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        // In fullscreen, use minimal padding since traffic lights auto-hide
        final left =
            leftPadding ?? (isFullscreen ? DesktopWindowPadding.macOSLeftFullscreen : DesktopWindowPadding.macOSLeft);
        final right = rightPadding ?? 0.0;

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
