package com.edde746.plezy.playback.tracks

import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.DEFAULT_TRACK
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.NAVIGATION
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.OFF
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.PROFILE
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.SERVER_SELECTED
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class TrackSelectorSubtitleTest {
    private val jellyfin = BackendKind.JELLYFIN

    private fun jellyfinMode(
        mode: SubtitlePlaybackMode,
        subtitleLanguage: String = "eng",
        audioLanguage: String? = null,
    ) = selector(jellyfin, profile = profile(defaultAudioLanguage = audioLanguage, defaultSubtitleLanguage = subtitleLanguage, subtitleMode = mode))

    @Test
    fun `Plex rows with none selected mean off`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, language = "eng"), sourceSub(11, language = "fre")))
        val result = selector(info = info).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), null, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `Jellyfin rows with none selected fall to the default track`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, language = "eng"), sourceSub(11, language = "fre")))
        val result = selector(jellyfin, info).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre", isDefault = true)), null, null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `Jellyfin DefaultSubtitleStreamIndex picks the subtitle when no row is selected`() {
        val info = sourceInfo(
            defaultSubtitleStreamIndex = 11,
            subs = listOf(sourceSub(10, index = 10, language = "eng"), sourceSub(11, index = 11, language = "fre")),
        )
        val result = selector(jellyfin, info).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), null, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }

    // Jellyfin direct play: an embedded stream reaches selection as a plain row.

    private fun directPlayInfo() = sourceInfo(
        defaultSubtitleStreamIndex = 3,
        subs = listOf(
            sourceSub(3, index = 3, languageCode = "eng", title = "English Forced", codec = "ass", selected = true, forced = true),
            sourceSub(4, index = 4, languageCode = "eng", title = "English", codec = "ass"),
        ),
    )

    private val directNatives = listOf(
        sub("1", lang = "eng", title = "English Forced", codec = "ass", isForced = true),
        sub("2", lang = "eng", title = "English", codec = "ass"),
    )

    @Test
    fun `Jellyfin direct play applies the server default instead of waiting for a sidecar`() {
        val result = selector(jellyfin, directPlayInfo()).selectSubtitleTrack(directNatives, null, null)
        assertEquals(SERVER_SELECTED, result?.priority)
        assertEquals("1", result?.track?.id)
    }

    @Test
    fun `Jellyfin direct play resolves a source preference carried from the open`() {
        val preferred = sub("source:3", lang = "eng", title = "English Forced", codec = "ass", isForced = true, isDefault = true)
        val result = selector(jellyfin, directPlayInfo()).selectSubtitleTrack(directNatives, native(preferred), null)
        assertEquals(NAVIGATION, result?.priority)
        assertEquals("1", result?.track?.id)
    }

    @Test
    fun `an unmatched source preference stops waiting once the catalog is complete`() {
        val result = selector(jellyfin, directPlayInfo()).selectSubtitleTrack(directNatives, native(sub("source:9", lang = "kor", codec = "srt")), null)
        assertNotNull(result)
        assertEquals("1", result.track.id)
    }

    @Test
    fun `a server selected sidecar is awaited even when another track arrived`() {
        val info = sourceInfo(
            defaultSubtitleStreamIndex = 3,
            subs = listOf(
                sourceSub(3, index = 3, languageCode = "eng", codec = "srt", key = "/Subtitles/3", selected = true),
                sourceSub(4, index = 4, languageCode = "swe", codec = "srt", key = "/Subtitles/4"),
            ),
        )
        val arrived = listOf(sub("sw", lang = "swe", codec = "srt", isDefault = true, isExternal = true))
        val s = selector(jellyfin, info)
        assertNull(s.selectSubtitleTrack(arrived, null, null))
        val selected = sub("en", lang = "eng", codec = "srt", isExternal = true, uri = "https://jf.example.com/Subtitles/3?api_key=tok")
        val resolved = s.selectSubtitleTrack(arrived + selected, null, null)
        assertEquals(SERVER_SELECTED, resolved?.priority)
        assertEquals("en", resolved?.track?.id)
    }

    @Test
    fun `a deadline pass resolves a source that never arrived`() {
        val info = sourceInfo(
            subs = listOf(
                sourceSub(3, index = 3, languageCode = "eng", codec = "srt", key = "/Subtitles/3", selected = true),
                sourceSub(4, index = 4, languageCode = "swe", codec = "srt", key = "/Subtitles/4"),
            ),
        )
        val natives = listOf(sub("1", lang = "eng", codec = "srt", isDefault = true))
        val preferred = native(sub("source:3", lang = "eng", codec = "srt"))
        val s = selector(jellyfin, info)
        assertNull(s.selectSubtitleTrack(natives, preferred, null))
        val resolved = s.selectSubtitleTrack(natives, preferred, null, waitForPendingSource = false)
        assertEquals(DEFAULT_TRACK, resolved?.priority)
        assertEquals("1", resolved?.track?.id)
    }

    @Test
    fun `a deadline pass turns an empty player catalog into an explicit off`() {
        val info = sourceInfo(subs = listOf(sourceSub(3, index = 3, languageCode = "eng", codec = "srt", key = "/Subtitles/3")))
        val s = selector(jellyfin, info)
        assertNull(s.selectSubtitleTrack(emptyList(), null, null))
        assertEquals("no", s.selectSubtitleTrack(emptyList(), null, null, waitForPendingSource = false)?.track?.id)
    }

    @Test
    fun `Jellyfin DefaultSubtitleStreamIndex 1 forces subtitles off`() {
        val info = sourceInfo(defaultSubtitleStreamIndex = -1, subs = listOf(sourceSub(10, language = "eng"), sourceSub(11, language = "fre")))
        val result = selector(jellyfin, info).selectSubtitleTrack(listOf(sub("1", lang = "eng", isDefault = true), sub("2", lang = "fre")), null, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `Jellyfin subtitle mode none forces subtitles off`() {
        val result = jellyfinMode(SubtitlePlaybackMode.NONE).selectSubtitleTrack(listOf(sub("1", lang = "eng", isDefault = true)), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `the Plex account subtitle mode is never re applied by the client`() {
        val none = AccountPreferences(preferredSubtitleLanguage = "eng", subtitlePlaybackMode = SubtitlePlaybackMode.NONE)
        val result = selector(profile = none).selectSubtitleTrack(listOf(sub("1", lang = "eng", isDefault = true)), null, null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("1", result.track.id)

        val always = AccountPreferences(preferredSubtitleLanguage = "eng", subtitlePlaybackMode = SubtitlePlaybackMode.ALWAYS)
        assertEquals(OFF, selector(profile = always).selectSubtitleTrack(listOf(sub("1", lang = "eng")), null, null)!!.priority)
    }

    @Test
    fun `only forced picks the forced subtitle in the profile language`() {
        val tracks = listOf(sub("1", lang = "eng"), sub("2", lang = "eng", isForced = true), sub("3", lang = "jpn", isForced = true))
        val result = jellyfinMode(SubtitlePlaybackMode.ONLY_FORCED).selectSubtitleTrack(tracks, null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `only forced honours a subtitle forced by its title only`() {
        val result = jellyfinMode(SubtitlePlaybackMode.ONLY_FORCED)
            .selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "eng", title = "English Forced")), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `only forced turns subtitles off without a forced subtitle`() {
        val result = jellyfinMode(SubtitlePlaybackMode.ONLY_FORCED).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "jpn")), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `always picks the profile subtitle language`() {
        val result = jellyfinMode(SubtitlePlaybackMode.ALWAYS).selectSubtitleTrack(listOf(sub("1", lang = "jpn"), sub("2", lang = "eng")), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `always does not prefix match est for es`() {
        val result = jellyfinMode(SubtitlePlaybackMode.ALWAYS, subtitleLanguage = "es")
            .selectSubtitleTrack(listOf(sub("1", lang = "est"), sub("2", lang = "spa")), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `always falls back to the default subtitle then the first`() {
        val result = jellyfinMode(SubtitlePlaybackMode.ALWAYS).selectSubtitleTrack(listOf(sub("1", lang = "jpn"), sub("2", lang = "fre", isDefault = true)), null, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `smart shows forced subtitles when the audio is in the preferred language`() {
        val result = jellyfinMode(SubtitlePlaybackMode.SMART, audioLanguage = "eng")
            .selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "eng", isForced = true)), null, audio("A", lang = "eng"))!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `smart shows the preferred subtitles when the audio differs`() {
        val result = jellyfinMode(SubtitlePlaybackMode.SMART, audioLanguage = "eng")
            .selectSubtitleTrack(listOf(sub("1", lang = "jpn"), sub("2", lang = "eng")), null, audio("A", lang = "jpn"))!!
        assertEquals(PROFILE, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `the default flagged subtitle plays without server info`() {
        val result = selector().selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre", isDefault = true)), null, null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `subtitles are off without a default or server info`() {
        val result = selector().selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), null, null)!!
        assertEquals(OFF, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `subtitles are off without any track`() {
        val result = selector().selectSubtitleTrack(emptyList(), null, null)!!
        assertEquals(OFF, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `an empty player list stays undecided while Plex advertises a selected subtitle`() {
        assertNull(selector(info = sourceInfo(subs = listOf(sourceSub(10, language = "eng", selected = true)))).selectSubtitleTrack(emptyList(), null, null))
    }

    @Test
    fun `an empty player list stays undecided while Plex advertises any subtitle`() {
        assertNull(selector(info = sourceInfo(subs = listOf(sourceSub(10, language = "eng")))).selectSubtitleTrack(emptyList(), null, null))
    }

    @Test
    fun `a selected keyed sidecar stays pending while only a same language container arrived`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, language = "eng", selected = true, external = true, key = "/library/streams/10")))
        val early = sub("20", lang = "eng", isExternal = true, isContainer = true)
        assertNull(selector(info = info).selectSubtitleTrack(listOf(early), null, null))
    }
}
