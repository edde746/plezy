package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.servers.MultiServerStore
import kotlinx.coroutines.CancellationException

/** The Live TV sources the screens load from: one [entries] row per DVR (Plex) or server (Jellyfin, Emby). */
interface LiveTvServers {
    /** The entries now. */
    val entries: List<LiveTvServerEntry>

    /** The connected client of [serverId]; null when it has none. */
    fun client(serverId: ServerId): MediaBackend?
}

/** [MultiServerStore]'s Live TV entries and clients. */
fun MultiServerStore.liveTvServers(): LiveTvServers = object : LiveTvServers {
    override val entries: List<LiveTvServerEntry> get() = state.value.liveTvServers
    override fun client(serverId: ServerId): MediaBackend? = this@liveTvServers.client(serverId)
}

/**
 * Runs [body] for each entry with a client, in order. [dedupeByServerId] visits a server once (its first entry); per-DVR
 * loads pass false. [isCurrent] is checked before each entry, so a superseded load stops. A failing [body] goes to
 * [onError] and the next entry runs; without [onError] it propagates.
 */
suspend fun LiveTvServers.forEachLiveTvServer(
    dedupeByServerId: Boolean = true,
    isCurrent: (() -> Boolean)? = null,
    onError: ((client: MediaBackend, entry: LiveTvServerEntry, error: Exception) -> Unit)? = null,
    body: suspend (client: MediaBackend, entry: LiveTvServerEntry) -> Unit,
) {
    val seen = HashSet<ServerId>()
    for (entry in entries) {
        if (isCurrent?.invoke() == false) return
        if (dedupeByServerId && !seen.add(entry.serverId)) continue
        val client = client(entry.serverId) ?: continue
        try {
            body(client, entry)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (onError == null) throw e
            onError(client, entry, e)
        }
    }
}

/**
 * The channels of [serverId]'s Live TV, each of its lineups in order, stamped with the server and DVR they tune on. A
 * lineup that fails is logged and left out.
 */
suspend fun LiveTvServers.channelsOf(serverId: ServerId): List<LiveTvChannel> {
    val channels = mutableListOf<LiveTvChannel>()
    forEachLiveTvServer(
        dedupeByServerId = false,
        onError = { _, entry, e -> Log.w(TAG, e) { "Channels of ${entry.serverId.value} (${entry.dvrKey}) failed" } },
    ) { client, entry ->
        if (entry.serverId != serverId) return@forEachLiveTvServer
        client.liveTv.fetchChannels(entry.lineup).mapTo(channels) { it.copy(serverId = serverId.value, liveDvrKey = entry.dvrKey) }
    }
    return channels
}

private const val TAG = "LiveTvServers"
