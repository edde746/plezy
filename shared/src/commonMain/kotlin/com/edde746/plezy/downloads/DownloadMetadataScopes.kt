package com.edde746.plezy.downloads

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.resolveActiveClientScopeId
import kotlinx.coroutines.CancellationException

/**
 * Which client and which cache namespace serve a download's metadata: the live client of a server or a download's
 * scope, the cache of the server's backend even while it is offline, and the namespace a profile sees.
 */
internal class DownloadMetadataScopes(
    private val database: DownloadLibraryRepository,
    private val clientResolver: (ServerId, String?) -> MediaBackend?,
    private val caches: Map<BackendKind, BackendCache>,
    private val mediaBrowserResolver: JellyfinCacheResolver,
) {
    /** Used when an item has no server id: the client that last drove the queue. */
    var fallbackClient: MediaBackend? = null

    fun cacheFor(backend: BackendKind): BackendCache = caches.getValue(backend)

    /** The live client for [serverId] (and [clientScopeId]); null while offline, so callers defer the work. */
    fun client(serverId: ServerId?, clientScopeId: String? = null): MediaBackend? =
        if (serverId != null) clientResolver(serverId, clientScopeId) else fallbackClient

    /**
     * The client to fetch [globalKey] with: the one of the row's scope, else (a shared row whose first owner's scope
     * has no live client) another valid owner's live scope.
     */
    suspend fun clientForDownloadKey(globalKey: String): MediaBackend? {
        val (serverId, _) = parseGlobalKey(globalKey) ?: return client(null)
        val rowScopeId = database.getDownloadedMedia(globalKey)?.client_scope_id
        val client = client(serverId, rowScopeId)
        if (client != null || rowScopeId == null) return client
        for (owner in database.getValidDownloadOwnersForKey(globalKey)) {
            val ownerScopeId = resolveActiveClientScopeId(serverId, owner.client_scope_id)
            if (ownerScopeId == null || ownerScopeId == rowScopeId) continue
            client(serverId, ownerScopeId)?.let { return it }
        }
        return null
    }

    fun activeClientScopeIdForServer(serverId: ServerId): String? =
        resolveActiveClientScopeId(serverId, client(serverId)?.cacheServerId)

    /**
     * The cache namespace [activeProfileId] sees on [serverId]. MediaBrowser servers prefer the persisted
     * profile-to-user binding (a cold start or profile switch must not inherit the download row's creator scope), then
     * the live scope; Plex uses the profile's private scope.
     */
    suspend fun profileClientScopeIdForServer(serverId: ServerId, activeProfileId: String?): String? {
        if (activeProfileId.isNullOrEmpty()) return null
        val backend = backendForServer(serverId) ?: return null
        return profileScopeIdForBackend(backend, serverId, activeProfileId)
    }

    private suspend fun profileScopeIdForBackend(backend: BackendKind, serverId: ServerId, activeProfileId: String): String? {
        if (backend.usesMediaBrowserApi) {
            return mediaBrowserResolver.findProfileScopeId(serverId.value, activeProfileId) ?: activeClientScopeIdForServer(serverId)
        }
        return PlexProfileScopeId.of(serverId, activeProfileId).value
    }

    /** The pinned metadata of every download [activeProfileId] owns, read only from that profile's exact namespaces. */
    suspend fun getAllPinnedMetadata(activeProfileId: String?): PinnedDownloadMetadata {
        if (activeProfileId.isNullOrEmpty()) return PinnedDownloadMetadata(emptyMap(), emptyMap())
        val ownerKeys = database.getDownloadOwnerKeysForProfile(activeProfileId)
        val serverIds = database.getAllDownloads().filter { it.global_key in ownerKeys }.mapTo(linkedSetOf()) { it.server_id }
        val scopes = linkedMapOf<String, Pair<BackendKind, String?>>()
        for (raw in serverIds) {
            val serverId = ServerId(raw)
            val backend = backendForServer(serverId) ?: continue
            scopes[raw] = backend to profileScopeIdForBackend(backend, serverId, activeProfileId)
        }
        val items = linkedMapOf<String, MediaItem>()
        for ((cache, kinds) in caches.entries.groupBy({ it.value }, { it.key })) {
            val allowed = scopes.values.filter { it.first in kinds }.mapNotNullTo(mutableSetOf()) { it.second }
            items += cache.getAllPinnedMetadata(allowed)
        }
        return PinnedDownloadMetadata(items, scopes.mapValues { it.value.second })
    }

    suspend fun lookupMetadata(serverId: ServerId, itemId: String, preferActiveScope: Boolean, activeProfileId: String?): MediaItem? {
        if (preferActiveScope) {
            val scopeId = profileClientScopeIdForServer(serverId, activeProfileId) ?: return null
            return lookup(serverId, itemId, scopeId)
        }
        val download = database.getDownloadedMedia(buildGlobalKey(serverId, itemId))
        for (scopeId in metadataScopeCandidates(serverId, download?.client_scope_id)) {
            lookup(serverId, itemId, scopeId.takeUnless { it == serverId.value })?.let { return it }
        }
        return null
    }

    private fun metadataScopeCandidates(serverId: ServerId, downloadedClientScopeId: String?): List<String> =
        listOfNotNull(downloadedClientScopeId, client(serverId, downloadedClientScopeId)?.cacheServerId, serverId.value)
            .filter { it.isNotEmpty() }
            .distinct()

    suspend fun fetchAndPinMetadata(serverId: ServerId, itemId: String, preferActiveScope: Boolean, activeProfileId: String?): MediaItem? {
        val clientScopeId = if (preferActiveScope) {
            profileClientScopeIdForServer(serverId, activeProfileId) ?: return null
        } else {
            database.getDownloadedMedia(buildGlobalKey(serverId, itemId))?.client_scope_id
        }
        val client = client(serverId, clientScopeId) ?: return null
        if (preferActiveScope && client.cacheServerId != clientScopeId) return null
        return try {
            val metadata = client.fetchItem(itemId) ?: return null
            cacheFor(client.backend).pinForOffline(client.cacheServerId, itemId)
            metadata
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "fetchAndPinMetadata failed for $serverId:$itemId" }
            null
        }
    }

    /** The backend of [serverId]: its live client's, else its saved connection's (works while the server is offline). */
    suspend fun backendForServer(serverId: ServerId): BackendKind? {
        client(serverId)?.let { return it.backend }
        return database.connectionKindForServer(serverId.value)?.let { kind -> BackendKind.entries.firstOrNull { it.id == kind } }
    }

    /**
     * The cached metadata of [itemId] in [clientScopeId] (else the live client's scope, else the bare server id). A
     * server whose backend can't be resolved (removed, rows left behind) is tried in every backend's cache.
     */
    suspend fun lookup(serverId: ServerId, itemId: String, clientScopeId: String?): MediaItem? {
        val backend = backendForServer(serverId)
        if (backend != null) {
            val scope = clientScopeId ?: client(serverId, clientScopeId)?.cacheServerId ?: serverId.value
            return cacheFor(backend).getMetadata(scope, itemId)
        }
        Log.w(TAG) { "Cache lookup for $serverId:$itemId: backend unresolved; trying every backend" }
        for (cache in caches.values.distinct()) {
            if (!clientScopeId.isNullOrEmpty()) cache.getMetadata(clientScopeId, itemId)?.let { return it }
            cache.getMetadata(serverId.value, itemId)?.let { return it }
        }
        return null
    }

    /** The cached metadata of a download row, in the row's scope. */
    suspend fun metadataFor(globalKey: String): MediaItem? {
        val (serverId, ratingKey) = parseGlobalKey(globalKey) ?: return null
        return lookup(serverId, ratingKey, database.getDownloadedMedia(globalKey)?.client_scope_id)
    }

    /** The year of an episode's show (its folder name), from the cache. */
    suspend fun showYear(serverId: ServerId, grandparentRatingKey: String?, clientScopeId: String?): Int? {
        if (grandparentRatingKey == null) return null
        return lookup(serverId, grandparentRatingKey, clientScopeId)?.year
    }

    /** Deletes [itemId]'s cached rows in the namespace [lookup] would read; every backend's when unresolved. */
    suspend fun deleteForItemByServer(serverId: ServerId, itemId: String, clientScopeId: String?) {
        val backend = backendForServer(serverId)
        if (backend != null) {
            val scope = clientScopeId ?: client(serverId, clientScopeId)?.cacheServerId ?: serverId.value
            cacheFor(backend).deleteForItem(scope, itemId)
            return
        }
        Log.w(TAG) { "Cache delete for $serverId:$itemId: backend unresolved; clearing every backend" }
        for (cache in caches.values.distinct()) {
            if (!clientScopeId.isNullOrEmpty()) cache.deleteForItem(clientScopeId, itemId)
            cache.deleteForItem(serverId.value, itemId)
        }
    }

    /**
     * Drops the metadata a departing owner saw: its exact scope's rows unless another valid owner sees the same scope;
     * a Plex owner without a recorded scope uses its profile scope.
     */
    suspend fun deleteMetadataForOwner(
        globalKey: String,
        serverId: ServerId,
        itemId: String,
        profileId: String,
        backendId: String?,
        clientScopeId: String?,
    ) {
        val scopeId = clientScopeId?.trim()
        if (!scopeId.isNullOrEmpty() && backendId != null) {
            if (database.hasDownloadOwnerForCacheScope(globalKey, backendId, scopeId)) return
            cacheFor(BackendKind.fromId(backendId)).deleteForItem(scopeId, itemId)
            return
        }
        if (backendId == null || backendId == BackendKind.PLEX.id) {
            cacheFor(BackendKind.PLEX).deleteForItem(PlexProfileScopeId.of(serverId, profileId).value, itemId)
        }
    }

    /**
     * Caches and pins [metadata] for offline use: MediaBrowser servers load the playback extras (and Jellyfin's media
     * segments), the others the item itself; a failed fetch still pins what is cached.
     */
    suspend fun pinMetadataForOffline(client: MediaBackend, metadata: MediaItem) {
        if (metadata.serverId == null) {
            Log.w(TAG) { "Cannot pin metadata without serverId" }
            return
        }
        try {
            if (client.backend.usesMediaBrowserApi) client.fetchPlaybackExtras(metadata.id) else client.fetchItem(metadata.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Metadata fetch failed while pinning ${metadata.globalKey} for offline use" }
        }
        cacheFor(client.backend).pinForOffline(client.cacheServerId, metadata.id)
    }

    /** The ids whose metadata a download needs offline: its own, its parent's and its grandparent's. */
    fun offlineMetadataIds(row: Downloaded_media): Set<String> =
        listOfNotNull(row.rating_key, row.parent_rating_key, row.grandparent_rating_key).toCollection(LinkedHashSet())

    private companion object {
        const val TAG = "DownloadMetadata"
    }
}
