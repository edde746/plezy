package com.edde746.plezy.plex

import com.edde746.plezy.model.MediaItem
import kotlinx.serialization.json.JsonObject

/** Plex `flattenSeasons` values: always list seasons, never list them, hide the list of a single season. */
private const val FLATTEN_SEASONS_SHOW = 0
private const val FLATTEN_SEASONS_HIDE = 1
private const val FLATTEN_SEASONS_SINGLE_SEASON = 2

/**
 * Whether a show's page lists its episodes instead of its seasons. The show's own `flattenSeasons` (1 yes, 0 no) wins,
 * then its `skipChildren`; else the library's [libraryPrefs] `flattenSeasons` (1, or 2 with exactly one season), and a
 * show without seasons always lists episodes.
 */
fun shouldShowPlexEpisodesDirectly(show: MediaItem, seasons: List<MediaItem>, libraryPrefs: JsonObject): Boolean {
    when (show.raw?.get("flattenSeasons").flexInt()) {
        FLATTEN_SEASONS_HIDE -> return true
        FLATTEN_SEASONS_SHOW -> return false
    }
    if (show.raw?.get("skipChildren").flexBool()) return true
    val libraryFlattenSeasons = libraryPrefs["flattenSeasons"].flexInt()
    return libraryFlattenSeasons == FLATTEN_SEASONS_HIDE ||
        seasons.isEmpty() ||
        (libraryFlattenSeasons == FLATTEN_SEASONS_SINGLE_SEASON && seasons.size == 1)
}
