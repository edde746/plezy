package com.edde746.plezy.image

import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.log.UrlTokens
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.SHA1

/**
 * How both UIs' image loaders (Coil on Compose, Nuke on Apple) cache server artwork:
 *
 * - An image is cached under [key], made from its URL with the server's token blanked ([UrlTokens]): no token is part
 *   of a memory or disk cache key, and an image keeps its entry when the token changes. The download still requests
 *   the URL with its token.
 * - The disk cache keeps at most [MAX_ENTRIES] images, none written more than [MAX_AGE_MILLIS] ago: as the app starts,
 *   it deletes [evictions]. An image deleted for its age downloads again the next time it shows.
 * - At most [downloadConcurrency] images download at once; one that receives nothing for [STALL_TIMEOUT_MILLIS]
 *   (headers or body) is aborted, freeing its slot.
 */
object ArtworkCache {
    const val MAX_ENTRIES: Int = 3000
    const val MAX_AGE_MILLIS: Long = 14L * 24 * 60 * 60 * 1000
    const val STALL_TIMEOUT_MILLIS: Long = 30_000

    /** Six images at once; three on the reduced effects tier. */
    fun downloadConcurrency(reduced: Boolean): Int = if (reduced) 3 else 6

    /** `plex_optimized_<lowercase hex SHA-1 of [url] with its tokens blanked>`. */
    @OptIn(DelicateCryptographyApi::class)
    fun key(url: String): String =
        "plex_optimized_" + cryptoProvider.get(SHA1).hasher().hashBlocking(UrlTokens.redact(url).encodeToByteArray()).toHexString()

    /**
     * Of the disk cache's entries, written at [writtenAtMillis] (one time per entry), the indices of those to delete at
     * [nowMillis]: each written more than [MAX_AGE_MILLIS] before it, then the oldest beyond [MAX_ENTRIES].
     */
    fun evictions(writtenAtMillis: List<Long>, nowMillis: Long): List<Int> {
        val (fresh, stale) = writtenAtMillis.indices.partition { nowMillis - writtenAtMillis[it] <= MAX_AGE_MILLIS }
        return stale + fresh.sortedBy { writtenAtMillis[it] }.dropLast(MAX_ENTRIES)
    }
}
