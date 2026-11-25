package com.edde746.plezy.presentation.ratings

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.strings.T
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.log10
import kotlin.math.pow

/**
 * A score's brand mark: a rating site's logo or a tracker's, drawn in the text colour. [id] names the artwork;
 * [aspect] is its viewBox's width over height, so a badge at a fixed height has a width known before layout.
 */
enum class RatingIcon(val id: String, val aspect: Double) {
    IMDB("imdb", 575 / 289.83),
    TMDB("tmdb", 185.04 / 133.4),
    RT_FRESH("rt_fresh", 138.75 / 141.25),
    RT_ROTTEN("rt_rotten", 145.0 / 140),
    RT_UPRIGHT("rt_upright", 106.25 / 140),
    RT_SPILLED("rt_spilled", 143.75 / 108.75),
    METACRITIC("metacritic", 1.0),
    LETTERBOXD("letterboxd", 262.0 / 97),

    /** The trackers' marks are their service logos, square. */
    TRAKT("trakt", 1.0),
    SIMKL("simkl", 1.0),
    MAL("mal", 1.0),
    ANILIST("anilist", 1.0),
}

/** The icon of a score without a brand mark: a star, people for the unattributed audience score. */
enum class GenericRatingIcon { STAR, PEOPLE }

/** A score's brand mark and its value written the way the source's own site writes it. */
data class RatingBadgeInfo(val icon: RatingIcon, val value: String)

/**
 * The brand badge of a score from [source] (its key, [MediaRatingSource.source]) of [value] (0–10): IMDb and Simkl with
 * one decimal, MyAnimeList with two, the Metascore whole, Letterboxd as 0–5 stars, and the scores out of 100 (Rotten
 * Tomatoes, TMDB, Trakt, AniList) as percentages. Rotten Tomatoes is fresh (upright for the audience) from 60 %, the
 * Tomatometer's own threshold, rotten (spilled) below. `null` for keys without a brand (`critic`, `audience`, unknown).
 */
fun ratingBadgeInfo(source: String, value: Double): RatingBadgeInfo? = when (source) {
    "imdb" -> RatingBadgeInfo(RatingIcon.IMDB, fixed(value, 1))
    "tmdb" -> RatingBadgeInfo(RatingIcon.TMDB, percent(value))
    "rottenTomatoes", "rottenTomatoesCritic" ->
        RatingBadgeInfo(if (value >= ROTTEN_TOMATOES_FRESH) RatingIcon.RT_FRESH else RatingIcon.RT_ROTTEN, percent(value))
    "rottenTomatoesAudience" ->
        RatingBadgeInfo(if (value >= ROTTEN_TOMATOES_FRESH) RatingIcon.RT_UPRIGHT else RatingIcon.RT_SPILLED, percent(value))
    "metacritic" -> RatingBadgeInfo(RatingIcon.METACRITIC, fixed(value * 10, 0))
    "letterboxd" -> RatingBadgeInfo(RatingIcon.LETTERBOXD, fixed(value / 2, 1))
    "trakt" -> RatingBadgeInfo(RatingIcon.TRAKT, percent(value))
    "simkl" -> RatingBadgeInfo(RatingIcon.SIMKL, fixed(value, 1))
    "mal" -> RatingBadgeInfo(RatingIcon.MAL, fixed(value, 2))
    "anilist" -> RatingBadgeInfo(RatingIcon.ANILIST, percent(value))
    else -> null
}

/** The localized name of a score's [source], or `null` for an unknown key: such a score is dropped, never shown raw. */
fun ratingSourceLabel(source: String): String? = when (source) {
    "critic" -> T.common.ratingSource.critic
    "audience" -> T.common.ratingSource.audience
    "imdb" -> T.common.ratingSource.imdb
    "tmdb" -> T.common.ratingSource.tmdb
    "rottenTomatoes" -> T.common.ratingSource.rottenTomatoes
    "rottenTomatoesCritic" -> T.common.ratingSource.rottenTomatoesCritic
    "rottenTomatoesAudience" -> T.common.ratingSource.rottenTomatoesAudience
    "metacritic" -> T.common.ratingSource.metacritic
    "letterboxd" -> T.common.ratingSource.letterboxd
    "simkl" -> T.common.ratingSource.simkl
    "mal" -> T.common.ratingSource.mal
    "anilist" -> T.common.ratingSource.anilist
    "trakt" -> T.common.ratingSource.trakt
    else -> null
}

/** A neutral 0–10 score: whole without decimals, otherwise one decimal. */
fun formatRating(value: Double): String = if (value == floor(value)) value.toLong().toString() else fixed(value, 1)

/** [rating]'s value as its brand badge writes it, else [formatRating]. */
fun mediaRatingLabel(rating: MediaRatingSource): String = ratingBadgeInfo(rating.source, rating.value)?.value ?: formatRating(rating.value)

/** One badge of an inline strip (detail line, spotlight, scores pill): [icon], or [generic] without one, then [value]. */
data class InlineRatingBadge(val icon: RatingIcon?, val generic: GenericRatingIcon, val value: String)

/** The inline strip's badges, one per score, in order. */
fun inlineRatingBadges(ratings: List<MediaRatingSource>): List<InlineRatingBadge> = ratings.map { rating ->
    InlineRatingBadge(
        icon = ratingBadgeInfo(rating.source, rating.value)?.icon,
        generic = if (rating.source == "audience") GenericRatingIcon.PEOPLE else GenericRatingIcon.STAR,
        value = mediaRatingLabel(rating),
    )
}

/**
 * The whole strip as one announcement, each score read as `<source> <value>` (the value alone where the source is
 * unnamed), so a reader can tell which score is whose.
 */
fun ratingsSemanticLabel(ratings: List<MediaRatingSource>): String = ratings.joinToString(", ") { rating ->
    val label = ratingSourceLabel(rating.source)
    if (label != null) "$label ${mediaRatingLabel(rating)}" else mediaRatingLabel(rating)
}

/**
 * One chip of a detail page's Ratings section: the source's [icon] (described by [sourceLabel]) and its value, or,
 * without a brand, a star and the source's name with the 0–10 value; `(N votes)` follows where the source says.
 */
data class RatingChip(val icon: RatingIcon?, val sourceLabel: String?, val label: String)

/** The Ratings section's chips, in order; scores from unknown sources are dropped. */
fun ratingChips(ratings: List<MediaRatingSource>): List<RatingChip> = ratings.mapNotNull { rating ->
    val source = ratingSourceLabel(rating.source)
    val badge = ratingBadgeInfo(rating.source, rating.value)
    if (source == null && badge == null) return@mapNotNull null
    val value = badge?.value ?: "$source ${fixed(rating.value, 1)}"
    val label = rating.votes?.let { "$value (${T.explore.stats.votes(formatCompactCount(it.toLong()))})" } ?: value
    RatingChip(badge?.icon, source, label)
}

/** [count] in short form, to three significant digits: 950, 1.23K, 12.3K, 123K, 3.21M, 1M for 999,999. */
fun formatCompactCount(count: Long): String {
    if (abs(count) < 1000) return count.toString()
    val sign = if (count < 0) "-" else ""
    val magnitude = abs(count).toDouble()
    var tier = 1
    while (tier < COMPACT_SUFFIXES.lastIndex && magnitude >= 1000.0.pow(tier + 1)) tier++
    var (value, decimals) = threeDigits(magnitude / 1000.0.pow(tier))
    if (value >= 1000 && tier < COMPACT_SUFFIXES.lastIndex) {
        tier++
        threeDigits(magnitude / 1000.0.pow(tier)).let { (v, d) -> value = v; decimals = d }
    }
    val text = fixed(value, decimals).let { if (decimals > 0) it.trimEnd('0').trimEnd('.') else it }
    return sign + text + COMPACT_SUFFIXES[tier]
}

/** [value] rounded to three significant digits (all of its whole part), and the decimals that leaves. */
private fun threeDigits(value: Double): Pair<Double, Int> {
    val digits = if (value < 1) 1 else floor(log10(value)).toInt() + 1
    val decimals = (3 - digits).coerceAtLeast(0)
    val factor = 10.0.pow(decimals)
    return floor(value * factor + 0.5) / factor to decimals
}

private val COMPACT_SUFFIXES = listOf("", "K", "M", "B", "T")

/** Ratings are 0–10; the Tomatometer's 60 % is 6. */
private const val ROTTEN_TOMATOES_FRESH = 6.0

private fun percent(value: Double): String = "${fixed(value * 10, 0)}%"

/** [value] (not negative) with [decimals] digits after the point, half up. */
private fun fixed(value: Double, decimals: Int): String {
    val factor = 10.0.pow(decimals).toLong()
    val scaled = floor(value * factor + 0.5).toLong()
    if (decimals == 0) return scaled.toString()
    return "${scaled / factor}.${(scaled % factor).toString().padStart(decimals, '0')}"
}
