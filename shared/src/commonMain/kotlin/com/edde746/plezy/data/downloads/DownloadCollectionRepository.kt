package com.edde746.plezy.data.downloads

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Download_collection_syncs
import com.edde746.plezy.data.db.Download_collections
import com.edde746.plezy.log.Log
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonPrimitive

/** A collection holding some of a profile's downloaded titles: [memberIds] in the collection's order. */
data class StoredDownloadCollection(val serverId: String, val collectionId: String, val memberIds: List<String>)

/** The last refresh of a profile's collections on a server: when, and which titles it looked up. */
data class DownloadCollectionSync(val syncedAt: Long, val checkedIds: Set<String>)

/**
 * The collections holding each profile's downloaded titles, so Downloads groups them offline. A refresh replaces a
 * profile's collections on one server wholesale ([replace]).
 */
class DownloadCollectionRepository internal constructor(private val db: Db) {
    /**
     * Every stored collection of [profileId] (none for an empty id). A row whose member list doesn't decode is left
     * out; the next refresh of its server rewrites it.
     */
    suspend fun collections(profileId: String): List<StoredDownloadCollection> {
        if (profileId.isEmpty()) return emptyList()
        return db.read { syncRuleQueries.selectCollections(profileId).executeAsList() }.mapNotNull { it.toModel() }
    }

    /** The last refresh of [profileId]'s collections on [serverId]; null when there was none or it doesn't decode. */
    suspend fun sync(profileId: String, serverId: String): DownloadCollectionSync? =
        db.read { syncRuleQueries.selectCollectionSync(profileId, serverId).executeAsOneOrNull() }?.toModel()

    /**
     * Replaces [profileId]'s collections on [serverId] with [membersByCollection] (collection id to member ids in
     * collection order) and records the refresh, [checkedIds] at [syncedAt], in one transaction.
     */
    suspend fun replace(
        profileId: String,
        serverId: String,
        membersByCollection: Map<String, List<String>>,
        checkedIds: Set<String>,
        syncedAt: Long,
    ) {
        db.write {
            val queries = q.syncRuleQueries
            queries.deleteCollectionsForServer(profileId, serverId)
            for ((collectionId, memberIds) in membersByCollection) {
                queries.insertCollectionRow(Download_collections(profileId, serverId, collectionId, encodeIds(memberIds)))
            }
            queries.upsertCollectionSync(Download_collection_syncs(profileId, serverId, syncedAt, encodeIds(checkedIds.sorted())))
        }
    }

    /** Drops a removed profile's collections and refresh records. */
    suspend fun deleteForProfile(profileId: String) {
        db.write {
            q.syncRuleQueries.deleteCollectionsForProfile(profileId)
            q.syncRuleQueries.deleteCollectionSyncsForProfile(profileId)
        }
    }

    /** Drops every profile's collections and refresh records (a full sign-out). */
    suspend fun clearAll() {
        db.write {
            q.syncRuleQueries.deleteAllCollections()
            q.syncRuleQueries.deleteAllCollectionSyncs()
        }
    }
}

private const val TAG = "download-collections"

private fun encodeIds(ids: List<String>): String = JsonArray(ids.map(::JsonPrimitive)).toString()

/** The ids of a JSON array (a number as its digits); null when [json] isn't an array, logged. */
private fun decodeIds(json: String, row: String): List<String>? {
    val array = try {
        Json.parseToJsonElement(json) as? JsonArray
    } catch (e: SerializationException) {
        Log.w(TAG, e) { "$row: the stored id list doesn't decode" }
        return null
    }
    if (array == null) {
        Log.w(TAG) { "$row: the stored id list isn't an array" }
        return null
    }
    return array.map { (it as? JsonPrimitive)?.content ?: it.toString() }
}

private fun Download_collections.toModel(): StoredDownloadCollection? =
    decodeIds(member_ids, "collection $server_id/$collection_id")?.let { StoredDownloadCollection(server_id, collection_id, it) }

private fun Download_collection_syncs.toModel(): DownloadCollectionSync? =
    decodeIds(checked_ids, "refresh of $server_id")?.let { DownloadCollectionSync(synced_at, it.toSet()) }
