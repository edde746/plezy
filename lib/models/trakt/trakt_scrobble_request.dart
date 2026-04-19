import 'trakt_ids.dart';

/// Body for `POST /scrobble/{start|pause|stop}` and `POST /sync/history`.
///
/// Either movie IDs or show IDs + season/episode are set, never both.
/// [progress] is the percent (0–100) for scrobble; ignored for `/sync/history`.
class TraktScrobbleRequest {
  final TraktIds? _movieIds;
  final TraktIds? _showIds;
  final int? _season;
  final int? _episode;
  final double? progress;

  const TraktScrobbleRequest._({TraktIds? movieIds, TraktIds? showIds, int? season, int? episode, this.progress})
    : _movieIds = movieIds,
      _showIds = showIds,
      _season = season,
      _episode = episode;

  bool get isMovie => _movieIds != null;
  bool get isEpisode => _showIds != null;

  TraktScrobbleRequest copyWith({double? progress}) => TraktScrobbleRequest._(
    movieIds: _movieIds,
    showIds: _showIds,
    season: _season,
    episode: _episode,
    progress: progress ?? this.progress,
  );

  /// Build a movie scrobble payload.
  factory TraktScrobbleRequest.movie({required TraktIds ids, double? progress}) {
    return TraktScrobbleRequest._(movieIds: ids, progress: progress);
  }

  /// Build an episode scrobble payload using the show's external IDs plus
  /// season/episode index. Trakt prefers this shape over an episode-IDs-only
  /// payload because it works even when the episode itself isn't in Trakt's
  /// catalog yet.
  factory TraktScrobbleRequest.episode({
    required TraktIds showIds,
    required int season,
    required int number,
    double? progress,
  }) {
    return TraktScrobbleRequest._(showIds: showIds, season: season, episode: number, progress: progress);
  }

  Map<String, dynamic> toJson() => {
    if (_movieIds != null) 'movie': {'ids': _movieIds.toJson()},
    if (_showIds != null) 'show': {'ids': _showIds.toJson()},
    if (_season != null && _episode != null) 'episode': {'season': _season, 'number': _episode},
    'progress': ?progress,
  };

  /// Build a `POST /sync/history` body that adds this item to history.
  ///
  /// Optional [watchedAt] (ISO-8601 UTC) lets the server attribute the play
  /// to a specific point in time; defaults to "now" on Trakt's side.
  Map<String, dynamic> toHistoryAddBody({String? watchedAt}) {
    if (isMovie) {
      return {
        'movies': [
          {'watched_at': ?watchedAt, 'ids': _movieIds!.toJson()},
        ],
      };
    }
    return {
      'shows': [
        {
          'ids': _showIds!.toJson(),
          'seasons': [
            {
              'number': _season,
              'episodes': [
                {'watched_at': ?watchedAt, 'number': _episode},
              ],
            },
          ],
        },
      ],
    };
  }

  /// Build a `POST /sync/history/remove` body that removes this item from history.
  Map<String, dynamic> toHistoryRemoveBody() {
    if (isMovie) {
      return {
        'movies': [
          {'ids': _movieIds!.toJson()},
        ],
      };
    }
    return {
      'shows': [
        {
          'ids': _showIds!.toJson(),
          'seasons': [
            {
              'number': _season,
              'episodes': [
                {'number': _episode},
              ],
            },
          ],
        },
      ],
    };
  }
}
