package com.edde746.plezy.model

import com.edde746.plezy.backend.AudioTrackPreference
import com.edde746.plezy.backend.SubtitlePreference
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class TrackSelectionTest {
    private fun sub(
        id: Int,
        languageCode: String? = null,
        title: String? = null,
        displayTitle: String? = null,
        codec: String? = null,
        forced: Boolean = false,
    ) = MediaSubtitleTrack(
        id = id,
        language = languageCode,
        languageCode = languageCode,
        title = title,
        displayTitle = displayTitle,
        codec = codec,
        selected = false,
        forced = forced,
    )

    private fun audio(id: Int, languageCode: String? = null, title: String? = null, codec: String? = null, channels: Int? = null) =
        MediaAudioTrack(id = id, language = languageCode, languageCode = languageCode, title = title, codec = codec, channels = channels, selected = false)

    private fun intent(language: String? = null, forced: Boolean = false, title: String? = null, codec: String? = null, sourceStreamId: Int? = null) =
        SubtitlePreference.Track(language = language, forced = forced, title = title, codec = codec, sourceStreamId = sourceStreamId)

    private val forcedIntent = intent(language = "fre", forced = true, title = "FR Forced [ASS]", codec = "ass")
    private val fullIntent = intent(language = "fre", title = "French", codec = "srt")

    // effectiveForced

    @Test
    fun forcedFlagOrForcedTitleOrDisplayTitleQualifies() {
        assertTrue(sub(1, forced = true).effectiveForced)
        assertTrue(sub(1, title = "FR Forced").effectiveForced)
        assertTrue(sub(1, displayTitle = "Français (Forced SRT)").effectiveForced)
        assertFalse(sub(1, title = "French", displayTitle = "Français (SRT)").effectiveForced)
        assertFalse(sub(1).effectiveForced)
    }

    // Subtitle intent

    @Test
    fun forcedIntentPicksTheTitleOnlyForcedRowOverTheFullRow() {
        val rows = listOf(sub(1, "fre", "French", codec = "srt"), sub(2, "fre", "FR Forced", codec = "ass"))
        assertEquals(2, findSourceTrackForIntent(forcedIntent, rows)?.id)
    }

    @Test
    fun forcedIntentPicksAFlagForcedRow() {
        val rows = listOf(sub(1, "fre", "French", codec = "srt"), sub(2, "fre", codec = "ass", forced = true))
        assertEquals(2, findSourceTrackForIntent(forcedIntent, rows)?.id)
    }

    @Test
    fun forcedIntentDeclinesWhenOnlyFullSameLanguageRowsExist() {
        val rows = listOf(sub(1, "fre", "French", codec = "srt"), sub(2, "eng", "English", codec = "srt"))
        assertNull(findSourceTrackForIntent(forcedIntent, rows))
    }

    @Test
    fun fullIntentDeclinesWhenOnlyForcedRowsShareTheLanguage() {
        val rows = listOf(sub(1, "fre", "FR Forced", codec = "srt"), sub(2, "fre", codec = "ass", forced = true))
        assertNull(findSourceTrackForIntent(fullIntent, rows))
    }

    @Test
    fun codecAndTitleBreakTiesBetweenSameClassRows() {
        val rows = listOf(sub(1, "fre", "Commentary", codec = "ass"), sub(2, "fre", "French", codec = "srt"))
        assertEquals(2, findSourceTrackForIntent(fullIntent, rows)?.id)
    }

    @Test
    fun languageLessIntentDeclinesWhenNoRowCarriesAMatchingTitle() {
        assertNull(findSourceTrackForIntent(intent(title = "French", codec = "srt"), listOf(sub(1, "fre"))))
    }

    @Test
    fun titleOnlyIntentMatchesTheSameTitledRowWhenTagsAreMissing() {
        val rows = listOf(sub(1, title = "English", codec = "subrip"), sub(2, title = "Swedish", codec = "subrip"))
        assertEquals(2, findSourceTrackForIntent(intent(title = "Swedish", codec = "subrip"), rows)?.id)
    }

    @Test
    fun taggedIntentReachesAnUntaggedRowThroughItsTitle() {
        val swedish = intent(language = "swe", title = "Swedish", codec = "subrip")
        assertEquals(1, findSourceTrackForIntent(swedish, listOf(sub(1, title = "Swedish", codec = "subrip")))?.id)
    }

    @Test
    fun titleOnlyIntentReachesATaggedRowThroughItsTitle() {
        val rows = listOf(sub(1, "eng", "English"), sub(2, "swe", "Swedish"))
        assertEquals(2, findSourceTrackForIntent(intent(title = "Swedish", codec = "subrip"), rows)?.id)
    }

    @Test
    fun declaredLanguagesStayAuthoritativeOverACoincidentalTitle() {
        val swedish = intent(language = "swe", title = "Swedish", codec = "subrip")
        assertNull(findSourceTrackForIntent(swedish, listOf(sub(1, "eng", "Swedish"))))
    }

    @Test
    fun codecParityAloneNeverVouchesForAnUntaggedRow() {
        assertNull(findSourceTrackForIntent(intent(title = "Swedish", codec = "subrip"), listOf(sub(1, codec = "subrip"))))
    }

    @Test
    fun anAmbiguousSameTitleUntaggedPairDeclines() {
        val rows = listOf(sub(1, title = "Swedish", codec = "subrip"), sub(2, title = "Swedish", codec = "subrip"))
        assertNull(findSourceTrackForIntent(intent(title = "Swedish", codec = "subrip"), rows))
    }

    @Test
    fun codecSeparatesSameTitledUntaggedRows() {
        val rows = listOf(sub(1, title = "Swedish", codec = "subrip"), sub(2, title = "Swedish", codec = "ass"))
        assertEquals(2, findSourceTrackForIntent(intent(title = "Swedish", codec = "ass"), rows)?.id)
    }

    @Test
    fun forcedParityStillGatesTitleEvidenceMatches() {
        val rows = listOf(sub(1, title = "Swedish Forced", codec = "subrip"))
        assertNull(findSourceTrackForIntent(intent(title = "Swedish", codec = "subrip"), rows))
    }

    @Test
    fun aLanguageParityMatchOutranksATitleEvidenceMatch() {
        val rows = listOf(sub(1, title = "Swedish", codec = "subrip"), sub(2, "swe", "Svenska full"))
        assertEquals(2, findSourceTrackForIntent(intent(language = "swe", title = "Swedish", codec = "subrip"), rows)?.id)
    }

    @Test
    fun theSemanticTitleOutranksARetainedCodecAcrossACodecFlip() {
        val rows = listOf(sub(1, "eng", "Full Subtitles", codec = "ass"), sub(2, "eng", "Signs/OP/ED", codec = "subrip"))
        assertEquals(2, findSourceTrackForIntent(intent(language = "eng", title = "Signs/OP/ED", codec = "ass"), rows)?.id)
    }

    @Test
    fun anIndistinguishableSameLanguagePairDeclines() {
        val rows = listOf(sub(1, "eng", codec = "subrip"), sub(2, "eng", codec = "subrip"))
        assertNull(findSourceTrackForIntent(intent(language = "eng", codec = "subrip"), rows))
    }

    @Test
    fun thePickedRowSettlesATieBetweenIdenticalSameLanguageRows() {
        val rows = listOf(
            sub(3, "eng", "Full", codec = "srt"),
            sub(4, "eng", "Full", codec = "srt"),
            sub(5, "eng", "Signs & Songs", codec = "pgs"),
        )
        fun pick(id: Int) = findSourceTrackForIntent(intent(language = "eng", title = "Full", codec = "srt", sourceStreamId = id), rows)?.id
        assertEquals(4, pick(4))
        // A stale id whose row the intent ranks below the tied pair still declines.
        assertNull(pick(5))
    }

    @Test
    fun thePickedRowWinsWhenTheIntentDeclaresNoLanguage() {
        val rows = listOf(sub(1, "eng", "English"), sub(2, "swe", "Swedish"))
        assertEquals(1, findSourceTrackForIntent(intent(title = "Swedish", sourceStreamId = 1), rows)?.id)
    }

    @Test
    fun aPickedIdMissingFromTheCatalogFallsBackToTheSemanticMatch() {
        val rows = listOf(sub(1, "eng", "English"), sub(2, "swe", "Swedish"))
        assertEquals(2, findSourceTrackForIntent(intent(language = "sv", sourceStreamId = 9), rows)?.id)
    }

    // Audio carry

    @Test
    fun audioBridgesTwoAndThreeLetterLanguageCodes() {
        val rows = listOf(audio(1, "eng"), audio(2, "swe"))
        assertEquals(2, findSourceAudioTrackForIntent(AudioTrackPreference(language = "sv"), rows)?.id)
    }

    @Test
    fun audioKeepsTheCommentaryMainDistinction() {
        val rows = listOf(audio(1, "eng", "Main"), audio(2, "eng", "Commentary"))
        assertEquals(2, findSourceAudioTrackForIntent(AudioTrackPreference(language = "eng", title = "Commentary"), rows)?.id)
    }

    @Test
    fun aUniqueTitleVouchesForUntaggedAudio() {
        val rows = listOf(audio(1, title = "Main"), audio(2, title = "Commentary"))
        assertEquals(2, findSourceAudioTrackForIntent(AudioTrackPreference(title = "Commentary"), rows)?.id)
    }

    @Test
    fun audioCodecParityAloneNeverVouchesForAnUntaggedTrack() {
        assertNull(findSourceAudioTrackForIntent(AudioTrackPreference(title = "Commentary", codec = "ac3"), listOf(audio(1, codec = "ac3"))))
    }

    @Test
    fun anAmbiguousSameTitleUntaggedAudioPairDeclines() {
        val rows = listOf(audio(1, title = "Stereo"), audio(2, title = "Stereo"))
        assertNull(findSourceAudioTrackForIntent(AudioTrackPreference(title = "Stereo"), rows))
    }

    @Test
    fun anAudioLanguageContradictionIsNeverRescuedByATitle() {
        val rows = listOf(audio(1, "eng", "Commentary"))
        assertNull(findSourceAudioTrackForIntent(AudioTrackPreference(language = "swe", title = "Commentary"), rows))
    }

    @Test
    fun channelCountBreaksTiesBetweenOtherwiseEqualAudioRows() {
        val rows = listOf(audio(1, "eng", codec = "aac", channels = 2), audio(2, "eng", codec = "aac", channels = 6))
        assertEquals(2, findSourceAudioTrackForIntent(AudioTrackPreference(language = "eng", codec = "aac", channels = 6), rows)?.id)
    }

    @Test
    fun aCommentaryTitleOutranksARetainedAudioCodec() {
        val rows = listOf(audio(1, "eng", "Main", codec = "ac3"), audio(2, "eng", "Commentary", codec = "aac"))
        val carried = AudioTrackPreference(language = "eng", title = "Commentary", codec = "ac3")
        assertEquals(2, findSourceAudioTrackForIntent(carried, rows)?.id)
    }

    @Test
    fun anIndistinguishableSameLanguageAudioPairDeclines() {
        val rows = listOf(audio(1, "eng", codec = "aac", channels = 2), audio(2, "eng", codec = "aac", channels = 2))
        assertNull(findSourceAudioTrackForIntent(AudioTrackPreference(language = "eng", codec = "aac"), rows))
    }
}
