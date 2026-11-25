package com.edde746.plezy.data.downloads

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Download_owners
import com.edde746.plezy.data.db.Download_queue
import com.edde746.plezy.data.db.Downloaded_media
import com.edde746.plezy.data.db.SelectConnectionIdentities
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.parsePlexHomeProfileId
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexTransferScopeId
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** What [DownloadLibraryRepository.insertQueuedDownload] did. */
enum class QueueDownloadOutcome {
    /** A missing or retryable row was admitted to the queue. */
    ADMITTED,

    /** The row was queued already; only its queue policy was refreshed. */
    ALREADY_QUEUED,

    /** The row is active, paused or complete, and was left alone. */
    UNCHANGED,
}

/**
 * What [DownloadLibraryRepository.removeSharedDownloadOwnerAndRebindIncompleteMedia] did: the owner row it removed, and
 * whether another valid owner keeps the download.
 */
internal data class SharedOwnerRelease(val removedOwner: Download_owners?, val hasRemainingOwner: Boolean)

/**
 * The offline media library: one physical row per public `<serverId>:<ratingKey>` (`downloaded_media`), the profiles
 * that see it (`download_owners`) and the downloads waiting their turn (`download_queue`). Storage only: the caller
 * owns the files and the network.
 *
 * An owner row counts ("valid") when its profile is a local profile, or a Plex Home profile whose account connection
 * still exists, or when there are no local profiles at all.
 */
internal class DownloadLibraryRepository(private val db: Db) {
    // Queue admission

    /**
     * Admits a download and its queue row in one transaction. A new row is stored queued; a failed, cancelled or
     * partial one is queued again with its request and attempt state refreshed, keeping its id and the files an
     * earlier attempt stored (the caller's to reuse or delete) and, when [libraryId]/[libraryTitle] are null, the
     * library stamped before. An active, paused or complete row is left alone, including when its state moved on while
     * this ran; an already queued one gets the new queue policy only. Nothing is written when any step fails.
     */
    suspend fun insertQueuedDownload(
        serverId: String,
        clientScopeId: String? = null,
        ratingKey: String,
        globalKey: String,
        type: String,
        parentRatingKey: String? = null,
        grandparentRatingKey: String? = null,
        libraryId: String? = null,
        libraryTitle: String? = null,
        mediaIndex: Int = 0,
        mediaSourceId: String? = null,
        transcodeQuality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL,
        priority: Int = 0,
        downloadSubtitles: Boolean = true,
        downloadArtwork: Boolean = true,
    ): QueueDownloadOutcome = db.write {
        val m = q.downloadedMediaQueries
        val admitted = if (m.selectMedia(globalKey).executeAsOneOrNull() == null) {
            m.insertQueuedMedia(
                serverId, clientScopeId, ratingKey, globalKey, type, parentRatingKey, grandparentRatingKey,
                libraryId, libraryTitle, mediaIndex.toLong(), mediaSourceId, transcodeQuality.storedName,
            )
            true
        } else {
            m.requeueMedia(
                serverId, clientScopeId, ratingKey, type, parentRatingKey, grandparentRatingKey, libraryId, libraryTitle,
                mediaIndex.toLong(), mediaSourceId, transcodeQuality.storedName, globalKey,
            )
            m.changes().executeAsOne() > 0
        }
        when {
            admitted -> {
                enqueue(globalKey, priority, downloadSubtitles, downloadArtwork)
                QueueDownloadOutcome.ADMITTED
            }
            m.selectMedia(globalKey).executeAsOneOrNull()?.status == DownloadedMediaStatus.QUEUED.code -> {
                enqueue(globalKey, priority, downloadSubtitles, downloadArtwork)
                QueueDownloadOutcome.ALREADY_QUEUED
            }
            else -> QueueDownloadOutcome.UNCHANGED
        }
    }

    // Queue

    /** Queues [mediaGlobalKey], replacing its queue row (and its place in line) when it had one. */
    suspend fun addToQueue(mediaGlobalKey: String, priority: Int = 0, downloadSubtitles: Boolean = true, downloadArtwork: Boolean = true) {
        db.write { enqueue(mediaGlobalKey, priority, downloadSubtitles, downloadArtwork) }
    }

    private fun Tx.enqueue(mediaGlobalKey: String, priority: Int, downloadSubtitles: Boolean, downloadArtwork: Boolean) {
        q.downloadedMediaQueries.upsertQueue(mediaGlobalKey, priority.toLong(), now(), downloadSubtitles, downloadArtwork)
    }

    /** Sets which supplementary files [mediaGlobalKey]'s queue row still asks for. */
    suspend fun updateSupplementaryQueueIntent(mediaGlobalKey: String, downloadSubtitles: Boolean, downloadArtwork: Boolean) {
        db.write { q.downloadedMediaQueries.setQueueIntent(downloadSubtitles, downloadArtwork, mediaGlobalKey) }
    }

    /**
     * Gives every queued download without a queue row (left by earlier releases, which wrote the two apart) one with
     * the default policy, and returns how many it added. Existing queue rows keep their priority and policy.
     */
    suspend fun repairMissingQueuedDownloadEntries(): Int = db.write {
        val m = q.downloadedMediaQueries
        val queued = m.selectMediaWithStatus(listOf(DownloadedMediaStatus.QUEUED.code)).executeAsList()
        val existing = m.selectQueueKeys().executeAsList().toMutableSet()
        var repaired = 0
        for (media in queued) {
            if (!existing.add(media.global_key)) continue
            enqueue(media.global_key, 0, downloadSubtitles = true, downloadArtwork = true)
            repaired++
        }
        repaired
    }

    /**
     * The queue row of the next download to start: of queued downloads only, the highest priority, then the oldest.
     * [excludedGlobalKeys] are heads the caller couldn't resolve, so one stale row can't hold up the rest.
     */
    suspend fun getNextQueueItem(excludedGlobalKeys: Set<String> = emptySet()): Download_queue? =
        db.read { downloadedMediaQueries.selectNextQueued(excludedGlobalKeys).executeAsOneOrNull() }

    /** The queue rows of completed videos that still ask for subtitles or artwork, the oldest first. */
    suspend fun getPendingSupplementaryQueueItems(): List<Download_queue> =
        db.read { downloadedMediaQueries.selectPendingSupplementary().executeAsList() }

    /** Every queue row. */
    suspend fun getQueue(): List<Download_queue> = db.read { downloadedMediaQueries.selectAllQueue().executeAsList() }

    suspend fun removeFromQueue(mediaGlobalKey: String) {
        db.write { q.downloadedMediaQueries.deleteQueue(mediaGlobalKey) }
    }

    /**
     * Fails every queued and downloading download with [errorMessage] once the target storage is full, clearing their
     * background task ids and queue rows so the next start doesn't queue them again. Returns their keys.
     */
    suspend fun failActiveDownloadsForStorageFull(errorMessage: String): List<String> = db.write {
        val m = q.downloadedMediaQueries
        val active = m.selectMediaWithStatus(listOf(DownloadedMediaStatus.QUEUED.code, DownloadedMediaStatus.DOWNLOADING.code))
            .executeAsList()
            .map { it.global_key }
        if (active.isNotEmpty()) {
            m.failActive(errorMessage, active)
            m.deleteQueueKeys(active)
        }
        active
    }

    // Updates

    suspend fun updateDownloadStatus(globalKey: String, status: DownloadedMediaStatus) {
        db.write { q.downloadedMediaQueries.setStatus(status.code, globalKey) }
    }

    suspend fun updateDownloadMediaSource(globalKey: String, mediaSourceId: String?) {
        db.write { q.downloadedMediaQueries.setMediaSource(mediaSourceId, globalKey) }
    }

    suspend fun updateDownloadProgress(globalKey: String, progress: Int, downloadedBytes: Long, totalBytes: Long) {
        db.write { q.downloadedMediaQueries.setProgress(progress.toLong(), downloadedBytes, totalBytes, globalKey) }
    }

    /**
     * Records the stored video path. [stampDownloadedAt] sets the completion time: true for a finished download,
     * false for a path repair that mustn't move it.
     */
    suspend fun updateVideoFilePath(globalKey: String, filePath: String, stampDownloadedAt: Boolean = true) {
        db.write {
            if (stampDownloadedAt) {
                q.downloadedMediaQueries.setVideoFilePathDownloaded(filePath, now(), globalKey)
            } else {
                q.downloadedMediaQueries.setVideoFilePath(filePath, globalKey)
            }
        }
    }

    /** Starts a download stacked across `1 + additionalPartCount` files over, no file stored; 0 makes it single-file. */
    suspend fun resetDownloadParts(globalKey: String, additionalPartCount: Int) {
        db.write {
            q.downloadedMediaQueries.resetParts(encodeAdditionalPartPaths(List(additionalPartCount) { null }), globalKey)
        }
    }

    /**
     * Records the stored path of file [partIndex] (from 1) of a stacked download; [stampDownloadedAt] sets the
     * completion time, for the last file. Throws IllegalStateException when the download has no such file.
     */
    suspend fun updateAdditionalPartPath(globalKey: String, partIndex: Int, filePath: String, stampDownloadedAt: Boolean = true) {
        db.write {
            val m = q.downloadedMediaQueries
            val paths = m.selectMedia(globalKey).executeAsOneOrNull()?.additionalPartPathList?.toMutableList()
            check(paths != null && partIndex >= 1 && partIndex <= paths.size) { "Download $globalKey has no file ${partIndex + 1} to record" }
            paths[partIndex - 1] = filePath
            val json = encodeAdditionalPartPaths(paths)
            if (stampDownloadedAt) m.setAdditionalPartPathsDownloaded(json, now(), globalKey) else m.setAdditionalPartPaths(json, globalKey)
        }
    }

    /** Rewrites the stored paths of the files after the first (a path normalisation); keeps the file count. */
    suspend fun updateAdditionalPartPaths(globalKey: String, paths: List<String?>) {
        db.write { q.downloadedMediaQueries.setAdditionalPartPaths(encodeAdditionalPartPaths(paths), globalKey) }
    }

    suspend fun updateDownloadSafRoot(globalKey: String, safRootUri: String?) {
        db.write { q.downloadedMediaQueries.setSafRoot(safRootUri, globalKey) }
    }

    suspend fun countDownloadsReferencingSafRoot(safRootUri: String): Int =
        db.read { downloadedMediaQueries.countSafRootReferences(safRootUri).executeAsOne().toInt() }

    suspend fun updateArtworkPaths(globalKey: String, thumbPath: String?) {
        db.write { q.downloadedMediaQueries.setThumbPath(thumbPath, globalKey) }
    }

    suspend fun updateDownloadError(globalKey: String, errorMessage: String) {
        db.write { q.downloadedMediaQueries.recordError(errorMessage, globalKey) }
    }

    /** Counts an app retry scheduled for a failed download. */
    suspend fun countDownloadRetry(globalKey: String) {
        db.write { q.downloadedMediaQueries.countRetry(globalKey) }
    }

    suspend fun clearDownloadError(globalKey: String) {
        db.write { q.downloadedMediaQueries.clearError(globalKey) }
    }

    suspend fun updateBgTaskId(globalKey: String, taskId: String?) {
        db.write { q.downloadedMediaQueries.setBgTaskId(taskId, globalKey) }
    }

    suspend fun getBgTaskId(globalKey: String): String? = getDownloadedMedia(globalKey)?.bg_task_id

    // Lookups

    suspend fun getDownloadedMedia(globalKey: String): Downloaded_media? =
        db.read { downloadedMediaQueries.selectMedia(globalKey).executeAsOneOrNull() }

    suspend fun getAllDownloads(): List<Downloaded_media> = db.read { downloadedMediaQueries.selectAllMedia().executeAsList() }

    suspend fun getDownloadsByServerId(serverId: String): List<Downloaded_media> =
        db.read { downloadedMediaQueries.selectMediaByServer(serverId).executeAsList() }

    /**
     * The downloads of season [seasonKey], of [serverId] only when given. A [clientScopeId] keeps that scope's; with
     * [filterClientScope] and no scope, only unscoped ones.
     */
    suspend fun getEpisodesBySeason(seasonKey: String, serverId: String? = null, clientScopeId: String? = null, filterClientScope: Boolean = false) =
        db.read { downloadedMediaQueries.selectMediaByParent(seasonKey).executeAsList() }.filtered(null, serverId, clientScopeId, filterClientScope)

    /** The downloads of show [showKey], filtered as [getEpisodesBySeason]. */
    suspend fun getEpisodesByShow(showKey: String, serverId: String? = null, clientScopeId: String? = null, filterClientScope: Boolean = false) =
        db.read { downloadedMediaQueries.selectMediaByGrandparent(showKey).executeAsList() }.filtered(null, serverId, clientScopeId, filterClientScope)

    /** The downloaded tracks of album [albumKey] (tracks only, whatever else shares the key), filtered as [getEpisodesBySeason]. */
    suspend fun getTracksByAlbum(albumKey: String, serverId: String? = null, clientScopeId: String? = null, filterClientScope: Boolean = false) =
        db.read { downloadedMediaQueries.selectMediaByParent(albumKey).executeAsList() }.filtered(TRACK, serverId, clientScopeId, filterClientScope)

    /** The downloaded tracks of artist [artistKey], filtered as [getTracksByAlbum]. */
    suspend fun getTracksByArtist(artistKey: String, serverId: String? = null, clientScopeId: String? = null, filterClientScope: Boolean = false) =
        db.read { downloadedMediaQueries.selectMediaByGrandparent(artistKey).executeAsList() }.filtered(TRACK, serverId, clientScopeId, filterClientScope)

    private fun List<Downloaded_media>.filtered(type: String?, serverId: String?, clientScopeId: String?, filterClientScope: Boolean) = filter { row ->
        (type == null || row.type == type) &&
            (serverId.isNullOrBlank() || row.server_id == serverId) &&
            when {
                !clientScopeId.isNullOrEmpty() -> row.client_scope_id == clientScopeId
                filterClientScope -> row.client_scope_id.isNullOrEmpty()
                else -> true
            }
    }

    /** Whether a download other than [excludingGlobalKey] records [videoFilePath] as one of its files. */
    suspend fun isVideoFilePathRecordedByOtherDownload(videoFilePath: String, excludingGlobalKey: String): Boolean =
        db.read { downloadedMediaQueries.selectMediaRecordingPath(videoFilePath, excludingGlobalKey).executeAsList() }
            .any { videoFilePath in it.storedPartPaths }

    /**
     * Deletes the download with its queue row, owners and sync rule links in one transaction, and returns the storage
     * root it was under (the caller reconciles that root's grant).
     */
    suspend fun deleteDownload(globalKey: String): String? = db.write {
        val m = q.downloadedMediaQueries
        val safRoot = m.selectMedia(globalKey).executeAsOneOrNull()?.saf_root_uri
        m.deleteSyncRuleLinksForKey(globalKey)
        m.deleteOwnersForKey(globalKey)
        m.deleteMedia(globalKey)
        m.deleteQueue(globalKey)
        safRoot
    }

    // Owners

    /**
     * Makes [profileId] an owner of [globalKey]. A repeated claim keeps the first claim's time and fills in only the
     * metadata it brings. An empty profile id claims nothing.
     */
    suspend fun addDownloadOwner(profileId: String, globalKey: String, backendId: String? = null, clientScopeId: String? = null) {
        if (profileId.isEmpty()) return
        db.write { claim(profileId, globalKey, backendId, clientScopeId) }
    }

    private fun Tx.claim(profileId: String, globalKey: String, backendId: String?, clientScopeId: String?) {
        val m = q.downloadedMediaQueries
        if (m.selectOwner(profileId, globalKey).executeAsOneOrNull() == null) {
            m.insertOwner(profileId, globalKey, backendId, clientScopeId, now())
        } else {
            m.fillOwner(backendId, clientScopeId, profileId, globalKey)
        }
    }

    /** Removes [profileId]'s ownership of [globalKey] and its sync rules' links to it. */
    suspend fun removeDownloadOwner(profileId: String, globalKey: String) {
        db.write { unown(profileId, globalKey) }
    }

    private fun Tx.unown(profileId: String, globalKey: String) {
        q.downloadedMediaQueries.deleteSyncRuleLink(profileId, globalKey)
        q.downloadedMediaQueries.deleteOwner(profileId, globalKey)
    }

    /**
     * Removes [profileId] from a download another valid owner keeps. When the download isn't complete and carries the
     * departing owner's scope, it moves to a remaining owner's (one with a scope first, then the oldest claim). With
     * no other valid owner nothing changes, so the caller deletes the files before the final owner goes.
     */
    suspend fun removeSharedDownloadOwnerAndRebindIncompleteMedia(profileId: String, globalKey: String): SharedOwnerRelease = db.write {
        val m = q.downloadedMediaQueries
        val departing = m.selectOwner(profileId, globalKey).executeAsOneOrNull()
        val remaining = validOwners(globalKey, excludingProfileId = profileId).sortedWith(
            compareBy<Download_owners> { it.client_scope_id.isNullOrEmpty() }.thenBy { it.created_at }.thenBy { it.profile_id },
        )
        if (remaining.isEmpty()) return@write SharedOwnerRelease(null, hasRemainingOwner = false)
        if (departing != null) {
            val media = m.selectMedia(globalKey).executeAsOneOrNull()
            val departingScope = departing.client_scope_id
            if (media != null && media.status != DownloadedMediaStatus.COMPLETED.code && !departingScope.isNullOrEmpty() &&
                media.client_scope_id == departingScope
            ) {
                m.setClientScope(remaining.first().client_scope_id, globalKey)
            }
            unown(profileId, globalKey)
        }
        SharedOwnerRelease(departing, hasRemainingOwner = true)
    }

    suspend fun getDownloadOwner(profileId: String, globalKey: String): Download_owners? =
        db.read { downloadedMediaQueries.selectOwner(profileId, globalKey).executeAsOneOrNull() }

    /** Removes every owner row and sync rule link, marking every rule's links as not built yet. */
    suspend fun clearAllDownloadOwners() {
        db.write { clearOwners() }
    }

    private fun Tx.clearOwners() {
        val m = q.downloadedMediaQueries
        m.deleteAllSyncRuleLinks()
        m.resetSyncRuleLinksInitialized()
        m.deleteAllOwners()
    }

    suspend fun getDownloadOwnerKeysForProfile(profileId: String): Set<String> =
        getDownloadOwnersForProfile(profileId).mapTo(mutableSetOf()) { it.global_key }

    suspend fun getDownloadOwnersForProfile(profileId: String): List<Download_owners> {
        if (profileId.isEmpty()) return emptyList()
        return db.read { downloadedMediaQueries.selectOwnersForProfile(profileId).executeAsList() }
    }

    suspend fun getValidDownloadOwnersForKey(globalKey: String): List<Download_owners> = db.write { validOwners(globalKey, null) }

    /** Whether a valid owner sees [globalKey] through [backendId]'s client scope [clientScopeId]. */
    suspend fun hasDownloadOwnerForCacheScope(globalKey: String, backendId: String, clientScopeId: String): Boolean =
        getValidDownloadOwnersForKey(globalKey).any { it.backend == backendId && it.client_scope_id == clientScopeId }

    private fun Tx.validOwners(globalKey: String, excludingProfileId: String?): List<Download_owners> {
        val m = q.downloadedMediaQueries
        val candidates = m.selectOwnersForKey(globalKey).executeAsList()
            .filter { excludingProfileId.isNullOrEmpty() || it.profile_id != excludingProfileId }
        if (candidates.isEmpty()) return emptyList()
        val validity = ownerValidity()
        return candidates.filter { validity.isValid(it.profile_id) }
    }

    private fun Tx.ownerValidity(): OwnerValidity {
        val m = q.downloadedMediaQueries
        return OwnerValidity(m.selectLocalProfileIds().executeAsList().toSet(), m.selectConnectionIdentities().executeAsList().mapTo(mutableSetOf()) { it.id })
    }

    // Adoption and logout

    /**
     * Claims for [profileId] the downloads no valid owner keeps (rows from before profiles, or left by a logout); a
     * download a valid owner keeps stays theirs. A Plex download carrying another profile's scope is skipped; one in
     * the logout transfer scope is anyone's. A Jellyfin or Emby download is claimed only when the profile has exactly
     * one binding for that server, and then takes that binding's `<machineId>/<userId>` scope; a download carrying a
     * user scope of that server, or of a server a Jellyfin or Emby connection names, is skipped otherwise. Then the
     * profile's Plex downloads in a transfer scope move into its own scope with their pinned metadata
     * ([adoptTransferredPlexMetadata]), in the same transaction. Stops early once [isStillActive] says the profile is no
     * longer the active one.
     */
    suspend fun adoptLegacyDownloadsForProfile(profileId: String, isStillActive: (() -> Boolean)? = null) {
        if (profileId.isEmpty() || isStillActive?.invoke() == false) return
        db.write {
            val m = q.downloadedMediaQueries
            val rows = m.selectAllMedia().executeAsList()
            if (rows.isEmpty()) return@write
            val connections = m.selectConnectionIdentities().executeAsList()
            val validity = OwnerValidity(m.selectLocalProfileIds().executeAsList().toSet(), connections.mapTo(mutableSetOf()) { it.id })
            val ownedKeys = m.selectAllOwners().executeAsList().filter { validity.isValid(it.profile_id) }.mapTo(mutableSetOf()) { it.global_key }
            val kinds = connections.associate { it.id to it.kind }
            val mediaBrowser = connections.filter { it.kind == JELLYFIN || it.kind == EMBY }.associate { it.id to it.mediaBrowserIdentity() }
            val mediaBrowserMachines = mediaBrowser.values.mapTo(mutableSetOf()) { it.machineId }
            // This profile's possible user scopes per server machine.
            val scopesByMachine = mutableMapOf<String, MutableSet<Pair<String, String>>>()
            for (binding in m.selectBindings().executeAsList()) {
                if (binding.profile_id != profileId || binding.user_identifier.isEmpty()) continue
                val identity = mediaBrowser[binding.connection_id] ?: continue
                if (identity.userId != null && identity.userId != binding.user_identifier) continue
                scopesByMachine.getOrPut(identity.machineId) { mutableSetOf() }
                    .add("${identity.machineId}/${binding.user_identifier}" to identity.backend)
            }
            for (row in rows) {
                if (row.global_key in ownedKeys) continue
                if (isStillActive?.invoke() == false) return@write
                val scope = row.client_scope_id
                val plexScope = scope?.let(PlexProfileScopeId::tryParse)
                if (plexScope != null && plexScope.profileId != profileId) continue
                if (plexScope != null || scope?.let(PlexTransferScopeId::tryParse) != null) {
                    claim(profileId, row.global_key, PLEX, scope)
                    continue
                }
                val scopes = scopesByMachine[row.server_id].orEmpty()
                if (scopes.size == 1) {
                    val (adoptingScope, backend) = scopes.single()
                    m.setClientScope(adoptingScope, row.global_key)
                    claim(profileId, row.global_key, backend, adoptingScope)
                    continue
                }
                if (scope?.startsWith("${row.server_id}/") == true || row.server_id in mediaBrowserMachines) continue
                claim(profileId, row.global_key, scope?.let { kinds[it] }, scope)
            }
            if (isStillActive?.invoke() == false) return@write
            adoptTransferredPlexMetadata(profileId)
        }
    }

    /**
     * Moves [profileId]'s Plex downloads that sit in their server's transfer scope (by their own scope or the owner
     * row's) into the profile's own scope ([PlexProfileScopeId]): the pinned metadata of the item, its parent and its
     * grandparent is copied there, the download and the owner row take that scope, and the transfer copies go.
     */
    private fun Tx.adoptTransferredPlexMetadata(profileId: String) {
        val m = q.downloadedMediaQueries
        for (owner in m.selectOwnersForProfile(profileId).executeAsList()) {
            val row = m.selectMedia(owner.global_key).executeAsOneOrNull() ?: continue
            val transfer = row.client_scope_id?.let(PlexTransferScopeId::tryParse)
                ?: owner.client_scope_id?.let(PlexTransferScopeId::tryParse)
                ?: continue
            if (transfer.publicServerId.value != row.server_id) continue
            val destination = PlexProfileScopeId.of(ServerId(row.server_id), profileId).value
            val ids = row.offlineMetadataIds()
            ids.forEach { copyPinnedMetadata(transfer.value, destination, it, stripProfileState = false) }
            m.setClientScope(destination, row.global_key)
            m.setOwnerScope(PLEX, destination, profileId, row.global_key)
            m.deleteCacheKeys(ids.flatMap { metadataCacheKeys(transfer.value, it) })
        }
    }

    /**
     * Keeps the downloads through a full logout while detaching them from the profiles about to go, in one
     * transaction. Each Plex download moves to its server's transfer scope ([PlexTransferScopeId]) with the pinned
     * metadata of the item, its parent and its grandparent, copied from the first of its owners' (and its own) Plex
     * profile scopes that has it, without the profile-private fields ([sanitizePlexMetadataForOwnerlessTransfer]); every
     * Plex profile's copy of that metadata on the server goes. The next profile to sign in adopts the downloads
     * ([adoptLegacyDownloadsForProfile]). Then every owner row and sync rule link is removed. A download counts as Plex
     * when its scope or an owner's is a Plex one, an owner claimed it through Plex, or a Plex connection is or lists its
     * server.
     */
    suspend fun detachDownloadsForLogout() {
        db.write {
            transferPlexDownloads { false }
            clearOwners()
        }
    }

    /**
     * The Plex half of [detachDownloadsForLogout] on its own, owners kept: every Plex download moves to its server's
     * transfer scope with its sanitized metadata. [isPlexServer] names further servers known to be Plex (a live client).
     */
    suspend fun preparePlexMetadataForLogoutTransfer(isPlexServer: (String) -> Boolean) {
        db.write { transferPlexDownloads(isPlexServer) }
    }

    /** Moves [profileId]'s Plex downloads in a transfer scope into its own scope ([adoptLegacyDownloadsForProfile]'s last step). */
    suspend fun adoptTransferredPlexMetadataForProfile(profileId: String, isStillActive: (() -> Boolean)? = null) {
        if (profileId.isEmpty() || isStillActive?.invoke() == false) return
        db.write { adoptTransferredPlexMetadata(profileId) }
    }

    private fun Tx.transferPlexDownloads(isPlexServer: (String) -> Boolean) {
        val m = q.downloadedMediaQueries
        val connections = m.selectConnectionIdentities().executeAsList()
        val validity = OwnerValidity(m.selectLocalProfileIds().executeAsList().toSet(), connections.mapTo(mutableSetOf()) { it.id })
        // A Plex connection serves the server named by its id, and every server its account lists.
        val plexServers = connections.filter { it.kind == PLEX }.flatMapTo(mutableSetOf()) { it.plexServerIds() + it.id }
        for (row in m.selectAllMedia().executeAsList()) {
            val owners = m.selectOwnersForKey(row.global_key).executeAsList().filter { validity.isValid(it.profile_id) }
            val rowScope = row.client_scope_id?.let(PlexProfileScopeId::tryParse)
            val isPlex = rowScope != null ||
                row.client_scope_id?.let(PlexTransferScopeId::tryParse) != null ||
                owners.any { it.backend == PLEX || it.client_scope_id?.let(PlexProfileScopeId::tryParse) != null } ||
                row.server_id in plexServers || isPlexServer(row.server_id)
            if (!isPlex) continue
            val server = ServerId(row.server_id)
            val sources = linkedSetOf<String>()
            for (owner in owners) {
                owner.client_scope_id?.let(PlexProfileScopeId::tryParse)?.takeIf { it.publicServerId == server }?.let { sources.add(it.value) }
                if (owner.profile_id.isNotEmpty()) sources.add(PlexProfileScopeId.of(server, owner.profile_id).value)
            }
            if (rowScope != null && rowScope.publicServerId == server) sources.add(rowScope.value)
            val transfer = PlexTransferScopeId.of(server).value
            val ids = row.offlineMetadataIds()
            for (id in ids) {
                sources.any { copyPinnedMetadata(it, transfer, id, stripProfileState = true) }
            }
            m.setClientScope(transfer, row.global_key)
            deleteAllProfileMetadata(row.server_id, ids)
        }
    }

    /**
     * The kind (`plex`, `jellyfin`, `emby`) of the saved connection serving [serverId] while no client is live: the
     * connection with that id, else a Plex account listing the server, else the first MediaBrowser user connection of
     * that machine by id. Null when none does.
     */
    suspend fun connectionKindForServer(serverId: String): String? = db.read {
        val connections = downloadedMediaQueries.selectConnectionIdentities().executeAsList()
        connections.firstOrNull { it.id == serverId }?.kind
            ?: connections.firstOrNull { it.kind == PLEX && serverId in it.plexServerIds() }?.kind
            ?: connections.filter { (it.kind == JELLYFIN || it.kind == EMBY) && it.id.startsWith("$serverId/") }.minByOrNull { it.id }?.kind
    }

    /**
     * Copies the cached metadata of [ratingKey] from client scope [source] to [destination], pinned there, without its
     * profile-private fields when [stripProfileState]. False when [source] has none (or, stripping, none that reads).
     */
    private fun Tx.copyPinnedMetadata(source: String, destination: String, ratingKey: String, stripProfileState: Boolean): Boolean {
        val m = q.downloadedMediaQueries
        val endpoint = "$METADATA_PATH$ratingKey"
        val cached = m.selectCacheData("$source:$endpoint").executeAsOneOrNull() ?: return false
        val payload = if (stripProfileState) sanitizePlexMetadataForOwnerlessTransfer(cached) ?: return false else cached
        m.putPinnedCache("$destination:$endpoint", payload, now())
        return true
    }

    /** Deletes every Plex profile's pinned metadata (and children) of [ratingKeys] on public server [serverId]. */
    private fun Tx.deleteAllProfileMetadata(serverId: String, ratingKeys: Collection<String>) {
        val m = q.downloadedMediaQueries
        val scopes = m.selectPinnedMetadataCacheKeys().executeAsList().mapNotNull { key ->
            val separator = key.indexOf(':')
            if (separator < 0) return@mapNotNull null
            val id = key.substring(separator + 1).removePrefix(METADATA_PATH)
            if (id !in ratingKeys || key.substring(separator + 1) != "$METADATA_PATH$id") return@mapNotNull null
            val scope = PlexProfileScopeId.tryParse(key.substring(0, separator)) ?: return@mapNotNull null
            if (scope.publicServerId.value != serverId) null else scope.value to id
        }
        if (scopes.isNotEmpty()) m.deleteCacheKeys(scopes.flatMap { (scope, id) -> metadataCacheKeys(scope, id) })
    }

    /** The ids whose metadata a download needs offline: its own, its parent's and its grandparent's. */
    private fun Downloaded_media.offlineMetadataIds(): Set<String> = listOfNotNull(rating_key, parent_rating_key, grandparent_rating_key).toCollection(LinkedHashSet())

    /** The cache keys of [ratingKey]'s metadata and children in client scope [scope]. */
    private fun metadataCacheKeys(scope: String, ratingKey: String): List<String> =
        listOf("$scope:$METADATA_PATH$ratingKey", "$scope:$METADATA_PATH$ratingKey/children")

    private class OwnerValidity(private val localProfileIds: Set<String>, private val connectionIds: Set<String>) {
        fun isValid(profileId: String): Boolean {
            if (profileId in localProfileIds) return true
            val account = parsePlexHomeProfileId(profileId)?.accountConnectionId
            if (account != null) return account in connectionIds
            return localProfileIds.isEmpty()
        }
    }

    private data class MediaBrowserIdentity(val machineId: String, val userId: String?, val backend: String)

    /** The server machine and user of a Jellyfin or Emby connection: from its config, else from its `<machineId>/<userId>` id. */
    private fun SelectConnectionIdentities.mediaBrowserIdentity(): MediaBrowserIdentity {
        val separator = id.indexOf('/')
        var machineId = if (separator < 0) id else id.substring(0, separator)
        var userId = if (separator < 0 || separator == id.length - 1) null else id.substring(separator + 1)
        val config = config()
        (config?.get("serverMachineId") as? JsonPrimitive)?.takeIf { it.isString && it.content.isNotEmpty() }?.let { machineId = it.content }
        (config?.get("userId") as? JsonPrimitive)?.takeIf { it.isString && it.content.isNotEmpty() }?.let { userId = it.content }
        return MediaBrowserIdentity(machineId, userId, kind)
    }

    /** The client identifiers of the servers a Plex connection lists. */
    private fun SelectConnectionIdentities.plexServerIds(): List<String> {
        val servers = config()?.get("servers") ?: return emptyList()
        return (servers as? JsonArray).orEmpty().mapNotNull { server ->
            ((server as? JsonObject)?.get("clientIdentifier") as? JsonPrimitive)?.takeIf { it.isString }?.content
        }
    }

    private fun SelectConnectionIdentities.config(): JsonObject? = try {
        Json.parseToJsonElement(config_json) as? JsonObject
    } catch (e: SerializationException) {
        // A connection whose config doesn't read still names its machine and user in its id.
        null
    }

    private companion object {
        const val TRACK = "track"
        const val PLEX = "plex"
        const val JELLYFIN = "jellyfin"
        const val EMBY = "emby"
        const val METADATA_PATH = "/library/metadata/"
    }
}
