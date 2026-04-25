import 'dart:io';

import 'package:saf_util/saf_util.dart';
import '../utils/app_logger.dart';
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
      appLogger.w('SAF pickDirectory error', error: e);
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
      appLogger.w('SAF createDirectory error', error: e);
      return null;
    }
  }

  /// Traverse to a child file/directory under a SAF directory.
  /// [names] is the path-component list from [parentUri] to the target;
  /// pass a single element for an immediate child.
  Future<SafDocumentFile?> getChild(String parentUri, List<String> names) async {
    if (!isAvailable) return null;
    try {
      return await _safUtil.child(parentUri, names);
    } catch (e) {
      appLogger.w('SAF getChild error', error: e);
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
      appLogger.w('SAF createNestedDirectories error', error: e);
      return null;
    }
  }

  /// Delete a SAF file or directory. Returns true on success, false on error.
  Future<bool> delete(String uri, {required bool isDir}) async {
    if (!isAvailable) return false;
    try {
      await _safUtil.delete(uri, isDir);
      return true;
    } catch (e) {
      appLogger.w('SAF delete error', error: e);
      return false;
    }
  }

  /// Check whether a SAF file or directory exists. Returns false on error.
  Future<bool> exists(String uri, {required bool isDir}) async {
    if (!isAvailable) return false;
    try {
      return await _safUtil.exists(uri, isDir);
    } catch (e) {
      appLogger.w('SAF exists error', error: e);
      return false;
    }
  }

  /// List children of a SAF directory. Returns null on error so callers can
  /// distinguish "error" from "empty dir".
  Future<List<SafDocumentFile>?> list(String uri) async {
    if (!isAvailable) return null;
    try {
      return await _safUtil.list(uri);
    } catch (e) {
      appLogger.w('SAF list error', error: e);
      return null;
    }
  }
}
