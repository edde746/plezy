package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.log.Log

/** A profile's sign-in on a connection: [userIdentifier] is the MediaBrowser user id the profile acts as. */
data class JellyfinProfileBinding(
    val profileId: String,
    val connectionId: String,
    val userIdentifier: String,
    val isDefault: Boolean = false,
    val lastUsedAt: Long? = null,
)

/** A parsed `{scopeId}:/Users/{userId}/Items/{itemId}` cache key; [scopeId] is `{machineId}` or `{machineId}/{userId}`. */
data class JellyfinItemCacheKey(val scopeId: String, val machineId: String, val userId: String, val itemId: String)

data class JellyfinCacheItem(val row: ApiCacheRow, val key: JellyfinItemCacheKey)

data class ResolvedJellyfinCacheItem(val row: ApiCacheRow, val connection: JellyfinConnection, val key: JellyfinItemCacheKey)

/**
 * Maps MediaBrowser item-cache keys to their rows and to the signed-in connection that owns them. Rows live under the
 * compound `{machineId}/{userId}` scope, or under the bare machine id for rows written before per-user scopes. A bare
 * id never picks between users: serving one user's row to another would leak their watch state and token.
 */
class JellyfinCacheResolver(
    private val store: ApiCacheStore,
    private val connections: suspend () -> List<JellyfinConnection>,
    private val bindings: suspend () -> List<JellyfinProfileBinding>,
) {
    /**
     * Every row holding [itemId] for [serverOrScopeId], ordered by key: a bare machine id matches every user's rows, a
     * compound scope its own and that user's legacy bare-scope row.
     */
    suspend fun itemRows(serverOrScopeId: String, itemId: String): List<JellyfinCacheItem> {
        val requested = splitScope(serverOrScopeId)
        return store.rowsMatching(requested.machineId, "$ITEMS_MARKER$itemId").mapNotNull { row ->
            val key = parseItemKey(row.key) ?: return@mapNotNull null
            val matches = key.itemId == itemId && key.machineId == requested.machineId &&
                (requested.userId == null || key.userId == requested.userId)
            if (matches) JellyfinCacheItem(row, key) else null
        }
    }

    suspend fun findItem(serverOrScopeId: String, itemId: String): JellyfinCacheItem? =
        findItems(serverOrScopeId, itemId).firstOrNull()

    suspend fun findResolvedItem(serverOrScopeId: String, itemId: String): ResolvedJellyfinCacheItem? {
        for (match in findItems(serverOrScopeId, itemId)) {
            val connection = findConnection(match.key.scopeId, userId = match.key.userId) ?: continue
            return ResolvedJellyfinCacheItem(match.row, connection, match.key)
        }
        return null
    }

    private suspend fun findItems(serverOrScopeId: String, itemId: String): List<JellyfinCacheItem> {
        val matches = itemRows(serverOrScopeId, itemId)
        if (splitScope(serverOrScopeId).userId != null) return matches.sortedBy { it.key.scopeId != serverOrScopeId }
        val userCount = matches.map { it.key.userId }.toSet().size
        if (userCount > 1) {
            Log.w(TAG) { "Refusing ambiguous bare-scope cache resolution: $serverOrScopeId item $itemId spans $userCount users" }
            return emptyList()
        }
        return matches
    }

    /** Every pinned item row with its owning connection: the compound connection first, then a legacy bare one. */
    suspend fun findPinnedItems(): List<ResolvedJellyfinCacheItem> {
        val rows = store.pinnedRows().sortedBy { it.key }
        if (rows.isEmpty()) return emptyList()
        val connectionById = connections().associateBy { it.id }
        val bindingsByConnection = bindings().groupBy { it.connectionId }
        fun matchesBinding(connectionId: String, userId: String): Boolean =
            bindingsByConnection[connectionId].let { it.isNullOrEmpty() || it.any { b -> b.userIdentifier == userId } }

        return rows.mapNotNull { row ->
            val key = parseItemKey(row.key) ?: return@mapNotNull null
            val connection = listOfNotNull(connectionById["${key.machineId}/${key.userId}"], connectionById[key.machineId])
                .firstOrNull { matchesBinding(it.id, key.userId) } ?: return@mapNotNull null
            ResolvedJellyfinCacheItem(row, connection, key)
        }
    }

    /**
     * The cache scope `{machineId}/{userIdentifier}` [profileId] owns on [serverOrScopeId]: its bindings by default first,
     * then most recently used, then connection id; the first whose connection is on that machine and the same user wins.
     */
    suspend fun findProfileScopeId(serverOrScopeId: String, profileId: String): String? {
        if (profileId.isEmpty()) return null
        val requested = splitScope(serverOrScopeId)
        val profileBindings = bindings().filter { it.profileId == profileId }.sortedWith(
            compareByDescending<JellyfinProfileBinding> { it.isDefault }
                .thenByDescending { it.lastUsedAt ?: Long.MIN_VALUE }
                .thenBy { it.connectionId },
        )
        if (profileBindings.isEmpty()) return null
        val connectionById = connections().associateBy { it.id }
        for (binding in profileBindings) {
            if (binding.userIdentifier.isEmpty()) continue
            val connection = connectionById[binding.connectionId] ?: continue
            val idScope = splitScope(connection.id)
            val machineId = connection.serverMachineId.ifEmpty { idScope.machineId }
            val userId = connection.userId.ifEmpty { idScope.userId }
            if (machineId != requested.machineId) continue
            if (userId != null && userId != binding.userIdentifier) continue
            return "$machineId/${binding.userIdentifier}"
        }
        return null
    }

    /**
     * The connection owning [serverOrScopeId]. With a user (from the scope or [userId], which must agree) only that
     * user's compound connection or a legacy bare one whose bindings name the user; without, the bare-id connection or
     * the first of the machine's users by id.
     */
    suspend fun findConnection(serverOrScopeId: String, userId: String? = null): JellyfinConnection? {
        val scope = splitScope(serverOrScopeId)
        if (scope.userId != null && userId != null && scope.userId != userId) return null
        val expectedUserId = userId ?: scope.userId
        val all = connections()
        if (expectedUserId != null) {
            val connectionBindings = bindings()
            return listOf("${scope.machineId}/$expectedUserId", scope.machineId).firstNotNullOfOrNull { id ->
                all.firstOrNull { it.id == id }?.takeIf { connection ->
                    val bound = connectionBindings.filter { it.connectionId == connection.id }
                    bound.isEmpty() || bound.any { it.userIdentifier == expectedUserId }
                }
            }
        }
        return all.firstOrNull { it.id == scope.machineId }
            ?: all.filter { it.id.startsWith("${scope.machineId}/") }.minByOrNull { it.id }
    }

    companion object {
        private const val TAG = "JellyfinCacheResolver"
        private const val USERS_MARKER = ":/Users/"
        private const val ITEMS_MARKER = "/Items/"

        /** Null for any other key, an item id with `/` or `?`, or a compound scope naming a different user. */
        fun parseItemKey(cacheKey: String): JellyfinItemCacheKey? {
            val usersMarker = cacheKey.indexOf(USERS_MARKER)
            if (usersMarker <= 0) return null
            val scopeId = cacheKey.substring(0, usersMarker)
            val userStart = usersMarker + USERS_MARKER.length
            val itemsMarker = cacheKey.indexOf(ITEMS_MARKER, userStart)
            if (itemsMarker <= userStart) return null
            val userId = cacheKey.substring(userStart, itemsMarker)
            val itemId = cacheKey.substring(itemsMarker + ITEMS_MARKER.length)
            if (itemId.isEmpty() || '/' in itemId || '?' in itemId) return null
            val scope = splitScope(scopeId)
            if (scope.userId != null && scope.userId != userId) return null
            return JellyfinItemCacheKey(scopeId, scope.machineId, userId, itemId)
        }

        internal data class Scope(val machineId: String, val userId: String?)

        internal fun splitScope(scopeId: String): Scope {
            val slash = scopeId.indexOf('/')
            if (slash <= 0 || slash == scopeId.length - 1) return Scope(scopeId, null)
            return Scope(scopeId.substring(0, slash), scopeId.substring(slash + 1))
        }
    }
}
