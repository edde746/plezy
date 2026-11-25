package com.edde746.plezy.livetv

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.servers.LiveTvServerEntry

/**
 * [client]'s Live TV sources: with DVRs (Plex), one entry per DVR; otherwise one entry keyed by the backend's id (`jellyfin`, `emby`) when
 * [LiveTvSupport.isAvailable]; else none. A failed DVR list throws.
 */
suspend fun liveTvServerEntries(client: MediaBackend): List<LiveTvServerEntry> {
    val dvrs = client.liveTvDvr?.fetchDvrs().orEmpty()
    if (dvrs.isNotEmpty()) return dvrs.map { LiveTvServerEntry(client.serverId, it.key, it.lineup, dvrs) }
    if (!client.liveTv.isAvailable()) return emptyList()
    return listOf(LiveTvServerEntry(client.serverId, client.backend.id))
}
