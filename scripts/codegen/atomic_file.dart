/// Atomic file write shared by the codegen scripts.
library;

import 'dart:io';

typedef AtomicFileWriter = Future<void> Function(String path, String contents);

Future<void> writeFileAtomically(String path, String contents) async {
  final output = File(path);
  await output.parent.create(recursive: true);
  final temporary = File('$path.tmp.$pid.${DateTime.now().microsecondsSinceEpoch}');
  try {
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(path);
  } finally {
    if (await temporary.exists()) {
      await temporary.delete();
    }
  }
}
