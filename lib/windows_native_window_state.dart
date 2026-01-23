import 'dart:io';
import 'package:flutter/services.dart';

/// Native Windows window state manager using Platform Channels
class WindowsNativeWindowState {
  static const MethodChannel _channel = MethodChannel('native_window_state');

  /// Saves the current window state to the Windows Registry
  static Future<bool> saveWindowState({required bool isMaximized}) async {
    if (!Platform.isWindows) return false;
    try {
      final result = await _channel.invokeMethod('saveWindowState', {'isMaximized': isMaximized});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Loads and applies the window state from the Windows Registry
  static Future<bool> loadWindowState() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await _channel.invokeMethod('loadWindowState');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the saved window state from the registry
  static Future<bool> clearWindowState() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await _channel.invokeMethod('clearWindowState');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current window state as a map
  static Future<Map<String, dynamic>?> getWindowState() async {
    if (!Platform.isWindows) return null;
    try {
      final result = await _channel.invokeMethod('getWindowState');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }
}
