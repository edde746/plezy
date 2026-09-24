import '../mpv/models.dart';

/// Whether a track id is safe to put on the wire.
///
/// Embedded mpv tracks carry plain ids (`1`, `2`, `no`, `auto`), but
/// [SubtitleTrack.uri] builds `external:<url>`, and those URLs embed the media
/// server's credentials (`X-Plex-Token`, Jellyfin's `api_key`). Any id that
/// looks like a URI is withheld; the track is selected by position instead.
bool isSafeTrackId(String id) => !id.startsWith('external:') && !id.contains('://');

/// [id] when it is safe to transmit, otherwise null. See [isSafeTrackId].
String? safeTrackId(String? id) => id != null && isSafeTrackId(id) ? id : null;

/// Position of [selectedId] within [ids], or null when it is not present.
///
/// The index is the credential-free way to identify a track: it is always
/// available and it round-trips through the `{index}` selection criteria.
int? indexOfTrackId(Iterable<String> ids, String? selectedId) {
  if (selectedId == null) return null;
  final index = ids.toList().indexOf(selectedId);
  return index < 0 ? null : index;
}

/// Wire serialisation of the player's audio tracks for the `syncState` frame.
///
/// Kept pure so the shape a controller depends on can be unit-tested without a
/// running player. Absent fields are omitted rather than sent as nulls, keeping
/// the frame small on the ~5s broadcast.
List<Map<String, dynamic>> audioTracksPayload(List<AudioTrack> tracks) => [
  for (final track in tracks)
    {
      'id': ?safeTrackId(track.id),
      if (track.title != null) 'title': track.title,
      if (track.language != null) 'language': track.language,
      if (track.codec != null) 'codec': track.codec,
      // Lets a controller tell '5.1' from '2.0' without parsing the title.
      if (track.channels != null) 'channels': track.channels,
    },
];

/// See [audioTracksPayload]. `uri` is never included, and `id` is withheld for
/// external tracks because it embeds that same credentialed URL.
List<Map<String, dynamic>> subtitleTracksPayload(List<SubtitleTrack> tracks) => [
  for (final track in tracks)
    {
      'id': ?safeTrackId(track.id),
      if (track.title != null) 'title': track.title,
      if (track.language != null) 'language': track.language,
      if (track.codec != null) 'codec': track.codec,
      'external': track.isExternal,
    },
];
