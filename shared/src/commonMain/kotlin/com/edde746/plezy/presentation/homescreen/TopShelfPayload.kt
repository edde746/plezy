package com.edde746.plezy.presentation.homescreen

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray

/**
 * The Apple TV's Top Shelf as the tvOS app hands it to its extension: a [HomeScreenShelf] as the JSON the app writes to
 * the App Group the two share, which the extension (apple/TopShelf/TopShelfContent.swift) turns into the shelf's one
 * row. The app has downloaded each poster into the App Group's container first ([json]'s `imageFiles`); the payload
 * names the file only, so the extension reads finished content and makes no network call, and no server address or
 * token reaches the shared container.
 *
 * `{schemaVersion, ownerId, sectionTitle, items: [{id, title, progress?, imageFile?, playUrl}]}`: `id` the content id,
 * `title` the shelf's label ([label]), `progress` 0 to 1 (absent without a position and a duration), `imageFile` the
 * poster's file name in the owner's artwork folder, `playUrl` `plezy://play?content_id=…` (Play and Select alike). No
 * owner or no items: the extension shows the app's static image.
 */
object TopShelfPayload {
    /** The format's version (TopShelfContent.schemaVersion): the extension shows nothing of a payload with another. */
    const val SCHEMA_VERSION = 2

    fun json(shelf: HomeScreenShelf, imageFiles: Map<String, String>): String = buildJsonObject {
        put("schemaVersion", SCHEMA_VERSION)
        shelf.ownerId?.let { put("ownerId", it) }
        put("sectionTitle", shelf.sectionTitle)
        putJsonArray("items") { if (shelf.ownerId != null) shelf.items.forEach { add(it.shelfItem(imageFiles[it.contentId])) } }
    }.toString()

    private fun HomeScreenItem.shelfItem(imageFile: String?): JsonObject = buildJsonObject {
        put("id", contentId)
        put("title", label(this@shelfItem))
        if (positionMillis > 0 && durationMillis > 0) put("progress", (positionMillis.toDouble() / durationMillis).coerceIn(0.0, 1.0))
        imageFile?.let { put("imageFile", it) }
        put("playUrl", playUrl)
    }

    /**
     * The Top Shelf's label: `S<s> E<e> - <episode title>` with season and episode, `E<e> - <episode title>` with only
     * the episode, `<title> - <episode title>` with neither, the title alone without an episode title.
     */
    fun label(item: HomeScreenItem): String {
        val episodeTitle = item.episodeTitle ?: return item.title
        val season = item.seasonNumber
        val episode = item.episodeNumber
        return when {
            season != null && episode != null -> "S$season E$episode - $episodeTitle"
            episode != null -> "E$episode - $episodeTitle"
            else -> "${item.title} - $episodeTitle"
        }
    }
}
