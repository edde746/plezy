import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('app.plezy/pip');

  // Singleton instance
  static final PipService _instance = PipService._internal();
  factory PipService() => _instance;

  PipService._internal() {
    // Listen for callbacks from native platforms (macOS and Android)
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// ValueNotifier for PiP state - widgets can listen to this
  final ValueNotifier<bool> isPipActive = ValueNotifier<bool>(false);

  /// Callback for play/pause commands from PiP overlay
  void Function()? onPlayPause;

  /// Callback for seek commands from PiP overlay (offset in seconds)
  void Function(int offset)? onSeek;

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipChanged':
        final isInPip = call.arguments as bool;
        isPipActive.value = isInPip;
        break;
      case 'playPause':
        onPlayPause?.call();
        break;
      case 'seek':
        final offset = call.arguments as int;
        onSeek?.call(offset);
        break;
    }
  }

  static Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  static Future<void> enter({int? width, int? height, bool? isPlaying}) async {
    await _channel.invokeMethod('enter', {
      'width': width,
      'height': height,
      'isPlaying': isPlaying,
    });
  }

  static Future<void> updatePlayPauseIcon({required bool isPlaying}) async {
    await _channel.invokeMethod('updatePlayPauseIcon', isPlaying);
  }
}
