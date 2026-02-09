/// Parses Plex ratingImage / audienceRatingImage URIs and returns
/// the corresponding local asset path and a display-formatted value.
library;

class RatingInfo {
  final String assetPath;
  final String formattedValue;

  const RatingInfo(this.assetPath, this.formattedValue);
}

/// Parse a ratingImage URI (e.g. "rottentomatoes://image.rating.ripe")
/// together with the numeric rating value into a [RatingInfo].
///
/// Returns null if the URI is unrecognised.
RatingInfo? parseRatingImage(String? imageUri, double? value) {
  if (imageUri == null || value == null) return null;

  // Rotten Tomatoes critic ratings
  if (imageUri.startsWith('rottentomatoes://image.rating.')) {
    final suffix = imageUri.substring('rottentomatoes://image.rating.'.length);
    final percent = '${(value * 10).toStringAsFixed(0)}%';
    return switch (suffix) {
      'ripe' => RatingInfo('assets/rating_icons/rt_fresh.svg', percent),
      'rotten' => RatingInfo('assets/rating_icons/rt_rotten.svg', percent),
      'upright' => RatingInfo('assets/rating_icons/rt_upright.svg', percent),
      'spilled' => RatingInfo('assets/rating_icons/rt_spilled.svg', percent),
      _ => null,
    };
  }

  // IMDb
  if (imageUri.startsWith('imdb://')) {
    return RatingInfo('assets/rating_icons/imdb.svg', value.toStringAsFixed(1));
  }

  // TMDB
  if (imageUri.startsWith('themoviedb://')) {
    return RatingInfo('assets/rating_icons/tmdb.svg', '${(value * 10).toStringAsFixed(0)}%');
  }

  return null;
}

/// Whether the URI is a Rotten Tomatoes rating source.
bool isRottenTomatoes(String? imageUri) => imageUri != null && imageUri.startsWith('rottentomatoes://');
