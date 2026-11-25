package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.jellyfin.JellyfinClient
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.formatQueueItemSubtitle
import com.edde746.plezy.model.nextEpisodeSkippingSameFile
import com.edde746.plezy.model.previousEpisodeSkippingSameFile
import com.edde746.plezy.model.sortEpisodesByWatchOrder
import com.edde746.plezy.playback.session.QueueEntry
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.createShowPlayQueue
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.PlaybackQueueState
import com.edde746.plezy.servers.PlaybackStateStore
import com.edde746.plezy.servers.QueueNavigationStatus
import kotlinx.coroutines.CancellationException

private const val TAG = "EpisodeQueue"

/**
 * The items before and after the playing one. [nextStatus] tells a confirmed end of the queue
 * ([QueueNavigationStatus.BOUNDARY]) from a lookup that failed and may be retried ([QueueNavigationStatus.FAILED]).
 */
data class AdjacentEpisodes(
    val next: MediaItem? = null,
    val previous: MediaItem? = null,
    val nextStatus: QueueNavigationStatus,
    val previousStatus: QueueNavigationStatus,
) {
    companion object {
        /** No queue applies: a standalone movie, live TV. */
        val UNAVAILABLE = AdjacentEpisodes(nextStatus = QueueNavigationStatus.UNAVAILABLE, previousStatus = QueueNavigationStatus.UNAVAILABLE)

        /** The queue could not be built or read. */
        val FAILED = AdjacentEpisodes(nextStatus = QueueNavigationStatus.FAILED, previousStatus = QueueNavigationStatus.FAILED)
    }
}

/**
 * What moves on with the viewer to the next or previous item: the playing version by its signature (another item
 * lists its versions in its own order), the quality, and the audio and subtitle choices. With
 * `follow_server_track_selections` on, no track choice moves on and the server's selection plays.
 */
data class EpisodeCarry(
    val versionSignature: String? = null,
    val quality: TranscodeQualityPreset? = null,
    val audio: AudioTrackPreference? = null,
    val subtitle: SubtitlePreference? = null,
    val secondarySubtitle: SubtitlePreference? = null,
) {
    companion object {
        /**
         * The carry from the item playing [versions]'s [versionIndex] at [quality]; [audio], [subtitle] and
         * [secondarySubtitle] are the session's preferences, dropped when [followServerTrackSelections].
         */
        fun of(
            versions: List<MediaVersion>,
            versionIndex: Int,
            quality: TranscodeQualityPreset?,
            audio: AudioTrackPreference?,
            subtitle: SubtitlePreference?,
            secondarySubtitle: SubtitlePreference?,
            followServerTrackSelections: Boolean,
        ): EpisodeCarry = EpisodeCarry(
            versionSignature = versions.getOrNull(versionIndex)?.signature,
            quality = quality,
            audio = audio.takeUnless { followServerTrackSelections },
            subtitle = subtitle.takeUnless { followServerTrackSelections },
            secondarySubtitle = secondarySubtitle.takeUnless { followServerTrackSelections },
        )
    }
}

/** How far into an item Previous restarts it instead of going to the item before. */
const val RESTART_BEFORE_PREVIOUS_SECONDS = 3.0

/** Previous at [positionSeconds] restarts the playing item (a movie too) rather than playing the item before it. */
fun shouldRestartBeforePreviousItem(positionSeconds: Double): Boolean = positionSeconds > RESTART_BEFORE_PREVIOUS_SECONDS

/**
 * The player's queue around the playing item, over the session-wide [playbackState]: what plays next and before, the
 * queue's entries for the queue sheet, and keeping the queue in step with what plays.
 *
 * A queue the item already belongs to (a playlist's, a collection's, a shuffled show's, one built here before) is
 * kept. Otherwise a Plex episode gets the show's server queue ([ensurePlexShowQueue]); failing that, with Specials last
 * on Plex, and for Jellyfin and Emby episodes, the series' episodes from
 * [com.edde746.plezy.backend.MediaBackend.fetchClientSideEpisodeQueue] become a local queue anchored at the episode, or
 * starting at it where the server's own client starts its queue there ([JellyfinClient.seriesQueueStartsAtEpisode]).
 * Series lists are cached for the last [SERIES_CACHE_CAPACITY] series.
 */
class EpisodeQueue(
    private val playbackState: PlaybackStateStore,
    private val servers: OnlineServers,
) {
    private val seriesEpisodes = LinkedHashMap<String, List<MediaItem>>()
    private var primedKey: String? = null

    /** Whether the queue plays shuffled. */
    val shuffled: Boolean get() = playbackState.isShuffleActive

    /**
     * Makes sure a Plex episode plays in its show's server queue: an active queue holding [item] is kept with its
     * cursor moved to it; a stale one is cleared and Plex's queue for the episode created, the one Plex Web plays (from
     * the episode on, nothing before it), with 50-item windows. With [SpecialsOrdering.SPECIALS_LAST] no server queue is
     * made: Plex orders that queue by air date, a Special between the episodes it aired between, so [loadAdjacent]'s
     * local series queue keeps the Specials last. Other items, other backends and failures leave it to that local queue
     * too. Not for downloads played offline or live TV.
     */
    suspend fun ensurePlexShowQueue(item: MediaItem) {
        if (item.kind != MediaKind.EPISODE || item.backend != BackendKind.PLEX) return
        val showKey = item.grandparentId ?: return
        if (playbackState.isItemInActiveQueue(item)) {
            playbackState.setCurrentItem(item)
            return
        }
        if (playbackState.isQueueActive) playbackState.clearShuffle()
        val client = ServerId.tryParse(item.serverId)?.let(servers::client) as? PlexClient ?: return
        if (client.environment.specialsOrdering() == SpecialsOrdering.SPECIALS_LAST) return
        val queue = client.createShowPlayQueue(
            showRatingKey = showKey,
            startingEpisodeKey = item.id,
            librarySectionId = item.libraryId,
            librarySectionTitle = item.libraryTitle,
        )
        if (queue == null || queue.items.isNullOrEmpty()) {
            Log.w(TAG) { "No usable play queue for show $showKey; next and previous use the series' episodes" }
            return
        }
        playbackState.setPlayQueueWindowFetcher(client.playQueueWindows(item.libraryId, item.libraryTitle))
        playbackState.setPlaybackFromPlayQueue(queue, showKey)
    }

    /**
     * The items before and after [item] in the queue, building the series queue when none holds it. [playedPartId], the
     * part playing when known, skips the other episodes of a multi-episode file. [showPlay]: [item] plays as its show's
     * Play (its next episode), not on its own. Never throws: a failure is [AdjacentEpisodes.FAILED].
     */
    suspend fun loadAdjacent(item: MediaItem, playedPartId: String? = null, showPlay: Boolean = false): AdjacentEpisodes = try {
        when (ensureQueueHolds(item, showPlay)) {
            QueueHold.UNAVAILABLE -> AdjacentEpisodes.UNAVAILABLE
            QueueHold.FAILED -> AdjacentEpisodes.FAILED
            QueueHold.ACTIVE -> if (!playbackState.isQueueActive) {
                AdjacentEpisodes.FAILED
            } else {
                val next = playbackState.getNextEpisode(item.id, playedPartId)
                val previous = playbackState.getPreviousEpisode(item.id, playedPartId)
                AdjacentEpisodes(next.item, previous.item, next.status.orFailed(), previous.status.orFailed())
            }
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Could not load adjacent items" }
        AdjacentEpisodes.FAILED
    }

    /**
     * The player opened [item]: the queue's cursor moves to it when the queue holds it; otherwise the queue is cleared
     * (continue watching, an episode opened directly), so next and previous don't walk a queue the item isn't in.
     */
    fun onPlayerOpened(item: MediaItem) {
        if (playbackState.isItemInActiveQueue(item)) playbackState.setCurrentItem(item) else playbackState.clearShuffle()
    }

    /** The player moved on to [item] (next, previous, a queue entry): the queue's cursor follows when it holds it. */
    fun onItemChanged(item: MediaItem) = playbackState.setCurrentItem(item)

    /**
     * The queue's entries for the queue sheet ([com.edde746.plezy.playback.session.SessionInfo.queue]): each one's
     * title, its series and code (`Show · S1E2`) or year, its thumbnail by [imageUrl] when it has one, the playing one
     * marked, and an unwatched episode marked as a spoiler when [hideSpoilers]. Keys are the queue's entry ids. Each
     * entry comes with its item, so a pick plays what the sheet showed even after the queue's state moved on.
     */
    fun entries(hideSpoilers: Boolean, imageUrl: (MediaItem) -> String?): List<Pair<QueueEntry, MediaItem>> {
        val state = playbackState.state.value
        return state.loadedItems.mapIndexedNotNull { index, item ->
            val id = state.entryId(index) ?: return@mapIndexedNotNull null
            QueueEntry(
                key = id.toString(),
                title = item.title.orEmpty(),
                subtitle = formatQueueItemSubtitle(item),
                imageUrl = item.thumbPath?.let { imageUrl(item) },
                current = id == state.currentPlayQueueItemId,
                spoiler = hideSpoilers && item.shouldHideSpoiler,
            ) to item
        }
    }

    /** Leaves the queue: standalone playback from here. */
    fun clear() = playbackState.clearShuffle()

    /**
     * Fetches [next]'s metadata once per item while the current one plays, so the server's answer is cached when the
     * next item opens. Best effort: a failure costs nothing.
     */
    suspend fun primeNext(next: MediaItem) {
        if (primedKey == next.globalKey) return
        val client = ServerId.tryParse(next.serverId)?.let(servers::client) ?: return
        primedKey = next.globalKey
        try {
            client.fetchItem(next.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG) { "Next item metadata prime failed: ${e.message}" }
        }
    }

    private enum class QueueHold { ACTIVE, UNAVAILABLE, FAILED }

    /**
     * Keeps a queue holding [item] or, for an episode, publishes its series' episodes anchored at it, or from it on
     * where the server's own client queues them so ([showPlay] as in [loadAdjacent]). A clone of the cursor's item (a
     * version or quality switch reloads a copy) keeps the queue too. A playlist's or collection's queue is never replaced
     * by a series queue.
     */
    private suspend fun ensureQueueHolds(item: MediaItem, showPlay: Boolean): QueueHold {
        if (playbackState.isItemInActiveQueue(item)) {
            playbackState.setCurrentItem(item)
            return QueueHold.ACTIVE
        }
        if (playbackState.isQueueActive && playbackState.currentQueueItem?.globalKey == item.globalKey) return QueueHold.ACTIVE
        val serverId = ServerId.tryParse(item.serverId)
        val seriesId = item.grandparentId
        if (serverId == null || item.kind != MediaKind.EPISODE || seriesId == null) {
            return if (playbackState.isQueueActive) QueueHold.FAILED else QueueHold.UNAVAILABLE
        }
        val activeKey = playbackState.shuffleContextKey
        if (playbackState.isQueueActive && activeKey != null && activeKey != seriesId) return QueueHold.FAILED
        val client = servers.client(serverId) ?: return QueueHold.FAILED
        val episodes = cachedSeries(seriesId) ?: run {
            val fetched = try {
                client.fetchClientSideEpisodeQueue(seriesId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Could not fetch the series' episodes for its queue" }
                return QueueHold.FAILED
            }
            if (fetched.isNullOrEmpty()) return QueueHold.FAILED
            cacheSeries(seriesId, fetched)
            fetched
        }
        val anchor = episodes.indexOfFirst { it.id == item.id }
        if (anchor < 0) return QueueHold.FAILED
        val fromEpisode = (client as? JellyfinClient)?.seriesQueueStartsAtEpisode(showPlay) == true
        val queue = if (fromEpisode) LocalPlayQueue(episodes.drop(anchor), 0) else LocalPlayQueue(episodes, anchor)
        playbackState.setPlaybackFromLocalQueue(queue, contextKey = seriesId)
        return QueueHold.ACTIVE
    }

    private fun cachedSeries(seriesId: String): List<MediaItem>? = seriesEpisodes.remove(seriesId)?.also { seriesEpisodes[seriesId] = it }

    private fun cacheSeries(seriesId: String, episodes: List<MediaItem>) {
        seriesEpisodes.remove(seriesId)
        seriesEpisodes[seriesId] = episodes
        while (seriesEpisodes.size > SERIES_CACHE_CAPACITY) seriesEpisodes.remove(seriesEpisodes.keys.first())
    }

    /** A lookup with no queue to read after one was set up is a failure to retry, not a missing queue. */
    private fun QueueNavigationStatus.orFailed() = if (this == QueueNavigationStatus.UNAVAILABLE) QueueNavigationStatus.FAILED else this

    /** The queue id of the loaded entry at [index]: a client-side queue's synthetic id, else the server's. */
    private fun PlaybackQueueState.entryId(index: Int): Int? = syntheticIds.getOrNull(index) ?: loadedItems[index].playQueueItemId

    companion object {
        /** How many series' episode lists stay cached: enough for a few shows watched side by side. */
        const val SERIES_CACHE_CAPACITY = 5

        /**
         * Next and previous among [downloadedEpisodes], the downloads of [item]'s show, in watch order ([ordering] places
         * the specials), skipping the other episodes of the playing file.
         */
        fun offlineAdjacent(item: MediaItem, downloadedEpisodes: List<MediaItem>, ordering: SpecialsOrdering): AdjacentEpisodes {
            if (item.kind != MediaKind.EPISODE || item.seriesGlobalKey == null) return AdjacentEpisodes.UNAVAILABLE
            if (downloadedEpisodes.isEmpty()) return AdjacentEpisodes.FAILED
            val sorted = sortEpisodesByWatchOrder(downloadedEpisodes, ordering)
            val index = sorted.indexOfFirst { it.id == item.id }
            if (index == -1) return AdjacentEpisodes.FAILED
            val next = nextEpisodeSkippingSameFile(sorted, index)
            val previous = previousEpisodeSkippingSameFile(sorted, index)
            return AdjacentEpisodes(next, previous, next.status(), previous.status())
        }

        private fun MediaItem?.status() = if (this == null) QueueNavigationStatus.BOUNDARY else QueueNavigationStatus.FOUND
    }
}
