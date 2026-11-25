package com.edde746.plezy.model

import kotlinx.serialization.json.JsonPrimitive

/**
 * The trailer among [parent]'s [extras]: Plex's own pick (the parent's trailer key) when it is among them, else the
 * first extra classified as a trailer; null when none is.
 */
fun primaryTrailer(parent: MediaItem, extras: List<MediaItem>): MediaItem? {
    parent.trailerKey?.let { key ->
        // "/library/metadata/52601" -> "52601"
        val primaryId = key.substringAfterLast('/')
        extras.firstOrNull { it.id == primaryId }?.let { return it }
    }
    return extras.firstOrNull(::isTrailerExtra)
}

/** Plex classifies an extra by its subtype; MediaBrowser by its `ExtraType` or `Type`. */
private fun isTrailerExtra(extra: MediaItem): Boolean {
    if (extra.backend == BackendKind.PLEX && extra.subtype != null) return extra.subtype.equals("trailer", ignoreCase = true)
    fun rawString(key: String): String? = (extra.raw?.get(key) as? JsonPrimitive)?.takeIf { it.isString }?.content
    return rawString("ExtraType").equals("trailer", ignoreCase = true) || rawString("Type").equals("trailer", ignoreCase = true)
}
