import 'package:flutter/widgets.dart';

/// Guards child content behind a [ValueNotifier<bool>] that signals
/// whether the first video frame has rendered.
///
/// Shows [placeholder] (defaults to `SizedBox.shrink()`) until the
/// notifier emits `true`, then renders the [builder] result.
/// If [hasFirstFrame] is null, the builder is rendered immediately.
class FirstFrameGuard extends StatelessWidget {
  final ValueNotifier<bool>? hasFirstFrame;
  final WidgetBuilder builder;
  final Widget placeholder;

  const FirstFrameGuard({
    super.key,
    required this.hasFirstFrame,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final notifier = hasFirstFrame;
    if (notifier == null) return builder(context);

    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, hasFrame, child) {
        if (!hasFrame) return placeholder;
        return builder(context);
      },
    );
  }
}
