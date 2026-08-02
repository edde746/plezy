/// Resolves the brand badge and written label shown beside a score, keyed by
/// the attributed source name every backend mapper normalizes to.
library;

import '../i18n/strings.g.dart';

class RatingInfo {
  final String assetPath;
  final String formattedValue;

  const RatingInfo(this.assetPath, this.formattedValue);
}

/// The brand badge for an attributed source key.
///
/// Rotten Tomatoes picks fresh/rotten and upright/spilled by the 60% threshold
/// the tomatometer itself uses — the same state Plex encodes in
/// `image.rating.ripe` / `.rotten` and Jellyfin's own web client applies to
/// `CriticRating`.
///
/// Returns null for keys with no brand badge (`critic`, `audience`, `simkl`,
/// `mal`, `anilist`, `trakt`); those stay labelled with their source name.
RatingInfo? ratingInfoForSource(String source, double value) => switch (source) {
  'imdb' => RatingInfo(_imdbAsset, value.toStringAsFixed(1)),
  'tmdb' => RatingInfo(_tmdbAsset, _percent(value)),
  'rottenTomatoes' ||
  'rottenTomatoesCritic' => RatingInfo(value >= _rottenTomatoesFresh ? _rtFreshAsset : _rtRottenAsset, _percent(value)),
  'rottenTomatoesAudience' => RatingInfo(
    value >= _rottenTomatoesFresh ? _rtUprightAsset : _rtSpilledAsset,
    _percent(value),
  ),
  _ => null,
};

/// Localized name for an attributed source key, or null when the key is
/// unknown and the score should be dropped rather than labelled raw.
String? ratingSourceLabel(String source) => switch (source) {
  'critic' => t.common.ratingSource.critic,
  'audience' => t.common.ratingSource.audience,
  'imdb' => t.common.ratingSource.imdb,
  'tmdb' => t.common.ratingSource.tmdb,
  'rottenTomatoes' => t.common.ratingSource.rottenTomatoes,
  // Plex splits Rotten Tomatoes into its two panels, so both the provenance
  // and the critic/audience distinction survive.
  'rottenTomatoesCritic' => t.common.ratingSource.rottenTomatoesCritic,
  'rottenTomatoesAudience' => t.common.ratingSource.rottenTomatoesAudience,
  'simkl' => t.common.ratingSource.simkl,
  'mal' => t.common.ratingSource.mal,
  'anilist' => t.common.ratingSource.anilist,
  'trakt' => t.common.ratingSource.trakt,
  _ => null,
};

const String _imdbAsset = 'assets/rating_icons/imdb.svg';
const String _tmdbAsset = 'assets/rating_icons/tmdb.svg';
const String _rtFreshAsset = 'assets/rating_icons/rt_fresh.svg';
const String _rtRottenAsset = 'assets/rating_icons/rt_rotten.svg';
const String _rtUprightAsset = 'assets/rating_icons/rt_upright.svg';
const String _rtSpilledAsset = 'assets/rating_icons/rt_spilled.svg';

/// Ratings are normalized to a 0-10 scale; Rotten Tomatoes is a percentage.
const double _rottenTomatoesFresh = 6.0;

String _percent(double value) => '${(value * 10).toStringAsFixed(0)}%';
