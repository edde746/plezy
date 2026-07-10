import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'saf_util_platform_interface.dart';

/// An implementation of [SafUtilPlatform] that uses method channels.
class MethodChannelSafUtil extends SafUtilPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('saf_util');

  @override
  Future<SafDocumentFile?> pickDirectory(
      {String? initialUri,
      bool? writePermission,
      bool? persistablePermission}) async {
    final map =
        await methodChannel.invokeMapMethod<String, dynamic>('pickDirectory', {
      'initialUri': initialUri,
      'writePermission': writePermission,
      'persistablePermission': persistablePermission,
    });
    if (map == null) {
      return null;
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<String?> openDirectory(
      {String? initialUri,
      bool? writePermission,
      bool? persistablePermission}) async {
    final res = await pickDirectory(
      initialUri: initialUri,
      writePermission: writePermission,
      persistablePermission: persistablePermission,
    );
    return res?.uri;
  }

  @override
  Future<SafDocumentFile?> pickFile({
    String? initialUri,
    List<String>? mimeTypes,
  }) async {
    final res = await pickFiles(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
      multiple: false,
    );
    return res?.first;
  }

  @override
  Future<String?> openFile({
    String? initialUri,
    List<String>? mimeTypes,
  }) async {
    final res = await pickFile(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
    );
    return res?.uri;
  }

  @override
  Future<List<SafDocumentFile>?> pickFiles({
    String? initialUri,
    List<String>? mimeTypes,
    multiple = true,
  }) async {
    final maps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('pickFiles', {
      'initialUri': initialUri,
      'mimeTypes': mimeTypes,
      'multiple': multiple,
    });
    return maps?.map((map) => SafDocumentFile.fromMap(map)).toList();
  }

  @override
  Future<List<String>?> openFiles({
    String? initialUri,
    List<String>? mimeTypes,
    multiple = true,
  }) async {
    final res = await pickFiles(
      initialUri: initialUri,
      mimeTypes: mimeTypes,
      multiple: multiple,
    );
    return res?.map((file) => file.uri).toList();
  }

  @override
  Future<List<SafDocumentFile>> list(String uri) async {
    final maps = await methodChannel
        .invokeListMethod<Map<dynamic, dynamic>>('list', {'uri': uri});
    return (maps ?? []).map((map) => SafDocumentFile.fromMap(map)).toList();
  }

  @override
  Future<SafDocumentFile?> documentFileFromUri(String uri, bool? isDir) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'documentFileFromUri',
      {'uri': uri, 'isDir': isDir},
    );
    if (map == null) {
      return null;
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<SafDocumentFile?> stat(String uri, bool? isDir) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'stat',
      {'uri': uri, 'isDir': isDir},
    );
    if (map == null) {
      return null;
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<bool> exists(String uri, bool isDir) async {
    final res = await methodChannel.invokeMethod<bool>(
      'exists',
      {'uri': uri, 'isDir': isDir},
    );
    if (res == null) {
      throw Exception('Failed to check if file exists: $uri');
    }
    return res;
  }

  @override
  Future<void> delete(String uri, bool isDir) async {
    final res = await methodChannel.invokeMethod<bool>(
      'delete',
      {'uri': uri, 'isDir': isDir},
    );
    if (res != true) {
      throw Exception('Failed to delete file: $uri');
    }
  }

  @override
  Future<SafDocumentFile> mkdirp(String uri, List<String> names) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'mkdirp',
      {'uri': uri, 'names': names},
    );
    if (map == null) {
      throw Exception('Failed to create directory: $uri');
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<SafDocumentFile?> child(String uri, List<String> names) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'child',
      {'uri': uri, 'names': names},
    );
    if (map == null) {
      return null;
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<SafDocumentFile> rename(String uri, bool isDir, String newName) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'rename',
      {'uri': uri, 'isDir': isDir, 'newName': newName},
    );
    if (map == null) {
      throw Exception('Failed to rename: $uri');
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<SafDocumentFile> moveTo(
      String uri, bool isDir, String parentUri, String newParentUri) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'moveTo',
      {
        'uri': uri,
        'isDir': isDir,
        'parentUri': parentUri,
        'newParentUri': newParentUri
      },
    );
    if (map == null) {
      throw Exception('Failed to move: $uri');
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<SafDocumentFile> copyTo(
      String uri, bool isDir, String newParentUri) async {
    final map = await methodChannel.invokeMapMethod<String, dynamic>(
      'copyTo',
      {'uri': uri, 'isDir': isDir, 'newParentUri': newParentUri},
    );
    if (map == null) {
      throw Exception('Failed to copy: $uri');
    }
    return SafDocumentFile.fromMap(map);
  }

  @override
  Future<bool> saveThumbnailToFile({
    required String uri,
    required int width,
    required int height,
    required String destPath,
    String? format,
    int? quality,
  }) async {
    final res = await methodChannel.invokeMethod<bool>(
      'saveThumbnailToFile',
      {
        'uri': uri.toString(),
        'width': width,
        'height': height,
        'destPath': destPath,
        'format': format,
        'quality': quality,
      },
    );
    return res ?? false;
  }

  @override
  Future<int> getFileDescriptor(String uri) async {
    final res = await methodChannel.invokeMethod<int>(
      'getFileDescriptor',
      {'uri': uri},
    );
    if (res == null) {
      throw Exception('Failed to get file descriptor: $uri');
    }
    return res;
  }

  @override
  Future<void> closeFileDescriptor(int fd) {
    return methodChannel.invokeMethod<void>(
      'closeFileDescriptor',
      {'fd': fd},
    );
  }

  @override
  Future<bool> hasPersistedPermission(
    String uri, {
    bool checkRead = true,
    bool checkWrite = false,
  }) async {
    final res = await methodChannel.invokeMethod<bool>(
      'hasPersistedPermission',
      {
        'uri': uri,
        'checkRead': checkRead,
        'checkWrite': checkWrite,
      },
    );
    if (res == null) {
      throw Exception('Failed to check persisted permission: $uri');
    }
    return res;
  }

  @override
  Future<void> releasePersistedPermission(String uri,
      {bool read = true, bool write = false}) async {
    await methodChannel.invokeMethod<void>(
      'releasePersistedPermission',
      {
        'uri': uri,
        'read': read,
        'write': write,
      },
    );
  }
}
