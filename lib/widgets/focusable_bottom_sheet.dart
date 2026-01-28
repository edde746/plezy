import 'package:flutter/material.dart';

import '../focus/input_mode_tracker.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';

/// A wrapper widget that provides autofocus functionality for bottom sheets.
///
/// When the sheet opens and keyboard/controller mode is active, this widget
/// will automatically request focus on the provided [initialFocusNode].
/// This enables keyboard/controller navigation within the sheet.
///
/// When opened via touch/mouse, no autofocus occurs to avoid showing
/// focus indicators unnecessarily.
class FocusableBottomSheet extends StatefulWidget {
  /// The content of the bottom sheet.
  final Widget child;

  /// The FocusNode to focus when the sheet opens in keyboard mode.
  /// If null, no autofocus occurs.
  final FocusNode? initialFocusNode;

  const FocusableBottomSheet({super.key, required this.child, this.initialFocusNode});

  @override
  State<FocusableBottomSheet> createState() => _FocusableBottomSheetState();
}

class _FocusableBottomSheetState extends State<FocusableBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Clear any stale back key suppression from previous sheet closes
    BackKeyUpSuppressor.clearSuppression();
    _requestInitialFocus();
  }

  void _requestInitialFocus() {
    if (widget.initialFocusNode == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Only autofocus when in keyboard/controller mode
      if (InputModeTracker.isKeyboardMode(context)) {
        widget.initialFocusNode?.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(FocusableBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the focus node changed, request focus on the new one
    if (widget.initialFocusNode != oldWidget.initialFocusNode) {
      _requestInitialFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        // Handle select key suppression (for when sheet was opened via select key)
        if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
          return KeyEventResult.handled;
        }
        // Handle back key to close the bottom sheet
        return handleBackKeyNavigation(context, event);
      },
      child: widget.child,
    );
  }
}
