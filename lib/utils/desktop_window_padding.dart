import 'dart:io' show Platform;
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

  /// Right padding for macOS to prevent actions from being too close to edge
  static const double macOSRight = 16.0;

  /// Right padding for mobile devices to prevent actions from being too close to edge
  static const double mobileRight = 6.0;

  /// Left padding for macOS reflecting the current fullscreen state
  /// (none in fullscreen, since the traffic lights auto-hide)
  static double get macOSLeftCurrent => FullscreenStateManager().isFullscreen ? 0.0 : macOSLeft;
}

/// Whether the widget tree at [context] must reserve space for the macOS traffic
/// lights. A side navigation already occupies that area, so nothing under it pads.
bool _trafficLightPaddingApplies(BuildContext context) => Platform.isMacOS && !SideNavigationScope.isPresent(context);

/// Helper class for adjusting app bar widgets to account for desktop window controls
class DesktopAppBarHelper {
  /// Builds actions list with appropriate right padding for macOS and mobile
  static List<Widget>? buildAdjustedActions(List<Widget>? actions) {
    double? rightPadding;

    if (Platform.isMacOS) {
      rightPadding = DesktopWindowPadding.macOSRight;
    } else if (Platform.isIOS || Platform.isAndroid) {
      rightPadding = DesktopWindowPadding.mobileRight;
    }

    if (rightPadding == null) {
      return actions;
    }

    return actions != null ? [...actions, SizedBox(width: rightPadding)] : [SizedBox(width: rightPadding)];
  }

  /// Builds leading widget with appropriate left padding for macOS traffic lights
  ///
  /// [includeGestureDetector] - If true, wraps in GestureDetector to prevent window dragging
  /// [context] - Required to check if side navigation is visible
  static Widget? buildAdjustedLeading(
    Widget? leading, {
    bool includeGestureDetector = false,
    required BuildContext context,
  }) {
    if (leading == null) {
      return null;
    }

    if (!_trafficLightPaddingApplies(context)) {
      return includeGestureDetector ? wrapWithGestureDetector(leading, opaque: true) : leading;
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final paddedWidget = Padding(
          padding: .only(left: DesktopWindowPadding.macOSLeftCurrent),
          child: leading,
        );

        return includeGestureDetector ? wrapWithGestureDetector(paddedWidget, opaque: true) : paddedWidget;
      },
    );
  }

  /// Builds flexible space with gesture detector on macOS to prevent window dragging
  static Widget? buildAdjustedFlexibleSpace(Widget? flexibleSpace) {
    if (!Platform.isMacOS || flexibleSpace == null) {
      return flexibleSpace;
    }

    return wrapWithGestureDetector(flexibleSpace);
  }

  /// Calculates the leading width for SliverAppBar to account for macOS traffic lights
  /// [context] - Required to check if side navigation is visible
  static double? calculateLeadingWidth(Widget? leading, {required BuildContext context}) {
    if (leading == null || !_trafficLightPaddingApplies(context)) {
      return null;
    }

    return DesktopWindowPadding.macOSLeftCurrent + kToolbarHeight;
  }

  /// Wraps a widget with GestureDetector on macOS to prevent window dragging
  ///
  /// [opaque] - If true, uses HitTestBehavior.opaque to fully consume gestures.
  ///            If false (default), uses HitTestBehavior.translucent.
  static Widget wrapWithGestureDetector(Widget child, {bool opaque = false}) {
    if (!Platform.isMacOS) {
      return child;
    }

    return GestureDetector(
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      // ignore: no-empty-block - consumes gesture to prevent macOS window dragging
      onPanDown: (_) {},
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
    if (!Platform.isMacOS) {
      return child;
    }

    if (!_trafficLightPaddingApplies(context)) {
      final right = rightPadding ?? 0.0;
      if (right == 0.0) {
        return child;
      }
      return Padding(
        padding: .only(right: right),
        child: child,
      );
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        // In fullscreen, use minimal padding since traffic lights auto-hide
        final left = leftPadding ?? DesktopWindowPadding.macOSLeftCurrent;
        final right = rightPadding ?? 0.0;

        if (left == 0.0 && right == 0.0) {
          return child;
        }

        return Padding(
          padding: .only(left: left, right: right),
          child: child,
        );
      },
    );
  }
}
