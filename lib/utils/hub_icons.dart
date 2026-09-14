import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_hub.dart';

/// Leading icon for a hub row, shared by every surface that renders hubs from
/// the same backend rows (Discover and a library's Recommended tab).
///
/// Continue Watching is matched on the hub key first so synthesized rows and
/// section-specific `*.inprogress.*` hubs are covered, then on title for
/// backends whose resume row is only recognizable by name (Plex "On Deck").
/// Everything else is keyword-matched on the title; the first match wins, so
/// the more specific keywords are checked before the broader ones.
IconData hubIconFor(MediaHub hub) {
  final title = hub.title.toLowerCase();

  if (hub.isContinueWatchingHub || title.contains('continue watching') || title.contains('on deck')) {
    return Symbols.play_circle_rounded;
  }
  for (final (keywords, icon) in _titleKeywordIcons) {
    if (keywords.any(title.contains)) return icon;
  }
  return _defaultHubIcon;
}

const _defaultHubIcon = Symbols.auto_awesome_rounded;

/// Title keywords in match order — see [hubIconFor].
const _titleKeywordIcons = <(List<String>, IconData)>[
  // Trending/Popular
  (['trending'], Symbols.trending_up_rounded),
  (['popular', 'imdb'], Symbols.whatshot_rounded),
  // Seasonal/Time-based
  (['seasonal'], Symbols.calendar_month_rounded),
  (['newly', 'new release'], Symbols.new_releases_rounded),
  (['recently released', 'recent'], Symbols.schedule_rounded),
  // Top/Rated
  (['top rated', 'highest rated'], Symbols.star_rounded),
  (['top '], Symbols.military_tech_rounded),
  // Genre-specific
  (['thriller'], Symbols.warning_amber_rounded),
  (['comedy', 'comedier'], Symbols.mood_rounded),
  (['action'], Symbols.flash_on_rounded),
  (['drama'], Symbols.theater_comedy_rounded),
  (['fantasy'], Symbols.auto_fix_high_rounded),
  (['science', 'sci-fi'], Symbols.rocket_launch_rounded),
  (['horror', 'skräck'], Symbols.nights_stay_rounded),
  (['romance', 'romantic'], Symbols.favorite_border_rounded),
  (['adventure', 'äventyr'], Symbols.explore_rounded),
  // Watchlist/Playlists
  (['playlist', 'watchlist'], Symbols.playlist_play_rounded),
  (['unwatched', 'unplayed'], Symbols.visibility_off_rounded),
  (['watched', 'played'], Symbols.visibility_rounded),
  // Network/Studio
  (['network', 'more from'], Symbols.tv_rounded),
  // Actor/Director
  (['actor', 'director'], Symbols.person_rounded),
  // Decades (80s, 90s, etc.)
  (['80', '90', '00'], Symbols.history_rounded),
  // Rediscover/Start Watching
  (['rediscover', 'start watching'], Symbols.play_arrow_rounded),
  // Broad library-hub keywords, last so the specific rows above keep their icons.
  (['rated'], Symbols.star_rounded),
  (['recommended'], Symbols.thumb_up_rounded),
  (['genre'], Symbols.category_rounded),
];
