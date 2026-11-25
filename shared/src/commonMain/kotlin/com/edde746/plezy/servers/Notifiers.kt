package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.filter

/**
 * An event about one item that also concerns its ancestors: an episode's [parentChain] is `[seasonId, showId]`, a
 * season's `[showId]`, a movie's empty.
 */
interface HierarchicalEvent {
    val itemId: String
    val serverId: ServerId
    val parentChain: List<String>

    /** `"{serverId}:{itemId}"`. */
    val globalKey: String get() = buildGlobalKey(serverId, itemId)

    fun affectsItem(id: String): Boolean = itemId == id || id in parentChain

    fun affectsAnyOf(ids: Set<String>): Boolean = itemId in ids || parentChain.any { it in ids }

    /** [globalKeys] holds this event's own key or one of `"{serverId}:{ancestorId}"`. */
    fun affectsAnyGlobalKey(globalKeys: Set<String>): Boolean =
        globalKey in globalKeys || parentChain.any { buildGlobalKey(serverId, it) in globalKeys }
}

/**
 * The events a screen showing some items cares about, filters read anew for every event. [serverId] non-null: only
 * that server's. [globalKeys] non-null decides alone; else [itemIds]: null passes everything, an empty set nothing.
 */
fun <E : HierarchicalEvent> Flow<E>.affecting(
    serverId: () -> ServerId? = { null },
    globalKeys: () -> Set<String>? = { null },
    itemIds: () -> Set<String>?,
): Flow<E> = filter { event ->
    val server = serverId()
    if (server != null && event.serverId != server) return@filter false
    val keys = globalKeys()
    if (keys != null) return@filter event.affectsAnyGlobalKey(keys)
    val ids = itemIds()
    ids == null || event.affectsAnyOf(ids)
}

/** The id filter for a screen showing [items]: each item with its parent and grandparent. */
fun hierarchicalEventIds(items: Iterable<MediaItem>): Set<String> = buildSet {
    for (item in items) {
        add(item.id)
        item.parentId?.let { add(it) }
        item.grandparentId?.let { add(it) }
    }
}

/**
 * [hierarchicalEventIds] as `"{serverId}:{id}"` keys. Items without a server fall back to [fallbackServerId]; null
 * when that is missing too, so the caller matches by id rather than silently under-matching.
 */
fun hierarchicalEventGlobalKeys(items: Iterable<MediaItem>, fallbackServerId: ServerId? = null): Set<String>? {
    val keys = mutableSetOf<String>()
    for (item in items) {
        val serverId = ServerId.tryParse(item.serverId) ?: fallbackServerId ?: return null
        keys += buildGlobalKey(serverId, item.id)
        item.parentId?.let { keys += buildGlobalKey(serverId, it) }
        item.grandparentId?.let { keys += buildGlobalKey(serverId, it) }
    }
    return keys
}

/** The server an event for [item] is routed by; null, with a warning, when the item has none. */
internal fun serverIdForEvent(item: MediaItem, tag: String, event: String): ServerId? {
    val serverId = ServerId.tryParse(item.serverId)
    if (serverId == null) Log.w(tag) { "missing serverId for ${item.id}, skipping $event event" }
    return serverId
}

/** An app-lifetime event stream: every emission reaches every current collector; nothing replays to later ones. */
internal fun <T> eventFlow(): MutableSharedFlow<T> = MutableSharedFlow(extraBufferCapacity = Channel.UNLIMITED)

/** Who reconciles with the server after a deletion was dropped from screens. */
enum class DeletionOrigin {
    /** The user deleted it here. */
    LOCAL,

    /** The server's push channel reported it; the coarse library change that accompanies it owns the refetch. */
    SERVER_PUSH,
}

/**
 * An item deleted from a server (or only its download, [isDownloadOnly]: screens drop those only in offline mode).
 * [leafCount] is the episodes it held: 1 for an episode.
 */
data class DeletionEvent(
    override val itemId: String,
    override val serverId: ServerId,
    override val parentChain: List<String>,
    val kind: MediaKind,
    val leafCount: Int = 1,
    val isDownloadOnly: Boolean = false,
    val origin: DeletionOrigin = DeletionOrigin.LOCAL,
) : HierarchicalEvent

/** The app's deletion events. */
class DeletionNotifier {
    private val _events = eventFlow<DeletionEvent>()
    val events: SharedFlow<DeletionEvent> = _events.asSharedFlow()

    fun notify(event: DeletionEvent) {
        Log.d(TAG) { "deleted ${event.globalKey} (${event.kind.id}, parents ${event.parentChain})" }
        _events.tryEmit(event)
    }

    /** Skipped, with a warning, for an item without a server. */
    fun notifyDeletedItem(item: MediaItem, isDownloadOnly: Boolean = false) {
        val serverId = serverIdForEvent(item, TAG, "deletion") ?: return
        notify(
            DeletionEvent(
                itemId = item.id,
                serverId = serverId,
                parentChain = item.parentChain,
                kind = item.kind,
                leafCount = item.leafCount ?: 1,
                isDownloadOnly = isDownloadOnly,
            ),
        )
    }

    private companion object {
        const val TAG = "DeletionNotifier"
    }
}

enum class LibraryRefreshType { COLLECTIONS, PLAYLISTS }

/** Asks library tabs to refetch their collections or playlists. */
class LibraryRefreshNotifier {
    private val _events = eventFlow<LibraryRefreshType>()
    val events: SharedFlow<LibraryRefreshType> = _events.asSharedFlow()

    val collectionsChanged: Flow<LibraryRefreshType> get() = events.filter { it == LibraryRefreshType.COLLECTIONS }

    fun notifyCollectionsChanged() {
        _events.tryEmit(LibraryRefreshType.COLLECTIONS)
    }

    fun notifyPlaylistsChanged() {
        _events.tryEmit(LibraryRefreshType.PLAYLISTS)
    }
}
