import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

class FocusedMediaPlayIntent extends Intent {
  const FocusedMediaPlayIntent();
}

class FocusedMediaPlayAction extends Action<FocusedMediaPlayIntent> {
  FocusedMediaPlayAction({required this.canPlay, required this.onPlay});

  final bool Function() canPlay;
  final Future<void> Function() onPlay;
  bool _launching = false;

  @override
  bool isEnabled(FocusedMediaPlayIntent intent) =>
      defaultTargetPlatform == TargetPlatform.android && PlatformDetector.isTV() && canPlay();

  @override
  Object? invoke(FocusedMediaPlayIntent intent) {
    if (!_launching) unawaited(_play());
    return null;
  }

  Future<void> _play() async {
    _launching = true;
    try {
      await onPlay();
    } catch (error, stackTrace) {
      appLogger.e('Failed to play focused media', error: error, stackTrace: stackTrace);
    } finally {
      _launching = false;
    }
  }
}

final _handledPlayEvents = Expando<bool>();
final _heldPlayKeys = <LogicalKeyboardKey>{};

KeyEventResult handleFocusedMediaPlayKey(KeyEvent event) {
  final key = event.logicalKey;
  if (key != LogicalKeyboardKey.mediaPlay && key != LogicalKeyboardKey.mediaPlayPause) {
    return KeyEventResult.ignored;
  }
  if (_handledPlayEvents[event] == true) return KeyEventResult.handled;
  if (event is! KeyDownEvent && _heldPlayKeys.contains(key)) {
    if (event is KeyUpEvent) _heldPlayKeys.remove(key);
    _handledPlayEvents[event] = true;
    return KeyEventResult.handled;
  }
  if (event is KeyDownEvent) _heldPlayKeys.remove(key);
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null || !context.mounted || ModalRoute.of(context)?.isCurrent == false) {
    return KeyEventResult.ignored;
  }
  const intent = FocusedMediaPlayIntent();
  final action = Actions.maybeFind<FocusedMediaPlayIntent>(context);
  if (action == null || !action.isEnabled(intent)) return KeyEventResult.ignored;
  _handledPlayEvents[event] = true;
  if (event is KeyDownEvent) {
    _heldPlayKeys.add(key);
    Actions.of(context).invokeAction(action, intent, context);
  }
  return KeyEventResult.handled;
}
