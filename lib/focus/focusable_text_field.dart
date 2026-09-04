import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/gamepad_service.dart';
import '../utils/platform_detector.dart';
import '../utils/text_input_diagnostics.dart';
import '../widgets/tv_virtual_keyboard.dart';
import 'dpad_navigator.dart';
import 'key_event_utils.dart';
import 'owned_focus_node_binding.dart';

enum TvTextInputPresentation {
  /// Use the native platform keyboard wherever it can host the field: always
  /// on Android TV (its docked IME handles multiline input), and for
  /// single-line input on Apple TV, whose modal fullscreen keyboard cannot
  /// edit multiline text — that falls back to the Flutter overlay.
  automatic,

  /// Always use the platform text input implementation.
  platform,

  /// Always use Plezy's in-app Flutter keyboard overlay.
  flutterOverlay,
}

bool _usesTvKeyboard({required TvTextInputPresentation presentation, TextInputType? keyboardType, int? maxLines}) {
  if (!PlatformDetector.isTV()) return false;
  return switch (presentation) {
    TvTextInputPresentation.automatic =>
      PlatformDetector.isAppleTV() && _isMultilineTextInput(keyboardType: keyboardType, maxLines: maxLines),
    TvTextInputPresentation.platform => false,
    TvTextInputPresentation.flutterOverlay => true,
  };
}

String? _keyboardHint(InputDecoration? decoration) => decoration?.hintText ?? decoration?.labelText;

enum TvTextInputAutoOpenBehavior {
  /// Resolve per presentation: open-on-first-focus for the native tvOS
  /// keyboard — arriving at a field opens it once, but returning to it during
  /// D-pad traversal does not, since it is a modal full-screen surface and
  /// re-raising it on every pass makes a form untraversable. Open-on-focus for
  /// the in-app Flutter overlay, which is cheap, non-modal, and involves no
  /// UIKit first responder.
  automatic,

  /// Keep initial focus on the field without opening text input, then open it
  /// automatically on later focus entries. Explicit tap/select still opens it.
  afterFirstFocus,

  /// Never auto-open text input on focus. Explicit tap/select still opens it.
  never,
}

/// Auto-open policy for an autofocused server-URL field (#1217): entering the
/// screen must not bury the form under a keyboard the user did not ask for.
///
/// This is the one documented exception to the `automatic` rule that a field's
/// first focus opens text input — the URL field's first focus is the screen's
/// own `autofocus`, not the user arriving. Apple TV therefore waits for an
/// explicit Select; Android's docked IME is cheap enough to open on a
/// deliberate return.
TvTextInputAutoOpenBehavior get deferredUrlFieldAutoOpen =>
    PlatformDetector.isAppleTV() ? TvTextInputAutoOpenBehavior.never : TvTextInputAutoOpenBehavior.afterFirstFocus;

/// Imperative handle to TV text input for a [FocusableTextField] /
/// [FocusableTextFormField]. Pass the same instance to the field's
/// `tvTextInputController`; the field's host attaches itself on mount.
///
/// Only meaningful on TV. On other platforms every method is an effective
/// no-op.
class TvTextInputController {
  _FocusableTextInputHostState? _host;

  void _attach(_FocusableTextInputHostState host) => _host = host;
  void _detach(_FocusableTextInputHostState host) {
    if (identical(_host, host)) _host = null;
  }

  /// Dismiss active native or Flutter text input and prevent it from reopening
  /// while the field keeps focus.
  void closeTextInput() => _host?._dismissTvKeyboard();

  /// Focus the field without opening either native or Flutter text input for
  /// this focus entry.
  void focusInputWithoutOpening() => _host?._focusWithoutKeyboard();

  /// Focus the field and open its text input, as an explicit Select would —
  /// for a field the app creates on the user's behalf (a new editor row) that
  /// should be typed into at once, without a second press.
  void focusAndOpenTextInput() => _host?._focusAndOpenTextInput();
}

String _describeTextInputKey(KeyEvent event) {
  return 'type=${event.runtimeType} logical=${event.logicalKey.keyLabel}/${event.logicalKey.keyId} '
      'physical=${event.physicalKey.usbHidUsage} deviceType=${event.deviceType} character=${event.character}';
}

void _logTvTextInput(String message) {
  TextInputDiagnostics.log('FlutterTextField', message);
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
  required FocusNode node,
  required bool usesTvKeyboard,
  required bool enabled,
  required VoidCallback openKeyboard,
  required bool activateNativeTextInput,
  required VoidCallback activateNativeTextInputCallback,
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
  final diagnosticsEnabled = TextInputDiagnostics.enabled;
  KeyEventResult finish(KeyEventResult result, String reason) {
    if (diagnosticsEnabled) {
      _logTvTextInput(
        'result=$result reason=$reason key=(${_describeTextInputKey(event)}) '
        'usesTvKeyboard=$usesTvKeyboard enabled=$enabled textLength=${controller.text.length} '
        'selection=${controller.selection} onNav(up=${onNavigateUp != null},down=${onNavigateDown != null},'
        'left=${onNavigateLeft != null},right=${onNavigateRight != null}) onSelect=${onSelect != null} onBack=${onBack != null}',
      );
    }
    return result;
  }

  if (diagnosticsEnabled) {
    _logTvTextInput(
      'received key=(${_describeTextInputKey(event)}) usesTvKeyboard=$usesTvKeyboard enabled=$enabled '
      'textLength=${controller.text.length} selection=${controller.selection}',
    );
  }

  if (activateNativeTextInput && enabled && event.isTvSelectEvent) {
    if (event is KeyDownEvent) activateNativeTextInputCallback();
    return finish(KeyEventResult.handled, 'activate-native-tv-text-input');
  }

  if (_shouldPassNativeTvKeyToPlatform(
    usesTvKeyboard: usesTvKeyboard,
    nativeTextInputActive: !activateNativeTextInput,
    enabled: enabled,
    event: event,
  )) {
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

  if (onBack != null && event.logicalKey.isBackKey) {
    // On TV the native text-input path can swallow the matching KeyUp (the
    // closing IME session eats it), so back fires on KeyDown — the same
    // down-only shape as [handleBackKeyAction]'s Apple TV branch, coordinator
    // mark included so a parallel back dispatch still dedupes. Elsewhere the
    // shared handler's KeyUp semantics apply.
    if (PlatformDetector.isTV()) {
      if (BackKeyUpSuppressor.consumeIfSuppressed(event)) return finish(KeyEventResult.handled, 'onBack');
      if (event is KeyDownEvent) {
        BackKeyCoordinator.markHandled();
        onBack();
        // onBack may move focus (empty search field -> sidebar); the matching
        // KeyUp is then delivered to the NEW focus chain, whose shared
        // handlers act on KeyUp — a second back action. Arm the suppressor
        // (after onBack, so a modal opened by it cannot clear the arming) so
        // whichever chain receives the KeyUp swallows it. This cannot pin:
        // the suppressor's hardware observer clears the armed state once the
        // physical press ends, and if the IME swallows that KeyUp entirely,
        // the next back KeyDown is treated as stale arming and passes
        // through — see _KeyUpSuppressor.
        BackKeyUpSuppressor.suppressBackUntilKeyUp();
      }
      return finish(KeyEventResult.handled, 'onBack');
    }
    final backResult = handleBackKeyAction(event, onBack);
    if (backResult != KeyEventResult.ignored) return finish(backResult, 'onBack');
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

  final isMultiline = _isMultilineTextInput(keyboardType: keyboardType, maxLines: maxLines);

  // Directional escape: an explicit callback always wins. Otherwise, fall back
  // to the framework's geometry-based directional traversal so an un-wired
  // field moves to its nearest neighbour instead of dead-ending (the field's
  // own onKeyEvent runs before EditableText, which would otherwise swallow the
  // arrow). Single-line only for UP/DOWN — multiline falls through so
  // EditableText can move the caret between lines.
  if (key.isUpKey) {
    if (onNavigateUp != null) {
      onNavigateUp();
      return finish(KeyEventResult.handled, 'onNavigateUp');
    }
    if (!isMultiline) {
      final moved = node.focusInDirection(TraversalDirection.up);
      return finish(moved ? KeyEventResult.handled : KeyEventResult.ignored, 'focusInDirection-up');
    }
  }
  if (key.isDownKey) {
    if (onNavigateDown != null) {
      onNavigateDown();
      return finish(KeyEventResult.handled, 'onNavigateDown');
    }
    if (!isMultiline) {
      final moved = node.focusInDirection(TraversalDirection.down);
      return finish(moved ? KeyEventResult.handled : KeyEventResult.ignored, 'focusInDirection-down');
    }
  }

  final sel = controller.selection;
  if (sel.isCollapsed) {
    if (key.isLeftKey && sel.baseOffset == 0) {
      if (onNavigateLeft != null) {
        onNavigateLeft();
        return finish(KeyEventResult.handled, 'onNavigateLeft-at-start');
      }
      final moved = node.focusInDirection(TraversalDirection.left);
      return finish(moved ? KeyEventResult.handled : KeyEventResult.ignored, 'focusInDirection-left-at-start');
    }
    if (key.isRightKey && sel.baseOffset == controller.text.length) {
      if (onNavigateRight != null) {
        onNavigateRight();
        return finish(KeyEventResult.handled, 'onNavigateRight-at-end');
      }
      final moved = node.focusInDirection(TraversalDirection.right);
      return finish(moved ? KeyEventResult.handled : KeyEventResult.ignored, 'focusInDirection-right-at-end');
    }
  }

  return finish(KeyEventResult.ignored, 'fall-through');
}

bool _shouldPassNativeTvKeyToPlatform({
  required bool usesTvKeyboard,
  required bool nativeTextInputActive,
  required bool enabled,
  required KeyEvent event,
}) {
  if (!enabled || usesTvKeyboard || !nativeTextInputActive || !PlatformDetector.isAppleTV()) {
    if (TextInputDiagnostics.enabled) {
      _logTvTextInput(
        'native-pass=false reason=inactive-disabled-or-custom enabled=$enabled '
        'usesTvKeyboard=$usesTvKeyboard nativeTextInputActive=$nativeTextInputActive '
        'isAppleTV=${PlatformDetector.isAppleTV()} key=(${_describeTextInputKey(event)})',
      );
    }
    return false;
  }

  // tvOS only: the custom engine routes remote keys through Flutter even
  // while UIKit text input is live, so they must be skipped back to the
  // platform to drive the system keyboard. Android needs no such pass — the
  // IME sees hardware keys *before* the app (ImeInputStage), so a navigation
  // key arriving here was already declined by the IME and must keep its
  // local caret/traversal semantics (see the host's Android branch).
  // Some remotes (Chromecast) are reported by Flutter as keyboard events, so
  // native TV navigation cannot rely on deviceType.
  final key = event.logicalKey;
  final shouldPass = key.isDpadDirection || key.isBackKey || event.isTvSelectEvent;
  if (TextInputDiagnostics.enabled) {
    _logTvTextInput(
      'native-pass=$shouldPass reason=${shouldPass ? "remote-navigation-key" : "not-navigation-key"} '
      'key=(${_describeTextInputKey(event)})',
    );
  }
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
  if (character != null && character.isNotEmpty && !key.isReservedControlKey && !_isControlCharacter(character)) {
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
    final range = expandToGraphemeRange(value.text, selection);
    controller.selection = TextSelection.collapsed(offset: delta < 0 ? range.start : range.end);
    return KeyEventResult.handled;
  }

  final offset = selection.extentOffset.clamp(0, value.text.length);
  if ((delta < 0 && offset == 0) || (delta > 0 && offset == value.text.length)) {
    return KeyEventResult.ignored;
  }
  final codeUnitRange = delta < 0
      ? TextRange(start: offset - 1, end: offset)
      : TextRange(start: offset, end: offset + 1);
  final range = expandToGraphemeRange(value.text, codeUnitRange);
  controller.selection = TextSelection.collapsed(offset: delta < 0 ? range.start : range.end);
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

({int start, int end}) _normalizedSelectionRange(TextEditingValue value) {
  final selection = value.selection;
  if (!selection.isValid) {
    return (start: value.text.length, end: value.text.length);
  }
  return (start: selection.start.clamp(0, value.text.length), end: selection.end.clamp(0, value.text.length));
}

void _insertText({
  required TextEditingController controller,
  required String text,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  ValueChanged<String>? onChanged,
}) {
  final value = controller.value;
  final range = _normalizedSelectionRange(value);
  final start = range.start;
  final end = range.end;
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
  final selectionRange = _normalizedSelectionRange(value);
  final start = selectionRange.start;
  final end = selectionRange.end;
  if (start == end && start == 0) return;

  final codeUnitRange = start == end ? TextRange(start: start - 1, end: start) : TextRange(start: start, end: end);
  final range = expandToGraphemeRange(value.text, codeUnitRange);
  if (range.isCollapsed) return;
  _replaceTextRange(
    controller,
    range.start,
    range.end,
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
  final selectionRange = _normalizedSelectionRange(value);
  final start = selectionRange.start;
  final end = selectionRange.end;
  if (start == end && start >= value.text.length) return;

  final codeUnitRange = start == end ? TextRange(start: start, end: start + 1) : TextRange(start: start, end: end);
  final range = expandToGraphemeRange(value.text, codeUnitRange);
  if (range.isCollapsed) return;
  _replaceTextRange(
    controller,
    range.start,
    range.end,
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
  final TvTextInputPresentation tvTextInputPresentation;
  final TvTextInputAutoOpenBehavior tvTextInputAutoOpenBehavior;
  final TvTextInputController? tvTextInputController;
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
    this.tvTextInputPresentation = TvTextInputPresentation.automatic,
    this.tvTextInputAutoOpenBehavior = TvTextInputAutoOpenBehavior.automatic,
    this.tvTextInputController,
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

  bool get _hasTvKeyboard =>
      _usesTvKeyboard(presentation: tvTextInputPresentation, keyboardType: keyboardType, maxLines: maxLines);
  bool get _usesNativeTvKeyboard => PlatformDetector.isTV() && !_hasTvKeyboard;

  VoidCallback? get _effectiveOnEditingComplete {
    if (onEditingComplete != null) return onEditingComplete;
    if (_usesNativeTvKeyboard && onSubmitted == null) return _handleTvKeyboardAction;
    return null;
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

  ({
    TextInputType? keyboardType,
    bool readOnly,
    bool? showCursor,
    bool? enableInteractiveSelection,
    VoidCallback? onTap,
  })
  _tvInputConfiguration({
    required bool usesTvKeyboard,
    required bool nativeTextInputReadOnly,
    required VoidCallback openKeyboard,
    required VoidCallback activateNativeTextInput,
  }) {
    return (
      keyboardType: usesTvKeyboard ? TextInputType.none : keyboardType,
      readOnly: usesTvKeyboard || nativeTextInputReadOnly,
      showCursor: usesTvKeyboard || nativeTextInputReadOnly ? true : null,
      enableInteractiveSelection: usesTvKeyboard ? false : enableInteractiveSelection,
      onTap: usesTvKeyboard
          ? openKeyboard
          : nativeTextInputReadOnly
          ? activateNativeTextInput
          : null,
    );
  }

  KeyEventResult _handleKey(
    BuildContext context,
    FocusNode node,
    KeyEvent event,
    VoidCallback openKeyboard, {
    required bool activateNativeTextInput,
    required VoidCallback activateNativeTextInputCallback,
  }) {
    return _handleInputKey(
      controller: controller,
      node: node,
      usesTvKeyboard: _hasTvKeyboard,
      enabled: enabled,
      openKeyboard: openKeyboard,
      activateNativeTextInput: activateNativeTextInput,
      activateNativeTextInputCallback: activateNativeTextInputCallback,
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

  Widget buildFocusableInput(_FocusableTextInputBuilder builder) {
    return _FocusableTextInputHost(input: this, builder: builder);
  }
}

typedef _FocusableTextInputBuilder =
    Widget Function({
      required bool usesTvKeyboard,
      required bool nativeTextInputReadOnly,
      required FocusNode focusNode,
      required VoidCallback openKeyboard,
      required VoidCallback activateNativeTextInput,
      required VoidCallback? onEditingComplete,
    });

class _FocusableTextInputHost extends StatefulWidget {
  final _FocusableTextInputBase input;
  final _FocusableTextInputBuilder builder;

  const _FocusableTextInputHost({required this.input, required this.builder});

  @override
  State<_FocusableTextInputHost> createState() => _FocusableTextInputHostState();
}

class _FocusableTextInputHostState extends State<_FocusableTextInputHost> {
  final OwnedFocusNodeBinding _focusNodeBinding = OwnedFocusNodeBinding();
  FocusNode? _installedFocusNode;
  FocusOnKeyEventCallback? _previousOnKeyEvent;
  late final FocusOnKeyEventCallback _keyHandler = _handleKey;
  late final VoidCallback _focusListener = _handleFocusChanged;
  final Object _nativeFocusToken = Object();
  bool _reportedNativeTextInputFocused = false;
  TvVirtualKeyboardHandle? _tvKeyboardHandle;
  bool _tvKeyboardOpen = false;
  bool _tvKeyboardOpenScheduled = false;
  bool _suppressTvKeyboardAutoOpen = false;
  bool _hasSeenTvKeyboardFocus = false;
  bool _suppressTvKeyboardForCurrentFocus = false;
  bool _nativeTextInputActivated = false;
  bool _hasSeenNativeTextInputFocus = false;
  bool _suppressNativeTextInputForCurrentFocus = false;
  bool _nativeTextInputCompletionHandled = false;

  FocusNode get _effectiveFocusNode => _focusNodeBinding.node;

  @override
  void initState() {
    super.initState();
    _focusNodeBinding.bind(externalNode: widget.input.focusNode, debugLabel: 'FocusableTextInput');
    widget.input.tvTextInputController?._attach(this);
  }

  @override
  void didUpdateWidget(_FocusableTextInputHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.input.tvTextInputController, widget.input.tvTextInputController)) {
      oldWidget.input.tvTextInputController?._detach(this);
      widget.input.tvTextInputController?._attach(this);
    }
    if (oldWidget.input.focusNode != widget.input.focusNode) {
      // An open keyboard dialog intentionally survives rebuilds and focusNode
      // swaps; it is closed only when this host unmounts — see dispose.
      _restoreInstalledHandler();
      _focusNodeBinding.bind(externalNode: widget.input.focusNode, debugLabel: 'FocusableTextInput');
      _suppressTvKeyboardAutoOpen = false;
      _tvKeyboardOpenScheduled = false;
      _hasSeenTvKeyboardFocus = false;
      _suppressTvKeyboardForCurrentFocus = false;
      _nativeTextInputActivated = false;
      _hasSeenNativeTextInputFocus = false;
      _suppressNativeTextInputForCurrentFocus = false;
    }
    if (oldWidget.input.tvTextInputPresentation != widget.input.tvTextInputPresentation ||
        oldWidget.input.tvTextInputAutoOpenBehavior != widget.input.tvTextInputAutoOpenBehavior) {
      _nativeTextInputActivated = false;
      _hasSeenNativeTextInputFocus = false;
      _suppressNativeTextInputForCurrentFocus = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleFocusChanged();
    });
  }

  @override
  void dispose() {
    widget.input.tvTextInputController?._detach(this);
    _restoreInstalledHandler();
    // The keyboard is a navigator route — it must not outlive the field that
    // opened it (e.g. a form section swapped out while the keyboard is up).
    // Navigator mutation is unsafe during tree finalization; defer a frame.
    final keyboard = _tvKeyboardHandle;
    if (keyboard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => keyboard.close());
    }
    _focusNodeBinding.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    _restoreFocusAfterPlatformDismissal();
    _syncNativeTextInputActivation();
    _syncNativeTextInputFocus();
    _syncTvKeyboardAutoOpen();
  }

  /// [EditableText.connectionClosed] unfocuses the field outright
  /// (editable_text.dart:4138-4145). On tvOS that fires whenever UIKit
  /// dismisses the system keyboard, which is a dismissal, not a navigation —
  /// left alone it strands the user with nothing focused and no way back.
  ///
  /// Deliberate exits never reach here: every path that moves focus off an
  /// active field (D-pad escape, Menu, [TvTextInputController.closeTextInput],
  /// submit) deactivates first. `unfocus()` parks focus on the field's own
  /// enclosing scope, so that exact node — not merely "some scope" — is the
  /// signature. A dialog or route opening in the post-frame gap makes *its*
  /// scope primary, which must not be mistaken for our dismissal.
  void _restoreFocusAfterPlatformDismissal() {
    final node = _installedFocusNode;
    if (node == null || node.hasFocus || !_nativeTextInputActivated) return;
    // Apple TV only: connectionClosed-driven unfocus is a behavior of the
    // custom tvOS engine. Android's IME hide keeps the field focused and the
    // connection alive, so there is nothing to restore there.
    if (!PlatformDetector.isAppleTV()) return;
    if (!widget.input.enabled || !widget.input._usesNativeTvKeyboard) return;
    final scope = node.enclosingScope;
    if (scope == null || !identical(FocusManager.instance.primaryFocus, scope)) return;

    _setNativeTextInputActivated(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _installedFocusNode;
      if (target == null || target.hasFocus || !target.canRequestFocus) return;
      if (!identical(FocusManager.instance.primaryFocus, scope)) return;
      // Set before requesting focus so the resulting focus-change callback
      // cannot reopen the keyboard we were just dismissed out of.
      _suppressNativeTextInputForCurrentFocus = true;
      target.requestFocus();
    });
  }

  void _syncNativeTextInputActivation() {
    final input = widget.input;
    final focused = _installedFocusNode?.hasFocus == true && input.enabled && input._usesNativeTvKeyboard;
    if (!focused) {
      _suppressNativeTextInputForCurrentFocus = false;
      _setNativeTextInputActivated(false);
      return;
    }
    if (_suppressNativeTextInputForCurrentFocus) return;

    switch (input.tvTextInputAutoOpenBehavior) {
      // Apple TV's system keyboard is modal and full-screen. Arriving at a
      // field should still open it — otherwise typing always costs two
      // presses — but re-raising it every time D-pad traversal passes back
      // over the field makes a multi-field form unusable, so `automatic`
      // opens only on first focus there. Android TV's native IME is a docked
      // soft keyboard that does not take over the screen, so it keeps the
      // historical auto-open.
      case TvTextInputAutoOpenBehavior.automatic:
        if (PlatformDetector.isAppleTV() && _hasSeenNativeTextInputFocus) return;
        _hasSeenNativeTextInputFocus = true;
        _setNativeTextInputActivated(true);
      case TvTextInputAutoOpenBehavior.afterFirstFocus:
        if (!_hasSeenNativeTextInputFocus) {
          _hasSeenNativeTextInputFocus = true;
          _suppressNativeTextInputForCurrentFocus = true;
          return;
        }
        _setNativeTextInputActivated(true);
      case TvTextInputAutoOpenBehavior.never:
        return;
    }
  }

  void _setNativeTextInputActivated(bool activated) {
    if (_nativeTextInputActivated == activated) return;
    if (activated) _nativeTextInputCompletionHandled = false;
    if (!mounted) {
      _nativeTextInputActivated = activated;
      return;
    }
    setState(() => _nativeTextInputActivated = activated);
  }

  void _activateNativeTextInput() {
    if (!widget.input.enabled || !widget.input._usesNativeTvKeyboard) return;
    _hasSeenNativeTextInputFocus = true;
    _suppressNativeTextInputForCurrentFocus = false;
    _setNativeTextInputActivated(true);
  }

  VoidCallback? get _effectiveOnEditingComplete {
    final input = widget.input;
    if (!input._usesNativeTvKeyboard) return input._effectiveOnEditingComplete;
    return _handleNativeEditingComplete;
  }

  void _handleNativeEditingComplete() {
    if (_nativeTextInputCompletionHandled) return;
    _nativeTextInputCompletionHandled = true;
    _suppressNativeTextInputForCurrentFocus = true;
    _setNativeTextInputActivated(false);

    final input = widget.input;
    final callback = input._effectiveOnEditingComplete;
    final onSubmitted = input.onSubmitted;
    if (callback != null) {
      callback();
    } else if (onSubmitted == null) {
      // Supplying this wrapper replaces EditableText's default completion.
      // Preserve it when there is no submit callback; submitted TV fields keep
      // focus until their callback chooses the next target so D-pad navigation
      // cannot dead-end while asynchronous work runs.
      _defaultEditingComplete(input.textInputAction);
    }

    // EditableText invokes onEditingComplete and onSubmitted independently
    // (_finalizeEditing, editable_text.dart:3841-3898), so both must fire when
    // both are supplied. The native path withholds onSubmitted from the widget
    // — letting EditableText own it would schedule a connection restart that
    // re-attaches and re-shows the input we just dismissed, which on tvOS
    // tears the system keyboard down and back up mid-submit — so call it here.
    onSubmitted?.call(input.controller.text);
  }

  void _syncNativeTextInputFocus() {
    // Activation-based, not focus-based: the platform hint pauses the gamepad
    // bridge and defers the pre-IME D-pad intercept to the IME, and it arms
    // MainActivity's soft-input show-retry/repair session — all of which must
    // track a *live* text input session, not a merely focused (read-only
    // gated) field. A dismissed keyboard therefore hands D-pad routing back
    // to the app immediately.
    final focused =
        _installedFocusNode?.hasFocus == true &&
        widget.input.enabled &&
        widget.input._usesNativeTvKeyboard &&
        _nativeTextInputActivated;
    if (TextInputDiagnostics.enabled) {
      _logTvTextInput(
        'Host.syncNativeTextInputFocus focused=$focused installed=${_installedFocusNode?.debugLabel} '
        'hasFocus=${_installedFocusNode?.hasFocus} enabled=${widget.input.enabled} '
        'usesNativeTvKeyboard=${widget.input._usesNativeTvKeyboard} activated=$_nativeTextInputActivated',
      );
    }
    _setNativeTextInputFocused(focused);
  }

  void _syncTvKeyboardAutoOpen() {
    final focused = _installedFocusNode?.hasFocus == true && widget.input.enabled && widget.input._hasTvKeyboard;
    final visible = _canShowTvKeyboard;
    if (TextInputDiagnostics.enabled) {
      _logTvTextInput(
        'Host.syncTvKeyboardAutoOpen focused=$focused open=$_tvKeyboardOpen scheduled=$_tvKeyboardOpenScheduled '
        'suppressed=$_suppressTvKeyboardAutoOpen behavior=${widget.input.tvTextInputAutoOpenBehavior} '
        'seenFocus=$_hasSeenTvKeyboardFocus suppressCurrent=$_suppressTvKeyboardForCurrentFocus '
        'installed=${_installedFocusNode?.debugLabel} '
        'hasFocus=${_installedFocusNode?.hasFocus} enabled=${widget.input.enabled} '
        'usesTvKeyboard=${widget.input._hasTvKeyboard} visible=$visible',
      );
    }

    if (!focused) {
      _suppressTvKeyboardForCurrentFocus = false;
      if (!_tvKeyboardOpen && !_tvKeyboardOpenScheduled) {
        _suppressTvKeyboardAutoOpen = false;
      }
      return;
    }

    if (!visible) return;
    if (!_shouldAutoOpenTvKeyboardForCurrentFocus()) return;
    if (_suppressTvKeyboardAutoOpen || _tvKeyboardOpen || _tvKeyboardOpenScheduled) return;

    _tvKeyboardOpenScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tvKeyboardOpenScheduled = false;
      final stillFocused = _installedFocusNode?.hasFocus == true && widget.input.enabled && widget.input._hasTvKeyboard;
      if (!stillFocused || !_canShowTvKeyboard || _suppressTvKeyboardAutoOpen || _tvKeyboardOpen) return;
      _openTvKeyboard();
    });
  }

  bool get _canShowTvKeyboard {
    final route = ModalRoute.of(context);
    return TickerMode.valuesOf(context).enabled && (route?.isCurrent ?? true);
  }

  bool _shouldAutoOpenTvKeyboardForCurrentFocus() {
    switch (widget.input.tvTextInputAutoOpenBehavior) {
      // The Flutter overlay is an in-app, non-modal widget with no UIKit first
      // responder behind it, so opening it on focus costs nothing.
      case TvTextInputAutoOpenBehavior.automatic:
        return true;
      case TvTextInputAutoOpenBehavior.afterFirstFocus:
        if (!_hasSeenTvKeyboardFocus) {
          _hasSeenTvKeyboardFocus = true;
          _suppressTvKeyboardForCurrentFocus = true;
          return false;
        }
        return !_suppressTvKeyboardForCurrentFocus;
      case TvTextInputAutoOpenBehavior.never:
        return false;
    }
  }

  void _openTvKeyboard() {
    if (!mounted || !widget.input.enabled || !widget.input._hasTvKeyboard || !_canShowTvKeyboard || _tvKeyboardOpen) {
      return;
    }

    _tvKeyboardOpenScheduled = false;
    _tvKeyboardOpen = true;
    _hasSeenTvKeyboardFocus = true;
    _suppressTvKeyboardForCurrentFocus = false;
    _suppressTvKeyboardAutoOpen = true;
    _logTvTextInput('Host.openTvKeyboard node=${_installedFocusNode?.debugLabel}');
    // The dialog outlives input rebuilds (e.g. a search field whose
    // onNavigateDown appears once results arrive while the keyboard is up),
    // so only static configuration may be snapshotted here — the callbacks
    // must resolve against widget.input at invoke time.
    final input = widget.input;
    final keyboard = showTvVirtualKeyboard(
      context: context,
      controller: input.controller,
      hintText: _keyboardHint(input.decoration),
      keyboardType: input.keyboardType,
      textInputAction: input.textInputAction,
      inputFormatters: input.inputFormatters,
      obscureText: input.obscureText,
      maxLength: input.maxLength,
      maxLines: input.maxLines,
      onChanged: (text) {
        if (!mounted) return;
        widget.input.onChanged?.call(text);
      },
      onSubmitted: (text) {
        if (!mounted) return;
        final current = widget.input;
        if (current.onSubmitted != null) {
          current.onSubmitted!(text);
        } else {
          current._handleTvKeyboardAction();
        }
      },
    );
    if (keyboard == null) {
      _tvKeyboardOpen = false;
      return;
    }
    _tvKeyboardHandle = keyboard;
    unawaited(
      keyboard.closed.whenComplete(() {
        _tvKeyboardHandle = null;
        if (!mounted) return;
        _tvKeyboardOpen = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_installedFocusNode?.hasFocus != true) {
            _suppressTvKeyboardAutoOpen = false;
          }
          _syncTvKeyboardAutoOpen();
        });
      }),
    );
  }

  /// Dismiss active text input imperatively (e.g. a companion-remote search
  /// that must show results instead of the keyboard). Suppresses auto-reopen
  /// so a field that keeps or regains focus does not relaunch it.
  void _dismissTvKeyboard() {
    if (widget.input._usesNativeTvKeyboard && _nativeTextInputActivated) {
      _suppressNativeTextInputForCurrentFocus = true;
      _setNativeTextInputActivated(false);
    }

    // No-op for the Flutter presentation when no overlay is up: setting its
    // suppress flag without a compensating unfocus would block a later
    // legitimate auto-open.
    if (!_tvKeyboardOpen && !_tvKeyboardOpenScheduled) return;
    _tvKeyboardOpenScheduled = false;
    _suppressTvKeyboardAutoOpen = true;
    _tvKeyboardHandle?.close();
  }

  /// Focus the field without opening either native or Flutter text input for
  /// this focus entry. Suppression is set before requestFocus so the resulting
  /// focus-change callback cannot open either presentation.
  void _focusWithoutKeyboard() {
    _suppressTvKeyboardAutoOpen = true;
    _suppressNativeTextInputForCurrentFocus = true;
    _tvKeyboardOpenScheduled = false;
    if (widget.input._usesNativeTvKeyboard) {
      _setNativeTextInputActivated(false);
    }
    final focusNode = _installedFocusNode ?? _effectiveFocusNode;
    focusNode.requestFocus();
    scheduleMicrotask(() {
      if (!mounted || focusNode.hasFocus || _tvKeyboardOpen || _tvKeyboardOpenScheduled) return;
      _suppressTvKeyboardAutoOpen = false;
      _suppressNativeTextInputForCurrentFocus = false;
    });
  }

  /// Focus the field and open text input as an explicit Select would. Clears
  /// per-focus suppression first so a field configured with
  /// [TvTextInputAutoOpenBehavior.never] still opens.
  void _focusAndOpenTextInput() {
    _suppressTvKeyboardAutoOpen = false;
    _suppressNativeTextInputForCurrentFocus = false;
    final focusNode = _installedFocusNode ?? _effectiveFocusNode;
    if (focusNode.hasFocus) {
      _openTextInputForFocusedField();
      return;
    }
    focusNode.requestFocus();
    // Focus lands in FocusManager's microtask. Activating before that would be
    // undone by the focus sync this frame's build already scheduled, which
    // deactivates an unfocused field.
    scheduleMicrotask(() {
      if (mounted && focusNode.hasFocus) _openTextInputForFocusedField();
    });
  }

  void _openTextInputForFocusedField() {
    if (widget.input._usesNativeTvKeyboard) {
      _activateNativeTextInput();
    } else if (widget.input._hasTvKeyboard && !_tvKeyboardOpen && !_tvKeyboardOpenScheduled) {
      // The overlay is a navigator route; push it once the focus request has
      // landed so the route's focus scope does not race the field's.
      _tvKeyboardOpenScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tvKeyboardOpenScheduled = false;
        _openTvKeyboard();
      });
    }
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
    var activateNativeTextInput = widget.input._usesNativeTvKeyboard && !_nativeTextInputActivated;
    final isRemoteNavigation = event.logicalKey.isDpadDirection || event.logicalKey.isBackKey || event.isTvSelectEvent;
    if (widget.input._usesNativeTvKeyboard &&
        _nativeTextInputActivated &&
        event is KeyDownEvent &&
        isRemoteNavigation) {
      if (PlatformDetector.isAppleTV()) {
        // Remote navigation events are system-owned while the native keyboard
        // is active. Receiving one here proves that UIKit has dismissed the
        // keyboard while Flutter focus stayed on the field. Restore the
        // read-only gate so this press navigates Flutter instead of reopening
        // the input connection.
        _suppressNativeTextInputForCurrentFocus = true;
        _setNativeTextInputActivated(false);
        activateNativeTextInput = true;
        if (event.logicalKey.isBackKey) {
          // This is the Menu press that dismissed UIKit's keyboard. Consume its
          // Flutter continuation so one press cannot also pop the app route.
          return KeyEventResult.handled;
        }
        if (event.isTvSelectEvent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _activateNativeTextInput();
          });
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey.isBackKey) {
        // Android: a healthy IME consumes Back to dismiss itself before the
        // app ever sees it. One arriving here means the keyboard is already
        // gone (or its key session is broken and MainActivity's repair budget
        // ran out): close the session and consume the press so it cannot also
        // pop the route underneath.
        _suppressNativeTextInputForCurrentFocus = true;
        _setNativeTextInputActivated(false);
        return KeyEventResult.handled;
      } else if (event.isTvSelectEvent) {
        // Android: Select on a field whose keyboard was dismissed re-raises
        // it (EditText parity). Toggle the connection so the engine issues a
        // fresh TextInput.show; MainActivity's show-retry covers the
        // served-view race (#1051/#1079).
        _suppressNativeTextInputForCurrentFocus = true;
        _setNativeTextInputActivated(false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _activateNativeTextInput();
        });
        return KeyEventResult.handled;
      }
      // Android arrows fall through deliberately: a healthy visible IME
      // consumes them before the app, and leaked ones are repaired and eaten
      // by MainActivity — so an arrow reaching this handler is real caret or
      // traversal input (BT keyboards included) and keeps the caret-aware
      // edge-escape semantics below.
    }
    return widget.input._handleKey(
      context,
      node,
      event,
      _openTvKeyboard,
      activateNativeTextInput: activateNativeTextInput,
      activateNativeTextInputCallback: _activateNativeTextInput,
    );
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
    _nativeTextInputActivated = false;
    _suppressNativeTextInputForCurrentFocus = false;
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
    _syncTvKeyboardAutoOpen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleFocusChanged();
    });
    final usesTvKeyboard = widget.input._hasTvKeyboard;
    return widget.builder(
      usesTvKeyboard: usesTvKeyboard,
      nativeTextInputReadOnly: widget.input._usesNativeTvKeyboard && !_nativeTextInputActivated,
      focusNode: focusNode,
      openKeyboard: _openTvKeyboard,
      activateNativeTextInput: _activateNativeTextInput,
      onEditingComplete: _effectiveOnEditingComplete,
    );
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
    super.tvTextInputPresentation,
    super.tvTextInputAutoOpenBehavior,
    super.tvTextInputController,
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
    return buildFocusableInput(({
      required bool usesTvKeyboard,
      required bool nativeTextInputReadOnly,
      required FocusNode focusNode,
      required VoidCallback openKeyboard,
      required VoidCallback activateNativeTextInput,
      required VoidCallback? onEditingComplete,
    }) {
      final tvInput = _tvInputConfiguration(
        usesTvKeyboard: usesTvKeyboard,
        nativeTextInputReadOnly: nativeTextInputReadOnly,
        openKeyboard: openKeyboard,
        activateNativeTextInput: activateNativeTextInput,
      );
      return TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        decoration: decoration,
        keyboardType: tvInput.keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        // Withheld on the native TV path: the host invokes it from
        // _handleNativeEditingComplete so EditableText cannot schedule a
        // connection restart that re-shows the dismissed input.
        onSubmitted: _usesNativeTvKeyboard ? null : onSubmitted,
        onEditingComplete: onEditingComplete,
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
        readOnly: tvInput.readOnly,
        showCursor: tvInput.showCursor,
        enableInteractiveSelection: tvInput.enableInteractiveSelection,
        onTap: tvInput.onTap,
      );
    });
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
    super.tvTextInputPresentation,
    super.tvTextInputAutoOpenBehavior,
    super.tvTextInputController,
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
    return buildFocusableInput(({
      required bool usesTvKeyboard,
      required bool nativeTextInputReadOnly,
      required FocusNode focusNode,
      required VoidCallback openKeyboard,
      required VoidCallback activateNativeTextInput,
      required VoidCallback? onEditingComplete,
    }) {
      final tvInput = _tvInputConfiguration(
        usesTvKeyboard: usesTvKeyboard,
        nativeTextInputReadOnly: nativeTextInputReadOnly,
        openKeyboard: openKeyboard,
        activateNativeTextInput: activateNativeTextInput,
      );
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        decoration: decoration,
        keyboardType: tvInput.keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        // Withheld on the native TV path — see FocusableTextField.build.
        onFieldSubmitted: _usesNativeTvKeyboard ? null : onFieldSubmitted,
        onEditingComplete: onEditingComplete,
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
        readOnly: tvInput.readOnly,
        showCursor: tvInput.showCursor,
        enableInteractiveSelection: tvInput.enableInteractiveSelection,
        onTap: tvInput.onTap,
      );
    });
  }
}
