import 'package:flutter/material.dart';
import '../focus/key_event_utils.dart';
import 'desktop_app_bar.dart';

/// A scaffold widget that wraps Focus + Scaffold + CustomScrollView
/// with consistent keyboard navigation handling and app bar styling.
///
/// This widget reduces boilerplate for screens that need:
/// - Keyboard navigation (back key handling)
/// - Custom scrollable content with slivers
/// - Consistent app bar with title and optional actions
class FocusedScrollScaffold extends StatelessWidget {
  /// The title to display in the app bar.
  /// Can be a Text widget or a more complex widget like Column.
  final Widget title;

  /// The list of slivers to display in the scroll view.
  /// Should not include the app bar (it's added automatically).
  final List<Widget> slivers;

  /// Optional actions to display in the app bar (e.g., IconButton widgets).
  final List<Widget>? actions;

  /// Whether the app bar should remain visible when scrolling.
  /// Defaults to true.
  final bool pinned;

  const FocusedScrollScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => handleBackKeyNavigation(context, event),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            CustomAppBar(title: title, pinned: pinned, actions: actions),
            ...slivers,
          ],
        ),
      ),
    );
  }
}
