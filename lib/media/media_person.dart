import '../utils/global_key_utils.dart';
import 'ids.dart';
import 'media_backend.dart';

/// The credit a person search hit matched on. Plex people search answers only
/// actors and directors; MediaBrowser `/Persons` rows do not name one.
enum PersonCredit { actor, director }

/// A person found by [MediaServerClient.searchPeople].
///
/// Not a media item: a person cannot be played, downloaded, rated, or marked
/// watched, and opens a filmography rather than a detail screen.
class MediaPerson {
  /// Backend person id — the value [MediaServerClient.fetchPersonMediaPage]
  /// takes: a Plex tag id, a MediaBrowser `Person` item id.
  final String id;
  final String name;

  /// Absolute URL (Plex `metadata-static.plex.tv`, MediaBrowser `api_key`
  /// URLs) or a server-relative path, resolved through this person's server
  /// client. Null when the server has no image.
  final String? thumbPath;

  /// Null when the backend does not say which credit matched.
  final PersonCredit? credit;
  final MediaBackend backend;
  final ServerId serverId;
  final String? serverName;

  const MediaPerson({
    required this.id,
    required this.name,
    this.thumbPath,
    this.credit,
    required this.backend,
    required this.serverId,
    this.serverName,
  });

  /// Cross-server identity. The `person:` prefix keeps it apart from a media
  /// item's [MediaItem.globalKey]: a Plex tag id and a rating key share one
  /// numeric space.
  String get globalKey => buildGlobalKey(serverId, 'person:$id');
}
