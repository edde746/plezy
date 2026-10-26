import 'source_models.dart';

enum PublicationShelf { ebooks, audiobooks, comics }

extension PublicationShelfContents on PublicationShelf {
  bool includes(SourceEntry entry) => switch (this) {
    PublicationShelf.ebooks => entry.ebooks.any((f) => f.kind == SourceItemKind.ebook),
    PublicationShelf.audiobooks => entry.kind == SourceItemKind.audiobook,
    PublicationShelf.comics => entry.ebooks.any((f) => f.kind == SourceItemKind.comic),
  };
}
