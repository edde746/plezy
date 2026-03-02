import 'package:flutter/material.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import 'desktop_app_bar.dart';

/// A scaffold widget that wraps Focus + Scaffold + CustomScrollView
/// with consistent keyboard navigation handling and app bar styling.
///
/// This widget reduces boilerplate for screens that need:
/// - Keyboard navigation (back key handling)
/// - Custom scrollable content with slivers
/// - Consistent app bar with title and optional actions
///
/// Automatically focuses the first content item (skipping the app bar)
/// when in keyboard navigation mode.
class FocusedScrollScaffold extends StatefulWidget {
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

  /// Whether to automatically add a back button.
  /// Defaults to true.
  final bool automaticallyImplyLeading;

  const FocusedScrollScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.pinned = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  State<FocusedScrollScaffold> createState() => _FocusedScrollScaffoldState();
}

class _FocusedScrollScaffoldState extends State<FocusedScrollScaffold> {
  final _scopeNode = FocusScopeNode();
  bool _focusRequested = false;

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  void _requestInitialFocus() {
    if (_focusRequested || !mounted || !InputModeTracker.isKeyboardMode(context)) return;
    _focusRequested = true;
    _scopeNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      primaryFocus?.nextFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Request focus after first build when in keyboard mode
    if (!_focusRequested && InputModeTracker.isKeyboardMode(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
    }

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => handleBackKeyNavigation(context, event),
      child: FocusScope(
        node: _scopeNode,
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              ExcludeFocus(
                child: CustomAppBar(
                  title: widget.title,
                  pinned: widget.pinned,
                  actions: widget.actions,
                  automaticallyImplyLeading: widget.automaticallyImplyLeading,
                ),
              ),
              ...widget.slivers,
            ],
          ),
        ),
      ),
    );
  }
}
