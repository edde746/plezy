import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/adapters/ftp_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  test('FTP rejects URL credentials and unsupported endpoint shapes before connecting', () async {
    for (final endpoint in [
      'ftp://user:password@nas.example/Media',
      'ftp://nas.example/Media?token=secret',
      'ftp://nas.example/Media#fragment',
      'https://nas.example/Media',
    ]) {
      var credentialRequests = 0;
      final adapter = FtpSourceAdapter(
        FileSource(id: 'ftp', profileId: 'profile', kind: FileSourceKind.ftp, name: 'FTP', endpoint: endpoint),
        SourceTransport(),
        () async {
          credentialRequests++;
          return const {};
        },
      );

      await expectLater(
        adapter.browse(),
        throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
        reason: endpoint,
      );
      expect(credentialRequests, 0, reason: endpoint);
      adapter.close();
    }
  });

  test('FTP rejects path traversal before requesting credentials', () async {
    var credentialRequests = 0;
    final adapter = FtpSourceAdapter(
      const FileSource(
        id: 'ftp',
        profileId: 'profile',
        kind: FileSourceKind.ftp,
        name: 'FTP',
        endpoint: 'ftps://nas.example:990',
        root: '/Media',
      ),
      SourceTransport(),
      () async {
        credentialRequests++;
        return const {};
      },
    );

    await expectLater(
      adapter.browse(parent: '/Media/../private'),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
    );
    expect(credentialRequests, 0);
    adapter.close();
  });
}
