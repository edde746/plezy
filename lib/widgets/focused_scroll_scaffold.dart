import 'package:flutter/material.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import 'desktop_app_bar.dart';
import 'ios_status_bar_tap_scroll_to_top.dart';

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

  /// Whether app-bar controls participate in keyboard/controller traversal.
  ///
  /// They remain excluded while initial focus is assigned so the first
  /// content control still receives focus when the screen opens.
  final bool focusableAppBarActions;

  /// Whether the app bar should remain visible when scrolling.
  /// Defaults to true.
  final bool pinned;

  /// Whether to automatically add a back button.
  /// Defaults to true.
  final bool automaticallyImplyLeading;

  /// Optional override for the back key handler.
  /// When set, this callback is invoked instead of the default
  /// [handleBackKeyNavigation] (which pops the current route).
  final VoidCallback? onBackPressed;

  const FocusedScrollScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.focusableAppBarActions = false,
    this.pinned = true,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  });

  @override
  State<FocusedScrollScaffold> createState() => _FocusedScrollScaffoldState();
}

class _FocusedScrollScaffoldState extends State<FocusedScrollScaffold> {
  final _scopeNode = FocusScopeNode();
  bool _focusRequested = false;
  bool _appBarFocusEnabled = false;

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  void _requestInitialFocus() {
    if (_focusRequested || !mounted || !InputModeTracker.isKeyboardMode(context, listen: false)) return;
    _focusRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scopeNode.focusedChild != null) return;
      _scopeNode.requestFocus();
      _scopeNode.nextFocus();
      if (widget.focusableAppBarActions && !_appBarFocusEnabled) {
        setState(() => _appBarFocusEnabled = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_focusRequested && InputModeTracker.isKeyboardMode(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
    }

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (widget.onBackPressed != null) {
          return handleBackKeyAction(event, widget.onBackPressed!);
        }
        return handleBackKeyNavigation(context, event);
      },
      child: FocusScope(
        node: _scopeNode,
        child: IosStatusBarTapScrollToTop(
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                if (!widget.focusableAppBarActions || !_appBarFocusEnabled)
                  ExcludeFocus(
                    child: CustomAppBar(
                      title: widget.title,
                      pinned: widget.pinned,
                      actions: widget.actions,
                      automaticallyImplyLeading: widget.automaticallyImplyLeading,
                    ),
                  )
                else
                  CustomAppBar(
                    title: widget.title,
                    pinned: widget.pinned,
                    actions: widget.actions,
                    automaticallyImplyLeading: widget.automaticallyImplyLeading,
                  ),
                ...widget.slivers,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
