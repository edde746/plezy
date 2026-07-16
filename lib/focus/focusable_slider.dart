import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dpad_navigator.dart';
import 'focusable_wrapper.dart';
import 'input_mode_tracker.dart';

class FocusableSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;

  final Color? activeColor;
  final Color? inactiveColor;
  const FocusableSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<FocusableSlider> createState() => _FocusableSliderState();
}

class _FocusableSliderState extends State<FocusableSlider> {
  bool _isFocused = false;

  double get _step {
    if (widget.divisions != null && widget.divisions! > 0) {
      return (widget.max - widget.min) / widget.divisions!;
    }
    return (widget.max - widget.min) * 0.05;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key.isLeftKey || key.isRightKey) {
      if (event.isActionable && widget.onChanged != null) {
        final delta = key.isRightKey ? _step : -_step;
        final newValue = (widget.value + delta).clamp(widget.min, widget.max);
        widget.onChangeStart?.call(widget.value);
        widget.onChanged!(newValue);
        widget.onChangeEnd?.call(newValue);
      }
      return KeyEventResult.handled;
    }
    if (key.isSelectKey && event is KeyDownEvent && widget.onSelect != null) {
      widget.onSelect!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderTheme.of(context);
    return FocusableWrapper(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: false,
      disableScale: true,
      focusColor: Colors.transparent,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: _handleKeyEvent,
      child: SliderTheme(
        data: sliderTheme.copyWith(
          overlayShape: sliderTheme.overlayShape ?? const RoundSliderOverlayShape(overlayRadius: 0),
          thumbSize: WidgetStatePropertyAll(
            (!InputModeTracker.isKeyboardMode(context) || _isFocused) ? const Size(4, 20) : Size.zero,
          ),
        ),
        child: Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: widget.onChanged,
          onChangeStart: widget.onChangeStart,
          onChangeEnd: widget.onChangeEnd,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
        ),
      ),
    );
  }
}
