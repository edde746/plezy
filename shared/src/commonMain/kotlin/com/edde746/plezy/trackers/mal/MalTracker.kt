package com.edde746.plezy.trackers.mal

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.AnimeListSnapshot
import com.edde746.plezy.trackers.client.AnimeListTracker
import com.edde746.plezy.trackers.client.flexibleBool
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.string

/**
 * The MyAnimeList account's write side: `num_watched_episodes` on the user's list entry through
 * `PUT /anime/{id}/my_list_status` (myanimelist.net/apiconfig/references/api/v2, "anime_anime_id_my_list_status_put").
 * Anime only: an item without a MyAnimeList id is skipped. Scores are MyAnimeList's own 1–10.
 */
internal class MalTracker(private val api: MalApi) : AnimeListTracker() {
    override val service: TrackerService get() = TrackerService.MYANIMELIST

    override fun animeId(anime: AnimeIds?): Int? = anime?.mal

    /** Episode total and the viewer's list status in one request. */
    override suspend fun loadSnapshot(animeId: Int): AnimeListSnapshot? {
        val anime = api.getOrNull("/anime/$animeId?fields=num_episodes,my_list_status")?.json().obj ?: return null
        val list = anime["my_list_status"].obj
        return AnimeListSnapshot(
            episodeCount = anime["num_episodes"].flexibleInt?.takeIf { it > 0 },
            rewatching = list?.get("is_rewatching").flexibleBool,
            completed = list?.get("status").string == "completed",
            rewatchCount = list?.get("num_times_rewatched").flexibleInt ?: 0,
            // The answer documents `num_episodes_watched`; only the update form says `num_watched_episodes`.
            progress = (list?.get("num_episodes_watched") ?: list?.get("num_watched_episodes")).flexibleInt ?: 0,
        )
    }

    override suspend fun saveProgress(animeId: Int, progress: Int, completed: Boolean, rewatching: Boolean, rewatchCount: Int?) {
        val fields = mutableListOf("num_watched_episodes" to progress.toString())
        if (rewatching) {
            // MyAnimeList models a rewatch as the existing status (normally completed) plus is_rewatching: writing
            // status=watching would take the show off the completed list. Fields left out stay as they are.
            fields += "is_rewatching" to "true"
        } else {
            fields += "status" to if (completed) "completed" else "watching"
            if (rewatchCount != null) {
                // Finishing a rewatch: back on completed with the count raised.
                fields += "is_rewatching" to "false"
                fields += "num_times_rewatched" to rewatchCount.toString()
            }
        }
        api.put("/anime/$animeId/my_list_status", fields)
        Log.d(TAG) { "mal: list entry $animeId at $progress" + if (completed) ", completed" else "" }
    }

    override suspend fun saveScore(animeId: Int, score: Int) {
        api.put("/anime/$animeId/my_list_status", listOf("score" to score.toString()))
    }

    override suspend fun loadScore(animeId: Int): Int? {
        val anime = api.getOrNull("/anime/$animeId?fields=my_list_status")?.json().obj ?: return null
        return anime["my_list_status"].obj?.get("score").flexibleInt?.takeIf { it > 0 }
    }

    private companion object {
        const val TAG = "trackers"
    }
}
