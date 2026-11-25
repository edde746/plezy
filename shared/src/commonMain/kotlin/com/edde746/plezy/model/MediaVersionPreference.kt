package com.edde746.plezy.model

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import kotlin.time.Clock
import kotlin.time.Instant

private const val TAG = "MediaVersions"

/**
 * A remembered version choice for a series or a standalone item, persisted as `{"id","sig","idx","at"}`.
 * Values written before the record form were bare positional ints; [fromJson] still reads them.
 */
data class MediaVersionPreference(
    /** The chosen [MediaVersion.id]; matches only on the item the pick was made on (ids differ per episode). */
    val versionId: String? = null,
    /** The chosen [MediaVersion.signature], matching the equivalent version on sibling episodes. */
    val signature: String? = null,
    /** The position in the version list at pick time: the last resort, and all a legacy value carries. */
    val index: Int,
    /** Epoch ms of the last write, for pruning the oldest entries; null on legacy entries (pruned first). */
    val updatedAt: Long? = null,
) {
    fun toJson(): JsonObject = buildJsonObject {
        versionId?.let { put("id", it) }
        signature?.let { put("sig", it) }
        put("idx", index)
        updatedAt?.let { put("at", it) }
    }

    /**
     * This preference's index in [versions]: the exact id, then the signature (tiered, see
     * [MediaVersion.findMatchingIndex]), then the stored index while in range; null when nothing applies.
     */
    fun resolveIndex(versions: List<MediaVersion>): Int? {
        if (versions.isEmpty()) return null
        if (!versionId.isNullOrEmpty()) {
            val byId = versions.indexOfFirst { it.id == versionId }
            if (byId >= 0) return byId
        }
        if (!signature.isNullOrEmpty()) MediaVersion.findMatchingIndex(versions, setOf(signature))?.let { return it }
        return index.takeIf { it in versions.indices }
    }

    companion object {
        /** [version], at [index] in its item's version list, picked at [now]. */
        fun forVersion(version: MediaVersion, index: Int, now: Instant = Clock.System.now()): MediaVersionPreference =
            MediaVersionPreference(
                versionId = version.id.ifEmpty { null },
                signature = version.signature,
                index = index,
                updatedAt = now.toEpochMilliseconds(),
            )

        /** A stored value: the record form, or a legacy bare index; anything else reads as index 0. */
        fun fromJson(raw: JsonElement?): MediaVersionPreference {
            if (raw is JsonPrimitive && !raw.isString) raw.intOrNull?.let { return MediaVersionPreference(index = it) }
            if (raw !is JsonObject) return MediaVersionPreference(index = 0)
            fun string(key: String) = (raw[key] as? JsonPrimitive)?.takeIf { it.isString }?.content
            fun number(key: String) = (raw[key] as? JsonPrimitive)?.takeIf { !it.isString }
            return MediaVersionPreference(
                versionId = string("id"),
                signature = string("sig"),
                index = number("idx")?.intOrNull ?: 0,
                updatedAt = number("at")?.longOrNull,
            )
        }
    }
}

/**
 * [item]'s versions for item-level actions, without every browse row carrying heavy media-source payloads: its own
 * when present, else [fallbackVersions], else the versions of the item [backend] fetches. Empty when none are known or
 * the fetch fails (logged).
 */
suspend fun resolveMediaVersions(item: MediaItem, backend: MediaBackend, fallbackVersions: List<MediaVersion>? = null): List<MediaVersion> {
    item.mediaVersions?.takeIf { it.isNotEmpty() }?.let { return it }
    fallbackVersions?.takeIf { it.isNotEmpty() }?.let { return it }
    return try {
        backend.fetchItem(item.id)?.mediaVersions.orEmpty()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Failed to resolve media versions for ${item.backend.id} item ${item.id}" }
        emptyList()
    }
}
