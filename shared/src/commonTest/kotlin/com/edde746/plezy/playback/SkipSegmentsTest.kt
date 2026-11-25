package com.edde746.plezy.playback

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class SkipSegmentsTest {
    private fun chapters(vararg chapters: Pair<Double, String?>) = chapters.map { (start, title) -> Chapter(title, start) }

    // Titles

    @Test
    fun everyListedTitleIsItsKind() {
        for ((title, kind) in SkipSegments.TITLES) assertEquals(kind, SkipSegments.kindOf(title), "\"$title\"")
        assertTrue(SkipSegments.TITLES.size >= 40)
    }

    @Test
    fun theDesignsIntroTitles() = assertKinds(
        SkipKind.INTRO,
        "Intro", "Introduction", "Opening", "Opening Credits", "Opening Titles", "Opening Song", "Title Sequence",
        "Main Titles", "OP", "OP1", "OP 2", "オープニング",
        // Also on anime and Blu-ray releases.
        "Opening Theme", "Opening Sequence", "Main Title", "Theme Song", "Intro Song", "Opening 2", "Op",
    )

    @Test
    fun theDesignsRecapTitles() = assertKinds(
        SkipKind.RECAP,
        "Recap", "Previously", "Previously on…", "Previously on...", "Previously on Breaking Bad", "Last Time", "前回",
        "Last time on Dragon Ball Z", "The Story So Far", "前回のあらすじ",
    )

    @Test
    fun theDesignsCreditsTitles() = assertKinds(
        SkipKind.CREDITS,
        "Credits", "End Credits", "Closing Credits", "Ending", "Ending Song", "Outro", "ED", "ED1", "ED 2", "エンディング",
        "End Titles", "Ending Theme", "Closing",
    )

    @Test
    fun theDesignsPreviewTitles() = assertKinds(
        SkipKind.PREVIEW,
        "Preview", "Next Episode", "Next Episode Preview", "Next Time", "予告", "次回予告", "Next time on Naruto", "Episode Preview",
    )

    @Test
    fun numberingAroundATitleIsIgnored() = assertKinds(
        SkipKind.INTRO,
        "Chapter 1 - Intro", "Chapter 01: Opening", "Ch. 2 - OP", "01. Opening", "1 - Intro", "2) Opening", "03 Opening",
        "  OPENING  ", "Opening 01", "Intro 2",
    )

    @Test
    fun contentAndUntitledTitlesHaveNoKind() {
        for (title in listOf(
            null, "", "   ", "Chapter 3", "Chapter 12", "3", "07", "Episode", "Part A", "Part B", "Avant", "Eyecatch",
            "The Ending", "A New Beginning", "Introduction to Algorithms", "Post-credits scene", "Credits scene", "Opening Night",
            "Previously unseen footage", "Ed's story", "Ending of the war", "Last Supper",
        )) {
            assertNull(SkipSegments.kindOf(title), "\"$title\"")
        }
    }

    // Segments

    @Test
    fun theTestClipsChapters() {
        // tools/media's chapters.mkv.
        val segments = SkipSegments.of(
            chapters(0.0 to "Recap", 4.0 to "Opening", 12.0 to "Episode", 44.0 to "Ending", 54.0 to "Preview"),
            60.0,
        )
        assertEquals(
            listOf(
                SkipSegment(SkipKind.RECAP, 0.0, 4.0),
                SkipSegment(SkipKind.INTRO, 4.0, 12.0),
                SkipSegment(SkipKind.CREDITS, 44.0, 60.0, toEnd = true),
            ),
            segments,
        )
        assertEquals(44.0, SkipSegments.creditsStart(segments))
    }

    @Test
    fun aChapterEndsWhereTheNextStartsAndTheLastAtTheDuration() {
        val segments = SkipSegments.of(chapters(0.0 to "Cold open", 60.0 to "OP", 150.0 to "Part A", 1300.0 to "ED"), 1420.0)
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 60.0, 150.0), SkipSegment(SkipKind.CREDITS, 1300.0, 1420.0, toEnd = true)), segments)
    }

    @Test
    fun chaptersInAnyOrderAndPastTheEndAreHandled() {
        val segments = SkipSegments.of(chapters(1300.0 to "ED", 0.0 to "Part A", 60.0 to "OP", 150.0 to "Part B", 1500.0 to "Preview"), 1420.0)
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 60.0, 150.0), SkipSegment(SkipKind.CREDITS, 1300.0, 1420.0, toEnd = true)), segments)
    }

    @Test
    fun noDurationNoSegments() {
        assertEquals(emptyList(), SkipSegments.of(chapters(0.0 to "Intro", 30.0 to "Episode"), 0.0))
        assertEquals(emptyList(), SkipSegments.of(emptyList(), 600.0))
    }

    @Test
    fun introsAndRecapsStartInTheFirstThirdAndLastAtMostThreeMinutes() {
        val late = SkipSegments.of(chapters(0.0 to "Episode", 250.0 to "Intro", 300.0 to "More"), 600.0)
        assertEquals(emptyList(), late, "an intro starting past the first third is content")
        val long = SkipSegments.of(chapters(0.0 to "Opening Credits", 181.0 to "Movie"), 6000.0)
        assertEquals(emptyList(), long, "a movie's long opening credits are the film")
        val exactly = SkipSegments.of(chapters(0.0 to "Recap", 180.0 to "Episode"), 2400.0)
        assertEquals(listOf(SkipSegment(SkipKind.RECAP, 0.0, 180.0)), exactly)
    }

    @Test
    fun creditsStartInTheSecondHalf() {
        val early = SkipSegments.of(chapters(0.0 to "Episode", 200.0 to "Credits", 260.0 to "Episode continues"), 600.0)
        assertEquals(emptyList(), early)
        val toEnd = SkipSegments.of(chapters(0.0 to "Episode", 250.0 to "Credits"), 600.0)
        assertEquals(emptyList(), toEnd, "credits to the end must start in the second half too")
    }

    @Test
    fun segmentsUnderTwoSecondsAreIgnored() {
        val segments = SkipSegments.of(chapters(0.0 to "Intro", 1.5 to "Episode", 590.0 to "Credits", 591.0 to "Episode"), 600.0)
        assertEquals(emptyList(), segments)
    }

    @Test
    fun adjacentChaptersOfOneKindMerge() {
        val segments = SkipSegments.of(
            chapters(0.0 to "Opening", 40.0 to "Opening Song", 100.0 to "Episode", 1300.0 to "End Credits", 1350.0 to "Credits 2"),
            1400.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 0.0, 100.0), SkipSegment(SkipKind.CREDITS, 1300.0, 1400.0, toEnd = true)), segments)
    }

    @Test
    fun aMergedIntroOverThreeMinutesIsContent() {
        val segments = SkipSegments.of(chapters(0.0 to "Opening", 100.0 to "OP 2", 200.0 to "Episode"), 2400.0)
        assertEquals(emptyList(), segments)
    }

    @Test
    fun creditsFollowedOnlyByPreviewsRunToTheEnd() {
        val segments = SkipSegments.of(chapters(0.0 to "Part A", 1300.0 to "Ending", 1390.0 to "Next Episode Preview"), 1420.0)
        assertEquals(listOf(SkipSegment(SkipKind.CREDITS, 1300.0, 1420.0, toEnd = true)), segments)
    }

    @Test
    fun creditsBeforeAPostCreditsSceneEndWhereItStarts() {
        val segments = SkipSegments.of(chapters(0.0 to "Movie", 5400.0 to "End Credits", 5800.0 to "Post-credits scene"), 5900.0)
        assertEquals(listOf(SkipSegment(SkipKind.CREDITS, 5400.0, 5800.0)), segments)
        assertNull(SkipSegments.creditsStart(segments))
    }

    @Test
    fun aPreviewAfterContentIsSkippedOnlyAtTheEnd() {
        // ED, then a C-part, then the preview: the ED ends at the C-part; the preview alone runs to the end.
        val anime = SkipSegments.of(chapters(0.0 to "Part A", 1250.0 to "ED", 1340.0 to "Part C", 1390.0 to "Preview"), 1420.0)
        assertEquals(listOf(SkipSegment(SkipKind.CREDITS, 1250.0, 1340.0), SkipSegment(SkipKind.CREDITS, 1390.0, 1420.0, toEnd = true)), anime)
        assertEquals(1390.0, SkipSegments.creditsStart(anime))
        // A preview with more of the episode after it isn't skipped.
        val middle = SkipSegments.of(chapters(0.0 to "Part A", 800.0 to "Preview", 900.0 to "Part B"), 1400.0)
        assertEquals(emptyList(), middle)
    }

    @Test
    fun aSliverAfterTheCreditsStillLetsThemRunToTheEnd() {
        val segments = SkipSegments.of(chapters(0.0 to "Episode", 1300.0 to "Credits", 1399.5 to null), 1400.0)
        assertEquals(listOf(SkipSegment(SkipKind.CREDITS, 1300.0, 1400.0, toEnd = true)), segments)
    }

    // The model's picks

    @Test
    fun anEpisodeOfNumberedChaptersHasItsIntroAndCredits() {
        val segments = SkipSegments.of(
            chapters(0.0 to "Chapter 1", 120.0 to "Chapter 2", 210.0 to "Chapter 3", 750.0 to "Chapter 4", 1290.0 to "Chapter 5"),
            1410.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 120.0, 210.0), SkipSegment(SkipKind.CREDITS, 1290.0, 1410.0, toEnd = true)), segments)
    }

    @Test
    fun anEpisodeOfUntitledChaptersHasItsIntroAndCredits() {
        val segments = SkipSegments.of(chapters(0.0 to null, 120.0 to null, 210.0 to null, 750.0 to "", 1290.0 to ""), 1410.0)
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 120.0, 210.0), SkipSegment(SkipKind.CREDITS, 1290.0, 1410.0, toEnd = true)), segments)
    }

    @Test
    fun aColdOpenTitledIntroBeforeTheOpeningStaysContent() {
        val segments = SkipSegments.of(
            chapters(0.0 to "Intro", 84.0 to "OP", 174.0 to "Episode", 1120.0 to "ED", 1210.0 to "Preview"),
            1225.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 84.0, 174.0), SkipSegment(SkipKind.CREDITS, 1120.0, 1225.0, toEnd = true)), segments)
    }

    @Test
    fun namesNoListHasCount() {
        val portuguese = SkipSegments.of(
            chapters(0.0 to "Prólogo", 120.0 to "Abertura", 210.0 to "Parte A", 750.0 to "Parte B", 1350.0 to "ED+Cast"),
            1440.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 120.0, 210.0), SkipSegment(SkipKind.CREDITS, 1350.0, 1440.0, toEnd = true)), portuguese)
        val staffRoll = SkipSegments.of(
            chapters(0.0 to "Avant", 120.0 to "Title Sequence", 210.0 to "Part A", 750.0 to "Part B", 1350.0 to "Staff Roll"),
            1440.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.INTRO, 120.0, 210.0), SkipSegment(SkipKind.CREDITS, 1350.0, 1440.0, toEnd = true)), staffRoll)
    }

    @Test
    fun aRecapTitleKeepsItsKindBesideThePickedIntro() {
        val segments = SkipSegments.of(
            chapters(0.0 to "Recap", 60.0 to "Chapter 2", 150.0 to "Chapter 3", 1400.0 to "Chapter 4", 2600.0 to "Chapter 5"),
            2700.0,
        )
        assertEquals(listOf(SkipSegment(SkipKind.RECAP, 0.0, 60.0), SkipSegment(SkipKind.INTRO, 60.0, 150.0)), segments)
    }

    @Test
    fun evenlyNumberedChaptersHaveNoIntroOrCredits() {
        assertEquals(emptyList(), SkipSegments.of(List(12) { Chapter("Chapter ${it + 1}", it * 600.0) }, 7200.0), "a movie")
        assertEquals(emptyList(), SkipSegments.of(List(5) { Chapter("Chapter ${it + 1}", it * 300.0) }, 1500.0), "an episode")
    }

    @Test
    fun aMidFilmClosingDayIsContent() {
        val segments = SkipSegments.of(
            chapters(
                0.0 to "Family History", 1057.93 to "Closing Day", 1230.9 to "The Tour", 8337.04 to "The Overlook Claims Jack",
                8476.3 to "End Credits",
            ),
            8625.76,
        )
        assertEquals(listOf(SkipSegment(SkipKind.CREDITS, 8476.3, 8625.76, toEnd = true)), segments)
    }

    private fun assertKinds(kind: SkipKind, vararg titles: String) {
        for (title in titles) assertEquals(kind, SkipSegments.kindOf(title), "\"$title\"")
    }
}
