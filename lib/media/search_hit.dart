import 'media_item.dart';
import 'media_person.dart';

/// One row of the ranked search results: a title or a person.
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
