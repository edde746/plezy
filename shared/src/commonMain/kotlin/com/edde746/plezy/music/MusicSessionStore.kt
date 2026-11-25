package com.edde746.plezy.music

import com.edde746.plezy.data.music.MusicSession
import com.edde746.plezy.data.music.MusicSessionRepository
import com.edde746.plezy.jellyfin.JellyfinImageAbsolutizer
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.fromJson
import com.edde746.plezy.model.toJson
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** What rebuilds a parked music session on the next launch. Volume isn't in it: it is a setting of its own. */
data class MusicSessionSnapshot(val queue: MusicQueueState, val playContext: MusicPlayContext?, val position: Duration)

/**
 * The profile's last music session over [MusicSessionRepository]. [save] rewrites the whole row (queue JSON included)
 * and runs on queue-shape and mode changes only; [updateProgress] is the cheap cursor and playhead write for track
 * changes, pauses and the throttled position tick. A malformed row is discarded whole: a restore never makes a
 * half-valid session.
 */
class MusicSessionStore(
    private val repository: MusicSessionRepository,
    private val profileId: String,
    private val clock: Clock = Clock.System,
) {
    // The last saved snapshot (unwindowed) and where its persisted window starts in playback order: an oversized
    // queue persists a window-relative cursor, so updateProgress maps the live cursor through them.
    private var lastSaved: MusicSessionSnapshot? = null
    private var windowStart = 0

    suspend fun save(snapshot: MusicSessionSnapshot) {
        val start = windowStartFor(snapshot.queue)
        lastSaved = snapshot
        windowStart = start
        val queue = windowed(snapshot.queue, start)
        repository.save(
            MusicSession(
                profileId = profileId,
                queueJson = JsonArray(queue.items.map { it.toJson() }).toString(),
                orderJson = JsonArray(queue.order.map { JsonPrimitive(it) }).toString(),
                cursor = queue.cursor,
                shuffled = queue.shuffled,
                repeatMode = queue.repeatMode.id,
                contextTitle = snapshot.playContext?.title,
                contextKind = snapshot.playContext?.kind?.id,
                positionMs = snapshot.position.inWholeMilliseconds.coerceAtLeast(0),
                updatedAt = clock.now().toEpochMilliseconds(),
            ),
        )
    }

    /** Moves the stored cursor and playhead; re-windows an oversized queue when the cursor left its window. */
    suspend fun updateProgress(cursor: Int, position: Duration) {
        var persistedCursor = cursor
        val saved = lastSaved
        if (saved != null && saved.queue.items.size > MAX_PERSISTED_TRACKS) {
            val windowed = cursor - windowStart
            if (windowed !in 0 until MAX_PERSISTED_TRACKS) {
                // Only the cursor moved since the last save: shape changes save in full.
                save(MusicSessionSnapshot(saved.queue.copy(cursor = cursor), saved.playContext, position))
                return
            }
            persistedCursor = windowed
        }
        repository.updateProgress(
            profileId,
            cursor = persistedCursor,
            positionMs = position.inWholeMilliseconds.coerceAtLeast(0),
            updatedAt = clock.now().toEpochMilliseconds(),
        )
    }

    suspend fun load(): MusicSessionSnapshot? {
        val row = repository.load(profileId) ?: return null
        return try {
            val items = Json.parseToJsonElement(row.queueJson).jsonArray.map { MediaItem.fromJson(it.jsonObject) }
            val order = Json.parseToJsonElement(row.orderJson).jsonArray.map { it.jsonPrimitive.int }
            val repeatMode = MusicRepeatMode.entries.firstOrNull { it.id == row.repeatMode } ?: return null
            val contextKind = row.contextKind?.let { id -> MusicPlayContextKind.entries.firstOrNull { it.id == id } }
            MusicSessionSnapshot(
                queue = MusicQueueState(items, order, row.cursor, row.shuffled, repeatMode),
                playContext = if (row.contextTitle != null && contextKind != null) MusicPlayContext(row.contextTitle, contextKind) else null,
                position = row.positionMs.coerceAtLeast(0).milliseconds,
            )
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Discarding a malformed persisted music session" }
            null
        }
    }

    suspend fun clear() {
        lastSaved = null
        windowStart = 0
        repository.deleteForProfile(profileId)
    }

    companion object {
        private const val TAG = "MusicSessionStore"
        private const val TOKEN = "api_key"

        /**
         * Drops Jellyfin's and Emby's `api_key` token from the image URLs in every profile's saved queue: earlier
         * releases and builds saved it there, and the images load without it. A queue that doesn't parse is left to
         * [load], which discards it.
         */
        suspend fun dropImageTokens(repository: MusicSessionRepository) = repository.rewriteQueues(::withoutImageTokens)

        private fun withoutImageTokens(queueJson: String): String {
            if (TOKEN !in queueJson) return queueJson
            val parsed = try {
                Json.parseToJsonElement(queueJson)
            } catch (e: SerializationException) {
                return queueJson
            }
            return stripTokens(parsed).toString()
        }

        private fun stripTokens(element: JsonElement): JsonElement = when (element) {
            is JsonObject -> JsonObject(element.mapValues { stripTokens(it.value) })
            is JsonArray -> JsonArray(element.map(::stripTokens))
            is JsonPrimitive -> {
                val text = element.content
                val tokenedUrl = element.isString && TOKEN in text && (text.startsWith("http://") || text.startsWith("https://"))
                if (tokenedUrl) JsonPrimitive(JellyfinImageAbsolutizer.removeQueryParam(text, TOKEN)) else element
            }
        }

        /**
         * The longest queue persisted. A longer one keeps a window of the playback order around the cursor
         * (materialized, so unshuffling a restored oversized queue keeps the current order).
         */
        const val MAX_PERSISTED_TRACKS = 1000

        /** How much of the window sits before the cursor; the rest is the upcoming tracks, which matter more. */
        private const val HISTORY_WINDOW = MAX_PERSISTED_TRACKS / 4

        private fun windowStartFor(state: MusicQueueState): Int {
            if (state.items.size <= MAX_PERSISTED_TRACKS) return 0
            return (state.cursor - HISTORY_WINDOW).coerceIn(0, state.items.size - MAX_PERSISTED_TRACKS)
        }

        private fun windowed(state: MusicQueueState, start: Int): MusicQueueState {
            if (state.items.size <= MAX_PERSISTED_TRACKS) return state
            val queue = state.order.map { state.items[it] }
            return state.copy(
                items = queue.subList(start, start + MAX_PERSISTED_TRACKS),
                order = List(MAX_PERSISTED_TRACKS) { it },
                cursor = state.cursor - start,
            )
        }
    }
}
