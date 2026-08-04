import 'package:flutter/services.dart';

/// Bridges the Android TV remote's subtitles/CC button (KEYCODE_CAPTIONS) from
/// the native activity to the video player controls, which toggle the subtitle
/// selector sheet.
///
/// The handler is registered unconditionally (the channel never fires on
/// non-Android platforms), so widget tests can drive it through the test
/// messenger. Production constructs the singleton from `main.dart`.
class CaptionsService {
  static const MethodChannel _channel = MethodChannel('com.plezy/captions');

  static CaptionsService? _instance;
  factory CaptionsService() => _instance ??= CaptionsService._internal();
  CaptionsService._internal() {
    _channel.setMethodCallHandler(handleMethodCall);
  }

  /// Set by the mounted video-player controls so the CAPTIONS key only toggles
  /// the subtitle selector while the player is on screen. Cleared on dispose.
  static VoidCallback? onToggleSubtitleSelector;

  static Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'toggleSubtitleSelector':
        onToggleSubtitleSelector?.call();
    }
    return null;
  }
}
