import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import 'app_icon.dart';
import '../theme/mono_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A TV-friendly number spinner with +/- buttons for D-pad navigation.
///
/// Displays a value with decrement/increment buttons on either side.
/// Supports keyboard repeat for faster value changes when holding arrows.
class TvNumberSpinner extends StatefulWidget {
  /// Current value.
  final int value;

  /// Minimum allowed value.
  final int min;

  /// Maximum allowed value.
  final int max;

  /// Step size for each increment/decrement.
  final int step;

  /// Optional suffix text (e.g., "s" for seconds).
  final String? suffix;

  /// Called when the value changes.
  final ValueChanged<int> onChanged;

  /// Called when the user presses SELECT to confirm.
  /// Use this to move focus to a confirm/save button.
  final VoidCallback? onConfirm;

  /// Called when the user presses BACK to cancel.
  /// Use this to close the dialog or cancel the operation.
  final VoidCallback? onCancel;

  /// Whether the spinner should request focus when built.
  final bool autofocus;

  const TvNumberSpinner({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
    this.autofocus = false,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<TvNumberSpinner> createState() => _TvNumberSpinnerState();
}

class _TvNumberSpinnerState extends State<TvNumberSpinner> {
  late FocusNode _focusNode;
  Timer? _repeatTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'TvNumberSpinner');
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    final newValue = widget.value + widget.step;
    if (newValue <= widget.max) {
      widget.onChanged(newValue);
    }
  }

  void _decrement() {
    final newValue = widget.value - widget.step;
    if (newValue >= widget.min) {
      widget.onChanged(newValue);
    }
  }

  void _startRepeat(VoidCallback action) {
    // Execute once immediately
    action();

    // Start repeat timer after initial delay
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 400), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        action();
      });
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (widget.onCancel != null) {
      final backResult = handleBackKeyAction(event, widget.onCancel!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    if (event is KeyDownEvent) {
      // Handle SELECT key to confirm/move to save button
      if (key.isSelectKey && widget.onConfirm != null) {
        widget.onConfirm!();
        return KeyEventResult.handled;
      }
      if (key.isUpKey || key.isRightKey) {
        _startRepeat(_increment);
        return KeyEventResult.handled;
      } else if (key.isDownKey || key.isLeftKey) {
        _startRepeat(_decrement);
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (key.isUpKey || key.isRightKey || key.isDownKey || key.isLeftKey) {
        _stopRepeat();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<MonoTokens>();
    final canDecrement = widget.value > widget.min;
    final canIncrement = widget.value < widget.max;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (!hasFocus) _stopRepeat();
      },
      onKeyEvent: _handleKeyEvent,
      child: AnimatedContainer(
        duration: tokens?.fast ?? const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(FocusTheme.defaultBorderRadius)),
          border: Border.fromBorderSide(
            BorderSide(
              color: _isFocused && isKeyboardMode ? FocusTheme.getFocusBorderColor(context) : Colors.transparent,
              width: FocusTheme.focusBorderWidth,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrement button
            _SpinnerButton(
              icon: Symbols.remove_rounded,
              onPressed: canDecrement ? _decrement : null,
              onLongPressStart: canDecrement ? () => _startRepeat(_decrement) : null,
              onLongPressEnd: _stopRepeat,
              semanticLabel: 'Decrease',
            ),
            const SizedBox(width: 16),
            // Value display
            Container(
              constraints: const BoxConstraints(minWidth: 60),
              alignment: Alignment.center,
              child: Text(
                widget.suffix != null ? '${widget.value}${widget.suffix}' : '${widget.value}',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            // Increment button
            _SpinnerButton(
              icon: Symbols.add_rounded,
              onPressed: canIncrement ? _increment : null,
              onLongPressStart: canIncrement ? () => _startRepeat(_increment) : null,
              onLongPressEnd: _stopRepeat,
              semanticLabel: 'Increase',
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual +/- button with long-press support.
class _SpinnerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final String semanticLabel;

  const _SpinnerButton({
    required this.icon,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onLongPressStart: onLongPressStart != null ? (_) => onLongPressStart!() : null,
        onLongPressEnd: onLongPressEnd != null ? (_) => onLongPressEnd!() : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: AppIcon(
                  icon,
                  fill: 1,
                  color: isEnabled
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
