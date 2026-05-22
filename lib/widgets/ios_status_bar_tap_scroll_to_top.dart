import 'package:flutter/material.dart';

import '../utils/platform_detector.dart';

/// Captures iPhone/iPad status-bar taps and scrolls the nearest primary
/// scroll view to the top.
///
/// Flutter's [Scaffold] handles the native `handleScrollToTop` callback, but
/// some iOS versions also deliver a normal pointer near the top of the Flutter
/// view. This prevents that pointer from activating controls underneath the
/// status bar.
class IosStatusBarTapScrollToTop extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;

  const IosStatusBarTapScrollToTop({super.key, required this.child, this.controller});

  @override
  State<IosStatusBarTapScrollToTop> createState() => _IosStatusBarTapScrollToTopState();
}

class _IosStatusBarTapScrollToTopState extends State<IosStatusBarTapScrollToTop> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void handleStatusBarTap() {
    _scrollToTop();
  }

  bool get _isCurrentRoute => ModalRoute.of(context)?.isCurrent ?? true;

  void _scrollToTop() {
    if (!PlatformDetector.isHandheldIOS(context) || !_isCurrentRoute) return;
    final controller = widget.controller ?? PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    controller.animateTo(0, duration: const Duration(milliseconds: 1000), curve: Curves.easeOutCirc);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    if (!PlatformDetector.isHandheldIOS(context) || topInset <= 0) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _scrollToTop,
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}
