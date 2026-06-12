import 'package:flutter/widgets.dart';

/// Rebuilds [builder] only when [selector]'s result changes (by `==`) after
/// [listenable] notifies — unlike [ListenableBuilder], which rebuilds on every
/// notification.
///
/// Pass the expensive subtree as [child]: it is built once by the parent and
/// handed through untouched, so a selection flip rebuilds only the cheap
/// wrapper in [builder]. Used to give every card in a focus-driven rail its
/// own `isFocused` without rebuilding the whole row per d-pad press.
class ListenableSelector<T> extends StatefulWidget {
  const ListenableSelector({
    super.key,
    required this.listenable,
    required this.selector,
    required this.builder,
    this.child,
  });

  final Listenable listenable;

  /// Derives the watched value. Re-evaluated on every notification and on
  /// widget updates (the closure may capture fresh values from a parent build).
  final T Function() selector;

  final Widget Function(BuildContext context, T value, Widget? child) builder;

  final Widget? child;

  @override
  State<ListenableSelector<T>> createState() => _ListenableSelectorState<T>();
}

class _ListenableSelectorState<T> extends State<ListenableSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(ListenableSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.listenable, widget.listenable)) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
    _value = widget.selector();
  }

  void _handleChange() {
    final next = widget.selector();
    if (next == _value) return;
    setState(() => _value = next);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value, widget.child);
}
