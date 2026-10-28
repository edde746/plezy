import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/offline_readiness.dart';
import 'package:plezy/sources/source_models.dart';

void main() {
  const book = PublicationFile(id: 'text', name: 'book.epub', mimeType: 'application/epub+zip');
  const first = PublicationFile(id: 'one', name: 'one.mp3', mimeType: 'audio/mpeg', revision: '1');
  const second = PublicationFile(id: 'two', name: 'two.mp3', mimeType: 'audio/mpeg');
  const audio = SourceEntry(
    sourceId: 's',
    id: 'b',
    title: 'Book',
    kind: SourceItemKind.audiobook,
    files: [first, second],
  );

  test('one downloaded chapter never promises a complete offline audiobook', () {
    final partial = PublicationOfflineReadiness.evaluate(audio, {offlineFileIdentity('s', first)});
    expect(partial.isReady, isFalse);
    expect(partial.isPartial, isTrue);
    expect(partial.availableFiles, 1);
    final complete = PublicationOfflineReadiness.evaluate(audio, {
      offlineFileIdentity('s', first),
      offlineFileIdentity('s', second),
    });
    expect(complete.canListen, isTrue);
    expect(complete.isReady, isTrue);
  });

  test('one complete reading edition is usable independently of the audiobook', () {
    const mixed = SourceEntry(
      sourceId: 's',
      id: 'b',
      title: 'Book',
      kind: SourceItemKind.ebook,
      files: [book, first, second],
    );
    final ready = PublicationOfflineReadiness.evaluate(mixed, {offlineFileIdentity('s', book)});
    expect(ready.isReady, isTrue);
    expect(ready.canListen, isFalse);
    expect(ready.readableEditions, {book.fingerprint});
  });

  test('other sources and old revisions cannot satisfy offline availability', () {
    const old = PublicationFile(id: 'one', name: 'one.mp3', mimeType: 'audio/mpeg', revision: '0');
    final ready = PublicationOfflineReadiness.evaluate(audio, {
      offlineFileIdentity('s', old),
      offlineFileIdentity('other', first),
      offlineFileIdentity('s', second),
    });
    expect(ready.canListen, isFalse);
    expect(ready.availableFiles, 1);
  });

  test('empty and folder entries never become ready through vacuous completeness', () {
    for (final kind in SourceItemKind.values) {
      final entry = SourceEntry(sourceId: 's', id: 'empty', title: 'Empty', kind: kind);
      expect(PublicationOfflineReadiness.evaluate(entry, {}).isReady, isFalse);
    }
  });
}
