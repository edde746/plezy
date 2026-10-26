import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/comic_document.dart';

void main() {
  test('natural ordering excludes archive housekeeping and preserves image case', () {
    final doc = ComicDocument.fromFiles(['10.JPG', '2.png', '__MACOSX/1.png', '.hidden.png', '1.webp']);
    expect(doc.pages.map((p) => p.name), ['1.webp', '2.png', '10.JPG']);
  });
  test('ComicInfo supplies direction, bookmarks and spread dimensions', () {
    final doc = ComicDocument.fromFiles(
      ['1.png'],
      comicInfo:
          '<ComicInfo><Manga>YesAndRightToLeft</Manga><Title>Example</Title><Pages><Page Image="0" Bookmark="Start" DoublePage="true" ImageWidth="1600" ImageHeight="1000"/></Pages></ComicInfo>',
    );
    expect(doc.direction, 'rtl');
    expect(doc.metadata['Title'], 'Example');
    expect(doc.pages.single.bookmark, 'Start');
    expect(doc.pages.single.doublePage, isTrue);
    expect(doc.pages.single.width, 1600);
  });
  test('broken and entity-bearing metadata fall back to readable pages', () {
    for (final xml in ['<broken', '<!DOCTYPE x [<!ENTITY x "secret">]><ComicInfo><Title>&x;</Title></ComicInfo>']) {
      final doc = ComicDocument.fromFiles(['1.png'], comicInfo: xml);
      expect(doc.pages, hasLength(1));
      expect(doc.metadata, isEmpty);
    }
  });
}
