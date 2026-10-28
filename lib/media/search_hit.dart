import '../sources/source_models.dart';

import 'media_item.dart';
import 'media_person.dart';

/// One row of the ranked search results: a server title, indexed file or person.
sealed class SearchHit {
  const SearchHit();

  /// Cross-server identity, unique across both kinds of hit.
  String get globalKey;
}

final class MediaSearchHit extends SearchHit {
  final MediaItem item;

  const MediaSearchHit(this.item);

  @override
  String get globalKey => item.globalKey;
}

final class PersonSearchHit extends SearchHit {
  final MediaPerson person;

  const PersonSearchHit(this.person);

  @override
  String get globalKey => person.globalKey;
}

/// An indexed publication retains its source identity, edition and native
/// open path. It is never disguised as a server item or merged by title.
final class SourceSearchHit extends SearchHit {
  final SourceEntry entry;

  const SourceSearchHit(this.entry);

  @override
  String get globalKey => 'source:${entry.key}';
}
