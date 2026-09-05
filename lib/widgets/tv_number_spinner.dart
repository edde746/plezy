import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/back_press.dart';
import '../focus/key_repeat_helper.dart';
import 'app_icon.dart';
import '../theme/mono_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Size variant for [TvNumberSpinner].
enum TvNumberSpinnerDensity {
  /// Large buttons with long-press repeat, for a spinner that owns the dialog.
  standard,

  /// Smaller buttons sized to sit in a stack of labelled rows.
  compact,
}

/// A TV-friendly number spinner with +/- buttons for D-pad navigation.
///
/// Displays a value with decrement/increment buttons on either side, optionally
/// behind a leading [label]. Supports keyboard repeat for faster value changes
/// when holding arrows.
class TvNumberSpinner extends StatefulWidget {
  final int value;

  final int min;

  final int max;

  final int step;

  /// Optional suffix text (e.g., "s" for seconds).
  final String? suffix;

  /// Optional leading label shown before the buttons (e.g., "H" for hue).
  final String? label;

  /// When set, the +/- buttons announce themselves as adjusting this value
  /// instead of using the generic increase/decrease labels.
  final String? semanticLabel;

  final ValueChanged<int> onChanged;

  /// Called when the user presses SELECT to confirm.
  /// Use this to move focus to a confirm/save button.
  final VoidCallback? onConfirm;

  /// Called when the user presses BACK to cancel.
  /// Use this to close the dialog or cancel the operation.
  final VoidCallback? onCancel;

  final bool autofocus;

  /// When false, UP/DOWN are left alone so focus traverses between rows, and
  /// held LEFT/RIGHT repeat events are consumed so they don't escape to the
  /// focus system as traversal actions.
  final bool verticalKeysAdjustValue;

  final TvNumberSpinnerDensity density;

  const TvNumberSpinner({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix,
    this.label,
    this.semanticLabel,
    this.autofocus = false,
    this.onConfirm,
    this.onCancel,
    this.verticalKeysAdjustValue = true,
    this.density = TvNumberSpinnerDensity.standard,
  });

  @override
  State<TvNumberSpinner> createState() => _TvNumberSpinnerState();
}

class _TvNumberSpinnerState extends State<TvNumberSpinner> with KeyRepeatHelper<TvNumberSpinner> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  final _backGate = BackPressGate();

  @override
  void initState() {
    super.initState();
    final label = widget.label;
    _focusNode = FocusNode(debugLabel: label == null ? 'TvNumberSpinner' : 'TvNumberSpinner_$label');
  }

  @override
  void dispose() {
    stopRepeat();
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

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    final vertical = widget.verticalKeysAdjustValue;

    if (widget.onCancel != null) {
      final backResult = _backGate.handle(event, widget.onCancel!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    // Let UP/DOWN pass through for focus traversal between rows.
    if (!vertical && (key.isUpKey || key.isDownKey)) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (key.isSelectKey && widget.onConfirm != null) {
        widget.onConfirm!();
        return KeyEventResult.handled;
      }
      if ((vertical && key.isUpKey) || key.isRightKey) {
        startRepeat(_increment);
        return KeyEventResult.handled;
      } else if ((vertical && key.isDownKey) || key.isLeftKey) {
        startRepeat(_decrement);
        return KeyEventResult.handled;
      }
    } else if (event is KeyRepeatEvent) {
      // The repeat timer from KeyDown already handles value repetition, so
      // swallow the OS repeats that would otherwise traverse focus. Only
      // needed when UP/DOWN traverse — otherwise no direction escapes.
      if (!vertical && (key.isRightKey || key.isLeftKey)) {
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if ((vertical && (key.isUpKey || key.isDownKey)) || key.isRightKey || key.isLeftKey) {
        stopRepeat();
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
    final isCompact = widget.density == TvNumberSpinnerDensity.compact;
    final gap = isCompact ? const SizedBox(width: 8) : const SizedBox(width: 16);
    final label = widget.label;
    final semanticLabel = widget.semanticLabel;
    final t = Translations.of(context);
    final decrementLabel = semanticLabel != null
        ? t.accessibility.decreaseValue(label: semanticLabel)
        : t.accessibility.decrease;
    final incrementLabel = semanticLabel != null
        ? t.accessibility.increaseValue(label: semanticLabel)
        : t.accessibility.increase;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: false,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (!hasFocus) stopRepeat();
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
          mainAxisSize: isCompact ? .max : .min,
          mainAxisAlignment: isCompact ? .start : .center,
          children: [
            if (label != null) ...[
              SizedBox(
                width: 24,
                child: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: .bold)),
              ),
              gap,
            ],
            _SpinnerButton(
              icon: Symbols.remove_rounded,
              onPressed: canDecrement ? _decrement : null,
              onLongPressStart: !isCompact && canDecrement ? () => startRepeat(_decrement) : null,
              onLongPressEnd: isCompact ? null : stopRepeat,
              semanticLabel: decrementLabel,
              compact: isCompact,
            ),
            gap,
            Container(
              constraints: BoxConstraints(minWidth: isCompact ? 56 : 60),
              alignment: .center,
              child: Text(
                '${widget.value}${widget.suffix ?? ''}',
                style: isCompact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.headlineMedium?.copyWith(fontWeight: .bold),
              ),
            ),
            gap,
            _SpinnerButton(
              icon: Symbols.add_rounded,
              onPressed: canIncrement ? _increment : null,
              onLongPressStart: !isCompact && canIncrement ? () => startRepeat(_increment) : null,
              onLongPressEnd: isCompact ? null : stopRepeat,
              semanticLabel: incrementLabel,
              compact: isCompact,
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
  final bool compact;

  const _SpinnerButton({
    required this.icon,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.semanticLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final size = compact ? 36.0 : 48.0;

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.all(Radius.circular(compact ? 20 : 24)),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: AppIcon(
              icon,
              size: compact ? 18 : null,
              fill: 1,
              color: isEnabled
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );

    if (onLongPressStart != null || onLongPressEnd != null) {
      button = GestureDetector(
        onLongPressStart: onLongPressStart != null ? (_) => onLongPressStart!() : null,
        onLongPressEnd: onLongPressEnd != null ? (_) => onLongPressEnd!() : null,
        child: button,
      );
    }

    return Semantics(label: semanticLabel, button: true, enabled: isEnabled, child: button);
  }
}
