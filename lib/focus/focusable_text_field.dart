import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/gamepad_service.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import '../widgets/tv_virtual_keyboard.dart';
import 'dpad_navigator.dart';

bool _usesTvKeyboard(bool enableTvKeyboard) => enableTvKeyboard && PlatformDetector.isAppleTV();

String? _keyboardHint(InputDecoration? decoration) => decoration?.hintText ?? decoration?.labelText;

String _describeTextInputKey(KeyEvent event) {
  return 'type=${event.runtimeType} logical=${event.logicalKey.keyLabel}/${event.logicalKey.keyId} '
      'physical=${event.physicalKey.usbHidUsage} deviceType=${event.deviceType} character=${event.character}';
}

void _logTvTextInput(String message) {
  if (!PlatformDetector.isTV()) return;
  appLogger.i('TextInputDiag FlutterTextField: $message');
}

class _NativeTvTextInputFocusBridge {
  static const _channel = MethodChannel('com.plezy/text_input');
  static final Set<Object> _focusedTokens = <Object>{};
  static bool _lastSentFocused = false;

  static void setFocused(Object token, bool focused) {
    _logTvTextInput(
      'NativeFocusBridge.setFocused requested focused=$focused token=$token activeTokens=${_focusedTokens.length}',
    );
    if (focused) {
      _focusedTokens.add(token);
    } else {
      _focusedTokens.remove(token);
    }

    if (!PlatformDetector.isTV() || PlatformDetector.isAppleTV()) {
      _logTvTextInput(
        'NativeFocusBridge clearing without platform send isTv=${PlatformDetector.isTV()} '
        'isAppleTV=${PlatformDetector.isAppleTV()}',
      );
      _focusedTokens.clear();
      _lastSentFocused = false;
      return;
    }

    final anyFocused = _focusedTokens.isNotEmpty;
    if (_lastSentFocused == anyFocused) {
      _logTvTextInput('NativeFocusBridge no-op anyFocused=$anyFocused tokenCount=${_focusedTokens.length}');
      return;
    }
    _lastSentFocused = anyFocused;
    _logTvTextInput('NativeFocusBridge sending anyFocused=$anyFocused tokenCount=${_focusedTokens.length}');
    unawaited(GamepadService.setNativeTextInputFocused(anyFocused));
    unawaited(_sendFocused(anyFocused));
  }

  static Future<void> _sendFocused(bool focused) async {
    try {
      await _channel.invokeMethod<void>('setNativeTextInputFocused', focused);
      _logTvTextInput('NativeFocusBridge platform send complete focused=$focused');
    } on MissingPluginException {
      _logTvTextInput('NativeFocusBridge platform send missing plugin focused=$focused');
      // Tests and non-Android embedders do not register this channel.
    } on PlatformException {
      _logTvTextInput('NativeFocusBridge platform send failed focused=$focused');
      // Focus reporting is a best-effort native routing hint.
    }
  }
}

KeyEventResult _handleInputKey({
  required TextEditingController controller,
  required bool usesTvKeyboard,
  required bool enabled,
  required VoidCallback openKeyboard,
  required KeyEvent event,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onEditingComplete,
  int? maxLength,
  int? maxLines,
  VoidCallback? onSelect,
  VoidCallback? onBack,
  VoidCallback? onNavigateLeft,
  VoidCallback? onNavigateRight,
  VoidCallback? onNavigateUp,
  VoidCallback? onNavigateDown,
}) {
  final key = event.logicalKey;
  KeyEventResult finish(KeyEventResult result, String reason) {
    _logTvTextInput(
      'result=$result reason=$reason key=(${_describeTextInputKey(event)}) '
      'usesTvKeyboard=$usesTvKeyboard enabled=$enabled textLength=${controller.text.length} '
      'selection=${controller.selection} onNav(up=${onNavigateUp != null},down=${onNavigateDown != null},'
      'left=${onNavigateLeft != null},right=${onNavigateRight != null}) onSelect=${onSelect != null} onBack=${onBack != null}',
    );
    return result;
  }

  _logTvTextInput(
    'received key=(${_describeTextInputKey(event)}) usesTvKeyboard=$usesTvKeyboard enabled=$enabled '
    'textLength=${controller.text.length} selection=${controller.selection}',
  );

  if (_shouldPassNativeTvKeyToPlatform(usesTvKeyboard: usesTvKeyboard, enabled: enabled, event: event)) {
    return finish(KeyEventResult.skipRemainingHandlers, 'pass-native-tv-key-to-platform');
  }

  if (usesTvKeyboard && enabled && event.isTvSelectEvent) {
    if (event is KeyDownEvent) openKeyboard();
    return finish(KeyEventResult.handled, 'open-custom-tv-keyboard');
  }

  if (usesTvKeyboard && enabled && event.isPhysicalKeyboardEvent) {
    final result = _handleTvHardwareKeyboardKey(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      maxLength: maxLength,
      maxLines: maxLines,
      event: event,
    );
    if (result != KeyEventResult.ignored) return finish(result, 'custom-tv-hardware-keyboard');
  }

  if (onBack != null && key.isBackKey) {
    if (event is KeyDownEvent) onBack();
    return finish(KeyEventResult.handled, 'onBack');
  }

  // Enter/numpad enter are left to TextField.onSubmitted. Handle only
  // non-text submit keys that TV remotes/gamepads may send while editing.
  if (!usesTvKeyboard &&
      onSelect != null &&
      (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.gameButtonA)) {
    if (event is KeyDownEvent) onSelect();
    return finish(KeyEventResult.handled, 'native-tv-non-text-select');
  }

  if (!event.isActionable) return finish(KeyEventResult.ignored, 'non-actionable');

  if (key.isUpKey && onNavigateUp != null) {
    onNavigateUp();
    return finish(KeyEventResult.handled, 'onNavigateUp');
  }
  if (key.isDownKey && onNavigateDown != null) {
    onNavigateDown();
    return finish(KeyEventResult.handled, 'onNavigateDown');
  }

  final sel = controller.selection;
  if (sel.isCollapsed) {
    if (key.isLeftKey && sel.baseOffset == 0 && onNavigateLeft != null) {
      onNavigateLeft();
      return finish(KeyEventResult.handled, 'onNavigateLeft-at-start');
    }
    if (key.isRightKey && sel.baseOffset == controller.text.length && onNavigateRight != null) {
      onNavigateRight();
      return finish(KeyEventResult.handled, 'onNavigateRight-at-end');
    }
  }

  return finish(KeyEventResult.ignored, 'fall-through');
}

bool _shouldPassNativeTvKeyToPlatform({required bool usesTvKeyboard, required bool enabled, required KeyEvent event}) {
  if (!enabled || usesTvKeyboard || !PlatformDetector.isTV()) {
    _logTvTextInput(
      'native-pass=false reason=disabled-or-custom-keyboard enabled=$enabled usesTvKeyboard=$usesTvKeyboard '
      'isTv=${PlatformDetector.isTV()} key=(${_describeTextInputKey(event)})',
    );
    return false;
  }

  // Android TV provides its own IME. Remote keys must reach the platform so
  // users can move around that keyboard instead of escaping the app field.
  final key = event.logicalKey;
  final isEngineSynthesizedTvSelect = key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.gameButtonA;
  if (event.isPhysicalKeyboardEvent && !isEngineSynthesizedTvSelect) {
    _logTvTextInput('native-pass=false reason=physical-keyboard key=(${_describeTextInputKey(event)})');
    return false;
  }

  final shouldPass = key.isDpadDirection || key.isBackKey || event.isTvSelectEvent;
  _logTvTextInput(
    'native-pass=$shouldPass reason=${shouldPass ? "remote-navigation-key" : "not-navigation-key"} '
    'key=(${_describeTextInputKey(event)})',
  );
  return shouldPass;
}

KeyEventResult _handleTvHardwareKeyboardKey({
  required TextEditingController controller,
  required KeyEvent event,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onEditingComplete,
  int? maxLength,
  int? maxLines,
}) {
  final key = event.logicalKey;

  if (event.isPhysicalKeyboardEnter) {
    if (event is KeyDownEvent) {
      if (_isMultilineTextInput(keyboardType: keyboardType, maxLines: maxLines)) {
        _insertText(
          controller: controller,
          text: '\n',
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: onChanged,
        );
      } else {
        _submitTextInput(
          controller: controller,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
        );
      }
    }
    return KeyEventResult.handled;
  }

  if (!event.isActionable) return KeyEventResult.ignored;

  if (key == LogicalKeyboardKey.backspace) {
    _backspace(controller: controller, inputFormatters: inputFormatters, maxLength: maxLength, onChanged: onChanged);
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.delete) {
    _deleteForward(
      controller: controller,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
    );
    return KeyEventResult.handled;
  }

  if (key.isLeftKey || key.isRightKey) {
    return _moveCaretHorizontally(controller, key.isLeftKey ? -1 : 1);
  }

  final character = event.character;
  if (character != null && character.isNotEmpty && !key.isNavigationKey && !_isControlCharacter(character)) {
    _insertText(
      controller: controller,
      text: character,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
    );
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
}

bool _isMultilineTextInput({TextInputType? keyboardType, int? maxLines}) {
  return keyboardType?.index == TextInputType.multiline.index || (maxLines != null && maxLines != 1);
}

bool _isControlCharacter(String text) {
  return text.runes.every((codeUnit) => codeUnit < 0x20 || codeUnit == 0x7f);
}

KeyEventResult _moveCaretHorizontally(TextEditingController controller, int delta) {
  final value = controller.value;
  final selection = value.selection;
  if (!selection.isValid) {
    controller.selection = TextSelection.collapsed(offset: value.text.length);
    return KeyEventResult.handled;
  }

  if (!selection.isCollapsed) {
    final offset = delta < 0
        ? (selection.start < selection.end ? selection.start : selection.end)
        : (selection.start > selection.end ? selection.start : selection.end);
    controller.selection = TextSelection.collapsed(offset: offset);
    return KeyEventResult.handled;
  }

  final nextOffset = selection.extentOffset + delta;
  if (nextOffset < 0 || nextOffset > value.text.length) return KeyEventResult.ignored;
  controller.selection = TextSelection.collapsed(offset: nextOffset);
  return KeyEventResult.handled;
}

void _submitTextInput({
  required TextEditingController controller,
  required TextInputAction? textInputAction,
  ValueChanged<String>? onSubmitted,
  VoidCallback? onEditingComplete,
}) {
  if (onEditingComplete != null) {
    onEditingComplete();
  } else {
    _defaultEditingComplete(textInputAction);
  }
  onSubmitted?.call(controller.text);
}

void _defaultEditingComplete(TextInputAction? textInputAction) {
  final focus = FocusManager.instance.primaryFocus;
  switch (textInputAction) {
    case TextInputAction.next:
      focus?.nextFocus();
    case TextInputAction.previous:
      focus?.previousFocus();
    default:
      focus?.unfocus();
  }
}

void _insertText({
  required TextEditingController controller,
  required String text,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final value = controller.value;
  final selection = value.selection;
  final start = selection.isValid
      ? (selection.start < selection.end ? selection.start : selection.end)
      : value.text.length;
  final end = selection.isValid
      ? (selection.start > selection.end ? selection.start : selection.end)
      : value.text.length;
  final newText = value.text.replaceRange(start, end, text);
  _replaceTextValue(
    controller: controller,
    nextValue: value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    ),
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    onChanged: onChanged,
  );
}

void _backspace({
  required TextEditingController controller,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final value = controller.value;
  final selection = value.selection;
  final start = selection.isValid
      ? (selection.start < selection.end ? selection.start : selection.end)
      : value.text.length;
  final end = selection.isValid
      ? (selection.start > selection.end ? selection.start : selection.end)
      : value.text.length;
  if (start != end) {
    _replaceTextRange(
      controller,
      start,
      end,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
    );
    return;
  }
  if (start == 0) return;
  _replaceTextRange(
    controller,
    start - 1,
    start,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    onChanged: onChanged,
  );
}

void _deleteForward({
  required TextEditingController controller,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final value = controller.value;
  final selection = value.selection;
  final start = selection.isValid
      ? (selection.start < selection.end ? selection.start : selection.end)
      : value.text.length;
  final end = selection.isValid
      ? (selection.start > selection.end ? selection.start : selection.end)
      : value.text.length;
  if (start != end) {
    _replaceTextRange(
      controller,
      start,
      end,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
    );
    return;
  }
  if (start >= value.text.length) return;
  _replaceTextRange(
    controller,
    start,
    start + 1,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    onChanged: onChanged,
  );
}

void _replaceTextRange(
  TextEditingController controller,
  int start,
  int end, {
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final value = controller.value;
  _replaceTextValue(
    controller: controller,
    nextValue: value.copyWith(
      text: value.text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
      composing: TextRange.empty,
    ),
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    onChanged: onChanged,
  );
}

void _replaceTextValue({
  required TextEditingController controller,
  required TextEditingValue nextValue,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final previousValue = controller.value;
  var formattedValue = nextValue;
  final formatters = [
    ...?inputFormatters,
    if (maxLength != null && maxLength > 0) LengthLimitingTextInputFormatter(maxLength),
  ];
  for (final formatter in formatters) {
    formattedValue = formatter.formatEditUpdate(previousValue, formattedValue);
  }

  controller.value = formattedValue;
  if (formattedValue.text != previousValue.text) {
    onChanged?.call(formattedValue.text);
  }
}

abstract class _FocusableTextInputBase extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onSelect;
  final VoidCallback? onBack;
  final bool autofocus;
  final bool enabled;
  final bool enableTvKeyboard;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool? enableInteractiveSelection;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final TextStyle? style;

  final VoidCallback? onNavigateLeft;
  final VoidCallback? onNavigateRight;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;

  const _FocusableTextInputBase({
    super.key,
    required this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onSelect,
    this.onBack,
    this.autofocus = false,
    this.enabled = true,
    this.enableTvKeyboard = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableInteractiveSelection,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onNavigateUp,
    this.onNavigateDown,
  });

  bool get _hasTvKeyboard => _usesTvKeyboard(enableTvKeyboard);
  bool get _usesNativeTvKeyboard => PlatformDetector.isTV() && !_hasTvKeyboard;

  VoidCallback? get _effectiveOnEditingComplete {
    if (onEditingComplete != null) return onEditingComplete;
    if (_usesNativeTvKeyboard && onSubmitted == null) return _handleTvKeyboardAction;
    return null;
  }

  void _showTvKeyboard(BuildContext context) {
    if (!enabled) return;
    showTvVirtualKeyboard(
      context: context,
      controller: controller,
      hintText: _keyboardHint(decoration),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onAction: _handleTvKeyboardAction,
    );
  }

  void _handleTvKeyboardAction() {
    if (onEditingComplete != null) {
      onEditingComplete!();
    } else if (onSelect != null) {
      onSelect!();
    } else if (onNavigateDown != null) {
      onNavigateDown!();
    } else {
      _defaultEditingComplete(textInputAction);
    }
  }

  KeyEventResult _handleKey(BuildContext context, FocusNode _, KeyEvent event) {
    return _handleInputKey(
      controller: controller,
      usesTvKeyboard: _hasTvKeyboard,
      enabled: enabled,
      openKeyboard: () => _showTvKeyboard(context),
      event: event,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      maxLength: maxLength,
      maxLines: maxLines,
      onSelect: onSelect,
      onBack: onBack,
      onNavigateLeft: onNavigateLeft,
      onNavigateRight: onNavigateRight,
      onNavigateUp: onNavigateUp,
      onNavigateDown: onNavigateDown,
    );
  }

  Widget buildFocusableInput(BuildContext context, Widget Function(bool usesTvKeyboard, FocusNode focusNode) builder) {
    return _FocusableTextInputHost(input: this, builder: builder);
  }
}

class _FocusableTextInputHost extends StatefulWidget {
  final _FocusableTextInputBase input;
  final Widget Function(bool usesTvKeyboard, FocusNode focusNode) builder;

  const _FocusableTextInputHost({required this.input, required this.builder});

  @override
  State<_FocusableTextInputHost> createState() => _FocusableTextInputHostState();
}

class _FocusableTextInputHostState extends State<_FocusableTextInputHost> {
  FocusNode? _ownedFocusNode;
  FocusNode? _installedFocusNode;
  FocusOnKeyEventCallback? _previousOnKeyEvent;
  late final FocusOnKeyEventCallback _keyHandler = _handleKey;
  late final VoidCallback _focusListener = _syncNativeTextInputFocus;
  final Object _nativeFocusToken = Object();
  bool _reportedNativeTextInputFocused = false;

  FocusNode get _effectiveFocusNode =>
      widget.input.focusNode ?? (_ownedFocusNode ??= FocusNode(debugLabel: 'FocusableTextInput'));

  @override
  void didUpdateWidget(_FocusableTextInputHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input.focusNode != widget.input.focusNode) {
      _restoreInstalledHandler();
    }
    _syncNativeTextInputFocus();
  }

  @override
  void dispose() {
    _restoreInstalledHandler();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _syncNativeTextInputFocus() {
    final focused = _installedFocusNode?.hasFocus == true && widget.input.enabled && widget.input._usesNativeTvKeyboard;
    _logTvTextInput(
      'Host.syncNativeTextInputFocus focused=$focused installed=${_installedFocusNode?.debugLabel} '
      'hasFocus=${_installedFocusNode?.hasFocus} enabled=${widget.input.enabled} '
      'usesNativeTvKeyboard=${widget.input._usesNativeTvKeyboard}',
    );
    _setNativeTextInputFocused(focused);
  }

  void _setNativeTextInputFocused(bool focused) {
    if (_reportedNativeTextInputFocused == focused) {
      _logTvTextInput('Host.setNativeTextInputFocused no-op focused=$focused');
      return;
    }
    _logTvTextInput('Host.setNativeTextInputFocused old=$_reportedNativeTextInputFocused new=$focused');
    _reportedNativeTextInputFocused = focused;
    _NativeTvTextInputFocusBridge.setFocused(_nativeFocusToken, focused);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final previous = _previousOnKeyEvent;
    if (previous != null && !identical(previous, _keyHandler)) {
      final result = previous(node, event);
      _logTvTextInput(
        'Host.previousOnKeyEvent node=${node.debugLabel} result=$result key=(${_describeTextInputKey(event)})',
      );
      if (result != KeyEventResult.ignored) return result;
    }
    return widget.input._handleKey(context, node, event);
  }

  void _installKeyHandler(FocusNode node) {
    // Handle D-pad escapes on the field's own node so EditableText shortcuts
    // can't consume directions before our reusable navigation callbacks run.
    if (_installedFocusNode == node) {
      if (identical(node.onKeyEvent, _keyHandler)) return;
      _previousOnKeyEvent = node.onKeyEvent;
      node.onKeyEvent = _keyHandler;
      _logTvTextInput('Host.reinstalled key handler node=${node.debugLabel} previous=${_previousOnKeyEvent != null}');
      return;
    }

    _restoreInstalledHandler();
    _installedFocusNode = node;
    _previousOnKeyEvent = node.onKeyEvent;
    node.onKeyEvent = _keyHandler;
    node.addListener(_focusListener);
    _logTvTextInput('Host.installed key handler node=${node.debugLabel} previous=${_previousOnKeyEvent != null}');
  }

  void _restoreInstalledHandler() {
    _logTvTextInput('Host.restoreInstalledHandler node=${_installedFocusNode?.debugLabel}');
    _setNativeTextInputFocused(false);
    final node = _installedFocusNode;
    if (node != null) {
      node.removeListener(_focusListener);
      if (identical(node.onKeyEvent, _keyHandler)) {
        node.onKeyEvent = _previousOnKeyEvent;
      }
    }
    _installedFocusNode = null;
    _previousOnKeyEvent = null;
  }

  @override
  Widget build(BuildContext context) {
    final focusNode = _effectiveFocusNode;
    _installKeyHandler(focusNode);
    _syncNativeTextInputFocus();
    return widget.builder(widget.input._hasTvKeyboard, focusNode);
  }
}

/// A [TextField] wrapper that exposes D-pad navigation callbacks with
/// caret-aware edge escapes — so LEFT at the start of the field and RIGHT
/// at the end escape to neighbouring focus targets instead of bouncing
/// against the caret boundary, while UP/DOWN always escape.
///
/// Collapsed selection only: if text is selected, LEFT/RIGHT fall through
/// to the TextField's default caret movement.
class FocusableTextField extends _FocusableTextInputBase {
  const FocusableTextField({
    super.key,
    required super.controller,
    super.focusNode,
    super.decoration,
    super.keyboardType,
    super.textInputAction,
    super.inputFormatters,
    super.onChanged,
    super.onSubmitted,
    super.onEditingComplete,
    super.onSelect,
    super.onBack,
    super.autofocus,
    super.enabled,
    super.enableTvKeyboard,
    super.obscureText,
    super.autocorrect,
    super.enableSuggestions,
    super.enableInteractiveSelection,
    super.maxLength,
    super.maxLines,
    super.minLines,
    super.textAlign,
    super.textCapitalization,
    super.style,
    super.onNavigateLeft,
    super.onNavigateRight,
    super.onNavigateUp,
    super.onNavigateDown,
  });

  @override
  Widget build(BuildContext context) {
    return buildFocusableInput(
      context,
      (usesTvKeyboard, effectiveFocusNode) => TextField(
        controller: controller,
        focusNode: effectiveFocusNode,
        enabled: enabled,
        decoration: decoration,
        keyboardType: usesTvKeyboard ? TextInputType.none : keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onEditingComplete: _effectiveOnEditingComplete,
        autofocus: autofocus,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        obscureText: obscureText,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        style: style,
        readOnly: usesTvKeyboard,
        showCursor: usesTvKeyboard ? true : null,
        enableInteractiveSelection: usesTvKeyboard ? false : enableInteractiveSelection,
        onTap: usesTvKeyboard ? () => _showTvKeyboard(context) : null,
      ),
    );
  }
}

class FocusableTextFormField extends _FocusableTextInputBase {
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final FormFieldSetter<String>? onSaved;

  const FocusableTextFormField({
    super.key,
    required super.controller,
    super.focusNode,
    super.decoration,
    super.keyboardType,
    super.textInputAction,
    super.inputFormatters,
    super.onChanged,
    this.onFieldSubmitted,
    super.onEditingComplete,
    super.onSelect,
    super.onBack,
    this.validator,
    this.autovalidateMode,
    this.onSaved,
    super.autofocus,
    super.enabled,
    super.enableTvKeyboard,
    super.obscureText,
    super.autocorrect,
    super.enableSuggestions,
    super.enableInteractiveSelection,
    super.maxLength,
    super.maxLines,
    super.minLines,
    super.textAlign,
    super.textCapitalization,
    super.style,
    super.onNavigateLeft,
    super.onNavigateRight,
    super.onNavigateUp,
    super.onNavigateDown,
  }) : super(onSubmitted: onFieldSubmitted);

  @override
  Widget build(BuildContext context) {
    return buildFocusableInput(
      context,
      (usesTvKeyboard, effectiveFocusNode) => TextFormField(
        controller: controller,
        focusNode: effectiveFocusNode,
        enabled: enabled,
        decoration: decoration,
        keyboardType: usesTvKeyboard ? TextInputType.none : keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        onEditingComplete: _effectiveOnEditingComplete,
        validator: validator,
        autovalidateMode: autovalidateMode,
        onSaved: onSaved,
        autofocus: autofocus,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        obscureText: obscureText,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        style: style,
        readOnly: usesTvKeyboard,
        showCursor: usesTvKeyboard ? true : null,
        enableInteractiveSelection: usesTvKeyboard ? false : enableInteractiveSelection,
        onTap: usesTvKeyboard ? () => _showTvKeyboard(context) : null,
      ),
    );
  }
}
