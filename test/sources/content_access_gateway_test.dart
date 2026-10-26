import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/content_access.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

class _GatewayAdapter extends SourceAdapter {
  _GatewayAdapter(SourceTransport transport, this._bytes)
    : super(
        const FileSource(id: 'gateway', profileId: 'profile', kind: FileSourceKind.local, name: 'Local file'),
        transport,
      );

  final List<int> _bytes;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async => const SourcePage([]);

  @override
  Future<ContentLease> resolve(PublicationFile file) async => throw StateError('Direct bytes are expected.');

  @override
  Future<int?> contentSize(PublicationFile file) async => _bytes.length;

  @override
  Future<SourceByteStream?> openContent(PublicationFile file, {required int offset, required int length}) async {
    final end = (offset + length).clamp(0, _bytes.length).toInt();
    return SourceByteStream(
      stream: Stream.value(_bytes.sublist(offset, end)),
      size: _bytes.length,
      offset: offset,
      length: end - offset,
    );
  }
}

void main() {
  test('loopback gateway serves and validates byte ranges', () async {
    final adapter = _GatewayAdapter(SourceTransport(), 'abcdef'.codeUnits);
    final gateway = SourceStreamGateway(valid: () => true);
    final client = HttpClient();
    addTearDown(() async {
      client.close(force: true);
      await gateway.close();
      adapter.close();
    });
    const file = PublicationFile(id: 'video', name: 'video.mp4', mimeType: 'video/mp4', size: 6);
    final uri = await gateway.register(adapter, file);

    final rangedRequest = await client.getUrl(uri);
    rangedRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=1-3');
    final rangedResponse = await rangedRequest.close();
    expect(rangedResponse.statusCode, HttpStatus.partialContent);
    expect(rangedResponse.headers.value(HttpHeaders.contentRangeHeader), 'bytes 1-3/6');
    expect(await rangedResponse.fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk)), 'bcd'.codeUnits);

    final invalidRequest = await client.getUrl(uri);
    invalidRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=9-');
    final invalidResponse = await invalidRequest.close();
    expect(invalidResponse.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(invalidResponse.headers.value(HttpHeaders.contentRangeHeader), 'bytes */6');
    await invalidResponse.drain<void>();
  });
}
