import 'dart:io';

import 'package:saf_util/saf_util.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

abstract interface class SafStorageOperations {
  Future<SafDocumentFile?> getChild(String parentUri, List<String> names);

  Future<String?> createNestedDirectories(String parentUri, List<String> pathComponents);

  Future<bool> delete(String uri, {required bool isDir});

  Future<bool> exists(String uri, {required bool isDir});

  Future<List<SafDocumentFile>?> list(String uri);

  Future<String?> resolvePersistedPermissionUri(String uri);

  Future<List<String>?> getPersistedPermissionUris();

  Future<bool> releasePersistedPermission(String uri);
}

/// Handles Storage Access Framework (SAF) operations for Android
class SafStorageService implements SafStorageOperations {
  static SafStorageService? _instance;
  static SafStorageService get instance => _instance ??= SafStorageService._();
  SafStorageService._();

  final SafUtil _safUtil = SafUtil();

  /// Check if SAF is available (Android only)
  bool get isAvailable => Platform.isAndroid;

  /// Android TV distributions commonly have no DocumentsUI activity, so a
  /// custom SAF root cannot be selected there.
  bool get supportsDirectoryPicker => isAvailable && !PlatformDetector.isTV();

  /// Pick a directory using SAF.
  ///
  /// Returns the content URI, or null only when the user cancels. Platform
  /// failures propagate so the settings screen can distinguish them from a
  /// cancellation and show an actionable error.
  Future<String?> pickDirectory() async {
    if (!supportsDirectoryPicker) return null;
    try {
      final doc = await _safUtil.pickDirectory(writePermission: true, persistablePermission: true);
      return doc?.uri;
    } catch (error, stackTrace) {
      appLogger.w('SAF pickDirectory failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Resolves a document or descendant URI to the canonical persisted tree URI.
  ///
  /// A null result means either that no persisted grant covers [uri] or that
  /// the native lookup failed. Callers must retain ownership on null rather
  /// than speculatively releasing a grant.
  @override
  Future<String?> resolvePersistedPermissionUri(String uri) async {
    if (!isAvailable) return null;
    try {
      return await _safUtil.resolvePersistedPermissionUri(uri);
    } catch (e) {
      appLogger.w('SAF persisted permission resolution failed', error: e);
      return null;
    }
  }

  /// Enumerates canonical persisted tree permission URIs.
  ///
  /// Returns null when Android enumeration fails so reconciliation remains
  /// retryable instead of treating a failure as an empty grant set.
  @override
  Future<List<String>?> getPersistedPermissionUris() async {
    if (!isAvailable) return const [];
    try {
      return await _safUtil.getPersistedPermissionUris();
    } catch (e) {
      appLogger.w('SAF persisted permission enumeration failed', error: e);
      return null;
    }
  }

  /// Releases both read and write access to the canonical grant covering [uri].
  ///
  /// The package operation is idempotent. A false result is reserved for a
  /// native failure and tells the owner to retry during startup reconciliation.
  @override
  Future<bool> releasePersistedPermission(String uri) async {
    if (!isAvailable) return true;
    try {
      await _safUtil.releasePersistedPermission(uri, read: true, write: true);
      return true;
    } catch (e) {
      appLogger.w('SAF persisted permission release failed', error: e);
      return false;
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
  @override
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
  @override
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
  @override
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
  @override
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
  @override
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
