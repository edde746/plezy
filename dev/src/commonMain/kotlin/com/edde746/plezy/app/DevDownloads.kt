package com.edde746.plezy.app

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.data.downloads.DownloadedMediaStatus
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.playback.queue.fetchAllCollectionItems
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.distinctUntilChangedBy
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException

/**
 * Downloads the items titled [titles] (each matched without case, `_` standing for a space: a movie, an episode, a
 * show, a collection; `<show>/<season>` for a show's season, as `Maestro_Show/Season_1`) from the server of [server], in
 * order, as their Download buttons would (all of a show's or season's episodes, all of a collection's items, the
 * default version), and logs them under the tag DevDownloads: each queueing, then each status a download goes
 * through until it ends (`completed`, `failed`, `cancelled`, `partial`), which is when this returns.
 *
 * @throws IllegalStateException when this device has no downloads (Apple TV), the server isn't connected, or it has no
 *   item of a title: the launch fails.
 */
@Throws(CancellationException::class, IllegalStateException::class)
suspend fun AppSession.queueDevDownloads(server: DevServerSession, titles: List<String>) {
    val downloads = checkNotNull(downloads) { "--dev-download: this device has no downloads" }
    val name = server.connection.serverName
    val client = checkNotNull(servers.manager.mediaBrowserClient(server.connection.id)) { "--dev-download: $name isn't connected" }
    val controller = downloads.controller
    controller.ensureInitialized()
    val followed = titles.flatMap { title ->
        when (val found = client.findDevTitle(title, "--dev-download", name)) {
            is DevTitle.Item -> {
                val item = found.item
                val queued = controller.queueDownload(item, client)
                Log.i(TAG) { "Queued ${item.title} (${item.globalKey}, ${item.kind}) from $name: $queued file(s)" }
                listOf(item)
            }
            is DevTitle.Collection -> {
                val collection = found.collection
                val members = client.fetchAllCollectionItems(collection.id, found.library.id, found.library.title)
                val queued = controller.queueListDownload(members, client)
                Log.i(TAG) { "Queued ${collection.title} (${collection.globalKey}, ${members.size} item(s)) from $name: $queued file(s)" }
                members
            }
        }
    }
    coroutineScope { followed.forEach { launch { follow(downloads, it) } } }
}

/** What a development option's title names ([findDevTitle]): a server item, or a collection with its library. */
internal sealed interface DevTitle {
    data class Item(val item: MediaItem) : DevTitle

    data class Collection(val collection: MediaItem, val library: MediaLibrary) : DevTitle
}

/**
 * The item [title] names on this server (`--dev-download`'s and `--dev-open-item`'s grammar): the first search result
 * of that title (a movie, an episode, a show), then for each `/<child>` that item's child of that title
 * (`Maestro_Show/Season_1`, `Maestro_Show/Season_1/Maestro_Episode_2`), else the first collection of that title; each
 * matched without case, `_` standing for a space.
 *
 * @throws IllegalStateException when the server has no such item, naming [option] and the server [name].
 */
internal suspend fun MediaBackend.findDevTitle(title: String, option: String, name: String): DevTitle {
    val path = title.split('/')
    findTitled(path.first())?.let { first ->
        var item = first
        for (child in path.drop(1)) {
            val wanted = child.spacesAsUnderscores()
            item = fetchChildren(item.id).firstOrNull { it.title?.spacesAsUnderscores() == wanted }
                ?: error("$option: ${item.title} on $name has no child titled '$child'")
        }
        return DevTitle.Item(item)
    }
    val found = path.singleOrNull()?.let { findCollectionTitled(it, fetchLibraries()) { library -> fetchAllCollections(library) } }
    val (collection, library) = found ?: error("$option: $name has no item titled '${path.first()}'")
    return DevTitle.Collection(collection, library)
}

/** The first search result titled [title] (without case, `_` standing for a space). */
private suspend fun MediaBackend.findTitled(title: String): MediaItem? {
    val wanted = title.spacesAsUnderscores()
    return searchItems(title.replace('_', ' ')).firstOrNull { it.title?.spacesAsUnderscores() == wanted }
}

/**
 * The first collection titled [title] (without case, `_` standing for a space) in [libraries], in order, with its
 * library; [collections] lists a library's collections. Search doesn't return collections, so they are looked up here.
 */
internal suspend fun findCollectionTitled(
    title: String,
    libraries: List<MediaLibrary>,
    collections: suspend (MediaLibrary) -> List<MediaItem>,
): Pair<MediaItem, MediaLibrary>? {
    val wanted = title.spacesAsUnderscores()
    for (library in libraries) {
        collections(library).firstOrNull { it.title?.spacesAsUnderscores() == wanted }?.let { return it to library }
    }
    return null
}

private suspend fun MediaBackend.fetchAllCollections(library: MediaLibrary): List<MediaItem> =
    drainPages(COLLECTIONS_PAGE_SIZE) { start, size -> fetchCollectionsPage(library.id, start, size) }

/** Logs each status of [item]'s download until it ends. */
private suspend fun follow(downloads: AppDownloads, item: MediaItem) {
    downloads.controller.progressFlow(item.globalKey).filterNotNull().distinctUntilChangedBy { it.status }
        .transformWhile { emit(it); it.status !in ENDED }
        .collect { Log.i(TAG) { "${item.title}: ${it.status.name.lowercase()} ${it.progress}%" } }
}

private fun String.spacesAsUnderscores(): String = lowercase().replace(' ', '_')

private val ENDED = setOf(
    DownloadedMediaStatus.COMPLETED,
    DownloadedMediaStatus.FAILED,
    DownloadedMediaStatus.CANCELLED,
    DownloadedMediaStatus.PARTIAL,
)

private const val COLLECTIONS_PAGE_SIZE = 100

private const val TAG = "DevDownloads"
