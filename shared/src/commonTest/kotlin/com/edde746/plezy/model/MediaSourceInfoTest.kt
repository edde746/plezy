package com.edde746.plezy.model

import com.edde746.plezy.playback.ChapterMarkerClassifier
import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.milliseconds

class MediaSourceInfoTest {
    private val classifier = ChapterMarkerClassifier.bundled

    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    // MediaChapter traversal

    private val chapters = listOf(
        MediaChapter(id = 1, startTimeOffset = 0, title = "One"),
        MediaChapter(id = 2, startTimeOffset = 10000, title = "Two"),
        MediaChapter(id = 3, startTimeOffset = 20000, title = "Three"),
    )

    @Test
    fun forwardTraversalUsesTheFirstStrictlyLaterChapter() {
        assertEquals(1, MediaChapter.seekTargetIndex(9999.milliseconds, chapters, forward = true))
        assertEquals(2, MediaChapter.seekTargetIndex(10000.milliseconds, chapters, forward = true))
        assertNull(MediaChapter.seekTargetIndex(20000.milliseconds, chapters, forward = true))
    }

    @Test
    fun previousTraversalPreservesTheStrictThreeSecondRestartThreshold() {
        assertEquals(0, MediaChapter.seekTargetIndex(13000.milliseconds, chapters, forward = false))
        assertEquals(1, MediaChapter.seekTargetIndex(13001.milliseconds, chapters, forward = false))
        assertNull(MediaChapter.seekTargetIndex(3000.milliseconds, chapters, forward = false))
    }

    @Test
    fun handlesEmptyChaptersAndNullStarts() {
        assertNull(MediaChapter.seekTargetIndex(Duration.ZERO, emptyList(), forward = true))
        val missingStart = listOf(MediaChapter(id = 1), MediaChapter(id = 2, startTimeOffset = 5000))
        assertEquals(1, MediaChapter.seekTargetIndex(Duration.ZERO, missingStart, forward = true))
        assertEquals(0, MediaChapter.seekTargetIndex(3001.milliseconds, missingStart, forward = false))
    }

    @Test
    fun indexAtPositionUsesStartInclusiveAndEndExclusiveRanges() {
        assertEquals(0, MediaChapter.indexAtPosition(Duration.ZERO, chapters))
        assertEquals(0, MediaChapter.indexAtPosition(9999.milliseconds, chapters))
        assertEquals(1, MediaChapter.indexAtPosition(10000.milliseconds, chapters))
        assertEquals(2, MediaChapter.indexAtPosition(1.hours, chapters))
    }

    // MediaSubtitleTrack label

    @Test
    fun languageLeadsAndABareForcedTitleFoldsIntoTheSuffix() {
        val track = MediaSubtitleTrack(
            id = 401,
            index = 0,
            codec = "srt",
            languageCode = "eng",
            title = "Forced",
            displayTitle = "English (SRT)",
            selected = false,
            forced = true,
        )
        assertEquals(TrackLabel("English (Forced)", "SRT"), track.labelForIndex(0))
        assertEquals(TrackLabel("English (Forced)", "SRT"), track.label)
    }

    @Test
    fun resolvesTheLanguageNameEvenWhenTheSourceTitleIsBlank() {
        val track = MediaSubtitleTrack(
            id = 402,
            index = 1,
            codec = "ass",
            languageCode = "jpn",
            title = " ",
            displayTitle = "Japanese Signs/Songs",
            selected = false,
            forced = false,
        )
        assertEquals(TrackLabel("Japanese", "ASS"), track.labelForIndex(1))
    }

    @Test
    fun subtitleFallsBackToDisplayTitleWhenNothingElseIsAvailable() {
        val track = MediaSubtitleTrack(id = 403, index = 2, displayTitle = "Director Commentary", selected = false, forced = false)
        assertEquals(TrackLabel("Director Commentary"), track.labelForIndex(2))
    }

    // MediaAudioTrack label

    @Test
    fun audioBuildsFromStreamFieldsIgnoringTheServerDisplayTitle() {
        val track = MediaAudioTrack(
            id = 301,
            index = 1,
            codec = "eac3",
            language = "English",
            languageCode = "eng",
            title = null,
            displayTitle = "English (EAC3 5.1)",
            channels = 6,
            selected = true,
        )
        assertEquals(TrackLabel("English", "E-AC3 · 5.1"), track.label)
    }

    @Test
    fun serverLanguageNameWinsOverAnUnmappableCode() {
        val track = MediaAudioTrack(id = 302, index = 2, codec = "aac", language = "Filipino", languageCode = "fil", channels = 2, selected = false)
        assertEquals(TrackLabel("Filipino", "AAC · Stereo"), track.label)
    }

    @Test
    fun audioFallsBackToDisplayTitleWhenStreamFieldsAreMissing() {
        val track = MediaAudioTrack(id = 303, index = 3, displayTitle = "Surround (EAC3)", selected = false)
        assertEquals(TrackLabel("Surround (EAC3)"), track.label)
    }

    @Test
    fun `a display title names the audio without the codec and channels again`() {
        val track = MediaAudioTrack(id = 304, index = 0, codec = "aac", channels = 2, displayTitle = "AAC - Stereo", selected = false)
        assertEquals(TrackLabel("AAC - Stereo"), track.label)
    }

    @Test
    fun fallbackIndexIsClampedForZeroIndexedStreams() {
        assertEquals(TrackLabel("Audio Track 1"), MediaAudioTrack(id = 0, index = 0, selected = false).label)
    }

    @Test
    fun anUnknownCodeShowsInCapitalsAndMetadataPrefixesQuotesAndCodecSegmentsGo() {
        assertEquals(TrackLabel("UND", "AAC"), MediaAudioTrack(id = 1, index = 0, codec = "aac", languageCode = "und", selected = false).label)
        assertEquals(
            TrackLabel("Commentary"),
            MediaAudioTrack(id = 2, index = 0, title = "title=\"Commentary\"", selected = false).label,
        )
        assertEquals(
            TrackLabel("English", "Signs · SRT"),
            MediaSubtitleTrack(id = 3, index = 0, codec = "srt", languageCode = "eng", title = "Signs - SRT", selected = false, forced = false).label,
        )
        assertEquals(
            TrackLabel("English (Forced)", "SRT"),
            MediaSubtitleTrack(id = 4, index = 0, codec = "srt", languageCode = "eng", title = "Forced", selected = false, forced = false).label,
            "a title that says forced is a forced track",
        )
    }

    // PlaybackExtras.withChapterFallback

    /** Chapters laid out back to back from zero, as (title, seconds) pairs. */
    private fun layout(vararg parts: Pair<String, Int>): List<MediaChapter> {
        var at = 0L
        return parts.mapIndexed { i, (title, seconds) ->
            val start = at
            at += seconds * 1000L
            MediaChapter(id = i + 1, startTimeOffset = start, endTimeOffset = at, title = title)
        }
    }

    private fun markersOf(extras: PlaybackExtras) = extras.markers.map { it.type to it.id }

    private fun fallback(
        chapters: List<MediaChapter>,
        markers: List<MediaMarker> = emptyList(),
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
    ) = PlaybackExtras.withChapterFallback(chapters, markers, classifier, introPattern, creditsPattern, forceChapterFallback)

    @Test
    fun findsTheIntroAndCreditsOfAnEpisodeWhoseChaptersAreAllChapterN() {
        val extras = fallback(
            layout("Chapter 1" to 120, "Chapter 2" to 90, "Chapter 3" to 540, "Chapter 4" to 540, "Chapter 5" to 90, "Chapter 6" to 30),
        )
        assertEquals(listOf("intro" to 2, "credits" to 5), markersOf(extras))
    }

    @Test
    fun marksTheExplicitOpNotTheColdOpenTitledIntroBeforeIt() {
        val extras = fallback(layout("Intro" to 84, "OP" to 90, "Episode" to 946, "ED" to 90, "Preview" to 15))
        assertEquals(listOf("intro" to 2, "credits" to 4), markersOf(extras))
    }

    @Test
    fun aShortEpisodesIntroTheModelTakesForContentIsStillTheIntroByItsTitle() {
        // A 90 s episode: the model scores this "Intro" as content, and picks no intro at all.
        val extras = fallback(layout("Intro" to 15, "Episode" to 60, "Credits" to 15))
        assertEquals(listOf("intro" to 1, "credits" to 3), markersOf(extras))
    }

    @Test
    fun chaptersWithoutAnEndUseTheNextChapterStart() {
        val laid = layout("Prologue" to 60, "OP" to 90, "Part A" to 1140, "ED" to 90, "Preview" to 30)
        val extras = fallback(laid.take(4).map { MediaChapter(id = it.id, startTimeOffset = it.startTimeOffset, title = it.title) } + laid.last())
        assertEquals(listOf("intro" to 2, "credits" to 4), markersOf(extras))
        assertEquals(laid[1].endTimeOffset, extras.markers.first().endTimeOffset)
    }

    @Test
    fun storedBlankPatternsBehaveLikeTheDefaultsInsteadOfMatchingEveryChapter() {
        val chapters = layout("Overture" to 90, "Part 1" to 1110)
        val blank = fallback(chapters, introPattern = "", creditsPattern = "   ")
        val unset = fallback(chapters)
        assertEquals(markersOf(unset), markersOf(blank))
        assertFalse(blank.markers.any { it.id == 2 })
    }

    @Test
    fun aCustomIntroPatternReplacesOnlyTheIntroPick() {
        val extras = fallback(layout("Prologue" to 60, "OP" to 90, "Part A" to 1140, "ED" to 90, "Preview" to 30), introPattern = "prologue")
        assertEquals(listOf("intro" to 1, "credits" to 4), markersOf(extras))
    }

    @Test
    fun aCustomCreditsPatternReplacesOnlyTheCreditsPick() {
        val extras = fallback(layout("Prologue" to 60, "OP" to 90, "Part A" to 1140, "ED" to 90, "Preview" to 30), creditsPattern = "preview")
        assertEquals(listOf("intro" to 2, "credits" to 5), markersOf(extras))
    }

    private val cap = PlaybackExtras.maxChapterIntroDuration.inWholeMilliseconds
    private val movieEnd = 7200000L

    @Test
    fun aMovieLengthOpeningCreditsChapterDoesNotBecomeAnIntro() {
        val extras = fallback(
            listOf(
                MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 480000, title = "Opening Credits"),
                MediaChapter(id = 2, startTimeOffset = 480000, endTimeOffset = movieEnd, title = "Chapter 2"),
            ),
        )
        assertTrue(extras.markers.isEmpty())
    }

    @Test
    fun aCustomPatternChapterExactlyAtTheCapStillQualifiesOneMillisecondOverDoesNot() {
        val atCap = fallback(listOf(MediaChapter(id = 1, startTimeOffset = 1000, endTimeOffset = 1000 + cap, title = "Intro")), introPattern = "^intro$")
        val overCap = fallback(listOf(MediaChapter(id = 1, startTimeOffset = 1000, endTimeOffset = 1001 + cap, title = "Intro")), introPattern = "^intro$")
        assertEquals(listOf("intro"), atCap.markers.map { it.type })
        assertTrue(overCap.markers.isEmpty())
    }

    @Test
    fun theCapUsesTheNextChapterStartWhenTheChapterHasNoEnd() {
        val extras = fallback(
            listOf(
                MediaChapter(id = 1, startTimeOffset = 0, title = "Opening"),
                MediaChapter(id = 2, startTimeOffset = 600000, title = "Chapter 2"),
            ),
        )
        assertTrue(extras.markers.isEmpty())
    }

    @Test
    fun longCreditsChaptersAreStillDerived() {
        val extras = fallback(
            listOf(
                MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 6600000, title = "Chapter 1"),
                MediaChapter(id = 2, startTimeOffset = 6600000, endTimeOffset = movieEnd, title = "End Credits"),
            ),
        )
        assertEquals(listOf("credits"), extras.markers.map { it.type })
        assertEquals(movieEnd, extras.markers.single().endTimeOffset)
    }

    @Test
    fun serverSuppliedIntroMarkersAreNeverCapped() {
        val extras = fallback(emptyList(), listOf(MediaMarker(id = 1, type = "intro", startTimeOffset = 0, endTimeOffset = 600000)))
        assertEquals(listOf("intro"), extras.markers.map { it.type })
        assertEquals(600000L, extras.markers.single().endTimeOffset)
    }

    @Test
    fun aDroppedChapterIntroLeavesNativeMarkersIntactUnderForcedFallback() {
        val extras = fallback(
            listOf(MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 480000, title = "Opening Credits")),
            listOf(MediaMarker(id = 9, type = "credits", startTimeOffset = 6600000, endTimeOffset = movieEnd)),
            forceChapterFallback = true,
        )
        assertEquals(listOf("credits"), extras.markers.map { it.type })
        assertEquals(9, extras.markers.single().id)
    }

    /** The chapters around the false positive in The Shining. */
    private val shiningChapters = listOf(
        MediaChapter(id = 6, startTimeOffset = 864280, endTimeOffset = 1057930, title = "Family History"),
        MediaChapter(id = 7, startTimeOffset = 1057930, endTimeOffset = 1230900, title = "Closing Day"),
        MediaChapter(id = 8, startTimeOffset = 1230900, endTimeOffset = 8337040, title = "The Tour"),
        MediaChapter(id = 39, startTimeOffset = 8337040, endTimeOffset = 8476300, title = "The Overlook Claims Jack"),
        MediaChapter(id = 40, startTimeOffset = 8476300, endTimeOffset = 8625760, title = "End Credits"),
    )

    @Test
    fun aMidFilmClosingDayChapterDoesNotBecomeCredits() {
        assertEquals(listOf("credits" to 40), markersOf(fallback(shiningChapters)))
    }

    @Test
    fun aSavedPatternThatStillMatchesClosingDayIsGatedByPosition() {
        val extras = fallback(
            shiningChapters,
            creditsPattern = """(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$""",
        )
        assertEquals(listOf(40), extras.markers.map { it.id })
    }

    @Test
    fun aCreditsChapterStartingAtThreeQuartersOfTheRuntimeQualifiesOneMillisecondEarlierDoesNot() {
        val atThreshold = fallback(
            listOf(
                MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 90000, title = "Episode"),
                MediaChapter(id = 2, startTimeOffset = 90000, endTimeOffset = 120000, title = "ED"),
            ),
            creditsPattern = "^ed$",
        )
        val beforeThreshold = fallback(
            listOf(
                MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 89999, title = "Episode"),
                MediaChapter(id = 2, startTimeOffset = 89999, endTimeOffset = 120000, title = "ED"),
            ),
            creditsPattern = "^ed$",
        )
        assertEquals(listOf("credits"), atThreshold.markers.map { it.type })
        assertTrue(beforeThreshold.markers.isEmpty())
    }

    @Test
    fun serverSuppliedCreditsMarkersAreNeverGatedByPosition() {
        val extras = fallback(shiningChapters, listOf(MediaMarker(id = 1, type = "credits", startTimeOffset = 1057930, endTimeOffset = 1230900)))
        assertEquals(listOf(1), extras.markers.map { it.id })
    }
}
