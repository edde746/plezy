package com.edde746.plezy.music

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.time.Duration.Companion.minutes

val TRACK_DURATION = 3.minutes

/** A Plex track on server `srv` of album "Album" by "Artist", three minutes long unless [durationMs] says otherwise. */
fun track(id: String, durationMs: Long? = TRACK_DURATION.inWholeMilliseconds, serverId: String = "srv", albumId: String? = null) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = MediaKind.TRACK,
    title = "Track $id",
    parentId = albumId,
    parentTitle = "Album",
    grandparentTitle = "Artist",
    durationMs = durationMs,
    serverId = serverId,
)

fun List<MediaItem>.ids() = map { it.id }
