import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

abstract interface class FilePickerDelegate {
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  });

  Future<String?> getDirectoryPath({String? dialogTitle});

  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    Uint8List? bytes,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  });
}

class _PluginFilePickerDelegate implements FilePickerDelegate {
  const _PluginFilePickerDelegate();

  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) {
    return FilePicker.pickFiles(type: type, allowedExtensions: allowedExtensions, withData: withData);
  }

  @override
  Future<String?> getDirectoryPath({String? dialogTitle}) {
    return FilePicker.getDirectoryPath(dialogTitle: dialogTitle);
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    Uint8List? bytes,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) {
    return FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
      type: type,
      allowedExtensions: allowedExtensions,
    );
  }
}

/// Serializes file_picker invocations to avoid
/// `PlatformException(already_active, File picker is already active)`.
class FilePickerService {
  static final FilePickerService _instance = FilePickerService._();
  static FilePickerService get instance => _instance;
  FilePickerService._();

  FilePickerDelegate _delegate = const _PluginFilePickerDelegate();
  bool _active = false;

  @visibleForTesting
  static void setDelegateForTesting(FilePickerDelegate? delegate) {
    _instance
      .._delegate = delegate ?? const _PluginFilePickerDelegate()
      .._active = false;
  }

  Future<T?> _guard<T>(String opName, Future<T?> Function() body) async {
    if (_active) return null;
    _active = true;
    try {
      return await body();
    } on PlatformException catch (e, st) {
      if (e.code == 'already_active') return null;
      appLogger.e('FilePicker.$opName failed', error: e, stackTrace: st);
      rethrow;
    } finally {
      _active = false;
    }
  }

  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool withData = false,
  }) {
    return _guard(
      'pickFiles',
      () => _delegate.pickFiles(type: type, allowedExtensions: allowedExtensions, withData: withData),
    );
  }

  Future<String?> getDirectoryPath({String? dialogTitle}) {
    return _guard('getDirectoryPath', () => _delegate.getDirectoryPath(dialogTitle: dialogTitle));
  }

  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    Uint8List? bytes,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) {
    return _guard(
      'saveFile',
      () => _delegate.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
        type: type,
        allowedExtensions: allowedExtensions,
      ),
    );
  }
}
