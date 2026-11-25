package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import kotlinx.coroutines.CompletableDeferred

/** In-memory [LibraryPreferences] keyed like the real store: `user_<profile>_library_order` / `..._hidden_libraries`. */
class FakeLibraryPreferences : LibraryPreferences {
    var activeProfileId: String? = null
    val orders = mutableMapOf<String, List<String>>()
    val hidden = mutableMapOf<String, Set<String>>()

    private fun prefix(profileId: String?) = (profileId ?: activeProfileId)?.let { "user_${it}_" } ?: ""

    override suspend fun libraryOrder(profileId: String?) = orders["${prefix(profileId)}library_order"]

    override suspend fun setLibraryOrder(keys: List<String>, profileId: String?) {
        orders["${prefix(profileId)}library_order"] = keys
    }

    override suspend fun hiddenLibraries(profileId: String?) = hidden["${prefix(profileId)}hidden_libraries"].orEmpty()

    override suspend fun setHiddenLibraries(keys: Set<String>, profileId: String?) {
        hidden["${prefix(profileId)}hidden_libraries"] = keys
    }

    override suspend fun removeServerEverywhere(serverId: ServerId) {
        for (key in orders.keys.toList()) orders[key] = orders.getValue(key).withoutServer(serverId)
        for (key in hidden.keys.toList()) hidden[key] = hidden.getValue(key).withoutServer(serverId).toSet()
    }
}

fun serverLib(serverId: String, id: String, title: String) =
    MediaLibrary(id = id, backend = BackendKind.PLEX, title = title, kind = MediaKind.MOVIE, serverId = serverId)

/** A server answering library fetches; [gate] holds a fetch open, [error] / [errorForCall] make it throw. */
class FakeLibraryServer(
    val id: ServerId,
    var libraries: List<MediaLibrary> = emptyList(),
    var gate: CompletableDeferred<Unit>? = null,
    var errorForCall: ((Int) -> Exception?)? = null,
) {
    var error: Exception? = null
    var calls = 0
        private set

    suspend fun fetch(): List<MediaLibrary> {
        calls++
        gate?.await()
        (errorForCall?.invoke(calls) ?: error)?.let { throw it }
        return libraries
    }
}

/** Fans a library fetch out over the registered servers and classifies each like the aggregation does. */
class FakeLibraryServers : LibrariesFetcher {
    private val servers = linkedMapOf<ServerId, FakeLibraryServer>()

    fun add(server: FakeLibraryServer) = server.also { servers[it.id] = it }

    fun remove(id: ServerId) {
        servers.remove(id)
    }

    override suspend fun fetch(serverIds: Set<ServerId>?): LibraryAggregationResult {
        val libraries = mutableListOf<MediaLibrary>()
        val succeeded = mutableSetOf<ServerId>()
        val failed = mutableSetOf<ServerId>()
        val cancelled = mutableSetOf<ServerId>()
        for (server in servers.values.toList()) {
            if (serverIds != null && server.id !in serverIds) continue
            try {
                libraries += server.fetch()
                succeeded += server.id
            } catch (e: MediaServerHttpException) {
                if (e.isCancellation) cancelled += server.id else failed += server.id
            } catch (e: IllegalStateException) {
                failed += server.id
            }
        }
        return LibraryAggregationResult(
            libraries = libraries,
            succeededServerIds = succeeded,
            cancelledServerIds = cancelled,
            failedServerIds = failed,
        )
    }
}
