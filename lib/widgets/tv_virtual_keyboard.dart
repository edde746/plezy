import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../i18n/strings.g.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../utils/platform_detector.dart';
import 'clickable_cursor.dart';

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
  if (!PlatformDetector.isTV()) return Future.value();

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.10),
    useSafeArea: false,
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

enum _TvKeyType { spacer, character, shift, symbols, space, newline, backspace, clear, cancel, done }

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

class _TvVirtualKeyboardDialogState extends State<_TvVirtualKeyboardDialog> with MountedSetStateMixin {
  final _focusNode = FocusNode(debugLabel: 'TvVirtualKeyboard');
  int _row = 0;
  int _column = 0;
  bool _shiftEnabled = false;
  bool _symbolsPage = false;

  List<List<_TvKey>> get _rows => _symbolsPage ? _buildSymbolRows() : _buildMainRows();
  int get _gridColumnCount => _isNumberKeyboard ? 3 : 12;

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
    setStateIfMounted(() {});
  }

  bool get _isNumberKeyboard {
    final type = widget.keyboardType;
    return type?.index == TextInputType.number.index || type?.index == TextInputType.phone.index;
  }

  bool get _isMultiline {
    final type = widget.keyboardType;
    return type?.index == TextInputType.multiline.index || (widget.maxLines != null && widget.maxLines != 1);
  }

  List<List<_TvKey>> _buildMainRows() {
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
      const _TvKey.character('='),
      _isMultiline
          ? const _TvKey.action('Line', _TvKeyType.newline, icon: Icons.keyboard_return_rounded)
          : const _TvKey.character('&'),
      _TvKey.action(t.common.clear, _TvKeyType.clear, icon: Icons.clear_all_rounded),
      _TvKey.action(t.common.cancel, _TvKeyType.cancel, icon: Icons.close_rounded),
      _TvKey.action(_doneLabel(), _TvKeyType.done, icon: _doneIcon()),
    ];

    return [
      [const _TvKey.spacer(), ..._characters('1234567890'), const _TvKey.spacer()],
      [const _TvKey.spacer(), ..._characters('qwertyuiop'), const _TvKey.spacer()],
      [const _TvKey.spacer(), ..._characters('asdfghjkl'), const _TvKey.character("'"), const _TvKey.spacer()],
      [
        const _TvKey.action('', _TvKeyType.symbols, icon: Icons.functions_rounded),
        _TvKey.action('Shift', _TvKeyType.shift, icon: Symbols.shift),
        ..._characters('zxcvbnm.-'),
        const _TvKey.action('Del', _TvKeyType.backspace, icon: Icons.backspace_outlined),
      ],
      [const _TvKey.spacer(), ...actionRow],
    ];
  }

  List<List<_TvKey>> _buildSymbolRows() {
    return [
      [
        const _TvKey.action('ABC', _TvKeyType.symbols),
        ..._symbols(['!', '?', r'$', '%', '^', '*', '+', '=', '~']),
        const _TvKey.action('Del', _TvKeyType.backspace, icon: Icons.backspace_outlined),
        const _TvKey.spacer(),
      ],
      [
        const _TvKey.spacer(),
        ..._symbols(['`', r'\', '|', ';', ':', '"', "'", '<', '>']),
        const _TvKey.spacer(),
        const _TvKey.spacer(),
      ],
      [
        const _TvKey.spacer(),
        ..._symbols(['[', ']', '{', '}', '(', ')', ',', '.', '-']),
        const _TvKey.spacer(),
        const _TvKey.spacer(),
      ],
      [
        const _TvKey.spacer(),
        const _TvKey.spacer(),
        const _TvKey.action('Space', _TvKeyType.space, icon: Icons.space_bar_rounded),
        const _TvKey.character('@'),
        const _TvKey.character('#'),
        const _TvKey.character('_'),
        const _TvKey.character('/'),
        _TvKey.action(t.common.clear, _TvKeyType.clear, icon: Icons.clear_all_rounded),
        _TvKey.action(t.common.cancel, _TvKeyType.cancel, icon: Icons.close_rounded),
        _TvKey.action(_doneLabel(), _TvKeyType.done, icon: _doneIcon()),
        const _TvKey.spacer(),
        const _TvKey.spacer(),
      ],
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

  List<_TvKey> _symbols(List<String> symbols) {
    return symbols.map((symbol) => _TvKey.character(symbol)).toList(growable: false);
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
      if (event is KeyUpEvent) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (_handlePhysicalKeyboardTextInput(event)) return KeyEventResult.handled;

      if (key == LogicalKeyboardKey.backspace) {
        _backspace();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.delete) {
        _deleteForward();
        return KeyEventResult.handled;
      }

      if (event.isPhysicalKeyboardEnter) {
        if (_isMultiline) {
          _insert('\n');
        } else if (event is KeyDownEvent) {
          _submit();
        }
        return KeyEventResult.handled;
      }

      if (event.isTvSelectEvent) {
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

  bool _handlePhysicalKeyboardTextInput(KeyEvent event) {
    if (!event.isPhysicalKeyboardEvent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      _dismissForPhysicalKeyboardInput();
      return true;
    }
    if (key == LogicalKeyboardKey.delete) {
      _deleteForward();
      _dismissForPhysicalKeyboardInput();
      return true;
    }
    if (event.isPhysicalKeyboardEnter && _isMultiline) {
      _insert('\n');
      _dismissForPhysicalKeyboardInput();
      return true;
    }

    final character = event.character;
    if (character != null && character.isNotEmpty && !key.isNavigationKey && !_isControlCharacter(character)) {
      _insert(character);
      _dismissForPhysicalKeyboardInput();
      return true;
    }
    return false;
  }

  bool _isControlCharacter(String text) {
    return text.runes.every((codeUnit) => codeUnit < 0x20 || codeUnit == 0x7f);
  }

  void _dismissForPhysicalKeyboardInput() {
    Navigator.of(context).pop();
  }

  void _moveHorizontal(int delta) {
    var nextColumn = _nextFocusableColumn(_row, _column + delta, delta);
    if (nextColumn == null) {
      final wrapStart = delta > 0 ? 0 : _rows[_row].length - 1;
      nextColumn = _nextFocusableColumn(_row, wrapStart, delta);
    }
    if (nextColumn == null) return;
    final column = nextColumn;
    setState(() {
      _column = column;
    });
  }

  void _moveVertical(int delta) {
    final rows = _rows;
    final nextRow = (_row + delta) % rows.length;
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
      case _TvKeyType.symbols:
        _toggleSymbolsPage();
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

  void _toggleSymbolsPage() {
    setState(() {
      _symbolsPage = !_symbolsPage;
      final rows = _rows;
      _row = _row.clamp(0, rows.length - 1).toInt();
      _column = _nearestFocusableColumn(_row, _column);
    });
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
    final (:start, :end) = _selectionRangeForEdit(value);
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
    final (:start, :end) = _selectionRangeForEdit(value);

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

  void _deleteForward() {
    final value = widget.controller.value;
    final (:start, :end) = _selectionRangeForEdit(value);

    if (start != end) {
      _replace(
        value.copyWith(
          text: value.text.replaceRange(start, end, ''),
          selection: TextSelection.collapsed(offset: start),
          composing: TextRange.empty,
        ),
      );
      return;
    }
    if (start >= value.text.length) return;

    _replace(
      value.copyWith(
        text: value.text.replaceRange(start, start + 1, ''),
        selection: TextSelection.collapsed(offset: start),
        composing: TextRange.empty,
      ),
    );
  }

  ({int start, int end}) _selectionRangeForEdit(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid) return (start: value.text.length, end: value.text.length);
    if (selection.isCollapsed && selection.baseOffset == 0 && value.text.isNotEmpty) {
      return (start: value.text.length, end: value.text.length);
    }
    return (
      start: selection.start < selection.end ? selection.start : selection.end,
      end: selection.start > selection.end ? selection.start : selection.end,
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
    if (formattedValue.text != previousValue.text) {
      widget.onChanged?.call(formattedValue.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final metrics = _metricsFor(media.size);
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;

    return Dialog(
      key: const Key('tv_virtual_keyboard_dialog'),
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.only(
        left: metrics.edgeInset,
        right: metrics.edgeInset,
        top: media.padding.top + 48,
        bottom: media.padding.bottom + metrics.bottomInset,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        child: Container(
          key: const Key('tv_virtual_keyboard_panel'),
          constraints: BoxConstraints(maxWidth: metrics.panelWidth),
          padding: EdgeInsets.all(metrics.panelPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(metrics.panelRadius),
          ),
          child: SizedBox(
            width: metrics.gridWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPreview(context, text, metrics),
                SizedBox(height: metrics.previewGap),
                for (var row = 0; row < _rows.length; row++) ...[
                  _buildRow(context, row, metrics),
                  if (row != _rows.length - 1) SizedBox(height: metrics.rowGap),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TvKeyboardMetrics _metricsFor(Size size) {
    final columns = _gridColumnCount;
    var keySize = (size.height * 0.061).clamp(36.0, 52.0).toDouble();
    var keyGap = (keySize * 0.09).clamp(3.0, 6.0).toDouble();
    var panelPadding = (keySize * 0.24).clamp(8.0, 14.0).toDouble();
    final edgeInset = (size.width * 0.035).clamp(20.0, 56.0).toDouble();

    final availableWidth = size.width - edgeInset * 2 - panelPadding * 2;
    final maxKeySize = (availableWidth - keyGap * (columns - 1)) / columns;
    final widthBoundKeySize = maxKeySize.clamp(24.0, 52.0).toDouble();
    if (keySize > widthBoundKeySize) keySize = widthBoundKeySize;
    keyGap = (keySize * 0.09).clamp(3.0, 6.0).toDouble();
    panelPadding = (keySize * 0.24).clamp(8.0, 14.0).toDouble();
    final gridWidth = keySize * columns + keyGap * (columns - 1);
    return _TvKeyboardMetrics(
      keySize: keySize,
      keyGap: keyGap,
      rowGap: keyGap,
      panelPadding: panelPadding,
      edgeInset: edgeInset,
      bottomInset: (size.height * 0.025).clamp(12.0, 28.0).toDouble(),
      gridWidth: gridWidth,
      panelWidth: gridWidth + panelPadding * 2,
      panelRadius: (keySize * 0.55).clamp(18.0, 28.0).toDouble(),
      keyRadius: (keySize * 0.28).clamp(10.0, 16.0).toDouble(),
      previewHeight: (_isMultiline ? keySize * 1.45 : keySize).clamp(40.0, 76.0).toDouble(),
      previewGap: (keySize * 0.18).clamp(6.0, 12.0).toDouble(),
      previewRadius: (keySize * 0.36).clamp(12.0, 18.0).toDouble(),
      iconSize: (keySize * 0.58).clamp(20.0, 30.0).toDouble(),
      keyFontSize: (keySize * 0.52).clamp(17.0, 26.0).toDouble(),
    );
  }

  Widget _buildPreview(BuildContext context, String text, _TvKeyboardMetrics metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmpty = text.isEmpty;
    final displayText = widget.obscureText && !isEmpty ? List.filled(text.length, '*').join() : text;
    final previewText = isEmpty ? (widget.hintText ?? '') : displayText;
    final multiline = _isMultiline;
    final style = (multiline ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
      color: isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
      fontSize: (metrics.keyFontSize * 1.08).clamp(16.0, 24.0).toDouble(),
    );

    return Container(
      height: metrics.previewHeight,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: metrics.keySize * 0.30),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(metrics.previewRadius),
      ),
      child: multiline
          ? SingleChildScrollView(reverse: true, child: Text(previewText, maxLines: 3, style: style))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(previewText, maxLines: 1, style: style),
            ),
    );
  }

  Widget _buildRow(BuildContext context, int row, _TvKeyboardMetrics metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var column = 0; column < _rows[row].length; column++) ...[
          _buildKey(context, _rows[row][column], row, column, metrics),
          if (column != _rows[row].length - 1) SizedBox(width: metrics.keyGap),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, _TvKey key, int row, int column, _TvKeyboardMetrics metrics) {
    if (key.type == _TvKeyType.spacer) {
      return SizedBox(width: metrics.keySize, height: metrics.keySize);
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
          width: metrics.keySize,
          height: metrics.keySize,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(metrics.keyRadius)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: metrics.keySize * 0.04),
            child: _buildKeyContent(context, key, foreground, metrics),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyContent(BuildContext context, _TvKey key, Color foreground, _TvKeyboardMetrics metrics) {
    final icon = key.icon;
    if (icon != null) {
      return Icon(
        icon,
        color: foreground,
        size: key.type == _TvKeyType.space ? metrics.iconSize * 1.12 : metrics.iconSize,
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        key.label,
        maxLines: 1,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: foreground, fontSize: metrics.keyFontSize, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TvKeyboardMetrics {
  final double keySize;
  final double keyGap;
  final double rowGap;
  final double panelPadding;
  final double edgeInset;
  final double bottomInset;
  final double gridWidth;
  final double panelWidth;
  final double panelRadius;
  final double keyRadius;
  final double previewHeight;
  final double previewGap;
  final double previewRadius;
  final double iconSize;
  final double keyFontSize;

  const _TvKeyboardMetrics({
    required this.keySize,
    required this.keyGap,
    required this.rowGap,
    required this.panelPadding,
    required this.edgeInset,
    required this.bottomInset,
    required this.gridWidth,
    required this.panelWidth,
    required this.panelRadius,
    required this.keyRadius,
    required this.previewHeight,
    required this.previewGap,
    required this.previewRadius,
    required this.iconSize,
    required this.keyFontSize,
  });
}
