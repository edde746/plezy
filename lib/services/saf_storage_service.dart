import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/platform_helper.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';
import 'package:saf_stream/saf_stream.dart';

/// Handles Storage Access Framework (SAF) operations for Android
class SafStorageService {
  static SafStorageService? _instance;
  static SafStorageService get instance => _instance ??= SafStorageService._();
  SafStorageService._();

  final SafUtil _safUtil = SafUtil();
  final SafStream _safStream = SafStream();

  /// Check if SAF is available (Android only)
  bool get isAvailable => AppPlatform.isAndroid;

  /// Pick a directory using SAF
  /// Returns the content:// URI or null if cancelled
  Future<String?> pickDirectory() async {
    if (!isAvailable) return null;
    try {
      // Pick directory with persistent write permission
      final doc = await _safUtil.pickDirectory(writePermission: true, persistablePermission: true);
      return doc?.uri;
    } catch (e) {
      debugPrint('SAF pickDirectory error: $e');
      return null;
    }
  }

  /// Check if we have persisted access to a URI
  Future<bool> hasPersistedPermission(String contentUri) async {
    if (!isAvailable) return false;
    try {
      return await _safUtil.hasPersistedPermission(contentUri, checkRead: true, checkWrite: true);
    } catch (e) {
      debugPrint('SAF hasPersistedPermission error: $e');
      return false;
    }
  }

  /// Get document file info for a URI
  Future<SafDocumentFile?> getDocumentFile(String contentUri, {bool isDir = true}) async {
    if (!isAvailable) return null;
    try {
      return await _safUtil.documentFileFromUri(contentUri, isDir);
    } catch (e) {
      debugPrint('SAF getDocumentFile error: $e');
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

  /// List files in a SAF directory
  Future<List<SafDocumentFile>> listDirectory(String contentUri) async {
    if (!isAvailable) return [];
    try {
      return await _safUtil.list(contentUri);
    } catch (e) {
      debugPrint('SAF listDirectory error: $e');
      return [];
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

  /// Delete a file or directory in SAF
  Future<bool> delete(String contentUri, {bool isDir = false}) async {
    if (!isAvailable) return false;
    try {
      await _safUtil.delete(contentUri, isDir);
      return true;
    } catch (e) {
      debugPrint('SAF delete error: $e');
      return false;
    }
  }

  /// Get a display name for a SAF URI (for UI purposes)
  Future<String?> getDisplayName(String contentUri) async {
    if (!isAvailable) return null;
    try {
      final doc = await _safUtil.documentFileFromUri(contentUri, true);
      return doc?.name;
    } catch (e) {
      debugPrint('SAF getDisplayName error: $e');
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

  /// Copy a file from local storage to SAF directory using native copy
  /// Returns the SAF URI of the copied file, or null on failure
  Future<String?> copyFileToSaf(
    String sourceFilePath,
    String targetDirectoryUri,
    String fileName,
    String mimeType,
  ) async {
    if (!isAvailable) return null;

    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        debugPrint('SAF copyFileToSaf: source file does not exist');
        return null;
      }

      // Use pasteLocalFile for native-side copy (no method channel streaming)
      // This is much more efficient for large files and avoids hangs
      final result = await _safStream
          .pasteLocalFile(sourceFilePath, targetDirectoryUri, fileName, mimeType, overwrite: true)
          .timeout(const Duration(minutes: 30), onTimeout: () => throw TimeoutException('SAF copy timed out'));

      debugPrint('SAF copyFileToSaf: successfully copied to ${result.uri}');
      return result.uri.toString();
    } on TimeoutException catch (e) {
      debugPrint('SAF copyFileToSaf timeout: $e');
      return null;
    } catch (e) {
      debugPrint('SAF copyFileToSaf error: $e');
      return null;
    }
  }

  /// Write bytes directly to a SAF file
  /// Returns the SAF URI of the created file, or null on failure
  Future<String?> writeFileBytes(String directoryUri, String fileName, String mimeType, Uint8List bytes) async {
    if (!isAvailable) return null;
    try {
      final result = await _safStream.writeFileBytes(directoryUri, fileName, mimeType, bytes);
      return result.uri.toString();
    } catch (e) {
      debugPrint('SAF writeFileBytes error: $e');
      return null;
    }
  }

  /// Read bytes from a SAF file
  Future<Uint8List?> readFileBytes(String fileUri) async {
    if (!isAvailable) return null;
    try {
      return await _safStream.readFileBytes(fileUri);
    } catch (e) {
      debugPrint('SAF readFileBytes error: $e');
      return null;
    }
  }

  /// Check if a file exists in a SAF directory
  Future<bool> fileExists(String parentUri, String fileName) async {
    if (!isAvailable) return false;
    try {
      final child = await _safUtil.child(parentUri, [fileName]);
      return child != null;
    } catch (e) {
      debugPrint('SAF fileExists error: $e');
      return false;
    }
  }

  /// Get the content URI for a file that should be readable by MediaStore/media players
  /// For SAF files, this returns the same URI as input (content:// URIs are already readable)
  String getReadableUri(String safUri) => safUri;
}
