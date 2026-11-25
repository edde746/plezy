package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.SubtitlePreference
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.NAVIGATION
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.OFF
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.SERVER_SELECTED
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class TrackMatchingTest {
    // Forced disambiguation, player track to server row.

    @Test
    fun `a container flagged forced track maps through the forced flag`() {
        val rows = listOf(sourceSub(10, index = 0, languageCode = "fre", codec = "ass"), sourceSub(11, index = 1, languageCode = "fre", codec = "ass", forced = true))
        val regular = sub("2_0", lang = "fre", codec = "ass")
        val forced = sub("2_1", lang = "fre", codec = "ass", isForced = true)
        val all = listOf(regular, forced)
        assertEquals(11, findSourceTrackForNativeSubtitle(forced, rows, all)?.id)
        assertEquals(10, findSourceTrackForNativeSubtitle(regular, rows, all)?.id)
    }

    @Test
    fun `a title only forced track and an untitled regular track stay distinct`() {
        val rows = listOf(
            sourceSub(30, index = 0, languageCode = "fre", title = "Forced", codec = "ass"),
            sourceSub(31, index = 1, languageCode = "fre", codec = "ass"),
            sourceSub(32, index = 2, languageCode = "eng", title = "SDH", codec = "ass"),
        )
        val forcedByName = sub("2_0", lang = "fre", title = "Forced", codec = "ass")
        val regular = sub("2_1", lang = "fre", codec = "ass")
        val all = listOf(forcedByName, regular, sub("2_2", lang = "eng", title = "SDH", codec = "ass"))
        assertEquals(30, findSourceTrackForNativeSubtitle(forcedByName, rows, all)?.id)
        assertEquals(31, findSourceTrackForNativeSubtitle(regular, rows, all)?.id)
    }

    @Test
    fun `a flag forced player track maps to a title only forced row`() {
        val rows = listOf(sourceSub(50, index = 0, languageCode = "fre", title = "FR Forced", codec = "ass"), sourceSub(51, index = 1, languageCode = "fre", codec = "ass"))
        val forced = sub("2_0", lang = "fre", codec = "ass", isForced = true)
        val regular = sub("2_1", lang = "fre", codec = "ass")
        val all = listOf(forced, regular)
        assertEquals(50, findSourceTrackForNativeSubtitle(forced, rows, all)?.id)
        assertEquals(51, findSourceTrackForNativeSubtitle(regular, rows, all)?.id)
    }

    @Test
    fun `a title only forced player track maps to a flag forced row`() {
        val rows = listOf(sourceSub(60, index = 0, languageCode = "fre", codec = "ass", forced = true), sourceSub(61, index = 1, languageCode = "fre", codec = "ass"))
        val forcedByName = sub("2_0", lang = "fre", title = "FR Forced [ASS]", codec = "ass")
        val regular = sub("2_1", lang = "fre", codec = "ass")
        val all = listOf(forcedByName, regular)
        assertEquals(60, findSourceTrackForNativeSubtitle(forcedByName, rows, all)?.id)
        assertEquals(61, findSourceTrackForNativeSubtitle(regular, rows, all)?.id)
    }

    // findNativeTrackForIntent

    private val forcedIntent = SubtitlePreference.Track(language = "fre", forced = true, title = "FR Forced [ASS]", codec = "ass")

    @Test
    fun `a forced intent picks the forced player track in either form`() {
        val byTitle = listOf(sub("1", lang = "fre", title = "French", codec = "srt"), sub("2", lang = "fre", title = "FR Forced", codec = "ass"))
        val byFlag = listOf(sub("1", lang = "fre", title = "French", codec = "srt"), sub("2", lang = "fre", codec = "ass", isForced = true))
        assertEquals("2", findNativeTrackForIntent(forcedIntent, byTitle)?.id)
        assertEquals("2", findNativeTrackForIntent(forcedIntent, byFlag)?.id)
    }

    @Test
    fun `player intent matching declines symmetrically and skips the sentinels`() {
        val fullOnly = listOf(NativeSubtitleTrack.AUTO, NativeSubtitleTrack.OFF, sub("1", lang = "fre", title = "French", codec = "srt"))
        assertNull(findNativeTrackForIntent(forcedIntent, fullOnly))
        assertNull(findNativeTrackForIntent(SubtitlePreference.Track(language = "fre"), listOf(sub("1", lang = "fre", title = "FR Forced", codec = "ass"))))
    }

    @Test
    fun `an untagged player track with the matching title serves the intent`() {
        val intent = SubtitlePreference.Track(language = "swe", title = "Swedish", codec = "subrip")
        val tracks = listOf(NativeSubtitleTrack.AUTO, NativeSubtitleTrack.OFF, sub("3", title = "Swedish", codec = "subrip"))
        assertEquals("3", findNativeTrackForIntent(intent, tracks)?.id)
    }

    @Test
    fun `an ambiguous untagged player pair declines`() {
        val intent = SubtitlePreference.Track(title = "Swedish", codec = "subrip")
        assertNull(findNativeTrackForIntent(intent, listOf(sub("1", title = "Swedish", codec = "subrip"), sub("2", title = "Swedish", codec = "subrip"))))
    }

    @Test
    fun `the audio carry skips the auto and off sentinels`() {
        val tracks = listOf(NativeAudioTrack.AUTO, NativeAudioTrack.OFF, audio("3", lang = "eng"))
        assertEquals("3", findNativeAudioTrackForIntent(audio("x", lang = "eng"), tracks)?.id)
    }

    // selectSubtitleTrack with intents

    private val forcedPreference = PreferredSubtitle.Intent(forcedIntent)

    @Test
    fun `a class preserving intent match is the choice of the viewer`() {
        val tracks = listOf(sub("1", lang = "fre", codec = "ass"), sub("2", lang = "fre", title = "FR Forced", codec = "ass"))
        val result = selector().selectSubtitleTrack(tracks, forcedPreference, null)!!
        assertEquals(NAVIGATION, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `a declined forced intent falls to the server selected full track`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, languageCode = "fre", codec = "ass", selected = true)))
        val result = selector(info = info).selectSubtitleTrack(listOf(sub("1", lang = "fre", codec = "ass")), forcedPreference, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("1", result.track.id)
    }

    @Test
    fun `a declined forced intent honours subtitles off from the server`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, languageCode = "fre", codec = "ass")))
        val result = selector(info = info).selectSubtitleTrack(listOf(sub("1", lang = "fre", codec = "ass")), forcedPreference, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `a servable intent stays pending until its player track arrives`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, languageCode = "fre", codec = "ass"), sourceSub(11, languageCode = "fre", title = "FR Forced", codec = "ass")))
        val s = selector(info = info)
        val arrived = listOf(sub("1", lang = "fre", codec = "ass"))
        assertNull(s.selectSubtitleTrack(arrived, forcedPreference, null))
        val resolved = s.selectSubtitleTrack(arrived + sub("2", lang = "fre", title = "FR Forced", codec = "ass"), forcedPreference, null)!!
        assertEquals(NAVIGATION, resolved.priority)
        assertEquals("2", resolved.track.id)
    }

    @Test
    fun `a deadline pass resolves a pending intent through the ladder`() {
        val info = sourceInfo(
            subs = listOf(sourceSub(10, languageCode = "fre", codec = "ass", selected = true), sourceSub(11, languageCode = "fre", title = "FR Forced", codec = "ass")),
        )
        val arrived = listOf(sub("1", lang = "fre", codec = "ass", isDefault = true))
        val result = selector(info = info).selectSubtitleTrack(arrived, forcedPreference, null, waitForPendingSource = false)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("1", result.track.id)
    }

    @Test
    fun `a full intent does not grab a forced only catalog`() {
        val full = PreferredSubtitle.Intent(SubtitlePreference.Track(language = "fre", title = "French", codec = "ass"))
        val result = selector().selectSubtitleTrack(listOf(sub("1", lang = "fre", title = "FR Forced", codec = "ass")), full, null)!!
        assertEquals(OFF, result.priority)
        assertEquals("no", result.track.id)
    }

    // Container sidecars

    private val containerRows = listOf(sourceSub(40, index = 0), sourceSub(41, index = 1))
    private val containerTracks = listOf(sub("2_0", isExternal = true, isContainer = true), sub("2_1", isExternal = true, isContainer = true))

    @Test
    fun `a metadata free row maps to its container track`() {
        assertEquals(containerTracks[1], findNativeTrackForSourceSubtitle(containerRows[1], containerTracks, containerRows))
    }

    @Test
    fun `a metadata free container track maps back to its row`() {
        assertEquals(40, findSourceTrackForNativeSubtitle(containerTracks[0], containerRows, containerTracks)?.id)
    }

    @Test
    fun `server to player keeps metadata scoring when the row has no container position`() {
        val probe = sourceSub(40, index = 0, languageCode = "eng")
        val tracks = listOf(sub("2_0", lang = "eng", isExternal = true, isContainer = true))
        assertEquals(tracks.first(), findNativeTrackForSourceSubtitle(probe, tracks, listOf(sourceSub(41, index = 1, languageCode = "eng"))))
    }

    @Test
    fun `player to server refuses a container track without a position`() {
        val probe = sub("2_0", lang = "eng", isExternal = true, isContainer = true)
        val others = listOf(sub("2_1", lang = "eng", isExternal = true, isContainer = true))
        assertNull(findSourceTrackForNativeSubtitle(probe, listOf(sourceSub(40, index = 0, languageCode = "eng")), others))
    }

    // Same-language audio

    private val frenchRows = listOf(
        sourceAudio(20, index = 0, languageCode = "fre", codec = "ac3", channels = 2),
        sourceAudio(21, index = 1, languageCode = "fre", codec = "ac3", channels = 6),
    )
    private val stereo = audio("1_0", lang = "fre", codec = "ac3", channels = 2)
    private val surround = audio("1_1", lang = "fre", codec = "ac3", channels = 6)

    @Test
    fun `a surround player track maps to the 6 channel row`() {
        assertEquals(21, findSourceTrackForNativeAudio(surround, frenchRows, listOf(stereo, surround))?.id)
    }

    @Test
    fun `a stereo player track maps to the 2 channel row`() {
        assertEquals(20, findSourceTrackForNativeAudio(stereo, frenchRows, listOf(stereo, surround))?.id)
    }
}
