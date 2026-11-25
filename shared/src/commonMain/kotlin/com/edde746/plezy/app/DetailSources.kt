package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.downloads.DownloadsController
import com.edde746.plezy.downloads.deleteDownloadsFolder
import com.edde746.plezy.downloads.setDownloadsFolderWatched
import com.edde746.plezy.presentation.detail.OfflineCollectionSource
import com.edde746.plezy.servers.WatchActions
import kotlinx.coroutines.flow.drop
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.tracks.previewPlaybackTracks
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.transcodeQuality
import com.edde746.plezy.presentation.detail.DetailDownloads
import com.edde746.plezy.presentation.detail.DownloadedVersion
import com.edde746.plezy.presentation.detail.OfflineDetailSource
import com.edde746.plezy.presentation.detail.EpisodeDownloadUi
import com.edde746.plezy.presentation.detail.TrackStatusUi
import com.edde746.plezy.presentation.detail.mediaVideoLabels
import com.edde746.plezy.presentation.downloads.DetailDownload
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.downloadButtonSpec
import com.edde746.plezy.servers.OfflineWatchProvider
import com.edde746.plezy.settings.json.MediaVersionPreferences
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map

/** The detail's download button over the downloads' controller. */
internal class ControllerDetailDownloads(private val controller: DownloadsController, private val detail: DetailDownload) : DetailDownloads {
    override fun spec(item: MediaItem): Flow<DownloadButtonSpec> =
        controller.changes.map { downloadButtonSpec(controller, item) }.distinctUntilChanged()

    override val changes: Flow<Any?> get() = controller.changes

    override fun episodeStatus(episode: MediaItem): EpisodeDownloadUi? {
        val key = episode.globalKey
        if (controller.isQueueing(key)) return EpisodeDownloadUi(null, null, queueing = true)
        val progress = controller.getProgress(key) ?: return null
        val downloading = progress.status == DownloadedMediaStatus.DOWNLOADING
        return EpisodeDownloadUi(progress.status, progress.progressPercent.toFloat().takeIf { downloading }, queueing = false)
    }

    override suspend fun press(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>?): DownloadFeedback? =
        detail.press(item, client, fallbackVersions)
}

/** An offline detail's item, seasons, episodes, on-deck episode and artwork, from the profile's downloads. */
internal class DownloadsOfflineDetail(
    private val controller: DownloadsController,
    private val offlineWatch: OfflineWatchProvider,
) : OfflineDetailSource {
    override suspend fun metadata(serverId: ServerId, itemId: String): MediaItem? = controller.lookupOfflineMetadata(serverId, itemId)

    override fun seasons(show: MediaItem): List<MediaItem> = controller.downloadedSeasonsForShow(show.globalKey, show)

    override fun episodes(show: MediaItem): List<MediaItem> = controller.getDownloadedEpisodesForShow(show.globalKey)

    override suspend fun onDeck(show: MediaItem): MediaItem? = offlineWatch.getNextUnwatchedEpisode(show.globalKey)

    override fun artwork(serverId: ServerId, path: String?): String? = controller.getArtworkLocalPath(serverId, path)

    override suspend fun downloadedVersion(item: MediaItem): DownloadedVersion? =
        controller.getCompletedDownload(item.globalKey)?.let { DownloadedVersion(it.media_index.toInt(), it.media_source_id, it.transcodeQuality) }
}

/**
 * The tracks Play will start [item] on, as its track status shows them: the item's full record, the saved version
 * choice, that version's cached source and the player's own ladder over it. Never starts a playback session or a
 * transcode. Null when neither picture labels nor tracks are known.
 */
internal suspend fun previewDetailTracks(item: MediaItem, client: MediaBackend, preferences: MediaVersionPreferences): TrackStatusUi? {
    val full = client.fetchItem(item.id) ?: item
    val versions = full.mediaVersions.orEmpty()
    val preference = preferences.saved(full)
    val index = preference?.resolveIndex(versions) ?: 0
    val sourceId = versions.getOrNull(index)?.id?.takeIf { full.backend != BackendKind.PLEX }
    val source = client.fetchCachedMediaSourceInfo(full.id, index, sourceId, preference?.signature)
    val preview = source?.let { previewPlaybackTracks(full, it) }
    val video = mediaVideoLabels(full, index)
    if (preview == null && video.isEmpty()) return null
    val audio = preview?.audio?.label
    val subtitle = preview?.subtitle?.label
    return TrackStatusUi(
        video = video,
        audio = audio?.primary,
        audioDetail = audio?.secondary,
        subtitle = subtitle?.primary ?: T.common.off,
        subtitleDetail = subtitle?.secondary,
    )
}

/** A downloads folder's metadata, titles and artwork, and its watched marks and deletion, from the profile's downloads. */
internal class DownloadsOfflineCollection(
    private val controller: DownloadsController,
    private val watchActions: WatchActions,
    private val offline: () -> Boolean,
) : OfflineCollectionSource {
    override val changes: Flow<Any?> get() = controller.changes.drop(1)

    override suspend fun metadata(serverId: ServerId, collectionId: String): MediaItem? = controller.lookupOfflineMetadata(serverId, collectionId)

    override fun items(folder: MediaItem): List<MediaItem> = controller.downloadedCollectionItems(folder.globalKey)

    override fun artwork(serverId: ServerId, path: String?): String? = controller.getArtworkLocalPath(serverId, path)

    override suspend fun setWatched(folder: MediaItem, watched: Boolean): DownloadFeedback =
        setDownloadsFolderWatched(controller, watchActions, folder, watched, offline())

    override suspend fun delete(folder: MediaItem): DownloadFeedback = deleteDownloadsFolder(controller, folder)
}
