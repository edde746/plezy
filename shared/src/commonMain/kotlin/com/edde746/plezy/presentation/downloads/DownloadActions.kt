package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.downloads.SyncRule
import com.edde746.plezy.data.downloads.SyncRuleFilter
import com.edde746.plezy.data.downloads.SyncRuleTarget
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.downloads.DownloadChoice
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadFilter
import com.edde746.plezy.downloads.DownloadResult
import com.edde746.plezy.downloads.DownloadVersionConfig
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.downloads.QueuedUnit
import com.edde746.plezy.downloads.SyncChoice
import com.edde746.plezy.downloads.SyncRuleCleanupBusyException
import com.edde746.plezy.downloads.SyncRuleCleanupUnavailableException
import com.edde746.plezy.downloads.SyncRuleRemovalResult
import com.edde746.plezy.downloads.canTranscodeDownload
import com.edde746.plezy.downloads.downloadVersionConfigFor
import com.edde746.plezy.downloads.downloadVersions
import com.edde746.plezy.downloads.queueWithFeedback
import com.edde746.plezy.downloads.syncRuleRemovalMessage
import com.edde746.plezy.format.formatByteSize
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.presentation.player.QualityRow
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException

/** Whether [rule] mirrors a collection or playlist (its filter is edited) rather than a show or season (its count). */
val SyncRule.isListRule: Boolean get() = target == SyncRuleTarget.COLLECTION || target == SyncRuleTarget.PLAYLIST

/**
 * The download flows the detail screens, the context menus and the sync rules screen share, their questions asked
 * through [dialogs]:
 * - [showDownloadOptionsAndQueue]: a movie, episode or track queues at once (after the version picker when it has
 *   several versions); a show or season first asks how many episodes ("Download now": all, unwatched, next 5, next 10,
 *   a custom count, and Delete when it has downloads), a show also whether to include Specials (remembered) and, for
 *   an unwatched choice, whether to keep it synced (a rule created before queueing);
 * - [showListDownloadOptionsAndQueue]: a collection or playlist (all or unwatched, then once or kept synced);
 * - the sync rule edits ([manageSyncRule], [confirmAndRemoveSyncRule]).
 *
 * Every user-initiated download first passes the background-restriction pre-flight ([warning]).
 */
class DownloadActions(
    private val controller: DownloadsController,
    private val dialogs: DownloadDialogs,
    private val warning: BackgroundDownloadWarning,
    private val settings: DeviceSettingsRepository,
) {
    /** The show/season/item flow; null when the user cancelled or picked Delete (which runs [onDelete]). */
    suspend fun showDownloadOptionsAndQueue(item: MediaItem, client: MediaBackend, onDelete: (suspend () -> Unit)? = null): DownloadResult? {
        if (!warning.confirmBeforeDownload()) return null
        val kind = item.kind
        var filter = DownloadFilter.ALL
        var maxCount: Int? = null
        var keepSynced = false
        var includeSpecials = settings.value(AppSettings.downloadIncludeSpecials)

        if (kind == MediaKind.SHOW || kind == MediaKind.SEASON) {
            val choices = DownloadChoice.options(hasDownloads = onDelete != null)
            var choice: DownloadChoice
            var customCount: Int? = null
            while (true) {
                val (index, toggle) = dialogs.pickOption(
                    DownloadDialog.Options(
                        title = T.downloads.downloadNow,
                        options = choices.map(::choiceOption),
                        toggle = if (kind == MediaKind.SHOW) DownloadDialogSwitch(T.downloads.includeSpecials, includeSpecials, DownloadDialogIcon.SPECIALS) else null,
                    ),
                ) ?: return null
                if (toggle != null) includeSpecials = toggle
                choice = choices[index]
                if (choice != DownloadChoice.CUSTOM) break
                // A cancelled count goes back to the choices.
                customCount = dialogs.enterCount(DownloadDialog.Count(T.downloads.howManyEpisodes, hint = "", allowZero = false)) ?: continue
                break
            }
            if (choice == DownloadChoice.DELETE) {
                onDelete?.invoke()
                return null
            }
            filter = choice.filter
            maxCount = choice.maxCount(customCount)
            if (filter == DownloadFilter.UNWATCHED && kind == MediaKind.SHOW) {
                keepSynced = askSyncChoice() ?: return null
            }
        }

        val versionConfig = resolveDownloadVersion(item, client) ?: return null

        // The rule exists before queueing, so it survives a queue that fails.
        var syncRuleUpdated = false
        if (keepSynced) {
            val serverId = ServerId(item.serverId ?: client.serverId.value)
            syncRuleUpdated = controller.hasSyncRule(controller.syncRuleKeyFor(serverId, item.id))
            controller.createSyncRule(
                serverId = serverId,
                ratingKey = item.id,
                target = if (kind == MediaKind.SEASON) SyncRuleTarget.SEASON else SyncRuleTarget.SHOW,
                episodeCount = maxCount ?: 0,
                mediaIndex = versionConfig.mediaIndex,
                transcodeQuality = versionConfig.quality,
                includeSpecials = includeSpecials,
                targetMetadata = item,
            )
        }
        if (kind == MediaKind.SHOW) settings.set(AppSettings.downloadIncludeSpecials, includeSpecials)

        val count = controller.queueDownload(item, client, versionConfig, filter, maxCount, includeSpecials)
        return DownloadResult(count, syncRuleCreated = keepSynced && !syncRuleUpdated, syncRuleUpdated = syncRuleUpdated, unit = QueuedUnit.of(kind))
    }

    /** [showDownloadOptionsAndQueue] with its outcome as feedback; null when nothing happened. */
    suspend fun queueDownloadWithFeedback(item: MediaItem, client: MediaBackend, onDelete: (suspend () -> Unit)? = null): DownloadFeedback? =
        queueWithFeedback { showDownloadOptionsAndQueue(item, client, onDelete) }

    /**
     * The version and quality to download: a version picker when [item] (or a show's or season's representative
     * episode) has several, then, where the server transcodes downloads and a preset makes the file smaller, the quality
     * ([downloadQualities]; a movie's or episode's rows each with its size). For a show or season, an episode whose
     * versions don't match the pick asks again. Null when cancelled.
     */
    suspend fun resolveDownloadVersion(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>? = null): DownloadVersionConfig? {
        val versions = downloadVersions(item, client, fallbackVersions)
        val config = if (versions != null && versions.size > 1) {
            val selected = pickVersion(versions, T.downloads.selectVersion) ?: return null
            downloadVersionConfigFor(item, versions, selected) { episode, episodeVersions ->
                pickVersion(episodeVersions, "${episode.displayTitle} - ${T.downloads.selectVersion}")
            }
        } else {
            DownloadVersionConfig()
        }
        if (!canTranscodeDownload(item, client)) return config
        val quality = pickQuality(item, versions?.getOrNull(config.mediaIndex)) ?: return null
        return config.copy(quality = quality)
    }

    private suspend fun pickVersion(versions: List<MediaVersion>, title: String): Int? =
        dialogs.pickOption(DownloadDialog.Options(title, versions.map { DownloadDialogOption(it.displayLabel, DownloadDialogIcon.VERSION) }))?.first

    private suspend fun pickQuality(item: MediaItem, version: MediaVersion?): TranscodeQualityPreset? {
        // A show's or season's episodes differ in length and size: only a single item's are known.
        val single = item.kind == MediaKind.MOVIE || item.kind == MediaKind.EPISODE
        val duration = item.durationMs.takeIf { single }
        val rows = downloadQualities(version, duration)
        if (rows.size < 2) return TranscodeQualityPreset.ORIGINAL
        val options = rows.map { row ->
            val size = when {
                !single -> null
                row.preset.isOriginal -> version?.sizeBytes?.let(::formatByteSize) ?: PlayerStates.qualitySize(row.preset, version?.bitrate, duration)
                // A transcode's bitrate is a cap: the file comes out at most this size, usually far smaller.
                else -> duration?.takeIf { it > 0 }?.let { "≤ ${formatByteSize(checkNotNull(row.preset.videoBitrateKbps).toLong() * it / 8)}" }
            }
            DownloadDialogOption(row.label, DownloadDialogIcon.QUALITY, size)
        }
        val index = dialogs.pickOption(DownloadDialog.Options(T.videoControls.qualityColumnHeader, options))?.first ?: return null
        return rows[index].preset
    }

    /**
     * The qualities a download of [version] lasting [runtimeMs] offers: Original, then the player's presets that make the
     * file clearly smaller, a bitrate cap at most [TRANSCODE_MAX_SHARE_PERCENT] % of the version's
     * ([downloadSourceBitrate]) and a frame no taller than its picture. Original alone when that bitrate is unknown or
     * no preset is that much smaller.
     */
    internal fun downloadQualities(version: MediaVersion?, runtimeMs: Long?): List<QualityRow> {
        val bitrate = downloadSourceBitrate(version, runtimeMs)
        val height = version?.resolutionHeight?.takeIf { it > 0 }
        return PlayerStates.offeredQualities(bitrate, height, TranscodeQualityPreset.ORIGINAL).filter { row ->
            val preset = row.preset
            preset.isOriginal ||
                bitrate != null && checkNotNull(preset.videoBitrateKbps).toLong() * 100 <= bitrate.toLong() * TRANSCODE_MAX_SHARE_PERCENT &&
                (height == null || checkNotNull(preset.resolutionHeight) <= height)
        }
    }

    /**
     * The kbps a download of [version] lasting [runtimeMs] is judged by: the file's real average (its size over the
     * runtime) when both are known, as a server's stated bitrate can add up every stream's nominal rate; else the
     * stated bitrate. Null when neither is known.
     */
    internal fun downloadSourceBitrate(version: MediaVersion?, runtimeMs: Long?): Int? {
        val size = version?.sizeBytes
        val runtime = runtimeMs?.takeIf { it > 0 }
        if (size != null && runtime != null) return (size * 8 / runtime).toInt().takeIf { it > 0 }
        return version?.bitrate?.takeIf { it > 0 }
    }

    /**
     * A collection's or playlist's flow over its [items] ([root] is the list itself, [target] its rule target): all or
     * unwatched, then once or kept synced (creating the rule, or updating an existing rule's filter). Null when cancelled.
     */
    suspend fun showListDownloadOptionsAndQueue(root: MediaItem, target: SyncRuleTarget, items: List<MediaItem>, client: MediaBackend): DownloadResult? {
        require(target == SyncRuleTarget.COLLECTION || target == SyncRuleTarget.PLAYLIST) { "$target is not a list" }
        if (!warning.confirmBeforeDownload()) return null
        val filter = pickFilter(T.downloads.downloadNow) ?: return null
        val keepSynced = askSyncChoice() ?: return null
        val serverId = ServerId(root.serverId ?: client.serverId.value)
        val ruleFilter = if (filter == DownloadFilter.UNWATCHED) SyncRuleFilter.UNWATCHED else SyncRuleFilter.ALL

        var created = false
        var updated = false
        var rule: SyncRule? = null
        if (keepSynced) {
            val ruleKey = controller.syncRuleKeyFor(serverId, root.id)
            if (controller.hasSyncRule(ruleKey)) {
                controller.updateSyncRuleOptions(ruleKey, downloadFilter = ruleFilter)
                updated = true
            } else {
                controller.createSyncRule(serverId, root.id, target, episodeCount = 0, mediaIndex = 0, downloadFilter = ruleFilter, targetMetadata = root)
                created = true
            }
            rule = controller.getSyncRule(ruleKey)
        }
        val count = controller.queueListDownload(items, client, filter, rule)
        return DownloadResult(count, syncRuleCreated = created, syncRuleUpdated = updated, isListRule = true, unit = QueuedUnit.of(items.map { it.kind }))
    }

    /** Fetches the list's items with [fetchItems] (every page), then [showListDownloadOptionsAndQueue], as feedback. */
    suspend fun fetchAndQueueListDownload(
        root: MediaItem,
        target: SyncRuleTarget,
        client: MediaBackend,
        fetchItems: suspend () -> List<MediaItem>,
    ): DownloadFeedback? = queueWithFeedback { showListDownloadOptionsAndQueue(root, target, fetchItems(), client) }

    private suspend fun askSyncChoice(): Boolean? {
        val choices = listOf(SyncChoice.DOWNLOAD_ONCE, SyncChoice.KEEP_SYNCED)
        val (index, _) = dialogs.pickOption(
            DownloadDialog.Options(
                T.downloads.downloadNow,
                listOf(
                    DownloadDialogOption(T.downloads.downloadOnce, DownloadDialogIcon.DOWNLOAD),
                    DownloadDialogOption(T.downloads.keepSynced, DownloadDialogIcon.SYNC),
                ),
            ),
        ) ?: return null
        return choices[index] == SyncChoice.KEEP_SYNCED
    }

    private suspend fun pickFilter(title: String): DownloadFilter? {
        val (index, _) = dialogs.pickOption(
            DownloadDialog.Options(
                title,
                listOf(
                    DownloadDialogOption(T.downloads.allEpisodes, DownloadDialogIcon.DOWNLOAD),
                    DownloadDialogOption(T.downloads.unwatchedOnly, DownloadDialogIcon.UNWATCHED),
                ),
            ),
        ) ?: return null
        return if (index == 0) DownloadFilter.ALL else DownloadFilter.UNWATCHED
    }

    /**
     * Edits the rule [globalKey]: a list rule's filter, a show's or season's episode count (0 offers to remove it).
     * The feedback to show, or null when nothing changed.
     */
    suspend fun manageSyncRule(globalKey: String, displayTitle: String? = null): DownloadFeedback? {
        val rule = controller.getSyncRule(globalKey) ?: return null
        return guarded {
            if (rule.isListRule) {
                val filter = pickFilter(T.downloads.editSyncFilter) ?: return@guarded null
                val ruleFilter = if (filter == DownloadFilter.UNWATCHED) SyncRuleFilter.UNWATCHED else SyncRuleFilter.ALL
                if (ruleFilter == rule.downloadFilter) return@guarded null
                controller.updateSyncRuleOptions(globalKey, downloadFilter = ruleFilter)
                return@guarded DownloadFeedback(T.downloads.syncRuleUpdated, isError = false)
            }
            val count = dialogs.enterCount(DownloadDialog.Count(T.downloads.editEpisodeCount, hint = rule.episodeCount.toString(), allowZero = true))
                ?: return@guarded null
            if (count == 0) return@guarded confirmAndRemoveSyncRule(globalKey, displayTitle ?: rule.ratingKey)
            controller.updateSyncRuleOptions(globalKey, episodeCount = count)
            DownloadFeedback(T.downloads.syncRuleUpdated, isError = false)
        }
    }

    /**
     * Asks, then removes the rule [globalKey]: a show or season rule alone (its downloads stay); a list rule with the
     * choice to delete the downloads only it holds. The feedback to show, or null when cancelled.
     */
    suspend fun confirmAndRemoveSyncRule(globalKey: String, displayTitle: String): DownloadFeedback? {
        val rule = controller.getSyncRule(globalKey) ?: return null
        val answer = dialogs.confirm(
            DownloadDialog.Confirm(
                title = T.downloads.removeSyncRule,
                message = if (rule.isListRule) T.downloads.removeListSyncRuleConfirm(displayTitle) else T.downloads.removeSyncRuleConfirm(displayTitle),
                confirmLabel = T.downloads.removeSyncRule,
                switch = if (rule.isListRule) {
                    DownloadDialogSwitch(T.downloads.deleteSyncRuleDownloads, false, subtitle = T.downloads.deleteSyncRuleDownloadsDescription)
                } else {
                    null
                },
            ),
        ) ?: return null
        return guarded {
            val result = if (answer.switch) {
                controller.deleteSyncRuleAndDownloads(globalKey)
                SyncRuleRemovalResult.RULE_AND_DOWNLOADS
            } else {
                controller.deleteSyncRule(globalKey)
                SyncRuleRemovalResult.RULE_ONLY
            }
            DownloadFeedback(syncRuleRemovalMessage(result), isError = false)
        }
    }

    private suspend fun guarded(block: suspend () -> DownloadFeedback?): DownloadFeedback? = try {
        block()
    } catch (e: CancellationException) {
        throw e
    } catch (_: SyncRuleCleanupBusyException) {
        DownloadFeedback(T.downloads.syncRuleCleanupBusy, isError = true)
    } catch (_: SyncRuleCleanupUnavailableException) {
        DownloadFeedback(T.downloads.syncRuleCleanupUnavailable, isError = true)
    } catch (e: Exception) {
        Log.e(TAG, e) { "Sync rule change failed" }
        DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
    }

    private fun choiceOption(choice: DownloadChoice) = when (choice) {
        DownloadChoice.ALL -> DownloadDialogOption(T.downloads.allEpisodes, DownloadDialogIcon.DOWNLOAD)
        DownloadChoice.UNWATCHED -> DownloadDialogOption(T.downloads.unwatchedOnly, DownloadDialogIcon.UNWATCHED)
        DownloadChoice.NEXT_5 -> DownloadDialogOption(T.downloads.nextNUnwatched(count = "5"), DownloadDialogIcon.NEXT_5)
        DownloadChoice.NEXT_10 -> DownloadDialogOption(T.downloads.nextNUnwatched(count = "10"), DownloadDialogIcon.NEXT_10)
        DownloadChoice.CUSTOM -> DownloadDialogOption(T.downloads.customAmount, DownloadDialogIcon.CUSTOM)
        DownloadChoice.DELETE -> DownloadDialogOption(T.downloads.deleteDownload, DownloadDialogIcon.DELETE)
    }

    private companion object {
        const val TAG = "Downloads"

        /** The largest share of the source's bitrate a download's transcode cap may be: a transcode saves a fifth at least. */
        const val TRANSCODE_MAX_SHARE_PERCENT = 80
    }
}
