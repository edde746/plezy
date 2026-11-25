package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.flow.MutableSharedFlow

/** Registered clients, which of them are online, and the visible subset (null: all). [emit] signals a change. */
class FakeOnlineServers : OnlineServers {
    private val registered = LinkedHashMap<ServerId, MediaBackend>()
    private val online = LinkedHashSet<ServerId>()
    var visible: Set<ServerId>? = null

    override val changes = MutableSharedFlow<Unit>(extraBufferCapacity = 16)

    /** Registers (or replaces) [client]. */
    fun register(client: MediaBackend, isOnline: Boolean = true) {
        registered[client.serverId] = client
        if (isOnline) online += client.serverId else online -= client.serverId
    }

    fun setOnline(serverId: ServerId, isOnline: Boolean) {
        if (isOnline) online += serverId else online -= serverId
    }

    fun emit() {
        changes.tryEmit(Unit)
    }

    override val onlineClients: Map<ServerId, MediaBackend>
        get() = registered.filterKeys { it in online }

    override val visibleOnlineClients: Map<ServerId, MediaBackend>
        get() = visible?.let { ids -> onlineClients.filterKeys { it in ids } } ?: onlineClients

    override fun client(serverId: ServerId): MediaBackend? = registered[serverId]
}
