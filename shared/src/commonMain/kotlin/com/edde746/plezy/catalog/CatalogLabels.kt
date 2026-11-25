package com.edde746.plezy.catalog

import com.edde746.plezy.strings.T

// Per-value wording of catalog enums shared by the detail screen and the card badges. Chip selection, precedence and
// badge composition stay at each call site.

val CatalogAirStatus.label: String
    get() = when (this) {
        CatalogAirStatus.AIRING -> T.explore.status.airing
        CatalogAirStatus.ENDED -> T.explore.status.ended
        CatalogAirStatus.CANCELED -> T.explore.status.canceled
        CatalogAirStatus.UPCOMING -> T.explore.status.upcoming
    }

val CatalogSeasonName.label: String
    get() = when (this) {
        CatalogSeasonName.WINTER -> T.explore.season.winter
        CatalogSeasonName.SPRING -> T.explore.season.spring
        CatalogSeasonName.SUMMER -> T.explore.season.summer
        CatalogSeasonName.FALL -> T.explore.season.fall
    }

/** "Fall 2025", or the bare season without a year. */
val CatalogSeasonInfo.label: String
    get() = year?.let { T.explore.season.withYear(name.label, it.toString()) } ?: name.label

val CatalogFormat.label: String
    get() = when (this) {
        CatalogFormat.TV -> T.explore.format.tv
        CatalogFormat.TV_SHORT -> T.explore.format.tvShort
        CatalogFormat.MOVIE -> T.explore.format.movie
        CatalogFormat.SPECIAL -> T.explore.format.special
        CatalogFormat.OVA -> T.explore.format.ova
        CatalogFormat.ONA -> T.explore.format.ona
        CatalogFormat.MUSIC -> T.explore.format.music
        CatalogFormat.OTHER -> T.explore.format.other
    }

val CatalogSourceMaterial.label: String
    get() = when (this) {
        CatalogSourceMaterial.ORIGINAL -> T.explore.sourceMaterial.original
        CatalogSourceMaterial.MANGA -> T.explore.sourceMaterial.manga
        CatalogSourceMaterial.LIGHT_NOVEL -> T.explore.sourceMaterial.lightNovel
        CatalogSourceMaterial.NOVEL -> T.explore.sourceMaterial.novel
        CatalogSourceMaterial.VISUAL_NOVEL -> T.explore.sourceMaterial.visualNovel
        CatalogSourceMaterial.GAME -> T.explore.sourceMaterial.game
        CatalogSourceMaterial.WEB_COMIC -> T.explore.sourceMaterial.webComic
        CatalogSourceMaterial.MUSIC_RELEASE -> T.explore.sourceMaterial.musicRelease
        CatalogSourceMaterial.OTHER_MEDIA -> T.explore.sourceMaterial.otherMedia
    }

val CatalogCreditRole.label: String
    get() = when (this) {
        CatalogCreditRole.DIRECTOR -> T.explore.creditRole.director
        CatalogCreditRole.WRITER -> T.explore.creditRole.writer
        CatalogCreditRole.PRODUCER -> T.explore.creditRole.producer
        CatalogCreditRole.CREATOR -> T.explore.creditRole.creator
        CatalogCreditRole.COMPOSER -> T.explore.creditRole.composer
    }

val CatalogRelationType.label: String
    get() = when (this) {
        CatalogRelationType.PREQUEL -> T.explore.relation.prequel
        CatalogRelationType.SEQUEL -> T.explore.relation.sequel
        CatalogRelationType.SIDE_STORY -> T.explore.relation.sideStory
        CatalogRelationType.SPIN_OFF -> T.explore.relation.spinOff
        CatalogRelationType.ALTERNATIVE_VERSION -> T.explore.relation.alternativeVersion
        CatalogRelationType.SUMMARY -> T.explore.relation.summary
        CatalogRelationType.PARENT_STORY -> T.explore.relation.parentStory
        CatalogRelationType.ADAPTATION -> T.explore.relation.adaptation
        CatalogRelationType.OTHER -> T.explore.relation.other
    }

/**
 * "#3 airing" for an all-time rank; a windowed rank keeps its window ("#3 in Fall 2025", "#3 in 2025"). Null for a
 * windowed rank with neither season nor year.
 */
val CatalogRank.label: String?
    get() {
        if (allTime) {
            val n = rank.toString()
            return when (scope) {
                CatalogRankScope.POPULAR -> T.explore.badge.rankPopular(n)
                CatalogRankScope.AIRING -> T.explore.badge.rankAiring(n)
                CatalogRankScope.RATED -> T.explore.badge.rankRated(n)
                CatalogRankScope.TRENDING -> T.explore.badge.rankTrending(n)
            }
        }
        val window = when {
            season != null && year != null -> T.explore.season.withYear(season.label, year.toString())
            season != null -> season.label
            year != null -> year.toString()
            else -> return null
        }
        return T.explore.badge.rankSeasonal(rank.toString(), window)
    }

/** The availability badge; with [is4k] only "available in 4K" is shown. Null when there is nothing to say. */
fun CatalogAvailability.label(is4k: Boolean): String? {
    if (is4k) return if (this == CatalogAvailability.AVAILABLE) T.explore.badge.availableIn4k else null
    return when (this) {
        CatalogAvailability.AVAILABLE -> T.explore.badge.available
        CatalogAvailability.PARTIALLY_AVAILABLE -> T.explore.badge.partiallyAvailable
        CatalogAvailability.UNAVAILABLE -> null
    }
}

/** The request badge; a pending, approved or processing 4K request reads "4K requested". */
fun CatalogRequestState.label(is4k: Boolean): String {
    if (is4k && this in setOf(CatalogRequestState.PENDING, CatalogRequestState.APPROVED, CatalogRequestState.PROCESSING)) {
        return T.explore.badge.requested4k
    }
    return when (this) {
        CatalogRequestState.PENDING -> T.explore.badge.pendingApproval
        CatalogRequestState.APPROVED -> T.explore.badge.requested
        CatalogRequestState.PROCESSING -> T.explore.badge.processing
        CatalogRequestState.DECLINED -> T.explore.badge.declined
        CatalogRequestState.FAILED -> T.explore.badge.requestFailed
    }
}
