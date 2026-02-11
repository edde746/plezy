import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';

/// Dialog for entering a 4-digit PIN to access a protected profile.
class PinEntryDialog extends StatefulWidget {
  final String userName;
  final String? errorMessage;

  const PinEntryDialog({super.key, required this.userName, this.errorMessage});

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final _pinInputKey = GlobalKey<_TvPinInputState>();

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shakeController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _submit(String pin) {
    Navigator.of(context).pop(pin);
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTV = PlatformDetector.isTV();
    final isMobile = PlatformDetector.isMobile(context) && !isTV;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(offset: Offset(_shakeAnimation.value, 0), child: child);
      },
      child: AlertDialog(
        title: Row(
          children: [
            AppIcon(Symbols.lock_outline_rounded, fill: 1, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.userName, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TvPinInput(
              key: _pinInputKey,
              onSubmit: _submit,
              onCancel: _cancel,
              hasError: widget.errorMessage != null,
              isMobile: isMobile,
              isTV: isTV,
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(widget.errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12), maxLines: 2),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: _cancel, child: Text(t.common.cancel)),
          if (!isMobile)
            FilledButton(
              onPressed: () => _pinInputKey.currentState?._trySubmit(),
              child: Text(t.common.submit),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TvPinInput — unified 4-digit PIN input
// ---------------------------------------------------------------------------

class _TvPinInput extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final bool hasError;
  final bool isMobile;
  final bool isTV;

  const _TvPinInput({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    required this.hasError,
    required this.isMobile,
    required this.isTV,
  });

  @override
  State<_TvPinInput> createState() => _TvPinInputState();
}

class _TvPinInputState extends State<_TvPinInput> {
  final List<int?> _digits = [null, null, null, null];
  int _activeIndex = 0;
  bool _isFocused = false;
  Timer? _repeatTimer;

  // Hidden text fields for mobile keyboard input
  final List<FocusNode> _mobileFocusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _mobileControllers = List.generate(4, (_) => TextEditingController());

  // Main focus node for TV/desktop keyboard handling
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'PinInput');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hasError) _reset();
      if (widget.isMobile) {
        _mobileFocusNodes[0].requestFocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _focusNode.dispose();
    for (final node in _mobileFocusNodes) {
      node.dispose();
    }
    for (final controller in _mobileControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _reset() {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _digits[i] = null;
        if (widget.isMobile) _mobileControllers[i].clear();
      }
      _activeIndex = 0;
    });
    if (widget.isMobile) {
      _mobileFocusNodes[0].requestFocus();
    }
  }

  String? _getPin() {
    if (_digits.any((d) => d == null)) return null;
    return _digits.map((d) => d.toString()).join();
  }

  void _trySubmit() {
    final pin = _getPin();
    if (pin != null) widget.onSubmit(pin);
  }

  // -- D-pad / keyboard handling (TV + desktop) --

  void _incrementDigit() {
    setState(() {
      _digits[_activeIndex] = ((_digits[_activeIndex] ?? -1) + 1) % 10;
    });
  }

  void _decrementDigit() {
    setState(() {
      final current = _digits[_activeIndex] ?? 0;
      _digits[_activeIndex] = (current - 1 + 10) % 10;
    });
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

  // Map digit keys (both main keyboard and numpad)
  static final _digitKeyMap = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.digit0: 0,
    LogicalKeyboardKey.digit1: 1,
    LogicalKeyboardKey.digit2: 2,
    LogicalKeyboardKey.digit3: 3,
    LogicalKeyboardKey.digit4: 4,
    LogicalKeyboardKey.digit5: 5,
    LogicalKeyboardKey.digit6: 6,
    LogicalKeyboardKey.digit7: 7,
    LogicalKeyboardKey.digit8: 8,
    LogicalKeyboardKey.digit9: 9,
    LogicalKeyboardKey.numpad0: 0,
    LogicalKeyboardKey.numpad1: 1,
    LogicalKeyboardKey.numpad2: 2,
    LogicalKeyboardKey.numpad3: 3,
    LogicalKeyboardKey.numpad4: 4,
    LogicalKeyboardKey.numpad5: 5,
    LogicalKeyboardKey.numpad6: 6,
    LogicalKeyboardKey.numpad7: 7,
    LogicalKeyboardKey.numpad8: 8,
    LogicalKeyboardKey.numpad9: 9,
  };

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Back / escape → cancel
    final backResult = handleBackKeyAction(event, widget.onCancel);
    if (backResult != KeyEventResult.ignored) return backResult;

    if (event is KeyDownEvent) {
      // Number key input (desktop only, TV uses d-pad)
      if (!widget.isTV) {
        final digit = _digitKeyMap[key];
        if (digit != null) {
          setState(() {
            _digits[_activeIndex] = digit;
            if (_activeIndex < 3) _activeIndex++;
          });
          return KeyEventResult.handled;
        }
      }

      // Backspace → clear and move left
      if (key == LogicalKeyboardKey.backspace) {
        setState(() {
          if (_digits[_activeIndex] != null) {
            _digits[_activeIndex] = null;
          } else if (_activeIndex > 0) {
            _activeIndex--;
            _digits[_activeIndex] = null;
          }
        });
        return KeyEventResult.handled;
      }

      // Up arrow → increment digit
      if (key.isUpKey) {
        _startRepeat(_incrementDigit);
        return KeyEventResult.handled;
      }

      // Down arrow → decrement digit
      if (key.isDownKey) {
        _startRepeat(_decrementDigit);
        return KeyEventResult.handled;
      }

      // Left arrow → move active index left
      if (key.isLeftKey) {
        if (_activeIndex > 0) {
          setState(() => _activeIndex--);
        }
        return KeyEventResult.handled;
      }

      // Right arrow → move active index right or advance to submit button
      if (key.isRightKey) {
        if (_activeIndex < 3) {
          setState(() => _activeIndex++);
          return KeyEventResult.handled;
        }
        // At rightmost digit, let focus move to submit button
        return KeyEventResult.ignored;
      }

      // Select / Enter → submit
      if (key.isSelectKey) {
        _trySubmit();
        return KeyEventResult.handled;
      }
    }

    if (event is KeyUpEvent) {
      if (key.isUpKey || key.isDownKey) {
        _stopRepeat();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // -- Mobile input handling --

  void _onMobileDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Backspace
      setState(() => _digits[index] = null);
      if (index > 0) {
        _mobileFocusNodes[index - 1].requestFocus();
        setState(() => _activeIndex = index - 1);
      }
      return;
    }

    // Take only the last character (handles paste/overwrite)
    final digit = int.tryParse(value[value.length - 1]);
    if (digit == null) {
      _mobileControllers[index].clear();
      return;
    }

    setState(() {
      _digits[index] = digit;
      _activeIndex = index;
      _mobileControllers[index].text = digit.toString();
      _mobileControllers[index].selection = TextSelection.collapsed(offset: 1);
    });

    if (index < 3) {
      _mobileFocusNodes[index + 1].requestFocus();
      setState(() => _activeIndex = index + 1);
    } else {
      // 4th digit entered → auto-submit
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pin = _getPin();
        if (pin != null) widget.onSubmit(pin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final showArrows = (widget.isTV || isKeyboardMode) && !widget.isMobile;

    if (widget.isMobile) {
      return _buildMobileLayout(context);
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (!hasFocus) _stopRepeat();
      },
      onKeyEvent: _handleKeyEvent,
      child: _buildDigitRow(context, showArrows: showArrows),
    );
  }

  Widget _buildDigitRow(BuildContext context, {required bool showArrows}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _DigitBox(
            digit: _digits[i],
            isActive: _isFocused && _activeIndex == i,
            showArrows: showArrows && _isFocused && _activeIndex == i,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 60,
            child: TextField(
              controller: _mobileControllers[i],
              focusNode: _mobileFocusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 2, // allow overwrite
              obscureText: true,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onMobileDigitChanged(i, value),
              onSubmitted: (_) => _trySubmit(),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _DigitBox — single digit display box for TV/desktop
// ---------------------------------------------------------------------------

class _DigitBox extends StatelessWidget {
  final int? digit;
  final bool isActive;
  final bool showArrows;

  const _DigitBox({required this.digit, required this.isActive, required this.showArrows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = FocusTheme.getFocusBorderColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up chevron
        SizedBox(
          height: 20,
          child: showArrows
              ? AppIcon(Symbols.keyboard_arrow_up_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        // Digit box
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
            border: Border.all(
              color: isActive ? focusColor : theme.colorScheme.outlineVariant,
              width: isActive ? FocusTheme.focusBorderWidth : 1.5,
            ),
            color: isActive ? focusColor.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Text(
            digit != null ? digit.toString() : '–',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: digit != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
        // Down chevron
        SizedBox(
          height: 20,
          child: showArrows
              ? AppIcon(Symbols.keyboard_arrow_down_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
      ],
    );
  }
}

/// Shows the PIN entry dialog and returns the entered PIN, or null if cancelled
Future<String?> showPinEntryDialog(BuildContext context, String userName, {String? errorMessage}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinEntryDialog(userName: userName, errorMessage: errorMessage),
  );
}
