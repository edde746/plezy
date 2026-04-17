import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/// Serializes file_picker invocations to avoid
/// `PlatformException(already_active, File picker is already active)`.
class FilePickerService {
  static final FilePickerService _instance = FilePickerService._();
  static FilePickerService get instance => _instance;
  FilePickerService._();

  bool _active = false;

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
    return _guard('pickFiles', () => FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
      withData: withData,
    ));
  }

  Future<String?> getDirectoryPath({String? dialogTitle}) {
    return _guard('getDirectoryPath', () => FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
    ));
  }
}
