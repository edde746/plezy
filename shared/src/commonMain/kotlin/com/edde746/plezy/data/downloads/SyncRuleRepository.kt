package com.edde746.plezy.data.downloads

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Sync_rules
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.buildProfileScopedKey

/** What a sync rule keeps downloaded. */
enum class SyncRuleTarget(val id: String) {
    /** The next unwatched (or all) episodes of a show. */
    SHOW("show"),
    SEASON("season"),
    /** Mirrors a collection's items. */
    COLLECTION("collection"),
    PLAYLIST("playlist"),
    ;

    companion object {
        fun fromId(id: String): SyncRuleTarget =
            entries.firstOrNull { it.id == id } ?: throw IllegalArgumentException("Unknown sync rule target '$id'")
    }
}

/** Which episodes a show or season rule counts. */
enum class SyncRuleFilter(val id: String) {
    UNWATCHED("unwatched"),
    ALL("all"),
    ;

    companion object {
        fun fromId(id: String): SyncRuleFilter =
            entries.firstOrNull { it.id == id } ?: throw IllegalArgumentException("Unknown sync rule filter '$id'")
    }
}

/** A profile's auto-download rule. */
data class SyncRule(
    val id: Long,
    /** Empty on rules from before profiles, until a profile adopts them. */
    val profileId: String,
    val serverId: String,
    val ratingKey: String,
    /** [syncRuleKey] of the profile and item. */
    val globalKey: String,
    val target: SyncRuleTarget,
    /** How many episodes a show or season rule keeps downloaded. */
    val episodeCount: Int,
    val enabled: Boolean,
    /** Epoch milliseconds. */
    val createdAt: Long,
    /** When the rule last ran to completion, epoch milliseconds. */
    val lastExecutedAt: Long?,
    val mediaIndex: Int,
    val downloadFilter: SyncRuleFilter,
    val includeSpecials: Boolean,
    /** Whether [SyncRuleRepository.linkDownload] has recorded the downloads the rule covers. */
    val downloadLinksInitialized: Boolean,
    /** The quality the rule's downloads take: the original files, or a server transcode. */
    val transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
)

/**
 * A sync rule's key: `"{profileId}|{serverId}:{ratingKey}"`, so profiles keep separate rules for one item; the public
 * `"{serverId}:{ratingKey}"` for an empty profile id (rules from before profiles).
 */
fun syncRuleKey(profileId: String, serverId: ServerId, ratingKey: String): String =
    if (profileId.isEmpty()) buildGlobalKey(serverId, ratingKey) else buildProfileScopedKey(profileId, serverId, ratingKey)

/**
 * Each profile's auto-download rules ([SyncRule]), and the downloads each covered, so removing a rule removes only the
 * downloads no other rule of the profile covers ([exclusiveDownloadKeys]).
 */
class SyncRuleRepository internal constructor(private val db: Db) {
    /** Every rule, or [profileId]'s, in creation order. */
    suspend fun rules(profileId: String? = null): List<SyncRule> = db.read {
        if (profileId == null) syncRuleQueries.selectAll().executeAsList() else syncRuleQueries.selectForProfile(profileId).executeAsList()
    }.map { it.toModel() }

    suspend fun rule(globalKey: String): SyncRule? =
        db.read { syncRuleQueries.selectByKey(globalKey).executeAsOneOrNull() }?.toModel()

    /**
     * Creates the profile's rule for the item ([syncRuleKey]), or updates the existing one's target and options. An
     * update keeps whether the rule is enabled, when it last ran and its download links.
     */
    suspend fun upsert(
        profileId: String,
        serverId: ServerId,
        ratingKey: String,
        target: SyncRuleTarget,
        episodeCount: Int,
        mediaIndex: Int = 0,
        downloadFilter: SyncRuleFilter = SyncRuleFilter.UNWATCHED,
        includeSpecials: Boolean = true,
        transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
    ): SyncRule {
        val globalKey = syncRuleKey(profileId, serverId, ratingKey)
        return db.write {
            val queries = q.syncRuleQueries
            if (queries.selectByKey(globalKey).executeAsOneOrNull() == null) {
                queries.insertRule(
                    profileId, serverId.value, ratingKey, globalKey, target.id, episodeCount.toLong(), now(), mediaIndex.toLong(),
                    downloadFilter.id, includeSpecials, transcodeQuality.storedName,
                )
            } else {
                queries.updateRuleTarget(
                    profileId, serverId.value, ratingKey, target.id, episodeCount.toLong(), mediaIndex.toLong(), downloadFilter.id,
                    includeSpecials, transcodeQuality.storedName, globalKey,
                )
            }
            queries.selectByKey(globalKey).executeAsOne().toModel()
        }
    }

    suspend fun setEnabled(globalKey: String, enabled: Boolean) {
        db.write { q.syncRuleQueries.setEnabled(enabled, globalKey) }
    }

    /**
     * Changes the given options of [expected], leaving the rest (and when it last ran) as they are now, and returns the
     * rule. Throws [IllegalStateException] when the rule is gone or was deleted and created again since [expected] was
     * read.
     */
    suspend fun updateOptions(
        expected: SyncRule,
        episodeCount: Int? = null,
        downloadFilter: SyncRuleFilter? = null,
        enabled: Boolean? = null,
        includeSpecials: Boolean? = null,
        mediaIndex: Int? = null,
    ): SyncRule = db.write {
        val queries = q.syncRuleQueries
        val current = queries.selectByKey(expected.globalKey).executeAsOneOrNull()
        check(current != null && current.id == expected.id && current.profile_id == expected.profileId) { "Sync rule no longer exists" }
        queries.updateOptions(
            episodeCount?.toLong() ?: current.episode_count,
            downloadFilter?.id ?: current.download_filter,
            enabled ?: current.enabled,
            includeSpecials ?: current.include_specials,
            mediaIndex?.toLong() ?: current.media_index,
            current.id,
        )
        queries.selectByKey(expected.globalKey).executeAsOne().toModel()
    }

    /** Records that the rule ran to completion now; its download links are recorded too. */
    suspend fun completeExecution(globalKey: String) {
        db.write { q.syncRuleQueries.completeExecution(now(), globalKey) }
    }

    suspend fun markDownloadLinksInitialized(globalKey: String) {
        db.write { q.syncRuleQueries.markLinksInitialized(globalKey) }
    }

    /**
     * The profile's rules on [serverId] whose download links must be refreshed before cleanup: collection and playlist
     * rules not linked yet, and every show and season rule (their links follow the downloads' parents).
     */
    suspend fun rulesNeedingLinks(profileId: String, serverId: ServerId): List<SyncRule> =
        db.read { syncRuleQueries.selectNeedingLinks(profileId, serverId.value).executeAsList() }.map { it.toModel() }

    /** Records that [rule] covers the download [downloadGlobalKey]. */
    suspend fun linkDownload(rule: SyncRule, downloadGlobalKey: String) {
        db.write { q.syncRuleQueries.linkDownload(rule.id, rule.profileId, downloadGlobalKey) }
    }

    /**
     * The profile's queued, downloading, paused or completed downloads on [serverId] under the item [ratingKey]: those
     * whose parent it is, or with [matchGrandparent] also those whose grandparent it is (a show's episodes).
     */
    suspend fun ownedDownloadKeysUnder(profileId: String, serverId: ServerId, ratingKey: String, matchGrandparent: Boolean): List<String> =
        db.read {
            if (matchGrandparent) {
                syncRuleQueries.selectOwnedKeysUnderAncestor(profileId, serverId.value, ratingKey).executeAsList()
            } else {
                syncRuleQueries.selectOwnedKeysUnderParent(profileId, serverId.value, ratingKey).executeAsList()
            }
        }

    /**
     * The downloads [rule] covers that no other rule of its profile covers: what removing the rule may remove. Another
     * profile's rules don't count; that profile's ownership of the download keeps it.
     */
    suspend fun exclusiveDownloadKeys(rule: SyncRule): List<String> = db.read {
        val keys = syncRuleQueries.selectLinkedKeys(rule.id).executeAsList()
        if (keys.isEmpty()) return@read emptyList()
        val linkCounts = syncRuleQueries.selectLinksForKeys(rule.profileId, keys).executeAsList().groupingBy { it }.eachCount()
        keys.filter { linkCounts[it] == 1 }
    }

    /**
     * Gives [profileId] the rules made before profiles (an empty profile id, the public key): each moves to the
     * profile's key with its download links, or goes when the profile already has a rule for its item. An empty id does
     * nothing.
     */
    suspend fun adoptLegacyRulesForProfile(profileId: String) {
        if (profileId.isEmpty()) return
        db.write {
            val queries = q.syncRuleQueries
            for (rule in queries.selectForProfile("").executeAsList()) {
                val scopedKey = buildProfileScopedKey(profileId, ServerId(rule.server_id), rule.rating_key)
                if (queries.selectByKey(scopedKey).executeAsOneOrNull() != null) {
                    queries.deleteById(rule.id)
                    continue
                }
                queries.adoptRule(profileId, scopedKey, rule.id)
                queries.adoptRuleDownloads(profileId, rule.id)
            }
        }
    }

    /** Deletes the rule and its download links. */
    suspend fun delete(globalKey: String) {
        db.write { q.syncRuleQueries.deleteByKey(globalKey) }
    }

    /** Drops a removed profile's rules. */
    suspend fun deleteForProfile(profileId: String) {
        db.write { q.syncRuleQueries.deleteForProfile(profileId) }
    }

    /** Drops every rule (a full sign-out). */
    suspend fun clearAll() {
        db.write { q.syncRuleQueries.deleteAll() }
    }
}

private fun Sync_rules.toModel() = SyncRule(
    id = id,
    profileId = profile_id,
    serverId = server_id,
    ratingKey = rating_key,
    globalKey = global_key,
    target = SyncRuleTarget.fromId(target_type),
    episodeCount = episode_count.toInt(),
    enabled = enabled,
    createdAt = created_at,
    lastExecutedAt = last_executed_at,
    mediaIndex = media_index.toInt(),
    downloadFilter = SyncRuleFilter.fromId(download_filter),
    includeSpecials = include_specials,
    downloadLinksInitialized = download_links_initialized,
    transcodeQuality = storedTranscodeQuality(transcode_quality),
)

/** How a download's or rule's quality is stored: the preset's name, null for the original file. */
internal val TranscodeQualityPreset.storedName: String? get() = name.takeUnless { isOriginal }

/** The quality stored as [name] ([storedName]); an unknown name throws. */
internal fun storedTranscodeQuality(name: String?): TranscodeQualityPreset = name?.let(TranscodeQualityPreset::valueOf) ?: TranscodeQualityPreset.ORIGINAL
