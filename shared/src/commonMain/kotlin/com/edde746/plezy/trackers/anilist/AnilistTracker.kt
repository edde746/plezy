package com.edde746.plezy.trackers.anilist

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.AnimeListSnapshot
import com.edde746.plezy.trackers.client.AnimeListTracker
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.string
import kotlin.math.roundToInt
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The AniList account's write side: `SaveMediaListEntry(progress, status)` once
 * playback crosses the watched threshold, keeping a `REPEATING` entry a rewatch instead of setting it back to
 * `CURRENT`. Anime only: an item without an AniList id is skipped.
 *
 * Scores are read and written as `POINT_100` (docs.anilist.co/reference/enum/scoreformat), whatever format the user
 * shows them in: the app's 1–10 is ×10 on the way out and rounded back on the way in.
 */
internal class AnilistTracker(private val api: AnilistApi) : AnimeListTracker() {
    override val service: TrackerService get() = TrackerService.ANILIST

    override fun animeId(anime: AnimeIds?): Int? = anime?.anilist

    /**
     * AniList takes 90 requests a minute, 30 while it runs degraded as it does now (docs.anilist.co/guide/rate-limiting),
     * and a write is two: the entry's read and its save.
     */
    override val writeSpacing: Duration get() = 4.seconds

    override suspend fun loadSnapshot(animeId: Int): AnimeListSnapshot? {
        val data = try {
            api.query(SNAPSHOT, buildJsonObject { put("mediaId", animeId) })
        } catch (e: TrackerException.Api) {
            // An id AniList doesn't know answers HTTP 404 with a "Not Found." error.
            if (e.status == 404) return null else throw e
        }
        val media = data["Media"].obj ?: return null
        val entry = media["mediaListEntry"].obj
        val status = entry?.get("status").string
        return AnimeListSnapshot(
            episodeCount = media["episodes"].flexibleInt?.takeIf { it > 0 },
            rewatching = status == "REPEATING",
            completed = status == "COMPLETED",
            rewatchCount = entry?.get("repeat").flexibleInt ?: 0,
            progress = entry?.get("progress").flexibleInt ?: 0,
        )
    }

    override suspend fun saveProgress(animeId: Int, progress: Int, completed: Boolean, rewatching: Boolean, rewatchCount: Int?) {
        val status = when {
            completed -> "COMPLETED"
            rewatching -> "REPEATING"
            else -> "CURRENT"
        }
        // `repeat` is sent only when a rewatch completes: an explicit null's effect is undocumented and must not
        // clear the stored count.
        val variables = buildJsonObject {
            put("mediaId", animeId)
            put("progress", progress)
            put("status", status)
            if (rewatchCount != null) put("repeat", rewatchCount)
        }
        api.query(if (rewatchCount == null) SAVE_PROGRESS else SAVE_PROGRESS_AND_REPEAT, variables)
        Log.d(TAG) { "anilist: list entry $animeId at $progress, $status" }
    }

    override suspend fun saveScore(animeId: Int, score: Int) {
        api.query(
            SAVE_SCORE,
            buildJsonObject {
                put("mediaId", animeId)
                put("scoreRaw", score.coerceIn(0, 10) * 10)
            },
        )
    }

    override suspend fun loadScore(animeId: Int): Int? {
        val media = api.query(SCORE, buildJsonObject { put("mediaId", animeId) })["Media"].obj ?: return null
        val raw = media["mediaListEntry"].obj?.get("scoreRaw").flexibleInt?.takeIf { it > 0 } ?: return null
        return (raw / 10.0).roundToInt().coerceIn(1, 10)
    }

    private companion object {
        const val TAG = "trackers"

        val SNAPSHOT = """
            query(${'$'}mediaId: Int) {
              Media(id: ${'$'}mediaId, type: ANIME) {
                episodes
                mediaListEntry { status repeat progress }
              }
            }
        """.trimIndent()

        val SAVE_PROGRESS = """
            mutation(${'$'}mediaId: Int, ${'$'}progress: Int, ${'$'}status: MediaListStatus) {
              SaveMediaListEntry(mediaId: ${'$'}mediaId, progress: ${'$'}progress, status: ${'$'}status) { id }
            }
        """.trimIndent()

        val SAVE_PROGRESS_AND_REPEAT = """
            mutation(${'$'}mediaId: Int, ${'$'}progress: Int, ${'$'}status: MediaListStatus, ${'$'}repeat: Int) {
              SaveMediaListEntry(mediaId: ${'$'}mediaId, progress: ${'$'}progress, status: ${'$'}status, repeat: ${'$'}repeat) { id }
            }
        """.trimIndent()

        val SAVE_SCORE = """
            mutation(${'$'}mediaId: Int, ${'$'}scoreRaw: Int) {
              SaveMediaListEntry(mediaId: ${'$'}mediaId, scoreRaw: ${'$'}scoreRaw) { id }
            }
        """.trimIndent()

        val SCORE = """
            query(${'$'}mediaId: Int) {
              Media(id: ${'$'}mediaId, type: ANIME) {
                mediaListEntry { scoreRaw: score(format: POINT_100) }
              }
            }
        """.trimIndent()
    }
}
