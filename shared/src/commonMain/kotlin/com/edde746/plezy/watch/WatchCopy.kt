package com.edde746.plezy.watch

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion

/**
 * One file in this user's libraries that a room can play: a version of an item on one server. It is the `ref` the Open
 * Watch Party SDK hands back with a choice, and the one the player attaches with once it has that file open.
 *
 * Copies compare by server, item and version only, so the player's own description of what it opened equals the
 * resolver's candidate for the same file, and an open made for another version never binds to this one. [item] and
 * [version] are the item as last fetched, for display and for opening without a lookup.
 */
class WatchCopy(
    val serverId: String,
    val itemId: String,
    /** The backend's version (Plex `Media`, Jellyfin/Emby media source) id; empty when the item lists no versions. */
    val versionId: String,
    val item: MediaItem? = null,
    val version: MediaVersion? = null,
) {
    /** The version's length: its parts back to back, or the item's own length when it has only this one version. */
    val durationMs: Long? get() = versionDurationMs(item, version)

    override fun equals(other: Any?): Boolean =
        other is WatchCopy && other.serverId == serverId && other.itemId == itemId && other.versionId == versionId

    override fun hashCode(): Int = (serverId.hashCode() * 31 + itemId.hashCode()) * 31 + versionId.hashCode()

    override fun toString(): String = "WatchCopy($serverId:$itemId${if (versionId.isEmpty()) "" else "#$versionId"})"

    companion object {
        /** The copy of [version] of [item]. [item] must carry its server. */
        fun of(item: MediaItem, version: MediaVersion?): WatchCopy = WatchCopy(
            serverId = requireNotNull(item.serverId) { "a watch copy needs its item's server" },
            itemId = item.id,
            versionId = version?.id.orEmpty(),
            item = item,
            version = version,
        )
    }
}

/**
 * [version]'s length as the server reports it: the sum of its parts when every part has one, else the item's own length
 * when [version] is its only version (or it lists none). Null when neither is known.
 */
fun versionDurationMs(item: MediaItem?, version: MediaVersion?): Long? {
    val parts = version?.parts.orEmpty()
    if (parts.isNotEmpty() && parts.all { (it.durationMs ?: 0) > 0 }) return parts.sumOf { it.durationMs!! }
    val only = item?.mediaVersions.orEmpty().size <= 1
    val itemDuration = item?.durationMs
    return if (only && itemDuration != null && itemDuration > 0) itemDuration else null
}

/** Where the room's version sits among an item's versions: its [index] and the [sourceId] the server knows it by. */
internal data class WatchVersion(val index: Int, val sourceId: String)

/**
 * [copy]'s version among [item]'s versions, for opening the room's file rather than this viewer's own pick: null when
 * the copy names no version or [item] no longer lists it (the viewer's own version plays then); the source passed
 * through at index 0 when [item] lists no versions.
 */
internal fun watchVersionOf(item: MediaItem, copy: WatchCopy): WatchVersion? {
    if (copy.versionId.isEmpty()) return null
    val versions = item.mediaVersions.orEmpty()
    if (versions.isEmpty()) return WatchVersion(0, copy.versionId)
    val index = versions.indexOfFirst { it.id == copy.versionId }
    return if (index < 0) null else WatchVersion(index, copy.versionId)
}
