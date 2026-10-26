import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/publication_library.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  const folder = SourceEntry(sourceId: 'library', id: 'folder', title: 'Folder', kind: SourceItemKind.folder);
  const finished = SourceEntry(sourceId: 'library', id: 'finished', title: 'Finished', kind: SourceItemKind.audiobook);
  const current = SourceEntry(sourceId: 'library', id: 'current', title: 'Current', kind: SourceItemKind.audiobook);
  const newBook = SourceEntry(sourceId: 'library', id: 'new', title: 'New', kind: SourceItemKind.audiobook);
  const authorA = SourceEntry(
    sourceId: 'library',
    id: 'author-a',
    title: 'Zebra',
    author: 'Ada',
    kind: SourceItemKind.audiobook,
  );
  const authorB = SourceEntry(
    sourceId: 'library',
    id: 'author-b',
    title: 'Alpha',
    author: 'Bea',
    kind: SourceItemKind.audiobook,
  );
  final progress = [
    PublicationProgress(
      entryKey: finished.key,
      edition: 'audio',
      mode: PublicationMode.listening,
      session: 'done',
      positionMs: 10000,
      fraction: 1,
      finished: true,
      updatedAt: 20,
    ),
    PublicationProgress(
      entryKey: current.key,
      edition: 'audio',
      mode: PublicationMode.listening,
      session: 'current',
      positionMs: 5000,
      fraction: .5,
      updatedAt: 30,
    ),
    PublicationProgress(
      entryKey: current.key,
      edition: 'ebook',
      mode: PublicationMode.reading,
      session: 'read',
      positionMs: 100,
      updatedAt: 100,
    ),
  ];

  test('status filtering keeps folders and evaluates listening progress independently', () {
    final entries = [finished, current, newBook, folder];
    expect(
      organizePublications(
        entries,
        progress,
        status: PublicationStatus.unstarted,
        mode: PublicationMode.listening,
      ).map((e) => e.id),
      ['folder', 'new'],
    );
    expect(
      organizePublications(
        entries,
        progress,
        status: PublicationStatus.inProgress,
        mode: PublicationMode.listening,
      ).map((e) => e.id),
      ['folder', 'current'],
    );
    expect(
      organizePublications(
        entries,
        progress,
        status: PublicationStatus.finished,
        mode: PublicationMode.listening,
      ).map((e) => e.id),
      ['folder', 'finished'],
    );
  });

  test('sorts by requested bibliographic field with stable title fallback', () {
    expect(organizePublications([authorB, authorA], [], sort: PublicationSort.author).map((e) => e.id), [
      'author-a',
      'author-b',
    ]);
  });

  test('recent sort uses the latest progress across modes', () {
    expect(organizePublications([current, finished], progress, sort: PublicationSort.recent).map((e) => e.id), [
      'current',
      'finished',
    ]);
  });
}
