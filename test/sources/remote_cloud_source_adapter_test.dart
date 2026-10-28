import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/remote_streams/remote_stream_models.dart';
import 'package:plezy/sources/adapters/remote_cloud_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  const source = FileSource(
    id: 'remote-cloud:account-1',
    profileId: 'profile-1',
    kind: FileSourceKind.remoteCloud,
    name: 'Viewer',
    endpoint: 'remote-cloud://torbox/account-1',
    options: {'accountId': 'account-1', 'service': 'torbox'},
  );

  RemoteCloudItem folder() => const RemoteCloudItem(
    id: 'tb:42',
    name: 'Film pack',
    service: RemoteStreamService.torbox,
    kind: RemoteCloudItemKind.folder,
    providerId: '42',
    accountId: 'account-1',
  );

  RemoteCloudItem video({String id = 'tb:42:7', String name = 'Film.mkv'}) => RemoteCloudItem(
    id: id,
    name: name,
    service: RemoteStreamService.torbox,
    kind: RemoteCloudItemKind.file,
    size: 700,
    mimeType: 'application/octet-stream',
    providerId: '42',
    providerFileId: '7',
    uri: Uri.https('cdn.example', 'signed/Film.mkv', {'token': 'secret'}),
    accountId: 'account-1',
  );

  RemoteCloudSourceAdapter adapter({
    required RemoteCloudPage Function({String? parentId, String? cursor}) page,
    Future<ContentLease> Function(RemoteCloudItem item)? resolve,
  }) => RemoteCloudSourceAdapter(
    source,
    SourceTransport(),
    service: RemoteStreamService.torbox,
    accountId: 'account-1',
    loadPage: ({parentId, cursor}) async => page(parentId: parentId, cursor: cursor),
    resolveContent: resolve ?? (item) async => ContentLease(item.uri!, size: item.size),
  );

  test('projects only video files, retains folders and keeps signed URLs transient', () async {
    final sourceAdapter = adapter(
      page: ({parentId, cursor}) => RemoteCloudPage(
        items: [
          folder(),
          video(),
          video(id: 'tb:42:8', name: 'notes.txt'),
          const RemoteCloudItem(
            id: 'tb:other:1',
            name: 'Other.mkv',
            service: RemoteStreamService.torbox,
            kind: RemoteCloudItemKind.file,
            accountId: 'another-account',
          ),
        ],
        nextCursor: '100',
      ),
    );
    addTearDown(sourceAdapter.close);

    final page = await sourceAdapter.browse();

    expect(page.entries.map((entry) => entry.id), ['tb:42', 'tb:42:7']);
    expect(page.entries.first.kind, SourceItemKind.folder);
    expect(page.entries.last.kind, SourceItemKind.video);
    expect(page.entries.last.files.single.streamOnly, isTrue);
    expect(page.entries.last.identifiers['remoteCloudProviderId'], '42');
    expect(page.next, '100');
    expect(page.entries.last.toJson().toString(), isNot(contains('signed/Film.mkv')));
    expect(page.entries.last.toJson().toString(), isNot(contains('token=secret')));
  });

  test('folder navigation maps the cached folder to its provider id', () async {
    final requestedParents = <String?>[];
    final sourceAdapter = adapter(
      page: ({parentId, cursor}) {
        requestedParents.add(parentId);
        return RemoteCloudPage(items: parentId == null ? [folder()] : [video()]);
      },
    );
    addTearDown(sourceAdapter.close);

    await sourceAdapter.browse();
    final childPage = await sourceAdapter.browse(parent: 'tb:42');

    expect(requestedParents, [null, '42']);
    expect(childPage.entries.single.parentId, 'tb:42');
    expect(childPage.entries.single.id, 'tb:42:7');
  });

  test('hydration refreshes a nested file link after a new adapter is created', () async {
    final requestedParents = <String?>[];
    final sourceAdapter = adapter(
      page: ({parentId, cursor}) {
        requestedParents.add(parentId);
        return RemoteCloudPage(items: parentId == '42' ? [video()] : const []);
      },
    );
    addTearDown(sourceAdapter.close);
    final cached = SourceEntry(
      sourceId: source.id,
      id: 'tb:42:7',
      title: 'Film.mkv',
      kind: SourceItemKind.video,
      parentId: 'tb:42',
      identifiers: const {'remoteCloudParentProviderId': '42'},
      files: const [PublicationFile(id: 'tb:42:7', name: 'Film.mkv', mimeType: 'video/x-matroska', streamOnly: true)],
    );

    final fresh = await sourceAdapter.hydrate(cached);
    final lease = await sourceAdapter.resolve(fresh.files.single);

    expect(requestedParents, ['42']);
    expect(lease.uri, Uri.https('cdn.example', 'signed/Film.mkv', {'token': 'secret'}));
    expect(lease.canPersistForBackgroundTransfer, isFalse);
  });

  test('refuses to browse a folder that is not owned by this account page', () async {
    final sourceAdapter = adapter(page: ({parentId, cursor}) => const RemoteCloudPage(items: []));
    addTearDown(sourceAdapter.close);

    await expectLater(sourceAdapter.browse(parent: 'tb:foreign'), throwsA(isA<SourceException>()));
  });
}
