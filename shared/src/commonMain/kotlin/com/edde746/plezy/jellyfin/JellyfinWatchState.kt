package com.edde746.plezy.jellyfin

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/** Played, resume, favourite and like state of one item for the signed-in user. */
internal class JellyfinWatchState(private val core: JellyfinCore) {
    private val userQuery get() = listOf("userId" to core.userId)

    /**
     * Continue Watching membership on this API is a non-zero `PlaybackPositionTicks` alone, never `Played`. Marking
     * played normally zeroes it, but a replayed stale progress report or another client can leave a position behind
     * and pin the row forever, so the postcondition is checked on the returned user data and repaired when broken.
     * Folders report 0 while the server resets their children, so they never need the repair.
     */
    suspend fun markWatched(item: MediaItem) {
        val response = core.post(core.paths.playedItem(item.id), userQuery).throwIfError()
        val positionMs = JellyfinTime.ticksToMs(response.obj?.long("PlaybackPositionTicks"))
        if (positionMs == null || positionMs <= 0) return
        Log.d(TAG) { "Item stayed resumable after mark-played; clearing its resume position" }
        core.post(
            core.paths.userItemData(item.id),
            userQuery,
            buildJsonObject { put("PlaybackPositionTicks", JsonPrimitive(0)) },
        ).throwIfError()
    }

    suspend fun markUnwatched(item: MediaItem) {
        core.delete(core.paths.playedItem(item.id), userQuery).throwIfError()
    }

    /**
     * Emby only: hides the row from `/Users/{uid}/Items/Resume` and keeps the resume position; new playback clears
     * the flag server-side. Jellyfin has no such route.
     */
    suspend fun removeFromContinueWatching(item: MediaItem) {
        if (!core.dialect.supportsContinueWatchingRemoval) {
            throw UnsupportedOperationException("${core.dialect.productName} does not support removing items from Continue Watching.")
        }
        core.post(core.paths.hideFromResume(item.id), listOf("Hide" to "true")).throwIfError()
    }

    /** The API stores only like/dislike: negative clears, 6 and up likes, the rest dislikes. */
    suspend fun rate(item: MediaItem, rating: Double) {
        val path = core.paths.itemRating(item.id)
        val response = if (rating < 0) {
            core.delete(path, userQuery)
        } else {
            core.post(path, userQuery + ("Likes" to (rating >= 6.0).toString()))
        }
        response.throwIfError()
    }

    suspend fun setFavorite(item: MediaItem, isFavorite: Boolean) = setItemFavorite(item.id, isFavorite)

    /** The per-user `IsFavorite` flag of [itemId]: items and Live TV channels alike. */
    suspend fun setItemFavorite(itemId: String, isFavorite: Boolean) {
        val path = core.paths.favoriteItem(itemId)
        val response = if (isFavorite) core.post(path, userQuery) else core.delete(path, userQuery)
        response.throwIfError()
    }

    private companion object {
        const val TAG = "JellyfinWatchState"
    }
}
