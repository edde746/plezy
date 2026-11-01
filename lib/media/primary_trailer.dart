import 'package:collection/collection.dart';

import 'media_item.dart';

/// The trailer among the [extras] of [parent]: Plex's own pick
/// (`primaryExtraKey`) when it is among them, otherwise the first extra
/// classified as a trailer. Null when none is.
MediaItem? primaryTrailer(MediaItem parent, List<MediaItem> extras) {
  if (parent case PlexMediaItem(:final trailerKey?)) {
    // "/library/metadata/52601" -> "52601"
    final primaryKey = trailerKey.split('/').last;
    if (extras.firstWhereOrNull((extra) => extra.id == primaryKey) case final trailer?) return trailer;
  }
  return extras.firstWhereOrNull(_isTrailerExtra);
}

bool _isTrailerExtra(MediaItem extra) {
  if (extra case PlexMediaItem(:final subtype?)) {
    return subtype.toLowerCase() == 'trailer';
  }
  final raw = extra.raw;
  final extraType = raw?['ExtraType'] as String?;
  final type = raw?['Type'] as String?;
  return extraType?.toLowerCase() == 'trailer' || type?.toLowerCase() == 'trailer';
}
