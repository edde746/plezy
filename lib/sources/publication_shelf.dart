import 'source_models.dart';

enum PublicationShelf { ebooks, audiobooks, music, comics, videos }

Set<PublicationShelf> defaultPublicationShelves(FileSourceKind kind) => {
  if (kind == FileSourceKind.openSubsonic || kind == FileSourceKind.podcastRss) PublicationShelf.music,
  if (kind != FileSourceKind.openSubsonic && kind != FileSourceKind.podcastRss) ...{
    PublicationShelf.ebooks,
    PublicationShelf.audiobooks,
  },
  if (kind == FileSourceKind.komga) PublicationShelf.comics,
  if (kind == FileSourceKind.local || kind == FileSourceKind.smb || kind == FileSourceKind.remoteCloud)
    PublicationShelf.videos,
};

extension PublicationShelfContents on PublicationShelf {
  bool includes(SourceEntry entry) => switch (this) {
    PublicationShelf.ebooks => entry.ebooks.any((f) => f.kind == SourceItemKind.ebook),
    PublicationShelf.audiobooks => entry.kind == SourceItemKind.audiobook,
    PublicationShelf.music => entry.kind == SourceItemKind.music,
    PublicationShelf.comics =>
      entry.kind == SourceItemKind.comic || entry.ebooks.any((f) => f.kind == SourceItemKind.comic),
    PublicationShelf.videos => entry.kind == SourceItemKind.video,
  };
}
