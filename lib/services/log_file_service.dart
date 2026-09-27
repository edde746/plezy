import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../i18n/strings.g.dart';
import '../utils/formatters.dart';
import '../utils/platform_detector.dart';
import 'file_picker_service.dart';

typedef LogFileSaver = Future<String?> Function(Uint8List bytes, String fileName);

const String logFileExtension = 'log';

String logFileName(DateTime time) {
  final date = '${padNumber(time.year, 4)}${padNumber(time.month, 2)}${padNumber(time.day, 2)}';
  final clock = '${padNumber(time.hour, 2)}${padNumber(time.minute, 2)}${padNumber(time.second, 2)}';
  return 'plezy-logs-$date-$clock.$logFileExtension';
}

Future<String?> saveLogFile(Uint8List bytes, String fileName) async {
  if (Platform.isAndroid && PlatformDetector.isTV()) {
    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
  return FilePickerService.instance.saveFile(
    dialogTitle: t.logs.saveLogs,
    fileName: fileName,
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: const [logFileExtension],
  );
}
