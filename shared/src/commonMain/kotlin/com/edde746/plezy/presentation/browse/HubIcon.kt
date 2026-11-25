package com.edde746.plezy.presentation.browse

/**
 * A hub row's leading icon, named after its Material Symbol (rounded, filled), as [of] picks it from the hub's title;
 * an Explore shelf names its own ([BOOKMARK], [EVENT_UPCOMING] are only theirs).
 */
enum class HubIcon {
    PLAY_CIRCLE, TRENDING_UP, WHATSHOT, CALENDAR_MONTH, NEW_RELEASES, SCHEDULE, STAR, MILITARY_TECH, WARNING_AMBER, MOOD,
    FLASH_ON, THEATER_COMEDY, AUTO_FIX_HIGH, ROCKET_LAUNCH, NIGHTS_STAY, FAVORITE_BORDER, EXPLORE, PLAYLIST_PLAY,
    VISIBILITY_OFF, VISIBILITY, TV, PERSON, HISTORY, PLAY_ARROW, THUMB_UP, CATEGORY, AUTO_AWESOME, BOOKMARK, EVENT_UPCOMING;

    companion object {
        /**
         * Continue Watching (by the hub, or a title naming it or Plex's On Deck) has the play circle; any other hub the
         * icon of the first keyword its title holds, the specific ones before the broad, else the sparkle.
         */
        fun of(title: String, continueWatching: Boolean): HubIcon {
            val lower = title.lowercase()
            if (continueWatching || "continue watching" in lower || "on deck" in lower) return PLAY_CIRCLE
            return KEYWORDS.firstOrNull { (words, _) -> words.any { it in lower } }?.second ?: AUTO_AWESOME
        }

        private val KEYWORDS: List<Pair<List<String>, HubIcon>> = listOf(
            listOf("trending") to TRENDING_UP,
            listOf("popular", "imdb") to WHATSHOT,
            listOf("seasonal") to CALENDAR_MONTH,
            listOf("newly", "new release") to NEW_RELEASES,
            listOf("recently released", "recent") to SCHEDULE,
            listOf("top rated", "highest rated") to STAR,
            listOf("top ") to MILITARY_TECH,
            listOf("thriller") to WARNING_AMBER,
            listOf("comedy", "comedier") to MOOD,
            listOf("action") to FLASH_ON,
            listOf("drama") to THEATER_COMEDY,
            listOf("fantasy") to AUTO_FIX_HIGH,
            listOf("science", "sci-fi") to ROCKET_LAUNCH,
            listOf("horror", "skräck") to NIGHTS_STAY,
            listOf("romance", "romantic") to FAVORITE_BORDER,
            listOf("adventure", "äventyr") to EXPLORE,
            listOf("playlist", "watchlist") to PLAYLIST_PLAY,
            listOf("unwatched", "unplayed") to VISIBILITY_OFF,
            listOf("watched", "played") to VISIBILITY,
            listOf("network", "more from") to TV,
            listOf("actor", "director") to PERSON,
            listOf("80", "90", "00") to HISTORY,
            listOf("rediscover", "start watching") to PLAY_ARROW,
            listOf("rated") to STAR,
            listOf("recommended") to THUMB_UP,
            listOf("genre") to CATEGORY,
        )
    }
}
