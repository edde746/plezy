import '../../utils/plex_external_ids.dart';
import 'anime_ids.dart';

/// Immutable per-playback context passed from the coordinator to each
/// tracker. Built once at `startPlayback`.
///
/// Carries both Plex external IDs (tvdb/tmdb/imdb, always present when the
/// item has any GUIDs) and Fribb-derived anime IDs (null when the item isn't
/// in the Fribb mapping). General-purpose trackers (Simkl) prefer Plex IDs;
/// anime-only trackers (MAL, AniList) no-op when [anime] is null.
class TrackerContext {
  final PlexExternalIds external;
  final AnimeIds? anime;

  final bool isMovie;
  final int? season;
  final int? episodeNumber;

  /// Plex ratingKey of the item being played. Used only for logging — not
  /// sent to any tracker.
  final String ratingKey;

  const TrackerContext._({
    required this.external,
    required this.anime,
    required this.isMovie,
    required this.ratingKey,
    this.season,
    this.episodeNumber,
  });

  factory TrackerContext.movie({
    required PlexExternalIds external,
    required AnimeIds? anime,
    required String ratingKey,
  }) {
    return TrackerContext._(external: external, anime: anime, isMovie: true, ratingKey: ratingKey);
  }

  factory TrackerContext.episode({
    required PlexExternalIds external,
    required AnimeIds? anime,
    required String ratingKey,
    required int season,
    required int episodeNumber,
  }) {
    return TrackerContext._(
      external: external,
      anime: anime,
      isMovie: false,
      ratingKey: ratingKey,
      season: season,
      episodeNumber: episodeNumber,
    );
  }
}
