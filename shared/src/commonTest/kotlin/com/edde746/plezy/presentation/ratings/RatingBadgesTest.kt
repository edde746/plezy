package com.edde746.plezy.presentation.ratings

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** How a score is badged, written and announced wherever a title's scores show. */
class RatingBadgesTest {
    @Test
    fun rottenTomatoesCriticsAreFreshFromTheTomatometersSixtyPercent() {
        assertEquals(RatingBadgeInfo(RatingIcon.RT_FRESH, "60%"), ratingBadgeInfo("rottenTomatoesCritic", 6.0))
        assertEquals(RatingBadgeInfo(RatingIcon.RT_ROTTEN, "59%"), ratingBadgeInfo("rottenTomatoesCritic", 5.9))
        assertEquals(RatingIcon.RT_FRESH, ratingBadgeInfo("rottenTomatoes", 9.2)?.icon, "the unsplit key follows the critics")
        assertEquals("76%", ratingBadgeInfo("rottenTomatoesCritic", 7.57)?.value, "a whole percentage")
    }

    @Test
    fun rottenTomatoesAudienceUsesThePopcornPairOnTheSameThreshold() {
        assertEquals(RatingIcon.RT_UPRIGHT, ratingBadgeInfo("rottenTomatoesAudience", 6.0)?.icon)
        assertEquals(RatingIcon.RT_SPILLED, ratingBadgeInfo("rottenTomatoesAudience", 5.9)?.icon)
    }

    @Test
    fun everyBrandedSourceIsWrittenTheWayItsOwnSiteWritesIt() {
        val cases = listOf(
            Triple("imdb", 7.5, RatingBadgeInfo(RatingIcon.IMDB, "7.5")),
            Triple("tmdb", 6.8, RatingBadgeInfo(RatingIcon.TMDB, "68%")),
            Triple("metacritic", 8.2, RatingBadgeInfo(RatingIcon.METACRITIC, "82")),
            Triple("letterboxd", 9.2, RatingBadgeInfo(RatingIcon.LETTERBOXD, "4.6")),
            Triple("trakt", 9.13, RatingBadgeInfo(RatingIcon.TRAKT, "91%")),
            Triple("anilist", 8.5, RatingBadgeInfo(RatingIcon.ANILIST, "85%")),
            Triple("simkl", 8.43, RatingBadgeInfo(RatingIcon.SIMKL, "8.4")),
            Triple("mal", 8.612, RatingBadgeInfo(RatingIcon.MAL, "8.61")),
        )
        for ((source, value, badge) in cases) assertEquals(badge, ratingBadgeInfo(source, value), source)
    }

    @Test
    fun sourcesWithoutABrandGetNoBadge() {
        for (source in listOf("critic", "audience", "rogerebert", "")) assertNull(ratingBadgeInfo(source, 8.0), source)
    }

    @Test
    fun everySourceTheMappersEmitHasALabelAndUnknownKeysNone() {
        val sources = listOf(
            "critic", "audience", "imdb", "tmdb", "rottenTomatoes", "rottenTomatoesCritic", "rottenTomatoesAudience",
            "metacritic", "letterboxd", "simkl", "mal", "anilist", "trakt",
        )
        for (source in sources) assertTrue(!ratingSourceLabel(source).isNullOrEmpty(), source)
        assertNotEquals(ratingSourceLabel("rottenTomatoesCritic"), ratingSourceLabel("rottenTomatoesAudience"))
        assertNull(ratingSourceLabel("rogerebert"))
        assertNull(ratingSourceLabel(""))
    }

    @Test
    fun theSpotlightBadgesEveryScoreTheListingCarried() {
        val ratings = listOf(MediaRatingSource("rottenTomatoesCritic", 9.2), MediaRatingSource("rottenTomatoesAudience", 8.5))

        assertEquals(
            listOf(
                InlineRatingBadge(RatingIcon.RT_FRESH, GenericRatingIcon.STAR, "92%"),
                InlineRatingBadge(RatingIcon.RT_UPRIGHT, GenericRatingIcon.STAR, "85%"),
            ),
            inlineRatingBadges(ratings),
        )
    }

    @Test
    fun anUnattributedCommunityScoreKeepsTheGenericIconAndTheNeutralValue() {
        val badges = inlineRatingBadges(listOf(MediaRatingSource("audience", 8.3)))

        assertEquals(listOf(InlineRatingBadge(null, GenericRatingIcon.PEOPLE, "8.3")), badges)
    }

    @Test
    fun anUnattributedScoreIsAGenericStar() {
        assertEquals(listOf(InlineRatingBadge(null, GenericRatingIcon.STAR, "7")), inlineRatingBadges(listOf(MediaRatingSource("", 7.0))))
    }

    @Test
    fun theStripIsAnnouncedAsOneLabelNamingEachSource() {
        val label = ratingsSemanticLabel(listOf(MediaRatingSource("rottenTomatoesCritic", 9.2), MediaRatingSource("imdb", 7.4), MediaRatingSource("", 6.5)))

        assertEquals("${T.common.ratingSource.rottenTomatoesCritic} 92%, ${T.common.ratingSource.imdb} 7.4, 6.5", label)
    }

    @Test
    fun theRatingsSectionLabelsUnbrandedScoresAddsVotesAndDropsUnknownSources() {
        val chips = ratingChips(
            listOf(
                MediaRatingSource("imdb", 9.3, 3207270),
                MediaRatingSource("critic", 7.0),
                MediaRatingSource("rogerebert", 8.0),
                MediaRatingSource("mal", 8.62, 1234),
            ),
        )

        assertEquals(
            listOf(
                RatingChip(RatingIcon.IMDB, T.common.ratingSource.imdb, "9.3 (${T.explore.stats.votes("3.21M")})"),
                RatingChip(null, T.common.ratingSource.critic, "${T.common.ratingSource.critic} 7.0"),
                RatingChip(RatingIcon.MAL, T.common.ratingSource.mal, "8.62 (${T.explore.stats.votes("1.23K")})"),
            ),
            chips,
        )
    }

    @Test
    fun voteCountsAreWrittenShortToThreeSignificantDigits() {
        val cases = mapOf(
            950L to "950",
            1000L to "1K",
            1234L to "1.23K",
            12345L to "12.3K",
            123456L to "123K",
            999999L to "1M",
            3207270L to "3.21M",
            2_500_000_000L to "2.5B",
        )
        for ((count, written) in cases) assertEquals(written, formatCompactCount(count), "$count")
    }
}
