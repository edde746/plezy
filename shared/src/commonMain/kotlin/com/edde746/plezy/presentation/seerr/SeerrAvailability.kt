package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.seerr.SeerrMediaInfo
import com.edde746.plezy.seerr.SeerrMediaStatus
import com.edde746.plezy.seerr.SeerrProduct
import com.edde746.plezy.seerr.SeerrRequest
import com.edde746.plezy.seerr.SeerrRequestStatus
import com.edde746.plezy.seerr.SeerrSeason
import com.edde746.plezy.strings.T

/** Why a title, or one of its seasons, can't be requested: what Seerr already has or is doing for it. */
enum class SeerrBlock {
    AVAILABLE,
    PARTIALLY_AVAILABLE,
    PROCESSING,
    REQUESTED,
    BLOCKLISTED,
    ;

    /** The state in words: "Available", "Requested". */
    val label: String
        get() = when (this) {
            AVAILABLE -> T.seerr.statusAvailable
            PARTIALLY_AVAILABLE -> T.seerr.statusPartiallyAvailable
            PROCESSING -> T.seerr.statusProcessing
            REQUESTED -> T.seerr.statusRequested
            BLOCKLISTED -> T.seerr.statusBlocklisted
        }
}

/**
 * A title's standing on its Seerr instance in one variant ([is4k]), as the Seerr web UI judges it from [info] (null:
 * Seerr has never seen the title) and the instance's [product]: what is available, being processed or claimed by a
 * pending or approved request can't be requested again. A failed arr push can leave the media status Processing or
 * Pending behind, so what only a failed request claims stays requestable; a deleted title may be requested again.
 */
internal class SeerrAvailability(private val info: SeerrMediaInfo?, private val product: SeerrProduct, private val is4k: Boolean) {
    private val variantRequests: List<SeerrRequest> = info?.requests.orEmpty().filter { (it.is4k ?: false) == is4k }

    /** The variant's requests that still claim the title: waiting for approval, or approved. */
    private val activeRequests = variantRequests.filter { it.status == SeerrRequestStatus.PENDING || it.status == SeerrRequestStatus.APPROVED }

    private val failedRequests = variantRequests.filter { it.status == SeerrRequestStatus.FAILED }

    /** Why the movie (or the show as a whole) can't be requested; null when it can. */
    val movieBlock: SeerrBlock?
        get() {
            val info = info ?: return null
            return block(status(info.statusCode, info.status4kCode), activeRequests.isNotEmpty(), failedRequests.isNotEmpty())
        }

    /** Why season [seasonNumber] can't be requested; null when it can. */
    fun seasonBlock(seasonNumber: Int): SeerrBlock? {
        val info = info ?: return null
        val season = info.seasons?.firstOrNull { it.seasonNumber == seasonNumber }
        return block(
            status(season?.statusCode, season?.status4kCode),
            coveredByRequest = activeRequests.any { it.covers(seasonNumber) },
            coveredByFailed = failedRequests.any { it.covers(seasonNumber) },
        )
    }

    private fun status(code: Int?, code4k: Int?): SeerrMediaStatus = SeerrMediaStatus.resolve(if (is4k) code4k else code, product)

    private fun block(status: SeerrMediaStatus, coveredByRequest: Boolean, coveredByFailed: Boolean): SeerrBlock? = when (status) {
        SeerrMediaStatus.AVAILABLE -> SeerrBlock.AVAILABLE
        SeerrMediaStatus.PARTIALLY_AVAILABLE -> SeerrBlock.PARTIALLY_AVAILABLE
        SeerrMediaStatus.PROCESSING, SeerrMediaStatus.PENDING -> when {
            coveredByFailed && !coveredByRequest -> null
            status == SeerrMediaStatus.PROCESSING -> SeerrBlock.PROCESSING
            else -> SeerrBlock.REQUESTED
        }
        SeerrMediaStatus.BLOCKLISTED -> SeerrBlock.BLOCKLISTED
        SeerrMediaStatus.UNKNOWN, SeerrMediaStatus.DELETED -> if (coveredByRequest) SeerrBlock.REQUESTED else null
    }

    private fun SeerrRequest.covers(seasonNumber: Int): Boolean = seasons?.any { it.seasonNumber == seasonNumber } == true
}

/**
 * Why the title [tmdbId] of [kind] can't be requested (not in 4K) on [client]'s instance, null when it can, as its
 * request sheet would judge it. A show counts by its seasons with episodes (specials aside): once none can be
 * requested it is [SeerrBlock.AVAILABLE] when every one is, else [SeerrBlock.REQUESTED].
 */
internal suspend fun seerrRequestBlock(client: SeerrClient, kind: MediaKind, tmdbId: Int): SeerrBlock? {
    val product = client.getPublicSettings().product
    if (kind == MediaKind.MOVIE) return SeerrAvailability(client.getMovie(tmdbId).mediaInfo, product, is4k = false).movieBlock
    val details = client.getTv(tmdbId)
    val availability = SeerrAvailability(details.mediaInfo, product, is4k = false)
    val blocks = details.seasons.orEmpty().filter { it.requestable }.map { availability.seasonBlock(it.seasonNumber) }
    return when {
        blocks.isEmpty() || blocks.any { it == null } -> null
        blocks.all { it == SeerrBlock.AVAILABLE } -> SeerrBlock.AVAILABLE
        else -> SeerrBlock.REQUESTED
    }
}

/** A season a request can name: a numbered one (not the specials) with episodes. */
internal val SeerrSeason.requestable: Boolean get() = seasonNumber > 0 && (episodeCount ?: 0) > 0
