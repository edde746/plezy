import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:saf_util/saf_util.dart';
import '../utils/platform_detector.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

/// Handles Storage Access Framework (SAF) operations for Android
class SafStorageService {
  static SafStorageService? _instance;
  static SafStorageService get instance => _instance ??= SafStorageService._();
  SafStorageService._();

  final SafUtil _safUtil = SafUtil();

  /// Check if SAF is available (Android only)
  bool get isAvailable => Platform.isAndroid;

  /// Pick a directory using SAF
  /// Returns the content:// URI or null if cancelled
  Future<String?> pickDirectory() async {
    if (!isAvailable) return null;
    // SAF document picker is not available on Android TV
    if (TvDetectionService.isTVSync()) return null;
    try {
      // Pick directory with persistent write permission
      final doc = await _safUtil.pickDirectory(writePermission: true, persistablePermission: true);
      return doc?.uri;
    } catch (e) {
      debugPrint('SAF pickDirectory error: $e');
      return null;
    }
  }

  /// Create a subdirectory in a SAF directory
  /// Returns the URI of the created directory
  Future<String?> createDirectory(String parentUri, String name) async {
    if (!isAvailable) return null;
    try {
      final result = await _safUtil.mkdirp(parentUri, [name]);
      return result.uri;
    } catch (e) {
      debugPrint('SAF createDirectory error: $e');
      return null;
    }
  }

  /// Get a child file/directory in a SAF directory
  Future<SafDocumentFile?> getChild(String parentUri, String name) async {
    if (!isAvailable) return null;
    try {
      return await _safUtil.child(parentUri, [name]);
    } catch (e) {
      debugPrint('SAF getChild error: $e');
      return null;
    }
  }

  /// Create nested directories in a SAF directory
  /// Returns the URI of the deepest directory
  Future<String?> createNestedDirectories(String parentUri, List<String> pathComponents) async {
    if (!isAvailable) return null;
    try {
      final result = await _safUtil.mkdirp(parentUri, pathComponents);
      return result.uri;
    } catch (e) {
      debugPrint('SAF createNestedDirectories error: $e');
      return null;
    }
  }

}
