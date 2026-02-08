import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../theme/mono_tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'app_icon.dart';

/// A TV-friendly color picker using HSV sliders for D-pad navigation.
///
/// Each channel row responds to LEFT/RIGHT for value adjustment while
/// letting UP/DOWN pass through for normal focus traversal between rows.
class TvColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  /// Called when the user presses SELECT on a channel row.
  /// Use this to move focus to a confirm/save button.
  final VoidCallback? onConfirm;

  const TvColorPicker({super.key, required this.initialColor, required this.onColorChanged, this.onConfirm});

  @override
  State<TvColorPicker> createState() => _TvColorPickerState();
}

class _TvColorPickerState extends State<TvColorPicker> {
  late int _hue;
  late int _saturation;
  late int _value;
  late TextEditingController _hexController;
  late FocusNode _hexFocusNode;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue.round();
    _saturation = (hsv.saturation * 100).round();
    _value = (hsv.value * 100).round();
    _hexController = TextEditingController(text: _currentHex());
    _hexFocusNode = FocusNode(debugLabel: 'TvColorPicker_hex', onKeyEvent: _handleHexKeyEvent);
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleHexKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    // Intercept UP/DOWN before the TextField consumes them,
    // so D-pad focus traversal works normally.
    if (key.isUpKey || key.isDownKey) {
      if (event is KeyDownEvent) {
        if (key.isUpKey) {
          node.previousFocus();
        } else {
          node.nextFocus();
        }
        return KeyEventResult.handled;
      }
      // Consume repeat/up events too so TextField doesn't act on them.
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Color _currentColor() {
    return HSVColor.fromAHSV(1.0, _hue.toDouble().clamp(0, 360), _saturation / 100.0, _value / 100.0).toColor();
  }

  String _currentHex() {
    final c = _currentColor();
    return '${((c.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
            '${((c.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
            '${((c.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _onChannelChanged() {
    _hexController.text = _currentHex();
    widget.onColorChanged(_currentColor());
  }

  void _onHexChanged(String text) {
    final cleaned = text.replaceAll('#', '').trim();
    if (cleaned.length != 6) return;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return;

    final color = Color(0xFF000000 | parsed);
    final hsv = HSVColor.fromColor(color);
    setState(() {
      _hue = hsv.hue.round();
      _saturation = (hsv.saturation * 100).round();
      _value = (hsv.value * 100).round();
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _currentColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        // Hue row
        _ColorChannelRow(
          label: 'H',
          value: _hue,
          min: 0,
          max: 360,
          step: 5,
          suffix: '°',
          autofocus: true,
          onConfirm: widget.onConfirm,
          onChanged: (v) {
            setState(() => _hue = v);
            _onChannelChanged();
          },
        ),
        const SizedBox(height: 8),
        // Saturation row
        _ColorChannelRow(
          label: 'S',
          value: _saturation,
          min: 0,
          max: 100,
          step: 5,
          suffix: '%',
          onConfirm: widget.onConfirm,
          onChanged: (v) {
            setState(() => _saturation = v);
            _onChannelChanged();
          },
        ),
        const SizedBox(height: 8),
        // Value row
        _ColorChannelRow(
          label: 'V',
          value: _value,
          min: 0,
          max: 100,
          step: 5,
          suffix: '%',
          onConfirm: widget.onConfirm,
          onChanged: (v) {
            setState(() => _value = v);
            _onChannelChanged();
          },
        ),
        const SizedBox(height: 16),
        // Hex input
        TextField(
          controller: _hexController,
          focusNode: _hexFocusNode,
          decoration: const InputDecoration(prefixText: '#', labelText: 'Hex', border: OutlineInputBorder()),
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))],
          onChanged: _onHexChanged,
        ),
      ],
    );
  }
}

/// A horizontal channel row for a single HSV component.
///
/// LEFT/RIGHT adjust the value (with repeat timer for held keys).
/// UP/DOWN are ignored so focus traverses normally between rows.
class _ColorChannelRow extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final bool autofocus;
  final ValueChanged<int> onChanged;

  /// Called when the user presses SELECT to confirm.
  final VoidCallback? onConfirm;

  const _ColorChannelRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.suffix,
    required this.onChanged,
    this.autofocus = false,
    this.onConfirm,
  });

  @override
  State<_ColorChannelRow> createState() => _ColorChannelRowState();
}

class _ColorChannelRowState extends State<_ColorChannelRow> {
  late FocusNode _focusNode;
  Timer? _repeatTimer;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'ColorChannel_${widget.label}');
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
    action();
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Let UP/DOWN pass through for focus traversal between rows
    if (key.isUpKey || key.isDownKey) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (key.isSelectKey && widget.onConfirm != null) {
        widget.onConfirm!();
        return KeyEventResult.handled;
      }
      if (key.isRightKey) {
        _startRepeat(_increment);
        return KeyEventResult.handled;
      } else if (key.isLeftKey) {
        _startRepeat(_decrement);
        return KeyEventResult.handled;
      }
    } else if (event is KeyRepeatEvent) {
      // Consume repeat events for LEFT/RIGHT so they don't escape
      // to the focus system as traversal actions. The repeat timer
      // from KeyDown already handles value repetition.
      if (key.isRightKey || key.isLeftKey) {
        return KeyEventResult.handled;
      }
    } else if (event is KeyUpEvent) {
      if (key.isRightKey || key.isLeftKey) {
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
          borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
          border: Border.all(
            color: _isFocused && isKeyboardMode ? FocusTheme.getFocusBorderColor(context) : Colors.transparent,
            width: FocusTheme.focusBorderWidth,
          ),
        ),
        child: Row(
          children: [
            // Label
            SizedBox(
              width: 24,
              child: Text(widget.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            // Decrement button
            _ChannelButton(
              icon: Symbols.remove_rounded,
              onPressed: canDecrement ? _decrement : null,
              semanticLabel: 'Decrease ${widget.label}',
            ),
            const SizedBox(width: 8),
            // Value display
            Container(
              constraints: const BoxConstraints(minWidth: 56),
              alignment: Alignment.center,
              child: Text('${widget.value}${widget.suffix}', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(width: 8),
            // Increment button
            _ChannelButton(
              icon: Symbols.add_rounded,
              onPressed: canIncrement ? _increment : null,
              semanticLabel: 'Increase ${widget.label}',
            ),
          ],
        ),
      ),
    );
  }
}

/// Small +/- button for a channel row.
class _ChannelButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const _ChannelButton({required this.icon, required this.onPressed, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: AppIcon(
                icon,
                size: 18,
                fill: 1,
                color: isEnabled
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
