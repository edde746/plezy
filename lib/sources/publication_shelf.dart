import 'source_models.dart';

enum PublicationShelf { ebooks, audiobooks, comics, videos }

Set<PublicationShelf> defaultPublicationShelves(FileSourceKind kind) => {
  PublicationShelf.ebooks,
  PublicationShelf.audiobooks,
  if (kind == FileSourceKind.komga) PublicationShelf.comics,
  if (kind == FileSourceKind.local || kind == FileSourceKind.smb || kind == FileSourceKind.remoteCloud)
    PublicationShelf.videos,
};

extension PublicationShelfContents on PublicationShelf {
  bool includes(SourceEntry entry) => switch (this) {
    PublicationShelf.ebooks => entry.ebooks.any((f) => f.kind == SourceItemKind.ebook),
    PublicationShelf.audiobooks => entry.kind == SourceItemKind.audiobook,
    PublicationShelf.comics =>
      entry.kind == SourceItemKind.comic || entry.ebooks.any((f) => f.kind == SourceItemKind.comic),
    PublicationShelf.videos => entry.kind == SourceItemKind.video,
  };
}
