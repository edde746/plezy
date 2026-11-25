package com.edde746.plezy.presentation.browse

import kotlin.test.Test
import kotlin.test.assertEquals

class HubIconTest {
    @Test
    fun continueWatchingHasThePlayCircleByTheHubOrItsTitle() {
        assertEquals(HubIcon.PLAY_CIRCLE, HubIcon.of("Weiterschauen", continueWatching = true))
        assertEquals(HubIcon.PLAY_CIRCLE, HubIcon.of("On Deck", continueWatching = false))
        assertEquals(HubIcon.PLAY_CIRCLE, HubIcon.of("Continue Watching in TV Shows", continueWatching = false))
    }

    @Test
    fun theFirstKeywordInOrderPicksTheIconElseTheSparkle() {
        assertEquals(HubIcon.SCHEDULE, HubIcon.of("Recently Added in Movies", continueWatching = false))
        assertEquals(HubIcon.STAR, HubIcon.of("Top Rated Movies", continueWatching = false))
        assertEquals(HubIcon.MILITARY_TECH, HubIcon.of("Top Movies of 1999", continueWatching = false))
        assertEquals(HubIcon.VISIBILITY_OFF, HubIcon.of("Unwatched Movies", continueWatching = false))
        assertEquals(HubIcon.TRENDING_UP, HubIcon.of("Trending", continueWatching = false))
        assertEquals(HubIcon.AUTO_AWESOME, HubIcon.of("Latest Albums in Music", continueWatching = false))
    }
}
