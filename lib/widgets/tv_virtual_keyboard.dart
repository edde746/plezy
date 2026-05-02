import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../i18n/strings.g.dart';
import '../utils/platform_detector.dart';

Future<void> showTvVirtualKeyboard({
  required BuildContext context,
  required TextEditingController controller,
  String? hintText,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  List<TextInputFormatter>? inputFormatters,
  bool obscureText = false,
  int? maxLength,
  int? maxLines,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onAction,
}) {
  if (!PlatformDetector.isAppleTV()) return Future.value();

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _TvVirtualKeyboardDialog(
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onAction: onAction,
    ),
  );
}

enum _TvKeyType { spacer, character, shift, space, newline, backspace, clear, cancel, done }

class _TvKey {
  final String label;
  final String value;
  final _TvKeyType type;
  final IconData? icon;

  const _TvKey.spacer() : label = '', value = '', type = _TvKeyType.spacer, icon = null;
  const _TvKey.character(this.value) : label = value, type = _TvKeyType.character, icon = null;
  const _TvKey.action(this.label, this.type, {this.icon}) : value = '';
}

class _TvVirtualKeyboardDialog extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final int? maxLength;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onAction;

  const _TvVirtualKeyboardDialog({
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.maxLength,
    this.maxLines,
    this.onChanged,
    this.onSubmitted,
    this.onAction,
  });

  @override
  State<_TvVirtualKeyboardDialog> createState() => _TvVirtualKeyboardDialogState();
}

class _TvVirtualKeyboardDialogState extends State<_TvVirtualKeyboardDialog> {
  static const double _keySize = 60;
  static const double _keyGap = 6;
  static const double _rowGap = 6;

  final _focusNode = FocusNode(debugLabel: 'TvVirtualKeyboard');
  int _row = 0;
  int _column = 0;
  bool _shiftEnabled = false;

  List<List<_TvKey>> get _rows => _buildRows();

  @override
  void initState() {
    super.initState();
    _column = _firstFocusableColumn(_row) ?? 0;
    widget.controller.addListener(_handleTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _isNumberKeyboard {
    final type = widget.keyboardType;
    return type?.index == TextInputType.number.index || type?.index == TextInputType.phone.index;
  }

  bool get _isMultiline {
    final type = widget.keyboardType;
    return type?.index == TextInputType.multiline.index || (widget.maxLines != null && widget.maxLines != 1);
  }

  List<List<_TvKey>> _buildRows() {
    if (_isNumberKeyboard) {
      return [
        _characters('123'),
        _characters('456'),
        _characters('789'),
        [
          _TvKey.action(t.common.clear, _TvKeyType.clear, icon: Icons.clear_all_rounded),
          const _TvKey.character('0'),
          const _TvKey.action('Del', _TvKeyType.backspace, icon: Icons.backspace_outlined),
        ],
        [
          _TvKey.action(t.common.cancel, _TvKeyType.cancel, icon: Icons.close_rounded),
          const _TvKey.character('.'),
          _TvKey.action(_doneLabel(), _TvKeyType.done, icon: _doneIcon()),
        ],
      ];
    }

    final actionRow = [
      const _TvKey.action('Space', _TvKeyType.space, icon: Icons.space_bar_rounded),
      const _TvKey.character('@'),
      const _TvKey.character('#'),
      const _TvKey.character('_'),
      const _TvKey.character('/'),
      const _TvKey.character(':'),
      _isMultiline
          ? const _TvKey.action('Line', _TvKeyType.newline, icon: Icons.keyboard_return_rounded)
          : const _TvKey.character('&'),
      _TvKey.action(t.common.clear, _TvKeyType.clear, icon: Icons.clear_all_rounded),
      _TvKey.action(t.common.cancel, _TvKeyType.cancel, icon: Icons.close_rounded),
      _TvKey.action(_doneLabel(), _TvKeyType.done, icon: _doneIcon()),
    ];

    return [
      [const _TvKey.spacer(), ..._characters('1234567890')],
      [const _TvKey.spacer(), ..._characters('qwertyuiop')],
      [const _TvKey.spacer(), ..._characters('asdfghjkl'), const _TvKey.character("'")],
      [
        _TvKey.action('Shift', _TvKeyType.shift, icon: Symbols.shift),
        ..._characters('zxcvbnm.-'),
        const _TvKey.action('Del', _TvKeyType.backspace, icon: Icons.backspace_outlined),
      ],
      [const _TvKey.spacer(), ...actionRow],
    ];
  }

  List<_TvKey> _characters(String chars) {
    return chars
        .split('')
        .map((c) {
          final code = c.codeUnitAt(0);
          final shifted = _shiftEnabled && code >= 0x61 && code <= 0x7a ? c.toUpperCase() : c;
          return _TvKey.character(shifted);
        })
        .toList(growable: false);
  }

  String _doneLabel() {
    switch (widget.textInputAction) {
      case TextInputAction.search:
        return t.common.search;
      case TextInputAction.next:
        return t.companionRemote.remote.next;
      case TextInputAction.go:
        return t.common.submit;
      default:
        return t.common.ok;
    }
  }

  IconData _doneIcon() {
    switch (widget.textInputAction) {
      case TextInputAction.search:
        return Icons.search_rounded;
      case TextInputAction.next:
        return Icons.arrow_forward_rounded;
      case TextInputAction.go:
        return Icons.keyboard_double_arrow_right_rounded;
      default:
        return Icons.check_rounded;
    }
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isBackKey) {
      if (event is KeyDownEvent) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
        _backspace();
        return KeyEventResult.handled;
      }

      if (key.isSelectKey) {
        _activate(_rows[_row][_column]);
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

      final character = event.character;
      if (character != null && character.isNotEmpty && !key.isNavigationKey) {
        _insert(character);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.handled;
  }

  void _moveHorizontal(int delta) {
    final nextColumn = _nextFocusableColumn(_row, _column + delta, delta);
    if (nextColumn == null) return;
    setState(() {
      _column = nextColumn;
    });
  }

  void _moveVertical(int delta) {
    final rows = _rows;
    final nextRow = (_row + delta).clamp(0, rows.length - 1).toInt();
    final nextColumn = _nearestFocusableColumn(nextRow, _column);
    setState(() {
      _row = nextRow;
      _column = nextColumn;
    });
  }

  int? _firstFocusableColumn(int row) {
    final rows = _rows;
    if (row < 0 || row >= rows.length) return null;
    final index = rows[row].indexWhere(_isFocusableKey);
    return index == -1 ? null : index;
  }

  int? _nextFocusableColumn(int row, int column, int delta) {
    final rows = _rows;
    if (row < 0 || row >= rows.length) return null;
    for (var c = column; c >= 0 && c < rows[row].length; c += delta) {
      if (_isFocusableKey(rows[row][c])) return c;
    }
    return null;
  }

  int _nearestFocusableColumn(int row, int preferredColumn) {
    final rows = _rows;
    if (row < 0 || row >= rows.length) return preferredColumn;
    final keys = rows[row];
    if (preferredColumn >= 0 && preferredColumn < keys.length && _isFocusableKey(keys[preferredColumn])) {
      return preferredColumn;
    }
    for (var offset = 1; offset < keys.length; offset++) {
      final right = preferredColumn + offset;
      if (right >= 0 && right < keys.length && _isFocusableKey(keys[right])) return right;
      final left = preferredColumn - offset;
      if (left >= 0 && left < keys.length && _isFocusableKey(keys[left])) return left;
    }
    return _firstFocusableColumn(row) ?? 0;
  }

  bool _isFocusableKey(_TvKey key) => key.type != _TvKeyType.spacer;

  void _activate(_TvKey key) {
    switch (key.type) {
      case _TvKeyType.spacer:
        return;
      case _TvKeyType.character:
        _insert(key.value);
        return;
      case _TvKeyType.shift:
        setState(() => _shiftEnabled = !_shiftEnabled);
        return;
      case _TvKeyType.space:
        _insert(' ');
        return;
      case _TvKeyType.newline:
        _insert('\n');
        return;
      case _TvKeyType.backspace:
        _backspace();
        return;
      case _TvKeyType.clear:
        _replace(TextEditingValue.empty);
        return;
      case _TvKeyType.cancel:
        Navigator.of(context).pop();
        return;
      case _TvKeyType.done:
        _submit();
        return;
    }
  }

  void _submit() {
    final text = widget.controller.text;
    final onSubmitted = widget.onSubmitted;
    final onAction = widget.onAction;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onSubmitted != null) {
        onSubmitted(text);
      } else {
        onAction?.call();
      }
    });
  }

  void _insert(String text) {
    final value = widget.controller.value;
    final selection = value.selection;
    final start = selection.isValid
        ? (selection.start < selection.end ? selection.start : selection.end)
        : value.text.length;
    final end = selection.isValid
        ? (selection.start > selection.end ? selection.start : selection.end)
        : value.text.length;
    final newText = value.text.replaceRange(start, end, text);
    _replace(
      value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + text.length),
        composing: TextRange.empty,
      ),
    );
  }

  void _backspace() {
    final value = widget.controller.value;
    final selection = value.selection;
    final start = selection.isValid
        ? (selection.start < selection.end ? selection.start : selection.end)
        : value.text.length;
    final end = selection.isValid
        ? (selection.start > selection.end ? selection.start : selection.end)
        : value.text.length;

    if (start != end) {
      _replace(
        value.copyWith(
          text: value.text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start),
        ),
      );
      return;
    }
    if (start == 0) return;

    _replace(
      value.copyWith(
        text: value.text.replaceRange(start - 1, start, ''),
        selection: TextSelection.collapsed(offset: start - 1),
        composing: TextRange.empty,
      ),
    );
  }

  void _replace(TextEditingValue nextValue) {
    final previousValue = widget.controller.value;
    var formattedValue = nextValue;
    final maxLength = widget.maxLength;
    final formatters = [
      ...?widget.inputFormatters,
      if (maxLength != null && maxLength > 0) LengthLimitingTextInputFormatter(maxLength),
    ];
    for (final formatter in formatters) {
      formattedValue = formatter.formatEditUpdate(previousValue, formattedValue);
    }
    widget.controller.value = formattedValue;
    widget.onChanged?.call(formattedValue.text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
      backgroundColor: Colors.transparent,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreview(context, text),
              const SizedBox(height: 12),
              for (var row = 0; row < _rows.length; row++) ...[
                _buildRow(context, row),
                if (row != _rows.length - 1) const SizedBox(height: _rowGap),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmpty = text.isEmpty;
    final displayText = widget.obscureText && !isEmpty ? List.filled(text.length, '*').join() : text;
    final previewText = isEmpty ? (widget.hintText ?? '') : displayText;
    final multiline = _isMultiline;

    return Container(
      height: multiline ? 86 : 60,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: multiline
          ? SingleChildScrollView(
              reverse: true,
              child: Text(
                previewText,
                maxLines: 3,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                previewText,
                maxLines: 1,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                ),
              ),
            ),
    );
  }

  Widget _buildRow(BuildContext context, int row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var column = 0; column < _rows[row].length; column++) ...[
          _buildKey(context, _rows[row][column], row, column),
          if (column != _rows[row].length - 1) const SizedBox(width: _keyGap),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, _TvKey key, int row, int column) {
    if (key.type == _TvKeyType.spacer) {
      return const SizedBox(width: _keySize, height: _keySize);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selected = row == _row && column == _column;
    final active = key.type == _TvKeyType.shift && _shiftEnabled;
    final background = selected
        ? colorScheme.primary
        : active
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.88);
    final foreground = selected
        ? colorScheme.onPrimary
        : active
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;

    return GestureDetector(
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
    );
  }

  Widget _buildKeyContent(BuildContext context, _TvKey key, Color foreground) {
    final icon = key.icon;
    if (icon != null) {
      return Icon(icon, color: foreground, size: key.type == _TvKeyType.space ? 34 : 30);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        key.label,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800),
      ),
    );
  }
}
