import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/adapters/smb_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';
import 'package:plezy/sources/video_nfo.dart';

void main() {
  group('SMB source endpoint validation', () {
    test('accepts a single share on the default SMB port', () {
      expect(validateSmbSourceEndpoint('smb://nas.example/Media').host, 'nas.example');
      expect(validateSmbSourceEndpoint('smb://192.168.1.5:445/Movies').port, 445);
    });

    test('rejects credentials, non-SMB schemes, unsafe paths, and custom ports', () {
      for (final endpoint in [
        'smb://user:password@nas.example/Media',
        'https://nas.example/Media',
        'smb://nas.example:139/Media',
        'smb://nas.example/Media/Movies',
        'smb://nas.example/../Media',
        'smb://nas.example/Media/../private',
        'smb://nas.example/Media/%2e%2e/private',
        'smb://nas.example/Media?token=secret',
        'smb://nas.example/Media#fragment',
      ]) {
        expect(
          () => validateSmbSourceEndpoint(endpoint),
          throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
          reason: endpoint,
        );
      }
    });

    test('rejects traversal before requesting credentials or opening a connection', () async {
      var credentialRequests = 0;
      final adapter = SmbSourceAdapter(
        const FileSource(
          id: 'nas',
          profileId: 'profile',
          kind: FileSourceKind.smb,
          name: 'NAS',
          endpoint: 'smb://nas.example/Media',
          root: 'Movies',
        ),
        SourceTransport(),
        () async {
          credentialRequests++;
          return const {};
        },
      );

      await expectLater(
        adapter.openContent(
          const PublicationFile(id: 'Movies/../private.mkv', name: 'private.mkv', mimeType: 'video/x-matroska'),
          offset: 0,
          length: 1,
        ),
        throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
      );
      expect(credentialRequests, 0);
      adapter.close();
    });
  });

  group('offline video NFO metadata', () {
    test('applies title, summary, year, rating, genres, and supported IDs', () {
      final metadata = parseVideoNfo('''
        <movie>
          <title>The Example</title>
          <plot>A local summary.</plot>
          <premiered>2024-05-17</premiered>
          <ratings><rating default="true"><value>8.4</value></rating></ratings>
          <genre>Drama</genre><genre>Science Fiction</genre><genre>Drama</genre>
          <uniqueid type="tmdb">12345</uniqueid>
          <uniqueid type="imdb">tt0123456</uniqueid>
          <uniqueid type="custom">ignored</uniqueid>
          <url>https://tracker.example/title</url>
        </movie>
      ''');

      expect(metadata, isNotNull);
      const entry = SourceEntry(
        sourceId: 'nas',
        id: 'Movies/example.mkv',
        title: 'example.mkv',
        kind: SourceItemKind.video,
        identifiers: {'existing': 'kept'},
      );
      final hydrated = metadata!.applyTo(entry);
      expect(hydrated.title, 'The Example');
      expect(hydrated.description, 'A local summary.');
      expect(hydrated.releaseYear, 2024);
      expect(hydrated.rating, 8.4);
      expect(hydrated.genres, ['Drama', 'Science Fiction']);
      expect(hydrated.identifiers, {'existing': 'kept', 'tmdb': '12345', 'imdb': 'tt0123456'});
    });

    test('ignores malformed, oversized, and metadata-free NFO documents', () {
      expect(parseVideoNfo('<movie><title>unfinished'), isNull);
      expect(parseVideoNfo('<movie><url>https://tracker.example/title</url></movie>'), isNull);
      expect(parseVideoNfo(' ' * (1024 * 1024 + 1)), isNull);
    });
  });
}
