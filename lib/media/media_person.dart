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

/// What a server can say about a person beyond their name and photo, from
/// [MediaServerClient.fetchPersonDetails]. Any field may be missing; a person
/// nobody describes is [empty].
class MediaPersonDetails {
  final String? biography;

  /// Calendar days at UTC midnight. These dates have no time of day, so
  /// reading one through a local time zone would move it to another day.
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;

  const MediaPersonDetails({this.biography, this.birthDate, this.deathDate, this.birthPlace});

  static const empty = MediaPersonDetails();

  bool get isEmpty => biography == null && birthDate == null && deathDate == null && birthPlace == null;

  /// Completed years from [birthDate] to [deathDate], or to [today] while the
  /// person is alive. Null without a birth date or when the dates contradict.
  int? ageOn(DateTime today) {
    final birth = birthDate;
    if (birth == null) return null;
    final end = deathDate ?? DateTime.utc(today.year, today.month, today.day);
    var years = end.year - birth.year;
    if (end.month < birth.month || (end.month == birth.month && end.day < birth.day)) years--;
    return years >= 0 ? years : null;
  }

  /// The calendar day a wire date names: Plex sends `1992-03-13`,
  /// MediaBrowser `1992-03-13T00:00:00.0000000Z`. Only the date part counts,
  /// as for MediaBrowser premiere dates.
  static DateTime? parseDate(Object? value) {
    if (value is! String || value.length < 10) return null;
    final date = DateTime.tryParse(value.substring(0, 10));
    return date == null ? null : DateTime.utc(date.year, date.month, date.day);
  }
}
