import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/comic_document.dart';
import 'package:plezy/sources/publication_archive.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // Exercise the real loopback capability server.
  late Directory temporary;
  late HttpClient browser;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('comic-stream-test-');
    browser = HttpClient()..maxConnectionsPerHost = 16;
  });
  tearDown(() async {
    browser.close(force: true);
    await temporary.delete(recursive: true);
  });
  ComicPageSource pages(SourceTransport transport, {int count = 12}) => ComicPageSource(
    document: ComicDocument([for (var i = 0; i < count; i++) ComicPage('page$i.jpg')]),
    transport: transport,
    resolve: (i) async =>
        ContentLease(Uri.parse('https://server.example/pages/$i'), headers: {'Authorization': 'Bearer secret'}),
  );
  Future<(int, List<int>)> get(Uri uri) async {
    final response = await (await browser.getUrl(uri)).close();
    final bytes = await response.fold<List<int>>([], (bytes, part) => bytes..addAll(part));
    return (response.statusCode, bytes);
  }

  test('thumbnail bursts queue, cap upstream concurrency and never expose credentials', () async {
    var active = 0, peak = 0;
    final transport = SourceTransport(
      client: MockClient.streaming((request, _) async {
        expect(request.headers['Authorization'], 'Bearer secret');
        active++;
        peak = max(peak, active);
        Stream<List<int>> body() async* {
          try {
            await Future<void>.delayed(const Duration(milliseconds: 15));
            yield [255, 216, 255, 217];
          } finally {
            active--;
          }
        }

        return http.StreamedResponse(body(), 200, headers: {'content-type': 'image/jpeg'});
      }),
    );
    final server = PublicationServer(await PublicationArchive.stream(pages(transport), temporary), valid: () => true);
    await server.start();
    try {
      final results = await Future.wait([for (var i = 0; i < 12; i++) get(server.origin.resolve('book/page$i.jpg'))]);
      expect(results.map((r) => r.$1), everyElement(200));
      expect(results.map((r) => r.$2.length), everyElement(4));
      expect(peak, 3);
      final manifest = utf8.decode((await get(server.origin.resolve('manifest'))).$2);
      expect(manifest, isNot(contains('secret')));
      expect(manifest, isNot(contains('server.example')));
    } finally {
      await server.close();
      transport.close();
    }
  });

  test('upstream HTML and oversized images cannot become reader pages', () async {
    for (final headers in [
      {'content-type': 'text/html'},
      {'content-type': 'image/jpeg', 'content-length': '${33 * 1024 * 1024}'},
    ]) {
      final transport = SourceTransport(
        client: MockClient.streaming(
          (_, _) async => http.StreamedResponse(
            Stream.value([1, 2]),
            200,
            headers: headers,
            contentLength: int.tryParse(headers['content-length'] ?? ''),
          ),
        ),
      );
      final server = PublicationServer(await PublicationArchive.stream(pages(transport), temporary), valid: () => true);
      await server.start();
      try {
        final result = await get(server.origin.resolve('book/page0.jpg'));
        expect(result.$1, 400);
        expect(result.$2, isEmpty);
      } finally {
        await server.close();
        transport.close();
      }
    }
  });

  test('profile invalidation during resolution prevents a remote request', () async {
    var valid = true, calls = 0;
    final resolving = Completer<void>(), release = Completer<void>();
    final transport = SourceTransport(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    final source = ComicPageSource(
      document: ComicDocument([const ComicPage('page.jpg')]),
      transport: transport,
      resolve: (_) async {
        resolving.complete();
        await release.future;
        return ContentLease(Uri.parse('https://server.example/page'));
      },
    );
    final server = PublicationServer(await PublicationArchive.stream(source, temporary), valid: () => valid);
    await server.start();
    try {
      final response = get(server.origin.resolve('book/page.jpg'));
      await resolving.future;
      valid = false;
      release.complete();
      expect((await response).$1, 403);
      expect(calls, 0);
    } finally {
      await server.close();
      transport.close();
    }
  });

  test('closing the reader aborts an active page transfer', () async {
    final started = Completer<void>(), cancelled = Completer<void>();
    final transport = SourceTransport(
      client: MockClient.streaming((request, _) async {
        final abortable = request as http.AbortableRequest;
        started.complete();
        await abortable.abortTrigger;
        cancelled.complete();
        throw http.RequestAbortedException(request.url);
      }),
    );
    final server = PublicationServer(await PublicationArchive.stream(pages(transport), temporary), valid: () => true);
    await server.start();
    final response = get(
      server.origin.resolve('book/page0.jpg'),
    ).then<Object>((r) => r, onError: (Object error) => error);
    await started.future;
    await server.close();
    await cancelled.future.timeout(const Duration(seconds: 2));
    await response;
    transport.close();
  });

  test('stream manifests reject duplicate names and unsafe paths before allocation', () async {
    final transport = SourceTransport();
    for (final names in [
      ['page.jpg', 'page.jpg'],
      ['../escape.jpg'],
      ['/absolute.jpg'],
    ]) {
      final source = ComicPageSource(
        document: ComicDocument(names.map(ComicPage.new).toList()),
        transport: transport,
        resolve: (_) async => throw StateError('unused'),
      );
      await expectLater(PublicationArchive.stream(source, temporary), throwsA(isA<SourceException>()));
      expect(await temporary.list().toList(), isEmpty);
    }
    transport.close();
  });
}
