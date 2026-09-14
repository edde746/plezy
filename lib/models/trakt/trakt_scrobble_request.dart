import 'package:freezed_annotation/freezed_annotation.dart';

import 'trakt_ids.dart';

part 'trakt_scrobble_request.freezed.dart';

/// Body for `POST /scrobble/{start|pause|stop}` and `POST /sync/history`.
///
/// Either movie IDs or show IDs + season/episode are set, never both.
/// [progress] is the percent (0–100) for scrobble; ignored for `/sync/history`.
@freezed
sealed class TraktScrobbleRequest with _$TraktScrobbleRequest {
  const TraktScrobbleRequest._();

  /// Build a movie scrobble payload.
  const factory TraktScrobbleRequest.movie({required TraktIds ids, double? progress}) = TraktScrobbleMovieRequest;

  /// Build an episode scrobble payload using the show's external IDs plus
  /// season/episode index. Trakt prefers this shape over an episode-IDs-only
  /// payload because it works even when the episode itself isn't in Trakt's
  /// catalog yet.
  const factory TraktScrobbleRequest.episode({
    required TraktIds showIds,
    required int season,
    required int number,
    double? progress,
  }) = TraktScrobbleEpisodeRequest;

  bool get isMovie => this is TraktScrobbleMovieRequest;
  bool get isEpisode => this is TraktScrobbleEpisodeRequest;

  Map<String, dynamic> toJson() => switch (this) {
    TraktScrobbleMovieRequest(:final ids, :final progress) => {
      'movie': {'ids': ids.toJson()},
      'progress': ?progress,
    },
    TraktScrobbleEpisodeRequest(:final showIds, :final season, :final number, :final progress) => {
      'show': {'ids': showIds.toJson()},
      'episode': {'season': season, 'number': number},
      'progress': ?progress,
    },
  };

  /// Build a `POST /sync/history[/remove]` body for this item. Both endpoints
  /// take the same shape; only the removal path ignores [watchedAt].
  ///
  /// Optional [watchedAt] (ISO-8601 UTC) lets the server attribute the play
  /// to a specific point in time; defaults to "now" on Trakt's side.
  Map<String, dynamic> toHistoryBody({String? watchedAt}) => switch (this) {
    TraktScrobbleMovieRequest(:final ids) => {
      'movies': [
        {'watched_at': ?watchedAt, 'ids': ids.toJson()},
      ],
    },
    TraktScrobbleEpisodeRequest(:final showIds, :final season, :final number) => {
      'shows': [
        {
          'ids': showIds.toJson(),
          'seasons': [
            {
              'number': season,
              'episodes': [
                {'watched_at': ?watchedAt, 'number': number},
              ],
            },
          ],
        },
      ],
    },
  };
}
