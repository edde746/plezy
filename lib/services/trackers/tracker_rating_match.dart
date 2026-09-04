import '../../media/media_kind.dart';
import '../../utils/json_utils.dart';
import 'tracker.dart';
import 'tracker_id_resolver.dart';

/// Shared rating helpers for the Trakt/MDBList/Simkl rating sources, which
/// all scan a list of remote rating entries and match them against local ids.
/// Trakt and MDBList additionally share the same `/sync/ratings` list names and
/// request body shape.

/// The `/sync/ratings/<type>` list name for [ctx]'s kind, or unavailable for
/// kinds neither service rates.
String trackerRatingType(TrackerRatingContext ctx, String service) => switch (ctx.kind) {
  MediaKind.movie => 'movies',
  MediaKind.show => 'shows',
  MediaKind.season => 'seasons',
  MediaKind.episode => 'episodes',
  _ => throw TrackerRatingUnavailableException(service),
};

/// True when a `/sync/ratings` [entry] refers to the local item described by
/// [ctx] and [localIds]. Season and episode rows may carry their parent show
/// inline (`season.show` / `episode.show`) rather than as a sibling `show`
/// key; the inline form wins when present.
bool trackerRatingEntryMatches(TrackerRatingContext ctx, Map<String, dynamic> entry, Map<String, Object?> localIds) {
  final show = entry['show'];
  final movie = entry['movie'];
  return switch (ctx.kind) {
    MediaKind.movie => trackerIdsMatch(trackerNestedIds(movie), localIds),
    MediaKind.show => trackerIdsMatch(trackerNestedIds(show), localIds),
    MediaKind.season =>
      trackerIdsMatch(trackerNestedIds(_nestedShow(entry['season']) ?? show), localIds) &&
          _numberMatches(entry['season'], ctx.season),
    MediaKind.episode =>
      trackerIdsMatch(trackerNestedIds(_nestedShow(entry['episode']) ?? show), localIds) &&
          _numberMatches(entry['episode'], ctx.episodeNumber) &&
          _seasonMatches(entry['episode'], ctx.season),
    _ => false,
  };
}

Object? _nestedShow(Object? value) => value is Map ? value['show'] : null;

bool _numberMatches(Object? value, int? expected) {
  if (expected == null || value is! Map) return false;
  return flexibleInt(value['number']) == expected;
}

bool _seasonMatches(Object? value, int? expected) {
  if (expected == null || value is! Map) return false;
  return flexibleInt(value['season']) == expected;
}

/// `/sync/ratings` add/remove body for [ctx] keyed by [ids]. Omit [rating] for
/// a removal body.
Map<String, dynamic> trackerRatingBody(
  TrackerRatingContext ctx,
  Map<String, Object?> ids,
  String service, {
  int? rating,
}) {
  final item = {'ids': ids, 'rating': ?rating};

  return switch (ctx.kind) {
    MediaKind.movie => {
      'movies': [item],
    },
    MediaKind.show => {
      'shows': [item],
    },
    MediaKind.season => {
      'shows': [
        {
          'ids': ids,
          'seasons': [
            {'number': ctx.season, 'rating': ?rating},
          ],
        },
      ],
    },
    MediaKind.episode => {
      'shows': [
        {
          'ids': ids,
          'seasons': [
            {
              'number': ctx.season,
              'episodes': [
                {'number': ctx.episodeNumber, 'rating': ?rating},
              ],
            },
          ],
        },
      ],
    },
    _ => throw TrackerRatingUnavailableException(service),
  };
}

/// Extract the nested `ids` map from a rating entry's media object (e.g. the
/// `movie`/`show` node), normalized to `Map<String, dynamic>`.
Map<String, dynamic>? trackerNestedIds(Object? value) {
  if (value is! Map) return null;
  final ids = value['ids'];
  return ids is Map ? ids.cast<String, dynamic>() : null;
}

/// True when any local id matches a remote id by string or integer value.
bool trackerIdsMatch(Map<String, dynamic>? remoteIds, Map<String, Object?> localIds) {
  if (remoteIds == null) return false;
  for (final entry in localIds.entries) {
    final local = entry.value;
    if (local == null) continue;
    final remote = remoteIds[entry.key];
    if (remote == null) continue;
    if (local is String && remote.toString() == local) return true;
    final remoteInt = flexibleInt(remote);
    final localInt = flexibleInt(local);
    if (remoteInt != null && localInt != null && remoteInt == localInt) return true;
  }
  return false;
}
