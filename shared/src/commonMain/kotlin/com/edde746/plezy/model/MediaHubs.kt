package com.edde746.plezy.model

import kotlin.concurrent.atomics.AtomicReference
import kotlin.concurrent.atomics.ExperimentalAtomicApi

/** The user's resumable Continue Watching row, by its id or identifier (Plex `*.inprogress.*`, Jellyfin `*.continue`). */
val MediaHub.isContinueWatchingHub: Boolean get() = anySemanticKey(continueWatchingKeys)

/**
 * Selecting an item honours the Continue Watching action preference. Broader than [isContinueWatchingHub]: Next Up
 * and On Deck rows share the activation preference without the remove-from-Continue-Watching menu.
 */
val MediaHub.usesContinueWatchingAction: Boolean get() = isContinueWatchingHub || anySemanticKey(continueWatchingActionKeys)

private fun MediaHub.anySemanticKey(matches: KeyMemo): Boolean = matches(id) || (identifier != null && matches(identifier))

private val hubKeySeparators = Regex("[^a-z0-9]+")

private fun hubKeyTokens(rawKey: String): List<String> = rawKey.lowercase().split(hubKeySeparators).filter { it.isNotEmpty() }

// Every card build and D-pad step asks again, and the answer takes two regex passes over a key; a session sees few
// distinct hub keys, so the memos stay small.
private val continueWatchingKeys = KeyMemo { rawKey ->
    val tokens = hubKeyTokens(rawKey)
    rawKey.lowercase().replace(hubKeySeparators, "") == "continuewatching" || "inprogress" in tokens || tokens.lastOrNull() == "continue"
}

private val continueWatchingActionKeys = KeyMemo { rawKey ->
    val tokens = hubKeyTokens(rawKey)
    tokens.lastOrNull() == "nextup" || "ondeck" in tokens
}

/** A per-key memo of [compute], safe to read from any thread. */
@OptIn(ExperimentalAtomicApi::class)
private class KeyMemo(private val compute: (String) -> Boolean) {
    private val answers = AtomicReference(emptyMap<String, Boolean>())

    operator fun invoke(key: String): Boolean {
        answers.load()[key]?.let { return it }
        val answer = compute(key)
        while (true) {
            val current = answers.load()
            if (key in current || answers.compareAndSet(current, current + (key to answer))) return answer
        }
    }
}

/**
 * Sorts home [hubs] in place by the user's [libraryOrder]: a hub by its own library, else by the earliest-ordered
 * library among its items. Hubs without a known library follow, keeping their order. Returns whether the order changed.
 */
fun sortMediaHubsByLibraryOrder(hubs: MutableList<MediaHub>, libraryOrder: List<MediaLibrary>): Boolean {
    if (hubs.size < 2 || libraryOrder.isEmpty()) return false
    val orderByGlobalKey = HashMap<String, Int>()
    libraryOrder.forEachIndexed { index, library -> orderByGlobalKey.getOrPut(library.globalKey) { index } }

    val sorted = hubs.map { it to hubLibraryOrderIndex(it, orderByGlobalKey) }
        .sortedWith(compareBy(nullsLast<Int>()) { it.second })
        .map { it.first }
    var changed = false
    for (i in hubs.indices) {
        if (hubs[i] !== sorted[i]) changed = true
        hubs[i] = sorted[i]
    }
    return changed
}

private fun hubLibraryOrderIndex(hub: MediaHub, orderByGlobalKey: Map<String, Int>): Int? {
    libraryKey(hub.serverId, hub.libraryId)?.let { key -> orderByGlobalKey[key]?.let { return it } }
    return hub.items.mapNotNull { item -> libraryKey(item.serverId ?: hub.serverId, item.libraryId)?.let(orderByGlobalKey::get) }.minOrNull()
}

private fun libraryKey(serverId: String?, libraryId: String?): String? {
    val server = ServerId.tryParse(serverId) ?: return null
    return libraryId?.let { buildGlobalKey(server, it) }
}
