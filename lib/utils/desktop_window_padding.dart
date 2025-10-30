import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../services/fullscreen_state_manager.dart';

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

    if (Platform.isMacOS) {
      rightPadding = DesktopWindowPadding.macOSRight;
    } else if (Platform.isIOS || Platform.isAndroid) {
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
  static Widget? buildAdjustedLeading(
    Widget? leading, {
    bool includeGestureDetector = false,
  }) {
    if (!Platform.isMacOS || leading == null) {
      return leading;
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        final leftPadding = isFullscreen
            ? DesktopWindowPadding.macOSLeftFullscreen
            : DesktopWindowPadding.macOSLeft;

        final paddedWidget = Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: leading,
        );

        if (includeGestureDetector) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown:
                (_) {}, // Consume pan gestures to prevent window dragging
            child: paddedWidget,
          );
        }

        return paddedWidget;
      },
    );
  }

  /// Builds flexible space with gesture detector on macOS to prevent window dragging
  static Widget? buildAdjustedFlexibleSpace(Widget? flexibleSpace) {
    if (!Platform.isMacOS || flexibleSpace == null) {
      return flexibleSpace;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
      child: flexibleSpace,
    );
  }

  /// Calculates the leading width for SliverAppBar to account for macOS traffic lights
  static double? calculateLeadingWidth(Widget? leading) {
    if (!Platform.isMacOS || leading == null) {
      return null;
    }

    final isFullscreen = FullscreenStateManager().isFullscreen;
    final leftPadding = isFullscreen
        ? DesktopWindowPadding.macOSLeftFullscreen
        : DesktopWindowPadding.macOSLeft;
    return leftPadding + kToolbarHeight;
  }

  /// Wraps a widget with GestureDetector on macOS to prevent window dragging
  static Widget wrapWithGestureDetector(Widget child) {
    if (!Platform.isMacOS) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
      child: child,
    );
  }
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
    if (!Platform.isMacOS) {
      return child;
    }

    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        // In fullscreen, use minimal padding since traffic lights auto-hide
        final left =
            leftPadding ??
            (isFullscreen
                ? DesktopWindowPadding.macOSLeftFullscreen
                : DesktopWindowPadding.macOSLeft);
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
