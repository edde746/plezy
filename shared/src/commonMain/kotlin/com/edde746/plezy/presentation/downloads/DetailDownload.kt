package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.downloads.CellularDownloadBlockedException
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.strings.T

/** The detail download button's symbol; each UI maps it to its icon. [DOWNLOADED]: the whole item is on the device. */
enum class DownloadButtonIcon { SPINNER, QUEUED, PROGRESS, PAUSED, FAILED, CANCELLED, SYNC, SYNC_DISABLED, PARTIAL, DOWNLOAD, DOWNLOADED }

/** The button's tint. */
enum class DownloadButtonTint { NONE, AMBER, RED, GREY, TEAL, ORANGE }

/**
 * What the detail download button shows. [interactive] is false while the downloads own the item (queueing, queued,
 * downloading). [progress] (0–1) goes with [DownloadButtonIcon.PROGRESS].
 */
data class DownloadButtonSpec(
    val icon: DownloadButtonIcon,
    val tooltip: String?,
    val tint: DownloadButtonTint = DownloadButtonTint.NONE,
    val interactive: Boolean = true,
    val progress: Float? = null,
)

/** The sync rule key of [item] for the active profile, or its global key when it has no server. */
fun DownloadsController.syncRuleKeyOf(item: MediaItem): String =
    ServerId.tryParse(item.serverId)?.let { syncRuleKeyFor(it, item.id) } ?: item.globalKey

/** Whether a detail screen shows the download button: never offline, never where downloads aren't supported (tvOS). */
fun detailDownloadVisible(offline: Boolean, downloadsSupported: Boolean): Boolean = !offline && downloadsSupported

/**
 * The detail download button for [item], in precedence order: queueing (a spinner), queued, downloading (a ring),
 * paused, failed, cancelled, partial, downloaded, not downloaded. A sync rule shows its own symbol once the item is
 * partial or complete.
 */
fun downloadButtonSpec(controller: DownloadsController, item: MediaItem): DownloadButtonSpec {
    val globalKey = item.globalKey
    val ruleKey = controller.syncRuleKeyOf(item)
    val progress = controller.getProgress(globalKey)
    val currentFile = progress?.currentFile
    val episodeFiles = currentFile?.takeIf { "episodes" in it }

    if (controller.isQueueing(globalKey)) return DownloadButtonSpec(DownloadButtonIcon.SPINNER, null, interactive = false)

    fun syncRuleSpec(complete: Boolean): DownloadButtonSpec {
        val rule = controller.getSyncRule(ruleKey)
        val enabled = rule?.enabled ?: true
        val keep = T.downloads.keepNUnwatched(count = rule?.episodeCount?.toString() ?: "?")
        val tooltip = when {
            complete -> keep
            currentFile != null -> T.downloads.syncingFile(file = currentFile, status = keep)
            else -> T.downloads.keepSynced
        }
        return DownloadButtonSpec(
            if (enabled) DownloadButtonIcon.SYNC else DownloadButtonIcon.SYNC_DISABLED,
            tooltip,
            if (enabled) DownloadButtonTint.TEAL else DownloadButtonTint.GREY,
        )
    }

    return when (progress?.status) {
        DownloadedMediaStatus.QUEUED -> DownloadButtonSpec(
            DownloadButtonIcon.QUEUED,
            episodeFiles?.let { T.downloads.queuedFilesTooltip(files = it) } ?: T.downloads.queuedTooltip,
            interactive = false,
        )
        DownloadedMediaStatus.DOWNLOADING -> DownloadButtonSpec(
            DownloadButtonIcon.PROGRESS,
            episodeFiles?.let { T.downloads.downloadingFilesTooltip(files = it) } ?: T.downloads.downloadingTooltip,
            interactive = false,
            progress = progress.progressPercent.toFloat(),
        )
        DownloadedMediaStatus.PAUSED -> DownloadButtonSpec(DownloadButtonIcon.PAUSED, T.downloads.resumeDownload, DownloadButtonTint.AMBER)
        DownloadedMediaStatus.FAILED -> DownloadButtonSpec(DownloadButtonIcon.FAILED, T.downloads.retryDownload, DownloadButtonTint.RED)
        DownloadedMediaStatus.CANCELLED -> DownloadButtonSpec(DownloadButtonIcon.CANCELLED, T.downloads.cancelledDownload, DownloadButtonTint.GREY)
        DownloadedMediaStatus.PARTIAL -> if (controller.hasSyncRule(ruleKey)) {
            syncRuleSpec(complete = false)
        } else {
            DownloadButtonSpec(
                DownloadButtonIcon.PARTIAL,
                currentFile?.let { T.downloads.downloadedFileClickToComplete(file = it) } ?: T.downloads.partialDownloadClickToComplete,
                DownloadButtonTint.ORANGE,
            )
        }
        DownloadedMediaStatus.COMPLETED -> if (controller.hasSyncRule(ruleKey)) {
            syncRuleSpec(complete = true)
        } else {
            DownloadButtonSpec(
                DownloadButtonIcon.DOWNLOADED,
                if (item.isShow || item.isSeason) T.downloads.manage else T.downloads.deleteDownload,
                DownloadButtonTint.ORANGE,
            )
        }
        null -> DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, T.downloads.downloadNow)
    }
}

/**
 * What a press of the detail download button does, per [downloadButtonSpec]'s state:
 * - paused: resumes ("Download resumed");
 * - failed: the pre-flight, the version picker, then the download again;
 * - cancelled: asks to delete it or retry;
 * - partial: a sync rule's actions, else queues only the missing episodes (an album's or artist's missing tracks);
 * - downloaded: a sync rule's actions; a show or season offers more episodes or Delete; else asks to delete it;
 * - not downloaded: the download flow ([DownloadActions.queueDownloadWithFeedback]).
 *
 * Returns the feedback to show, or null when there is none.
 */
class DetailDownload(
    private val controller: DownloadsController,
    private val actions: DownloadActions,
    private val dialogs: DownloadDialogs,
    private val warning: BackgroundDownloadWarning,
    private val deletion: SmartDeletion,
) {
    suspend fun press(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>? = null): DownloadFeedback? {
        val globalKey = item.globalKey
        val ruleKey = controller.syncRuleKeyOf(item)
        val status = controller.getProgress(globalKey)?.status
        if (controller.isQueueing(globalKey) || status == DownloadedMediaStatus.QUEUED || status == DownloadedMediaStatus.DOWNLOADING) return null

        return when (status) {
            DownloadedMediaStatus.PAUSED -> {
                controller.resumeDownload(globalKey, client)
                DownloadFeedback(T.downloads.downloadResumed, isError = false)
            }
            DownloadedMediaStatus.FAILED -> retry(item, client, fallbackVersions)
            DownloadedMediaStatus.CANCELLED -> {
                // Dismissing it deletes too: retrying is the only choice that keeps the download.
                val retrying = dialogs.confirm(
                    DownloadDialog.Confirm(
                        T.downloads.cancelledDownloadTitle,
                        T.downloads.cancelledDownloadMessage,
                        confirmLabel = T.common.retry,
                        cancelLabel = T.common.delete,
                    ),
                ) != null
                if (retrying) {
                    retry(item, client, fallbackVersions)
                } else {
                    deletion.deleteWithProgress(globalKey)
                    DownloadFeedback(T.downloads.downloadDeleted, isError = false)
                }
            }
            DownloadedMediaStatus.PARTIAL -> {
                if (controller.hasSyncRule(ruleKey)) return syncRuleActions(item, ruleKey)
                // An album or artist queues itself again: the tracks the profile has are skipped, the rest queue.
                if (!(item.isShow || item.isSeason)) return actions.queueDownloadWithFeedback(item, client)
                if (!warning.confirmBeforeDownload()) return null
                val versionConfig = actions.resolveDownloadVersion(item, client, fallbackVersions) ?: return null
                val count = controller.queueMissingEpisodes(item, client, versionConfig)
                DownloadFeedback(
                    if (count > 0) T.downloads.episodesQueued(count = count.toString()) else T.downloads.allEpisodesAlreadyDownloaded,
                    isError = false,
                )
            }
            DownloadedMediaStatus.COMPLETED -> {
                if (controller.hasSyncRule(ruleKey)) return syncRuleActions(item, ruleKey)
                var deleted: DownloadFeedback? = null
                val confirmAndDelete: suspend () -> Unit = { deleted = confirmAndDelete(item) }
                if (!(item.isShow || item.isSeason)) {
                    confirmAndDelete()
                    return deleted
                }
                actions.queueDownloadWithFeedback(item, client, onDelete = confirmAndDelete) ?: deleted
            }
            null -> actions.queueDownloadWithFeedback(item, client)
        }
    }

    private suspend fun retry(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>?): DownloadFeedback? {
        // A failure is the likeliest moment for a background restriction to be the cause: check before trying again.
        if (!warning.confirmBeforeDownload()) return null
        val versionConfig = actions.resolveDownloadVersion(item, client, fallbackVersions) ?: return null
        controller.deleteDownload(item.globalKey)
        return try {
            controller.queueDownload(item, client, versionConfig)
            DownloadFeedback(T.downloads.downloadQueued, isError = false)
        } catch (_: CellularDownloadBlockedException) {
            DownloadFeedback(T.settings.cellularDownloadBlocked, isError = true)
        }
    }

    /**
     * Runs a context-menu [entry] of [item] ([itemDownloadMenuEntries], [listDownloadMenuEntries]); [listItems] fetches
     * a collection's or playlist's items for its download entry. The download entries need [client] (nothing happens
     * without it); the sync rule and delete entries don't. A Downloads screen folder's own entries go to
     * [DownloadsStore.performFolder]. Returns the feedback to show, or null when there is none.
     */
    suspend fun perform(
        item: MediaItem,
        entry: DownloadMenuEntry,
        client: MediaBackend?,
        listItems: (suspend () -> List<MediaItem>)? = null,
    ): DownloadFeedback? {
        val ruleKey = controller.syncRuleKeyOf(item)
        return when (entry) {
            DownloadMenuEntry.DOWNLOAD -> {
                if (client == null || !warning.confirmBeforeDownload()) return null
                actions.queueDownloadWithFeedback(item, client)
            }
            DownloadMenuEntry.DOWNLOAD_COLLECTION, DownloadMenuEntry.DOWNLOAD_PLAYLIST -> {
                val fetch = listItems ?: return null
                if (client == null || !warning.confirmBeforeDownload()) return null
                val target = if (entry == DownloadMenuEntry.DOWNLOAD_PLAYLIST) SyncRuleTarget.PLAYLIST else SyncRuleTarget.COLLECTION
                actions.fetchAndQueueListDownload(item, target, client, fetch)
            }
            DownloadMenuEntry.MANAGE_SYNC -> actions.manageSyncRule(ruleKey, item.displayTitle)
            DownloadMenuEntry.REMOVE_SYNC -> actions.confirmAndRemoveSyncRule(ruleKey, item.displayTitle)
            DownloadMenuEntry.DELETE_DOWNLOAD -> confirmAndDelete(item)
            DownloadMenuEntry.MARK_WATCHED, DownloadMenuEntry.MARK_UNWATCHED, DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS -> null
        }
    }

    private suspend fun confirmAndDelete(item: MediaItem): DownloadFeedback? {
        dialogs.confirm(
            DownloadDialog.Confirm(T.downloads.deleteDownload, T.downloads.deleteConfirm(title = item.displayTitle), T.common.delete, destructive = true),
        ) ?: return null
        deletion.deleteWithProgress(item.globalKey)
        return DownloadFeedback(T.downloads.downloadDeleted, isError = false)
    }

    /** A synced item's actions: edit the rule, remove it, or delete the download (and the rule). */
    private suspend fun syncRuleActions(item: MediaItem, ruleKey: String): DownloadFeedback? {
        controller.getSyncRule(ruleKey) ?: return null
        val (index, _) = dialogs.pickOption(
            DownloadDialog.Options(
                T.downloads.manageSyncRule,
                listOf(
                    DownloadDialogOption(T.downloads.editSyncRule, DownloadDialogIcon.CUSTOM),
                    DownloadDialogOption(T.downloads.removeSyncRule, DownloadDialogIcon.SYNC),
                    DownloadDialogOption(T.downloads.deleteDownload, DownloadDialogIcon.DELETE),
                ),
            ),
        ) ?: return null
        return when (index) {
            0 -> actions.manageSyncRule(ruleKey, item.displayTitle)
            1 -> actions.confirmAndRemoveSyncRule(ruleKey, item.displayTitle)
            else -> {
                dialogs.confirm(
                    DownloadDialog.Confirm(T.downloads.deleteDownload, T.downloads.deleteConfirm(title = item.displayTitle), T.common.delete, destructive = true),
                ) ?: return null
                controller.deleteSyncRule(ruleKey)
                deletion.deleteWithProgress(item.globalKey)
                DownloadFeedback(T.downloads.downloadDeleted, isError = false)
            }
        }
    }
}

/** A download entry of an item's context menu; [destructive] ones draw as such. */
enum class DownloadMenuEntry(val id: String, val destructive: Boolean = false) {
    DOWNLOAD("download"),
    DOWNLOAD_COLLECTION("download_collection"),
    DOWNLOAD_PLAYLIST("download_playlist"),
    MANAGE_SYNC("manage_sync"),
    REMOVE_SYNC("remove_sync"),
    DELETE_DOWNLOAD("delete_download", destructive = true),
    MARK_WATCHED("watch"),
    MARK_UNWATCHED("unwatch"),
    DELETE_FOLDER_DOWNLOADS("delete_folder_downloads", destructive = true),
    ;

    val label: String
        get() = when (this) {
            DOWNLOAD, DOWNLOAD_COLLECTION, DOWNLOAD_PLAYLIST -> T.downloads.downloadNow
            MANAGE_SYNC -> T.downloads.manageSyncRule
            REMOVE_SYNC -> T.downloads.removeSyncRule
            DELETE_DOWNLOAD -> T.downloads.deleteDownload
            MARK_WATCHED -> T.mediaMenu.markAsWatched
            MARK_UNWATCHED -> T.mediaMenu.markAsUnwatched
            DELETE_FOLDER_DOWNLOADS -> T.downloads.deleteCollectionDownloads
        }
}

/**
 * The sync and download entries of a context menu: with a sync rule, manage and remove it (and delete the download
 * when any file exists); with a download only, delete it; otherwise [download].
 */
fun syncDownloadMenuEntries(hasSyncRule: Boolean, hasAnyDownload: Boolean, download: DownloadMenuEntry): List<DownloadMenuEntry> = when {
    hasSyncRule -> listOfNotNull(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC, DownloadMenuEntry.DELETE_DOWNLOAD.takeIf { hasAnyDownload })
    hasAnyDownload -> listOf(DownloadMenuEntry.DELETE_DOWNLOAD)
    else -> listOf(download)
}

/**
 * The download entries of [item]'s context menu: movies, episodes, shows, seasons, albums and tracks (not artists,
 * whose whole discography is too large for one tap); none where downloads aren't supported.
 */
fun itemDownloadMenuEntries(controller: DownloadsController, item: MediaItem): List<DownloadMenuEntry> {
    if (!controller.syncRulesSupported) return emptyList()
    if (!(item.isVideoContent || item.kind == MediaKind.ALBUM || item.kind == MediaKind.TRACK)) return emptyList()
    return syncDownloadMenuEntries(
        hasSyncRule = controller.hasSyncRule(controller.syncRuleKeyOf(item)),
        hasAnyDownload = controller.getProgress(item.globalKey) != null,
        download = DownloadMenuEntry.DOWNLOAD,
    )
}

/** The download entries of a collection's or playlist's context menu ([playlist] for a video or audio playlist). */
fun listDownloadMenuEntries(controller: DownloadsController, list: MediaItem, playlist: Boolean): List<DownloadMenuEntry> {
    if (!controller.syncRulesSupported) return emptyList()
    return syncDownloadMenuEntries(
        hasSyncRule = controller.hasSyncRule(controller.syncRuleKeyOf(list)),
        hasAnyDownload = false,
        download = if (playlist) DownloadMenuEntry.DOWNLOAD_PLAYLIST else DownloadMenuEntry.DOWNLOAD_COLLECTION,
    )
}

/** A Downloads screen collection folder's menu: mark watched or unwatched by its titles' state, and delete its downloads. */
fun downloadsFolderMenuEntries(folder: MediaItem): List<DownloadMenuEntry> = listOfNotNull(
    DownloadMenuEntry.MARK_WATCHED.takeIf { !folder.isWatched },
    DownloadMenuEntry.MARK_UNWATCHED.takeIf { folder.isWatched || folder.isPartiallyWatched },
    DownloadMenuEntry.DELETE_FOLDER_DOWNLOADS,
)
