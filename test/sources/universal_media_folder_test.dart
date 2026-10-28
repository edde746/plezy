import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/universal_media_folder.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plezy-media-folder-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('finds supported nested media in stable relative-path order', () async {
    final nested = Directory(p.join(root.path, 'disc 2'))..createSync();
    final hidden = Directory(p.join(root.path, '.private'))..createSync();
    File(p.join(root.path, 'zeta.mkv')).writeAsBytesSync([1]);
    File(p.join(root.path, 'disc.iso')).writeAsBytesSync([7]);
    File(p.join(nested.path, '01.m4b')).writeAsBytesSync([2]);
    File(p.join(nested.path, '02.mp3')).writeAsBytesSync([3]);
    File(p.join(root.path, 'notes.txt')).writeAsBytesSync([4]);
    File(p.join(root.path, '.hidden.mp4')).writeAsBytesSync([5]);
    File(p.join(hidden.path, 'hidden.mkv')).writeAsBytesSync([6]);

    final files = await const UniversalMediaFolderScanner().scan(root);

    expect(files.map((file) => p.relative(file.path, from: root.path)).toList(), [
      'disc 2/01.m4b',
      'disc 2/02.mp3',
      'disc.iso',
      'zeta.mkv',
    ]);
  });

  test('never follows symbolic links', () async {
    final outside = await Directory.systemTemp.createTemp('plezy-media-outside-');
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    File(p.join(outside.path, 'private.mp4')).writeAsBytesSync([1]);
    final link = Link(p.join(root.path, 'linked'));
    try {
      await link.create(outside.path);
    } on FileSystemException {
      markTestSkipped('Symbolic links are unavailable in this environment');
    }
    File(p.join(root.path, 'local.mp4')).writeAsBytesSync([2]);

    final files = await const UniversalMediaFolderScanner().scan(root);

    expect(files.map((file) => p.basename(file.path)), ['local.mp4']);
  });

  test('rejects empty or unsupported folders', () async {
    File(p.join(root.path, 'readme.txt')).writeAsBytesSync([1]);

    await expectLater(
      const UniversalMediaFolderScanner().scan(root),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.unsupported)),
    );
  });

  test('stops when the entry bound is exceeded instead of returning a partial queue', () async {
    File(p.join(root.path, 'one.mp4')).writeAsBytesSync([1]);
    File(p.join(root.path, 'two.mp4')).writeAsBytesSync([2]);
    File(p.join(root.path, 'three.mp4')).writeAsBytesSync([3]);

    await expectLater(
      const UniversalMediaFolderScanner(maxEntries: 2).scan(root),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.invalidData)),
    );
  });

  test('rejects a folder deeper than the traversal bound', () async {
    final deep = Directory(p.join(root.path, 'one', 'two', 'three'))..createSync(recursive: true);
    File(p.join(deep.path, 'movie.mp4')).writeAsBytesSync([1]);

    await expectLater(
      const UniversalMediaFolderScanner(maxDepth: 1).scan(root),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.invalidData)),
    );
  });
}
