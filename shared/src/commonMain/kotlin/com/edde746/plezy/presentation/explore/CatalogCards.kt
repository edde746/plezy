package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogAudience
import com.edde746.plezy.catalog.CatalogAudiencePeriod
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogNextEpisode
import com.edde746.plezy.catalog.CatalogRequestState
import com.edde746.plezy.catalog.CatalogServerState
import com.edde746.plezy.catalog.catalogItem
import com.edde746.plezy.catalog.label
import com.edde746.plezy.format.formatCompactNumber
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.format.formatPercent
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.formatContentRating
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.HubIcon
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.BadgeIcon
import com.edde746.plezy.presentation.browse.BadgeShortForm
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.strings.T
import kotlin.math.floor
import kotlin.math.roundToLong
import kotlin.time.Clock
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

// Catalog titles (Explore's shelves, catalog search, More like this) as the cards every browse surface draws.

/** At most this many badges stack on a catalog card. */
const val CATALOG_BADGE_LIMIT = 3

/**
 * [item] (a catalog stand-in, [CatalogItem.toMediaItem]) as a poster card; null for any other item. The caption is the
 * compact line (`8.4★ • 2019 • 2h 10min`), the spotlight's metadata the full one ([catalogMetadataLine]), the badges
 * [catalogBadges]. The artwork is the poster variant nearest [posterPx] wide; the spotlight's background is the banner,
 * else the backdrop variant nearest [backdropPx] wide (the spotlight's width in pixels), with the clear logo, the
 * accent colour as its tint and the next episode after its metadata.
 */
fun MediaItem.toCatalogCard(now: Instant, posterPx: Int, backdropPx: Int): MediaCardUi? {
    val catalog = catalogItem ?: return null
    val backdrop = catalog.bannerUrl?.takeIf { it.isNotEmpty() } ?: catalog.backdropFor(backdropPx)
    return MediaCardUi(
        id = id,
        title = catalog.title,
        caption = catalogCaption(this).takeIf { it.isNotEmpty() },
        shape = CardShape.POSTER,
        placeholder = if (kind == MediaKind.MOVIE) PlaceholderKind.MOVIE else PlaceholderKind.SHOW,
        artwork = Artwork.fixed(catalog.posterFor(posterPx)),
        backdrops = listOfNotNull(Artwork.fixed(backdrop)),
        logo = Artwork.fixed(catalog.logoUrl),
        summary = summary,
        metadata = catalogMetadataLine(this, catalog).takeIf { it.isNotEmpty() },
        listMetadata = catalogMetadataLine(this, catalog).takeIf { it.isNotEmpty() },
        qualityLabels = catalogBadges(catalog, now),
        badgeShortForms = catalogBadgeShortForms(catalog),
        accentColor = parseAccentColor(catalog.accentColor),
        spotlightNote = catalog.nextEpisode?.let { nextEpisodeLabel(it, now) },
    )
}

/** [toCatalogCard] as of now. */
fun MediaItem.toCatalogCard(posterPx: Int, backdropPx: Int): MediaCardUi? = toCatalogCard(Clock.System.now(), posterPx, backdropPx)

/** An Explore shelf as a hub row of catalog cards ([toCatalogCard]), with its own icon and the provider's total ("347 results"). */
fun ExploreRow.toHubUi(now: Instant, posterPx: Int, backdropPx: Int): HubUi = HubUi(
    id = hub.id,
    title = hub.title,
    items = hub.items.mapNotNull { it.toCatalogCard(now, posterPx, backdropPx) },
    shape = CardShape.POSTER,
    more = hub.more,
    icon = icon.hubIcon,
    totalResults = totalResults?.let { T.explore.totalResults(it) },
)

/** [toHubUi] as of now. */
fun ExploreRow.toHubUi(posterPx: Int, backdropPx: Int): HubUi = toHubUi(Clock.System.now(), posterPx, backdropPx)

/** The Material Symbol a shelf's header shows. */
val ExploreRowIcon.hubIcon: HubIcon
    get() = when (this) {
        ExploreRowIcon.WATCHLIST -> HubIcon.BOOKMARK
        ExploreRowIcon.RECOMMENDED -> HubIcon.THUMB_UP
        ExploreRowIcon.TRENDING -> HubIcon.TRENDING_UP
        ExploreRowIcon.POPULAR -> HubIcon.WHATSHOT
        ExploreRowIcon.UPCOMING -> HubIcon.EVENT_UPCOMING
    }

/**
 * A catalog card's badges, at most [CATALOG_BADGE_LIMIT], the first that apply in this order: server availability,
 * request state (each its own slot: HD available beside a pending 4K request), "recommended by N users" (else the
 * percent of viewers), adult, the next episode's countdown (only while it is ahead of [now]), a rank (a windowed one
 * over an all-time one), watching now, the viewers in their period, and a show's episodes and minutes per episode.
 */
fun catalogBadges(item: CatalogItem, now: Instant): List<String> {
    val labels = mutableListOf<String>()
    fun add(label: String?) {
        if (!label.isNullOrEmpty() && labels.size < CATALOG_BADGE_LIMIT) labels += label
    }
    val locale = T.locale
    add(availabilityBadge(item.serverState)?.first)
    add(requestBadge(item.serverState)?.first)
    val count = item.recommendationCount
    val percent = item.recommendationPercent
    if (count != null && count > 0) {
        add(T.explore.detail.recommendedByUsers(count))
    } else if (percent != null && percent > 0 && percent <= 1) {
        add(T.explore.detail.recommendedByPercent(formatPercent(percent, locale)))
    }
    if (item.isAdult == true) add(T.explore.badge.adult)
    item.nextEpisode?.takeIf { it.airsAt > now }?.let { add(nextEpisodeLabel(it, now)) }
    val ranks = item.ranks.orEmpty()
    add(ranks.filterNot { it.allTime }.firstNotNullOfOrNull { it.label } ?: ranks.firstOrNull { it.allTime }?.label)
    item.audience?.watchingNow?.takeIf { it > 0 }?.let { add(T.explore.badge.watchingNow(formatCompactNumber(it.toLong(), locale))) }
    add(viewersBadge(item.audience, locale))
    if (item.kind == MediaKind.SHOW) {
        val parts = listOfNotNull(
            item.episodeCount?.takeIf { it > 0 }?.let { T.explore.badge.episodesShort(it.toString()) },
            item.runtimeMinutes?.takeIf { it > 0 }?.let { T.explore.badge.minutesPerEpisode(it.toString()) },
        )
        add(parts.joinToString(" • "))
    }
    return labels
}

/** A catalog card's caption: the score first (`8.4★`), then the year and the runtime, joined with ` • `. */
fun catalogCaption(item: MediaItem): String = listOfNotNull(
    item.rating?.let { "${formatScore(it)}★" },
    item.year?.toString(),
    item.durationMs?.let { formatDurationTextual(it.milliseconds) },
).joinToString(" • ")

/**
 * The full metadata line of a catalog title (list rows, the TV spotlight): certification, year, runtime, the score
 * with its compact vote count (`7.7★ (12.3K)`), its first two genres and its network, joined with ` • `.
 */
fun catalogMetadataLine(item: MediaItem, catalog: CatalogItem): String {
    val parts = mutableListOf<String>()
    formatContentRating(item.contentRating).takeIf { it.isNotEmpty() }?.let { parts += it }
    item.year?.let { parts += it.toString() }
    item.durationMs?.let { parts += formatDurationTextual(it.milliseconds) }
    item.rating?.let { rating ->
        val votes = catalog.votes?.takeIf { it > 0 }?.let { " (${formatCompactNumber(it.toLong(), T.locale)})" }.orEmpty()
        parts += "${formatScore(rating)}★$votes"
    }
    catalog.genres?.takeIf { it.isNotEmpty() }?.let { parts += it.take(2).joinToString(", ") }
    catalog.network?.takeIf { it.isNotEmpty() }?.let { parts += it }
    return parts.joinToString(" • ")
}

/** "Ep 5 in 2d 3h", or "Next in 2d 3h" without an episode number. */
private fun nextEpisodeLabel(next: CatalogNextEpisode, now: Instant): String {
    val duration = formatDurationTextual(next.timeUntil(now))
    return next.episode?.let { T.explore.badge.nextEpisodeIn(it.toString(), duration) } ?: T.explore.badge.nextAiringIn(duration)
}

/**
 * The availability badge's ladder with each rung's short form: available in 4K ("4K"), available (✓), the seasons on
 * the server ("2/3"), partly available (either tier, ◐). Not [CatalogAvailability.label]: the card puts the season
 * count above partly available.
 */
private fun availabilityBadge(state: CatalogServerState?): Pair<String, BadgeShortForm>? {
    state ?: return null
    if (state.availability4k == CatalogAvailability.AVAILABLE) return T.explore.badge.availableIn4k to BadgeShortForm(text = "4K")
    if (state.availability == CatalogAvailability.AVAILABLE) return T.explore.badge.available to BadgeShortForm(BadgeIcon.AVAILABLE)
    val available = state.availableSeasons
    val total = state.totalSeasons
    if (available != null && total != null && available > 0 && total > 0) {
        return T.explore.badge.seasonsAvailable(available.toString(), total.toString()) to BadgeShortForm(text = "$available/$total")
    }
    if (state.availability == CatalogAvailability.PARTIALLY_AVAILABLE || state.availability4k == CatalogAvailability.PARTIALLY_AVAILABLE) {
        return T.explore.badge.partiallyAvailable to BadgeShortForm(BadgeIcon.PARTIAL)
    }
    return null
}

/**
 * Only an approved 4K request reads "4K requested" on a card; otherwise the HD request's state shows. Short form: a
 * clock while it is under way, a no-entry mark once declined or failed.
 */
private fun requestBadge(state: CatalogServerState?): Pair<String, BadgeShortForm>? {
    if (state?.request4k == CatalogRequestState.APPROVED) return T.explore.badge.requested4k to BadgeShortForm(BadgeIcon.REQUESTED)
    val request = state?.request ?: return null
    val ended = request == CatalogRequestState.DECLINED || request == CatalogRequestState.FAILED
    return request.label(is4k = false) to BadgeShortForm(if (ended) BadgeIcon.DECLINED else BadgeIcon.REQUESTED)
}

/** The short forms of a catalog card's status badges ([MediaCardUi.badgeShortForms]). */
fun catalogBadgeShortForms(item: CatalogItem): Map<String, BadgeShortForm> =
    listOfNotNull(availabilityBadge(item.serverState), requestBadge(item.serverState)).toMap()

private fun viewersBadge(audience: CatalogAudience?, locale: String): String? {
    val viewers = audience?.viewers?.takeIf { it > 0 } ?: return null
    val period = audience.viewersPeriod ?: return null
    val n = formatCompactNumber(viewers.toLong(), locale)
    return when (period) {
        CatalogAudiencePeriod.DAY -> T.explore.stats.viewersDay(n)
        CatalogAudiencePeriod.WEEK -> T.explore.stats.viewersWeek(n)
        CatalogAudiencePeriod.MONTH -> T.explore.stats.viewersMonth(n)
        CatalogAudiencePeriod.YEAR -> T.explore.stats.viewersYear(n)
        CatalogAudiencePeriod.ALL_TIME -> T.explore.stats.viewersAllTime(n)
    }
}

/** A 0–10 score: whole without decimals (`8`), otherwise one decimal (`8.4`). */
private fun formatScore(value: Double): String {
    if (value == floor(value)) return value.toLong().toString()
    val tenths = (value * 10).roundToLong()
    return "${tenths / 10}.${tenths % 10}"
}

/** `#RRGGBB` as opaque `0xAARRGGBB`; null for anything else. */
private fun parseAccentColor(value: String?): Long? {
    if (value == null || value.length != 7 || value[0] != '#') return null
    val hex = value.substring(1)
    if (!hex.all { it in '0'..'9' || it.lowercaseChar() in 'a'..'f' }) return null
    return 0xFF000000L or hex.toLong(16)
}
