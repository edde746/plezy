import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel =
      MethodChannel('app.plezy/pip');

  static Future<bool> isSupported() async {
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  static Future<void> enter({
    int? width,
    int? height,
  }) async {
    await _channel.invokeMethod('enter', {
      'width': width,
      'height': height,
    });
  }
}