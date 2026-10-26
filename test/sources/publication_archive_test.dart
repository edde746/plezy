import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/publication_archive.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('plezy-publication-test-');
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });
  Future<File> zip(Map<String, String> entries) async {
    final archive = Archive();
    for (final e in entries.entries) {
      archive.add(ArchiveFile.bytes(e.key, utf8.encode(e.value)));
    }
    final bytes = ZipEncoder().encode(archive);
    // The encoder normalizes backslashes; put a malformed name into both ZIP headers.
    for (final name in entries.keys.where((n) => n.contains('\\'))) {
      final normalized = utf8.encode(name.replaceAll('\\', '/'));
      final raw = utf8.encode(name);
      for (var i = 0; i <= bytes.length - raw.length; i++) {
        if (List.generate(raw.length, (j) => bytes[i + j] == normalized[j]).every((same) => same)) {
          bytes.setRange(i, i + raw.length, raw);
        }
      }
    }
    return File('${temporary.path}/book.epub').writeAsBytes(bytes);
  }

  test('valid EPUB extracts and session cleanup removes only its folder', () async {
    final file = await zip({
      'META-INF/container.xml': '<container/>',
      'EPUB/chapter.xhtml': '<html><body>Hello</body></html>',
    });
    final archive = await PublicationArchive.open(file, temporary);
    expect(archive.files.keys, contains('EPUB/chapter.xhtml'));
    expect(await File('${archive.directory.path}/EPUB/chapter.xhtml').readAsString(), contains('Hello'));
    await archive.close();
    expect(await archive.directory.exists(), isFalse);
    expect(await file.exists(), isTrue);
  });
  test('archive traversal and absolute paths are rejected before extraction', () async {
    for (final name in ['../escape', '/absolute', 'folder/../../escape', 'folder\\escape', 'C:/escape']) {
      final file = await zip({'META-INF/container.xml': '<container/>', name: 'payload'});
      await expectLater(PublicationArchive.open(file, temporary), throwsA(isA<SourceException>()));
    }
  });
  test('zip without an EPUB container is not accepted as an ebook', () async {
    await expectLater(
      PublicationArchive.open(await zip({'a.txt': 'not an EPUB'}), temporary),
      throwsA(isA<SourceException>()),
    );
  });
  test('DRM encryption is rejected; font obfuscation remains supported', () async {
    for (final algorithm in ['http://www.idpf.org/2008/embedding', 'http://ns.adobe.com/pdf/enc#RC']) {
      final file = await zip({
        'META-INF/container.xml': '<container/>',
        'META-INF/encryption.xml': '<encryption><EncryptionMethod Algorithm="$algorithm"/></encryption>',
      });
      final archive = await PublicationArchive.open(file, temporary);
      await archive.close();
    }
    final file = await zip({
      'META-INF/container.xml': '<container/>',
      'META-INF/encryption.xml':
          '<encryption><EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc"/></encryption>',
    });
    await expectLater(PublicationArchive.open(file, temporary), throwsA(isA<SourceException>()));
  });
}
