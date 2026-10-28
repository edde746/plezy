import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/content_access.dart';
import 'package:plezy/sources/offline_readiness.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

class DownloadSource extends SourceAdapter {
  DownloadSource(SourceTransport transport)
    : super(const FileSource(id: 'source', profileId: 'p', kind: FileSourceKind.webdav, name: 'Files'), transport);
  @override
  SourceCapabilities get capabilities => const SourceCapabilities();
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async => const SourcePage([]);
  @override
  Future<ContentLease> resolve(PublicationFile file) async =>
      ContentLease(Uri.parse('https://files.example/book'), size: 6);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(const MethodChannel('disk_usage'), (call) async {
      expect(call.method, 'getDiskSpace');
      expect(call.arguments['type'], 'free');
      return 1024 * 1024 * 1024;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(const MethodChannel('disk_usage'), null));
  late Directory directory;
  late SourceDatabase database;
  late PublicationDownloads downloads;
  late SourceRepository repository;
  const file = PublicationFile(
    id: 'book',
    name: 'book.epub',
    mimeType: 'application/epub+zip',
    size: 6,
    revision: 'v1',
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('plezy-download-test');
    database = SourceDatabase(NativeDatabase.memory());
    repository = SourceRepository(database);
    downloads = PublicationDownloads(repository, directory);
  });
  tearDown(() async {
    downloads.cancelAll();
    await database.close();
    await directory.delete(recursive: true);
  });
  test('offline verification rejects deleted, truncated and replaced downloads', () async {
    final source = DownloadSource(SourceTransport(client: MockClient((_) async => http.Response('abcdef', 200))));
    addTearDown(source.close);
    const entry = SourceEntry(sourceId: 'source', id: 'book', title: 'Book', kind: SourceItemKind.ebook, files: [file]);
    final local = await downloads.download('p', source, file);
    expect(await downloads.verifiedFiles('p', [entry, entry]), {offlineFileIdentity('source', file)});
    expect(await downloads.verifiedFiles('other', [entry]), isEmpty);
    await local.writeAsString('abc');
    expect(await downloads.verifiedFiles('p', [entry]), isEmpty);
    await local.writeAsString('abcdef');
    const replacement = PublicationFile(
      id: 'book',
      name: 'book.epub',
      mimeType: 'application/epub+zip',
      size: 6,
      revision: 'v2',
    );
    const updated = SourceEntry(
      sourceId: 'source',
      id: 'book',
      title: 'Book',
      kind: SourceItemKind.ebook,
      files: [replacement],
    );
    expect(await downloads.verifiedFiles('p', [updated]), isEmpty);
    await local.delete();
    expect(await downloads.verifiedFiles('p', [entry]), isEmpty);
  });

  test('immediate cancellation cannot start a late transfer or publish a file', () async {
    var requested = false;
    final source = DownloadSource(
      SourceTransport(
        client: MockClient((_) async {
          requested = true;
          return http.Response('abcdef', 200);
        }),
      ),
    );
    final transfer = downloads.download('p', source, file);
    downloads.cancelAll();
    await expectLater(
      transfer,
      throwsA(isA<SourceException>().having((e) => e.reason, 'reason', SourceFailure.cancelled)),
    );
    expect(requested, isFalse);
    expect(await downloads.local('p', 'source', file), isNull);
    expect(await directory.list(recursive: true).toList(), isEmpty);
    source.close();
  });
  for (final scenario in ['resume', 'restart', 'conflicting-range', 'no-validator']) {
    test('download $scenario never combines different representations', () async {
      var calls = 0;
      final source = DownloadSource(
        SourceTransport(
          client: MockClient((request) async {
            calls++;
            if (calls == 1) return http.Response('abc', 200, headers: {if (scenario != 'no-validator') 'etag': '"v1"'});
            expect(request.headers['Range'], scenario == 'no-validator' ? isNull : 'bytes=3-');
            if (scenario != 'no-validator') expect(request.headers['If-Range'], '"v1"');
            return switch (scenario) {
              'restart' || 'no-validator' => http.Response('uvwxyz', 200, headers: {'etag': '"v2"'}),
              'conflicting-range' => http.Response(
                'xyz',
                206,
                headers: {'etag': '"v2"', 'content-range': 'bytes 3-5/6'},
              ),
              _ => http.Response('def', 206, headers: {'etag': '"v1"', 'content-range': 'bytes 3-5/6'}),
            };
          }),
        ),
      );
      await expectLater(downloads.download('p', source, file), throwsA(isA<SourceException>()));
      expect(await downloads.local('p', 'source', file), isNull);
      if (scenario == 'conflicting-range') {
        await expectLater(downloads.download('p', source, file), throwsA(isA<SourceException>()));
        expect(await downloads.local('p', 'source', file), isNull);
      } else {
        final complete = await downloads.download('p', source, file);
        expect(await complete.readAsString(), scenario == 'resume' ? 'abcdef' : 'uvwxyz');
        expect(await downloads.local('other-profile', 'source', file), isNull);
      }
      source.close();
    });
  }
}
