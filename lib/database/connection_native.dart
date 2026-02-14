/// Native database connection implementation.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    final Directory dbFolder;
    if (Platform.isAndroid || Platform.isIOS) {
      dbFolder = await getApplicationDocumentsDirectory();
    } else {
      dbFolder = await getApplicationSupportDirectory();
    }

    final file = File(p.join(dbFolder.path, 'plezy_downloads.db'));

    // Ensure directory exists
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Migrate from old location on desktop (was in Documents subfolder)
    if (!Platform.isAndroid && !Platform.isIOS && !await file.exists()) {
      final oldFolder = await getApplicationDocumentsDirectory();
      final oldFile = File(p.join(oldFolder.path, 'plezy_downloads.db'));
      if (await oldFile.exists()) {
        await oldFile.rename(file.path);
      }
    }

    return NativeDatabase(file);
  });
}
