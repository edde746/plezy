package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.jellyfin.JellyfinCacheResolver
import com.edde746.plezy.jellyfin.JellyfinCore
import com.edde746.plezy.jellyfin.JellyfinMediaInfo
import com.edde746.plezy.jellyfin.array
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.playback.ChapterMarkerClassifier
import com.edde746.plezy.plex.firstObject
import com.edde746.plezy.plex.mediaContainer
import com.edde746.plezy.plex.plexApplyCreditsDetectionPreference
import com.edde746.plezy.plex.plexMediaSourceInfoForSelection
import com.edde746.plezy.plex.plexPlaybackExtrasFromCacheJson
import com.edde746.plezy.plex.resolvePlexPlaybackSelection
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.time.Duration

/**
 * Track and chapter information of an item read from the API cache alone, never the network: what a downloaded copy
 * plays with, with or without a live client. [cacheServerId] is the client's cache scope, or the download's when no
 * client is there. Every read answers null when the row is missing or unreadable.
 */
class CachedPlaybackMetadata(private val store: ApiCacheStore, private val jellyfinCache: JellyfinCacheResolver) {
    /**
     * The cached source of [itemId]'s version [mediaIndex]. Plex picks the version as stored (the file is already on
     * disk, so a stale "unplayable" flag must not swap in another version's tracks) and, for a version stacked over
     * several files, the file holding [position]. Jellyfin and Emby take `MediaSources[mediaIndex]` (out of range is
     * the first) with the item's chapters and trickplay.
     */
    suspend fun mediaSourceInfo(
        backend: BackendKind,
        cacheServerId: String,
        itemId: String,
        mediaIndex: Int = 0,
        position: Duration? = null,
    ): MediaSourceInfo? = readOrNull("media source info", cacheServerId, itemId) {
        when (backend) {
            BackendKind.PLEX -> {
                val metadata = plexMetadata(cacheServerId, itemId) ?: return@readOrNull null
                val selection = resolvePlexPlaybackSelection(metadata, mediaIndex, preferPlayable = false, position = position)
                selection?.let { plexMediaSourceInfoForSelection(metadata, it) }
            }
            BackendKind.JELLYFIN, BackendKind.EMBY -> {
                val raw = jellyfinItem(cacheServerId, itemId).raw
                val sources = raw.array("MediaSources")
                if (sources.isNullOrEmpty()) return@readOrNull null
                val index = if (mediaIndex in sources.indices) mediaIndex else 0
                val selected = sources[index] as? JsonObject ?: return@readOrNull null
                JellyfinMediaInfo.mediaSourceInfo(selected, raw.array("Chapters"), raw["Trickplay"], index)
            }
        }
    }

    /**
     * Cached chapters and skip markers, missing marker types filled from chapter titles by the bundled classifier and
     * the user's [introPattern] / [creditsPattern] ([forceChapterFallback] prefers the chapters over the server's
     * markers). Plex drops credits markers where the show or movie has credits detection off; Jellyfin adds its cached
     * media segments (none when that row is missing or unreadable).
     */
    suspend fun playbackExtras(
        backend: BackendKind,
        cacheServerId: String,
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
    ): PlaybackExtras? = readOrNull("playback extras", cacheServerId, itemId) {
        when (backend) {
            BackendKind.PLEX -> {
                val metadata = plexMetadata(cacheServerId, itemId) ?: return@readOrNull null
                val extras = plexPlaybackExtrasFromCacheJson(
                    metadata,
                    ChapterMarkerClassifier.bundled,
                    introPattern,
                    creditsPattern,
                    forceChapterFallback,
                )
                plexApplyCreditsDetectionPreference(extras, metadata) { ratingKey -> plexMetadata(cacheServerId, ratingKey) }
            }
            BackendKind.JELLYFIN, BackendKind.EMBY -> {
                val item = jellyfinItem(cacheServerId, itemId)
                JellyfinMediaInfo.playbackExtras(
                    item.raw,
                    itemId,
                    introPattern,
                    creditsPattern,
                    forceChapterFallback,
                    jellyfinSegmentMarkers(item.scopeId, itemId),
                )
            }
        }
    }

    private suspend fun plexMetadata(cacheServerId: String, ratingKey: String): JsonObject? =
        store.get(cacheServerId, "/library/metadata/$ratingKey").mediaContainer()?.get("Metadata").firstObject()

    private class JellyfinCachedItem(val raw: JsonObject, val scopeId: String)

    /** The item's row under [cacheServerId] (a machine id or a `{machineId}/{userId}` scope); throws when none is cached. */
    private suspend fun jellyfinItem(cacheServerId: String, itemId: String): JellyfinCachedItem {
        val found = jellyfinCache.findItem(cacheServerId, itemId)
            ?: throw IllegalStateException("No MediaBrowser cache row for $cacheServerId:$itemId")
        return JellyfinCachedItem(Json.parseToJsonElement(found.row.data).jsonObject, found.key.scopeId)
    }

    private suspend fun jellyfinSegmentMarkers(scopeId: String, itemId: String) = try {
        JellyfinMediaInfo.segmentMarkers(store.get(scopeId, "/MediaSegments/${JellyfinCore.segment(itemId)}"))
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Cached media segments unavailable for $scopeId:$itemId" }
        emptyList()
    }

    private suspend fun <T> readOrNull(what: String, cacheServerId: String, itemId: String, read: suspend () -> T?): T? = try {
        read()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "Cached $what unavailable for $cacheServerId:$itemId" }
        null
    }

    private companion object {
        const val TAG = "CachedPlaybackMetadata"
    }
}
