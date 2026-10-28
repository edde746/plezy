import 'package:flutter/services.dart';

class PlezyPreparation {
  static const channel = MethodChannel('org.plezy/preparation');
  static Future<void> schedule() => channel.invokeMethod<void>('schedule');
  static Future<void> cancel() => channel.invokeMethod<void>('cancel');
}
