package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException

private const val TAG = "PlexActivities"

/** A running background task on the server (thumbnail generation, credits detection, a scan, …). */
data class PlexActivity(
    val uuid: String,
    val type: String,
    val title: String,
    val subtitle: String?,
    /** 0–100. */
    val progress: Int,
    val cancellable: Boolean,
)

/**
 * `GET /activities`. Scalars are read leniently; rows without a uuid or not objects are skipped. A cancellation
 * propagates; any other failure is an empty list.
 */
suspend fun PlexClient.getActivities(): List<PlexActivity> = try {
    getWithFailover("/activities").data.mediaContainer()?.get("Activity").objectList().mapNotNull { row ->
        val uuid = row["uuid"].scalarString().orEmpty()
        if (uuid.isEmpty()) return@mapNotNull null
        PlexActivity(
            uuid = uuid,
            type = row["type"].scalarString().orEmpty(),
            title = row["title"].scalarString().orEmpty(),
            subtitle = row["subtitle"].scalarString(),
            progress = row["progress"].flexInt() ?: 0,
            cancellable = row["cancellable"].flexBool(),
        )
    }
} catch (e: CancellationException) {
    throw e
} catch (e: MediaServerHttpException) {
    if (e.isCancellation) throw e
    Log.e(TAG, e) { "Failed to get activities" }
    emptyList()
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get activities" }
    emptyList()
}

/** `DELETE /activities/{uuid}`; a status of 400 or more throws. */
suspend fun PlexClient.cancelActivity(uuid: String) {
    throwIfHttpError(http.delete("/activities/$uuid"))
}
