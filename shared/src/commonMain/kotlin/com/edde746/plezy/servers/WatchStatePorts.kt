package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId

/** The bound server clients, as watch marks and the offline watch sync reach them. */
interface WatchClients {
    /** The client bound for [serverId], online or not. */
    fun client(serverId: ServerId): MediaBackend?

    /** The client whose [MediaBackend.cacheServerId] is exactly [clientScopeId]; no fallback. */
    fun clientByScope(clientScopeId: String): MediaBackend?

    val onlineClients: Map<ServerId, MediaBackend>

    /** Whether [serverId] is reachable, through the client of [clientScopeId] when given. */
    fun isClientOnline(serverId: ServerId, clientScopeId: String? = null): Boolean
}

/**
 * The trackers (Trakt, MyAnimeList, …) a watched mark is mirrored to: manual marks, replayed offline marks, and changes
 * observed on the server. Swallows and queues its own failures; never throws.
 */
fun interface TrackerWatchMarks {
    suspend fun mark(item: MediaItem, client: MediaBackend, watched: Boolean)
}

/**
 * Each profile's trackers: [forProfile]'s marks reach that profile's trackers whichever profile is active by the time
 * they are made, so work that outlives a profile switch never reaches the next profile's.
 */
fun interface ProfileTrackerWatchMarks {
    fun forProfile(profileId: String): TrackerWatchMarks
}
