package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.CANCELLED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.COMPLETED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.DOWNLOADING
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.FAILED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PARTIAL
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.PAUSED
import com.edde746.plezy.data.downloads.DownloadedMediaStatus.QUEUED
import com.edde746.plezy.downloads.DownloadProgress
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.strings.T

/** What a row of the Manage tab's tree stands for. */
enum class DownloadNodeType {
    SHOW,
    SEASON,
    EPISODE,
    MOVIE,
    ALBUM,
    TRACK,
    ;

    val isContainer: Boolean get() = this == SHOW || this == SEASON || this == ALBUM
}

/**
 * A row of the Manage tab's tree: a download ([metadata] and [downloadProgress] set) or a show, season or album holding
 * downloads ([children]). A container's [key] is a tree key, not a global key; [resolveDownloadContainerGlobalKey]
 * finds the item's.
 *
 * @param progress 0–1; a container's is its children's mean.
 */
data class DownloadTreeNode(
    val key: String,
    val title: String,
    val type: DownloadNodeType,
    val status: DownloadedMediaStatus,
    val progress: Double = 0.0,
    val children: List<DownloadTreeNode> = emptyList(),
    val metadata: MediaItem? = null,
    val downloadProgress: DownloadProgress? = null,
) {
    val hasChildren: Boolean get() = children.isNotEmpty()

    val completedChildrenCount: Int get() = children.count { it.status == COMPLETED }

    /** A container's summary line: how many of its children completed. */
    val summary: String get() = T.downloads.completedOfTotal(completedChildrenCount.toString(), children.size.toString())

    /**
     * The status the row shows: a download that reports downloading with no progress and no speed waits in the
     * downloader's holding queue, so it shows as queued.
     */
    val effectiveStatus: DownloadedMediaStatus
        get() = if (status == DOWNLOADING && progress == 0.0 && (downloadProgress?.speed ?: 0.0) == 0.0) QUEUED else status

    /** Whether any download below this container failed; the aggregate status hides one next to an active sibling. */
    val hasFailedLeaf: Boolean get() = children.any { if (it.hasChildren) it.hasFailedLeaf else it.status == FAILED }

    /** The global keys of the downloads below this container, in tree order, those matching [where] only. */
    fun leafKeys(where: (DownloadTreeNode) -> Boolean = { true }): List<String> = buildList {
        for (child in children) {
            if (child.hasChildren) addAll(child.leafKeys(where)) else if (where(child)) add(child.key)
        }
    }

    internal val firstLeafKey: String?
        get() {
            for (child in children) {
                if (!child.hasChildren) return child.key
                child.firstLeafKey?.let { return it }
            }
            return null
        }
}

/** An action a tree row offers. */
enum class DownloadRowAction {
    PAUSE,
    RESUME,
    CANCEL,
    RETRY,
    DELETE,
    PAUSE_ALL,
    RESUME_ALL,
    RETRY_ALL,
    DELETE_ALL,
    ;

    val label: String
        get() = when (this) {
            PAUSE -> T.common.pause
            RESUME -> T.common.resume
            CANCEL -> T.common.cancel
            RETRY -> T.downloads.retryDownload
            DELETE -> T.common.delete
            PAUSE_ALL -> T.downloads.pauseAll
            RESUME_ALL -> T.downloads.resumeAll
            RETRY_ALL -> T.downloads.retryAll
            DELETE_ALL -> T.downloads.deleteAll
        }

    /** Deleting asks first. */
    val confirms: Boolean get() = this == DELETE || this == DELETE_ALL
}

/**
 * The actions [node] offers, in display order, from its own status (not [DownloadTreeNode.effectiveStatus]):
 * - a download: Pause while downloading, Resume while paused, Cancel while downloading or queued, Retry when failed,
 *   Delete when completed, failed or cancelled;
 * - a container: Pause all while downloading or queued, Resume all while paused, Retry all while any download below
 *   failed, Delete all.
 */
fun downloadRowActions(node: DownloadTreeNode): List<DownloadRowAction> = buildList {
    val status = node.status
    if (node.type.isContainer) {
        if (status == DOWNLOADING || status == QUEUED) add(DownloadRowAction.PAUSE_ALL)
        if (status == PAUSED) add(DownloadRowAction.RESUME_ALL)
        if (node.hasFailedLeaf) add(DownloadRowAction.RETRY_ALL)
        add(DownloadRowAction.DELETE_ALL)
        return@buildList
    }
    if (status == DOWNLOADING) add(DownloadRowAction.PAUSE)
    if (status == PAUSED) add(DownloadRowAction.RESUME)
    if (status == DOWNLOADING || status == QUEUED) add(DownloadRowAction.CANCEL)
    if (status == FAILED) add(DownloadRowAction.RETRY)
    if (status == COMPLETED || status == FAILED || status == CANCELLED) add(DownloadRowAction.DELETE)
}

/**
 * The Manage tab's tree of [downloads] (global key → progress) with their [metadata]: movies, then shows (show → season
 * → episode), then albums (album → track), each level by status (downloading, queued, paused, partial, completed,
 * failed, cancelled) then title. Episodes follow their index, seasons their number, tracks disc then track number. A
 * download without metadata isn't shown.
 */
fun buildDownloadTree(downloads: Map<String, DownloadProgress>, metadata: Map<String, MediaItem>): List<DownloadTreeNode> {
    val showGroups = LinkedHashMap<String, MutableList<Pair<String, DownloadProgress>>>()
    val albumGroups = LinkedHashMap<String, MutableList<Pair<String, DownloadProgress>>>()
    val movies = mutableListOf<DownloadTreeNode>()

    for ((globalKey, download) in downloads) {
        val meta = metadata[globalKey] ?: continue
        when {
            meta.isEpisode -> showGroups.getOrPut(meta.grandparentId ?: UNKNOWN) { mutableListOf() } += globalKey to download
            meta.kind == MediaKind.TRACK -> albumGroups.getOrPut(meta.parentId ?: UNKNOWN) { mutableListOf() } += globalKey to download
            meta.isMovie -> movies += leaf(globalKey, meta.displayTitle, DownloadNodeType.MOVIE, download, meta)
        }
    }

    val shows = showGroups.mapNotNull { (showKey, episodes) -> showNode(showKey, episodes, metadata) }
    val albums = albumGroups.mapNotNull { (albumKey, tracks) -> albumNode(albumKey, tracks, metadata) }
    return movies.sortedWith(byStatusAndTitle) + shows.sortedWith(byStatusAndTitle) + albums.sortedWith(byStatusAndTitle)
}

private fun showNode(showKey: String, episodes: List<Pair<String, DownloadProgress>>, metadata: Map<String, MediaItem>): DownloadTreeNode? {
    if (episodes.isEmpty()) return null
    val showTitle = metadata[episodes.first().first]?.grandparentTitle ?: T.downloads.unknownShow

    val seasonGroups = LinkedHashMap<String, MutableList<Pair<String, DownloadProgress>>>()
    for (episode in episodes) {
        val meta = metadata[episode.first] ?: continue
        seasonGroups.getOrPut(meta.parentId ?: UNKNOWN) { mutableListOf() } += episode
    }

    val seasons = seasonGroups.mapNotNull { (seasonKey, seasonEpisodes) ->
        val first = metadata[seasonEpisodes.first().first]
        val seasonNumber = first?.parentIndex
        val seasonTitle = first?.parentTitle?.takeIf { it.isNotEmpty() }
            ?: seasonNumber?.let { T.common.seasonNumber(it.toString()) }
            ?: T.downloads.unknownSeason
        val episodeNodes = seasonEpisodes.mapNotNull { (globalKey, download) ->
            val meta = metadata[globalKey] ?: return@mapNotNull null
            val title = meta.index?.let { T.common.episodeNumberTitle(it.toString(), meta.title.orEmpty()) } ?: meta.title.orEmpty()
            leaf(globalKey, title, DownloadNodeType.EPISODE, download, meta)
        }.sortedBy { it.metadata?.index ?: 0 }
        if (episodeNodes.isEmpty()) return@mapNotNull null
        container("$showKey:$seasonKey", seasonTitle, DownloadNodeType.SEASON, episodeNodes)
    }.sortedBy { metadata[it.children.first().key]?.parentIndex ?: 0 }

    return container(showKey, showTitle, DownloadNodeType.SHOW, seasons)
}

private fun albumNode(albumKey: String, tracks: List<Pair<String, DownloadProgress>>, metadata: Map<String, MediaItem>): DownloadTreeNode? {
    if (tracks.isEmpty()) return null
    val first = metadata[tracks.first().first]
    val albumTitle = first?.albumTitle ?: T.downloads.unknownAlbum
    val artist = first?.albumArtistTitle
    val title = if (!artist.isNullOrEmpty()) "$artist - $albumTitle" else albumTitle

    val trackNodes = tracks.mapNotNull { (globalKey, download) ->
        val meta = metadata[globalKey] ?: return@mapNotNull null
        leaf(globalKey, meta.title ?: globalKey, DownloadNodeType.TRACK, download, meta)
    }.sortedWith(compareBy({ it.metadata?.discNumber ?: 1 }, { it.metadata?.trackNumber ?: 0 }))
    if (trackNodes.isEmpty()) return null
    return container(albumKey, title, DownloadNodeType.ALBUM, trackNodes)
}

private fun leaf(globalKey: String, title: String, type: DownloadNodeType, download: DownloadProgress, meta: MediaItem) =
    DownloadTreeNode(globalKey, title, type, download.status, download.progressPercent, metadata = meta, downloadProgress = download)

private fun container(key: String, title: String, type: DownloadNodeType, children: List<DownloadTreeNode>) = DownloadTreeNode(
    key = key,
    title = title,
    type = type,
    status = determineDownloadAggregateStatus(children.map { it.status }),
    progress = if (children.isEmpty()) 0.0 else children.sumOf { it.progress } / children.size,
    children = children,
)

private const val UNKNOWN = "unknown"

private val statusOrder = listOf(DOWNLOADING, QUEUED, PAUSED, PARTIAL, COMPLETED, FAILED, CANCELLED)

private val byStatusAndTitle = compareBy<DownloadTreeNode>({ statusOrder.indexOf(it.status) }, { it.title })

/**
 * A container's status from its children's: downloading over queued over paused over failed; then all cancelled stays
 * cancelled, all completed stays completed, and any other mix (completed next to cancelled, a partial child) is
 * partial. No children reads as queued.
 */
fun determineDownloadAggregateStatus(statuses: List<DownloadedMediaStatus>): DownloadedMediaStatus = when {
    statuses.isEmpty() -> QUEUED
    DOWNLOADING in statuses -> DOWNLOADING
    QUEUED in statuses -> QUEUED
    PAUSED in statuses -> PAUSED
    FAILED in statuses -> FAILED
    statuses.all { it == CANCELLED } -> CANCELLED
    statuses.all { it == COMPLETED } -> COMPLETED
    else -> PARTIAL
}

/**
 * The global key of the item a container row stands for, built from its first download's server and parent: a show's
 * from the episode's grandparent, a season's or album's from the parent. Null for a download row, or when the first
 * download's metadata lacks what it needs.
 */
fun resolveDownloadContainerGlobalKey(node: DownloadTreeNode, metadata: Map<String, MediaItem>): String? {
    val firstLeafMeta = node.firstLeafKey?.let { metadata[it] } ?: return null
    val serverId = ServerId.tryParse(firstLeafMeta.serverId) ?: return null
    val ratingKey = when (node.type) {
        DownloadNodeType.SHOW -> firstLeafMeta.grandparentId
        DownloadNodeType.SEASON, DownloadNodeType.ALBUM -> firstLeafMeta.parentId
        DownloadNodeType.EPISODE, DownloadNodeType.MOVIE, DownloadNodeType.TRACK -> null
    } ?: return null
    return buildGlobalKey(serverId, ratingKey)
}

/** A row of the flattened tree: [node] at [depth] (0 for top level). */
data class DownloadTreeRow(val node: DownloadTreeNode, val depth: Int)

/** [tree] as rows, the children of the containers whose keys are in [expanded] under them. */
fun flattenDownloadTree(tree: List<DownloadTreeNode>, expanded: Set<String>, depth: Int = 0): List<DownloadTreeRow> = buildList {
    for (node in tree) {
        add(DownloadTreeRow(node, depth))
        if (node.key in expanded && node.hasChildren) addAll(flattenDownloadTree(node.children, expanded, depth + 1))
    }
}
