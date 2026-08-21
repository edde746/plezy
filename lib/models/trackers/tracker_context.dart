import '../../utils/external_ids.dart';
import 'anime_ids.dart';

/// Immutable per-playback context passed from the coordinator to each
/// tracker. Built once at `startPlayback`.
///
/// Carries both Plex external IDs (tvdb/tmdb/imdb, always present when the
/// item has any GUIDs) and Fribb-derived anime IDs (null when the item isn't
/// in the Fribb mapping). General-purpose trackers (Simkl) prefer Plex IDs;
/// anime-only trackers (MAL, AniList) no-op when [anime] is null.
class TrackerContext {
  final ExternalIds external;
  final AnimeIds? anime;

  final bool isMovie;
  final int? season;
  final int? episodeNumber;
  final int? animeProgress;

  /// Plex ratingKey of the item being played. Used only for logging — not
  /// sent to any tracker.
  final String ratingKey;

  /// Library globalKey the item belongs to, or null when the metadata didn't
  /// carry library info.
  final String? libraryGlobalKey;

  const TrackerContext._({
    required this.external,
    required this.anime,
    required this.isMovie,
    required this.ratingKey,
    required this.libraryGlobalKey,
    this.season,
    this.episodeNumber,
    this.animeProgress,
  });

  factory TrackerContext.movie({
    required ExternalIds external,
    required AnimeIds? anime,
    required String ratingKey,
    required String? libraryGlobalKey,
  }) {
    return TrackerContext._(
      external: external,
      anime: anime,
      isMovie: true,
      ratingKey: ratingKey,
      libraryGlobalKey: libraryGlobalKey,
    );
  }

  factory TrackerContext.episode({
    required ExternalIds external,
    required AnimeIds? anime,
    required String ratingKey,
    required String? libraryGlobalKey,
    required int season,
    required int episodeNumber,
    int? animeProgress,
  }) {
    return TrackerContext._(
      external: external,
      anime: anime,
      isMovie: false,
      ratingKey: ratingKey,
      libraryGlobalKey: libraryGlobalKey,
      season: season,
      episodeNumber: episodeNumber,
      animeProgress: animeProgress,
    );
  }

  /// Serialized into the persisted tracker write queue so a failed watched
  /// write replays against exactly the item it was built for — no second
  /// metadata fetch, no re-resolution against a library that may have changed.
  Map<String, Object?> toJson() => {
    'external': external.toJson(),
    if (anime != null) 'anime': anime!.toJson(),
    'isMovie': isMovie,
    'ratingKey': ratingKey,
    if (libraryGlobalKey != null) 'libraryGlobalKey': libraryGlobalKey,
    if (season != null) 'season': season,
    if (episodeNumber != null) 'episodeNumber': episodeNumber,
    if (animeProgress != null) 'animeProgress': animeProgress,
  };

  /// Throws on a malformed row; the queue archives and discards the batch.
  factory TrackerContext.fromJson(Map<String, Object?> json) {
    final anime = json['anime'];
    return TrackerContext._(
      external: ExternalIds.fromJson((json['external'] as Map).cast<String, Object?>()),
      anime: anime == null ? null : AnimeIds.fromJson((anime as Map).cast<String, Object?>()),
      isMovie: json['isMovie'] as bool,
      ratingKey: json['ratingKey'] as String,
      libraryGlobalKey: json['libraryGlobalKey'] as String?,
      season: (json['season'] as num?)?.toInt(),
      episodeNumber: (json['episodeNumber'] as num?)?.toInt(),
      animeProgress: (json['animeProgress'] as num?)?.toInt(),
    );
  }
}
