import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_theme.dart';
import '../../focus/key_event_utils.dart';
import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../mixins/controller_disposer_mixin.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/clickable_cursor.dart';

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
  final _cancelFocusNode = FocusNode(debugLabel: 'PinCancelButton');
  bool _completed = false;

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
    _cancelFocusNode.dispose();
    super.dispose();
  }

  void _submit(String pin) {
    if (_completed) return;
    _completed = true;
    Navigator.of(context).pop<String>(pin);
  }

  void _cancel() {
    if (_completed) return;
    _completed = true;
    Navigator.of(context).pop<String>();
  }

  void _focusPinInput() {
    _pinInputKey.currentState?._requestInputFocus();
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
      child: isMobile ? _buildMobileDialog(theme) : _buildTvDialog(theme),
    );
  }

  Widget _buildMobileDialog(ThemeData theme) {
    return AlertDialog(
      title: _buildTitle(theme),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TvPinInput(
            key: _pinInputKey,
            onSubmit: _submit,
            onCancel: _cancel,
            hasError: widget.errorMessage != null,
            isMobile: true,
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(widget.errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12), maxLines: 2),
          ],
        ],
      ),
      actions: [
        FocusableButton(
          focusNode: _cancelFocusNode,
          onPressed: _cancel,
          onNavigateUp: _focusPinInput,
          onBack: _cancel,
          child: TextButton(onPressed: _cancel, child: Text(t.common.cancel)),
        ),
      ],
    );
  }

  Widget _buildTvDialog(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitle(theme),
            const SizedBox(height: 12),
            _TvPinInput(
              key: _pinInputKey,
              onSubmit: _submit,
              onCancel: _cancel,
              hasError: widget.errorMessage != null,
              isMobile: false,
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(widget.errorMessage!, style: TextStyle(color: colorScheme.error, fontSize: 12), maxLines: 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Row(
      children: [
        AppIcon(Symbols.lock_outline_rounded, fill: 1, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(widget.userName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _TvPinInput extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;
  final bool hasError;
  final bool isMobile;

  const _TvPinInput({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    required this.hasError,
    required this.isMobile,
  });

  @override
  State<_TvPinInput> createState() => _TvPinInputState();
}

class _TvPinInputState extends State<_TvPinInput> with ControllerDisposerMixin {
  static const _keySize = 60.0;
  static const _keyGap = 6.0;
  static const _rowGap = 6.0;
  static const _keypadColumns = 3;
  static const _rows = <List<_PinKey>>[
    [_PinKey.digit(1), _PinKey.digit(2), _PinKey.digit(3)],
    [_PinKey.digit(4), _PinKey.digit(5), _PinKey.digit(6)],
    [_PinKey.digit(7), _PinKey.digit(8), _PinKey.digit(9)],
    [_PinKey.close(), _PinKey.digit(0), _PinKey.backspace()],
  ];

  final List<int?> _digits = [null, null, null, null];
  int _activeIndex = 0;
  int _row = 0;
  int _column = 0;

  // Keep a single mobile text input client so iOS does not hide/show the
  // software keyboard while advancing between visual PIN boxes.
  final FocusNode _mobileFocusNode = FocusNode(debugLabel: 'PinInputMobile');
  late final TextEditingController _mobileController = createTextEditingController();
  final FocusNode _keypadFocusNode = FocusNode(debugLabel: 'PinKeypad');
  bool _keypadRefocusScheduled = false;

  @override
  void initState() {
    super.initState();
    _mobileFocusNode.addListener(_handleMobileFocusChanged);
    _keypadFocusNode.addListener(_handleKeypadFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.hasError) _reset();
      if (widget.isMobile) {
        _requestMobileKeyboardFocus();
      } else {
        _requestKeypadFocus();
      }
    });
  }

  @override
  void dispose() {
    _keypadFocusNode.removeListener(_handleKeypadFocusChanged);
    _keypadFocusNode.dispose();
    _mobileFocusNode.removeListener(_handleMobileFocusChanged);
    _mobileFocusNode.dispose();
    super.dispose();
  }

  void _handleMobileFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleKeypadFocusChanged() {
    if (!mounted || widget.isMobile || _keypadFocusNode.hasFocus) return;
    _scheduleKeypadRefocus();
  }

  void _scheduleKeypadRefocus() {
    if (_keypadRefocusScheduled) return;
    _keypadRefocusScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keypadRefocusScheduled = false;
      if (!mounted || widget.isMobile || _keypadFocusNode.hasFocus) return;
      _requestKeypadFocus();
    });
  }

  void _reset() {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _digits[i] = null;
      }
      if (widget.isMobile) _mobileController.clear();
      _activeIndex = 0;
    });
    if (widget.isMobile) {
      _requestMobileKeyboardFocus();
    } else {
      _row = 0;
      _column = 0;
      _requestKeypadFocus();
    }
  }

  int get _pinLength {
    for (int i = 0; i < _digits.length; i++) {
      if (_digits[i] == null) return i;
    }
    return _digits.length;
  }

  String? _getPin() {
    if (_digits.any((d) => d == null)) return null;
    return _digits.map((d) => d.toString()).join();
  }

  void _trySubmit() {
    final pin = _getPin();
    if (pin != null) widget.onSubmit(pin);
  }

  void _requestInputFocus() {
    if (widget.isMobile) {
      _requestMobileKeyboardFocus();
    } else {
      _requestKeypadFocus();
    }
  }

  void _requestKeypadFocus() {
    if (widget.isMobile) return;
    _keypadFocusNode.requestFocus();
  }

  void _requestMobileKeyboardFocus() {
    _mobileFocusNode.requestFocus();
    final offset = _mobileController.text.length;
    _mobileController.selection = TextSelection.collapsed(offset: offset);
  }

  void _setPinFromString(String pin) {
    setState(() {
      for (int i = 0; i < 4; i++) {
        _digits[i] = i < pin.length ? int.parse(pin[i]) : null;
      }
      _activeIndex = pin.length >= 4 ? 3 : pin.length;
    });

    if (pin.length == 4) _submitWhenCompleteAfterFrame();
  }

  void _appendDigit(int digit) {
    final length = _pinLength;
    if (length >= _digits.length) return;

    setState(() {
      _digits[length] = digit;
      final nextLength = length + 1;
      _activeIndex = nextLength >= _digits.length ? _digits.length - 1 : nextLength;
    });

    if (length + 1 == _digits.length) _submitWhenCompleteAfterFrame();
  }

  void _deleteLastDigit() {
    final length = _pinLength;
    if (length == 0) return;

    setState(() {
      _digits[length - 1] = null;
      _activeIndex = length - 1;
    });
  }

  void _submitWhenCompleteAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pin = _getPin();
      if (pin != null) widget.onSubmit(pin);
    });
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

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    final backResult = handleBackKeyAction(event, widget.onCancel);
    if (backResult != KeyEventResult.ignored) return backResult;

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _deleteLastDigit();
        return KeyEventResult.handled;
      }

      if (event.isTvSelectEvent || (PlatformDetector.isTV() && event.isPhysicalKeyboardEnter)) {
        _activate(_rows[_row][_column]);
        return KeyEventResult.handled;
      }

      if (event.isPhysicalKeyboardEnter) {
        _trySubmit();
        return KeyEventResult.handled;
      }

      if (key.isUpKey) {
        _moveVertical(-1);
        return KeyEventResult.handled;
      }
      if (key.isDownKey) {
        _moveVertical(1);
        return KeyEventResult.handled;
      }
      if (key.isLeftKey) {
        _moveHorizontal(-1);
        return KeyEventResult.handled;
      }
      if (key.isRightKey) {
        _moveHorizontal(1);
        return KeyEventResult.handled;
      }

      if (event is! KeyDownEvent) return KeyEventResult.handled;

      final digit = _digitKeyMap[key];
      if (digit != null) {
        _appendDigit(digit);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.handled;
  }

  void _onMobilePinChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    final pin = digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;
    if (pin != value) {
      _mobileController.value = TextEditingValue(
        text: pin,
        selection: TextSelection.collapsed(offset: pin.length),
      );
    }

    _setPinFromString(pin);
  }

  void _activate(_PinKey key) {
    switch (key.type) {
      case _PinKeyType.digit:
        _appendDigit(key.digit!);
        return;
      case _PinKeyType.backspace:
        _deleteLastDigit();
        return;
      case _PinKeyType.close:
        widget.onCancel();
        return;
    }
  }

  void _moveHorizontal(int delta) {
    setState(() {
      _column = (_column + delta).clamp(0, _keypadColumns - 1).toInt();
    });
  }

  void _moveVertical(int delta) {
    setState(() {
      _row = (_row + delta).clamp(0, _rows.length - 1).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileLayout(context);
    }

    return Focus(
      focusNode: _keypadFocusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: _buildKeypadLayout(context),
    );
  }

  Widget _buildKeypadLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildDigitRow(context, obscureDigits: true), const SizedBox(height: 18), _buildKeypad(context)],
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < _rows.length; row++) ...[
          if (row > 0) const SizedBox(height: _rowGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < _keypadColumns; col++) ...[
                if (col > 0) const SizedBox(width: _keyGap),
                _buildKey(context, _rows[row][col], row, col),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, _PinKey key, int row, int column) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = row == _row && column == _column;
    final background = selected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.88);
    final foreground = selected ? colorScheme.onPrimary : colorScheme.onSurface;

    return ClickableCursor(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _row = row;
            _column = column;
          });
          _activate(key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _keySize,
          height: _keySize,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeyContent(context, key, foreground),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyContent(BuildContext context, _PinKey key, Color foreground) {
    final icon = key.icon;
    if (icon != null) return Icon(icon, color: foreground, size: 30);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        key.label,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildDigitRow(BuildContext _, {bool obscureDigits = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _DigitBox(
            digit: _digits[i],
            isActive: (widget.isMobile ? _mobileFocusNode.hasFocus : true) && _activeIndex == i,
            obscureDigit: obscureDigits,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _requestMobileKeyboardFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 222,
            height: 56,
            child: IgnorePointer(
              child: TextField(
                controller: _mobileController,
                focusNode: _mobileFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                maxLength: 4,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                enableInteractiveSelection: false,
                showCursor: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent, fontSize: 1, height: 1),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                onChanged: _onMobilePinChanged,
                onSubmitted: (_) => _trySubmit(),
              ),
            ),
          ),
          _buildDigitRow(context, obscureDigits: true),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  final int? digit;
  final bool isActive;
  final bool obscureDigit;

  const _DigitBox({required this.digit, required this.isActive, this.obscureDigit = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = FocusTheme.getFocusBorderColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(FocusTheme.defaultBorderRadius)),
            border: Border.fromBorderSide(
              BorderSide(
                color: isActive ? focusColor : theme.colorScheme.outlineVariant,
                width: isActive ? FocusTheme.focusBorderWidth : 1.5,
              ),
            ),
            color: isActive ? focusColor.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Text(
            digit != null ? (obscureDigit || !isActive ? '•' : digit.toString()) : '–',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: digit != null
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}

enum _PinKeyType { digit, backspace, close }

class _PinKey {
  final _PinKeyType type;
  final int? digit;

  const _PinKey.digit(this.digit) : type = _PinKeyType.digit;
  const _PinKey.backspace() : type = _PinKeyType.backspace, digit = null;
  const _PinKey.close() : type = _PinKeyType.close, digit = null;

  String get label {
    switch (type) {
      case _PinKeyType.digit:
        return digit.toString();
      case _PinKeyType.backspace:
        return t.common.delete;
      case _PinKeyType.close:
        return t.common.cancel;
    }
  }

  IconData? get icon {
    switch (type) {
      case _PinKeyType.digit:
        return null;
      case _PinKeyType.backspace:
        return Icons.backspace_outlined;
      case _PinKeyType.close:
        return Icons.close_rounded;
    }
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

/// Two-step "set + confirm" PIN entry. Returns the matching PIN, or null
/// when the user cancels. On mismatch, surfaces a snackbar via [onMismatch]
/// (or no-op if not provided) and returns null — the helper keeps the UX
/// in one place so multiple call sites don't drift.
Future<String?> captureAndConfirmPin(
  BuildContext context, {
  String? setLabel,
  String? confirmLabel,
  void Function(BuildContext)? onMismatch,
}) async {
  final pin = await showPinEntryDialog(context, setLabel ?? t.profiles.setPinTitle);
  if (pin == null || !context.mounted) return null;
  final confirm = await showPinEntryDialog(context, confirmLabel ?? t.profiles.confirmPinTitle);
  if (confirm == null || !context.mounted) return null;
  if (pin == confirm) return pin;
  onMismatch?.call(context);
  return null;
}
