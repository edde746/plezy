package com.edde746.plezy.playback.tracks

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.DEFAULT_TRACK
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.NAVIGATION
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.OFF
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.PROFILE
import com.edde746.plezy.playback.tracks.TrackSelectionPriority.SERVER_SELECTED
import com.edde746.plezy.playback.tracks.TrackSelector.Companion.languageMatches
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class TrackSelectorTest {
    // languageMatches

    @Test
    fun `null on either side never matches`() {
        assertFalse(languageMatches(null, "eng"))
        assertFalse(languageMatches("eng", null))
        assertFalse(languageMatches(null, null))
    }

    @Test
    fun `language match is case insensitive`() {
        assertTrue(languageMatches("ENG", "eng"))
        assertTrue(languageMatches("en", "EN"))
    }

    @Test
    fun `language match strips region suffixes on both sides`() {
        assertTrue(languageMatches("en-US", "en"))
        assertTrue(languageMatches("en", "en-AU"))
        assertTrue(languageMatches("en-GB", "en-US"))
    }

    @Test
    fun `language match crosses ISO 639 1 and 639 2`() {
        assertTrue(languageMatches("en", "eng"))
        assertTrue(languageMatches("eng", "en"))
    }

    @Test
    fun `different languages do not match`() {
        assertFalse(languageMatches("en", "fr"))
        assertFalse(languageMatches("eng", "fre"))
    }

    // findBestSubtitleMatch

    @Test
    fun `an off preference always means off`() {
        assertSame(NativeSubtitleTrack.OFF, selector().findBestSubtitleMatch(listOf(sub("1", lang = "eng")), NativeSubtitleTrack(id = "no")))
    }

    @Test
    fun `best subtitle match falls back to the language when the title differs`() {
        val tracks = listOf(sub("1", lang = "eng", title = "English"))
        assertEquals(tracks[0], selector().findBestSubtitleMatch(tracks, sub("999", lang = "eng", title = "Other")))
    }

    @Test
    fun `best subtitle match is null without a language match`() {
        assertNull(selector().findBestSubtitleMatch(listOf(sub("1", lang = "fre")), sub("1", lang = "eng")))
    }

    // findAudioTrackByProfile

    @Test
    fun `profile audio is null when auto select is off`() {
        assertNull(selector().findAudioTrackByProfile(listOf(audio("1", lang = "eng")), profile(autoSelectAudio = false, defaultAudioLanguage = "eng")))
    }

    @Test
    fun `profile audio is null without a preferred language`() {
        assertNull(selector().findAudioTrackByProfile(listOf(audio("1", lang = "eng")), profile()))
    }

    @Test
    fun `profile audio matches the preferred language`() {
        val tracks = listOf(audio("1", lang = "fre"), audio("2", lang = "eng"))
        assertEquals(tracks[1], selector().findAudioTrackByProfile(tracks, profile(defaultAudioLanguage = "eng")))
    }

    @Test
    fun `profile audio is null when the language is missing`() {
        assertNull(selector().findAudioTrackByProfile(listOf(audio("1", lang = "jpn")), profile(defaultAudioLanguage = "eng")))
    }

    @Test
    fun `an est track before spa does not prefix match a preference for es`() {
        val tracks = listOf(audio("1", lang = "est"), audio("2", lang = "spa"))
        assertEquals(tracks[1], selector().findAudioTrackByProfile(tracks, profile(defaultAudioLanguage = "es")))
    }

    @Test
    fun `regional variants match the base language`() {
        val tracks = listOf(audio("1", lang = "est"), audio("2", lang = "es-419"))
        assertEquals(tracks[1], selector().findAudioTrackByProfile(tracks, profile(defaultAudioLanguage = "es")))
        val spaOnly = listOf(audio("1", lang = "spa"))
        assertEquals(spaOnly[0], selector().findAudioTrackByProfile(spaOnly, profile(defaultAudioLanguage = "es-419")))
    }

    @Test
    fun `profile audio is null without tracks`() {
        assertNull(selector().findAudioTrackByProfile(emptyList(), profile(defaultAudioLanguage = "eng")))
    }

    // selectAudioTrack

    @Test
    fun `audio selection is null without tracks`() {
        assertNull(selector().selectAudioTrack(emptyList(), audio("1", lang = "eng")))
    }

    @Test
    fun `a carried audio track wins when it matches`() {
        val tracks = listOf(audio("1", lang = "fre"), audio("2", lang = "eng"))
        val result = selector().selectAudioTrack(tracks, audio("2", lang = "eng"))!!
        assertEquals(NAVIGATION, result.priority)
        assertEquals(tracks[1], result.track)
    }

    @Test
    fun `a cross item audio carry matches through the evidence bands`() {
        val tracks = listOf(audio("1", lang = "eng", title = "Main"), audio("2", lang = "eng", title = "Commentary"))
        val result = selector().selectAudioTrack(tracks, audio("source:99", lang = "eng", title = "Commentary"))!!
        assertEquals(NAVIGATION, result.priority)
        assertEquals(tracks[1], result.track)
    }

    @Test
    fun `a declined audio carry falls to the server selected track`() {
        val tracks = listOf(audio("A", lang = "eng"), audio("B", lang = "fre"))
        val info = sourceInfo(audio = listOf(sourceAudio(1, language = "eng", selected = true), sourceAudio(2, language = "fre")))
        val result = selector(info = info).selectAudioTrack(tracks, audio("source:9", lang = "swe"))!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("eng", result.track.language)
    }

    @Test
    fun `a demoted cross item carry cannot latch a reused player id`() {
        val tracks = listOf(audio("1", lang = "eng", codec = "aac", channels = 2), audio("2", lang = "eng", codec = "aac", channels = 2))
        val info = sourceInfo(audio = listOf(sourceAudio(1, language = "eng", selected = true), sourceAudio(2, language = "eng")))
        val raw = audio("2", lang = "eng", codec = "aac", channels = 2)
        val carried = raw.copy(id = CARRIED_AUDIO_TRACK_ID)

        assertEquals(SERVER_SELECTED, selector(info = info).selectAudioTrack(tracks, carried)!!.priority)
        val latched = selector(info = info).selectAudioTrack(tracks, raw)!!
        assertEquals(NAVIGATION, latched.priority)
        assertEquals("2", latched.track.id)
    }

    @Test
    fun `the Plex selected audio row picks the track`() {
        val tracks = listOf(audio("A", lang = "eng"), audio("B", lang = "fre"))
        val info = sourceInfo(audio = listOf(sourceAudio(1, language = "eng"), sourceAudio(2, language = "fre", selected = true)))
        val result = selector(info = info).selectAudioTrack(tracks, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }

    @Test
    fun `a Jellyfin selected audio stream wins over DefaultAudioStreamIndex`() {
        val tracks = listOf(audio("A", lang = "eng"), audio("B", lang = "fre"))
        val info = sourceInfo(
            defaultAudioStreamIndex = 1,
            audio = listOf(sourceAudio(1, index = 1, language = "eng"), sourceAudio(2, index = 2, language = "fre", selected = true)),
        )
        val result = selector(BackendKind.JELLYFIN, info).selectAudioTrack(tracks, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }

    @Test
    fun `Jellyfin DefaultAudioStreamIndex picks audio when no row is selected`() {
        val tracks = listOf(audio("A", lang = "eng"), audio("B", lang = "fre"))
        val info = sourceInfo(
            defaultAudioStreamIndex = 2,
            audio = listOf(sourceAudio(1, index = 1, language = "eng"), sourceAudio(2, index = 2, language = "fre")),
        )
        val result = selector(BackendKind.JELLYFIN, info).selectAudioTrack(tracks, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }

    @Test
    fun `the profile picks audio when nothing stronger applies`() {
        val tracks = listOf(audio("A", lang = "eng"), audio("B", lang = "fre"))
        val result = selector(profile = profile(defaultAudioLanguage = "eng")).selectAudioTrack(tracks, null)!!
        assertEquals(PROFILE, result.priority)
        assertEquals("eng", result.track.language)
    }

    @Test
    fun `the default flagged audio track is the last resort`() {
        val result = selector().selectAudioTrack(listOf(audio("A", lang = "eng"), audio("B", lang = "fre", isDefault = true)), null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("B", result.track.id)
    }

    @Test
    fun `the first audio track plays when none is flagged default`() {
        val result = selector().selectAudioTrack(listOf(audio("A", lang = "eng"), audio("B", lang = "fre")), null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("A", result.track.id)
    }

    @Test
    fun `an unmatched carried audio track falls through`() {
        val result = selector().selectAudioTrack(listOf(audio("A", lang = "eng"), audio("B", lang = "fre")), audio("Z", lang = "jpn"))!!
        assertEquals(DEFAULT_TRACK, result.priority)
    }

    // selectSubtitleTrack

    @Test
    fun `an off subtitle preference forces subtitles off`() {
        val result = selector().selectSubtitleTrack(listOf(sub("1", lang = "eng", isDefault = true)), PreferredSubtitle.Off, null)!!
        assertEquals(NAVIGATION, result.priority)
        assertEquals("no", result.track.id)
    }

    @Test
    fun `a carried subtitle matches by language`() {
        val result = selector().selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), native(sub("99", lang = "fre")), null)!!
        assertEquals(NAVIGATION, result.priority)
        assertEquals("2", result.track.id)
    }

    @Test
    fun `the Plex server selected subtitle wins`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, language = "eng"), sourceSub(11, language = "fre", selected = true)))
        val result = selector(info = info).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), null, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }

    @Test
    fun `a complete metadata free direct catalog selects its unique player subtitle`() {
        val source = sourceSub(20, codec = "ass", selected = true)
        val info = sourceInfo(subs = listOf(source))
        val nativeTrack = sub("native-ass", codec = "ass")
        val preferred = selector(info = info).selectSubtitleTrack(listOf(nativeTrack), native(NativeSubtitleTrack(id = "source:20", codec = "ass")), null)!!
        val server = selector(info = info).selectSubtitleTrack(listOf(nativeTrack), null, null)!!
        assertEquals(NAVIGATION, preferred.priority)
        assertSame(nativeTrack, preferred.track)
        assertEquals(SERVER_SELECTED, server.priority)
        assertSame(nativeTrack, server.track)
        assertSame(nativeTrack, findNativeTrackForSourceSubtitle(source, listOf(nativeTrack), listOf(source)))
        assertSame(source, findSourceTrackForNativeSubtitle(nativeTrack, listOf(source), listOf(nativeTrack)))
    }

    @Test
    fun `a complete low metadata direct catalog pairs by facts not order`() {
        val ass = sourceSub(30, codec = "ass", selected = true)
        val srt = sourceSub(31, codec = "srt")
        val nativeSrt = sub("native-srt", codec = "srt")
        val nativeAss = sub("native-ass", codec = "ass")
        assertSame(nativeAss, findNativeTrackForSourceSubtitle(ass, listOf(nativeSrt, nativeAss), listOf(ass, srt)))
        assertSame(ass, findSourceTrackForNativeSubtitle(nativeAss, listOf(ass, srt), listOf(nativeSrt, nativeAss)))
    }

    @Test
    fun `an ambiguous metadata free direct catalog never pairs by order`() {
        val selected = sourceSub(40, codec = "ass", selected = true)
        val rows = listOf(selected, sourceSub(41, codec = "ass"))
        val natives = listOf(sub("native-second", codec = "ass"), sub("native-first", codec = "ass"))
        assertNull(findNativeTrackForSourceSubtitle(selected, natives, rows))
        assertNull(findSourceTrackForNativeSubtitle(natives.first(), rows, natives))

        val s = selector(info = sourceInfo(subs = rows))
        val preferred = s.selectSubtitleTrack(natives, native(NativeSubtitleTrack(id = "source:40", codec = "ass")), null)!!
        val server = s.selectSubtitleTrack(natives, null, null)!!
        assertEquals(OFF, preferred.priority)
        assertEquals("no", preferred.track.id)
        assertEquals(OFF, server.priority)
        assertEquals("no", server.track.id)
    }

    @Test
    fun `an ambiguous complete direct catalog falls to the player default`() {
        val rows = listOf(sourceSub(50, codec = "ass", selected = true), sourceSub(51, codec = "ass"))
        val natives = listOf(sub("native-first", codec = "ass"), sub("native-default", codec = "ass", isDefault = true))
        val result = selector(info = sourceInfo(subs = rows)).selectSubtitleTrack(natives, native(NativeSubtitleTrack(id = "source:50", codec = "ass")), null)!!
        assertEquals(DEFAULT_TRACK, result.priority)
        assertEquals("native-default", result.track.id)
    }

    @Test
    fun `a partial metadata free direct catalog stays pending`() {
        val rows = listOf(sourceSub(60, codec = "ass", selected = true), sourceSub(61, codec = "ass"))
        val natives = listOf(sub("native-only", codec = "ass", isDefault = true))
        val s = selector(info = sourceInfo(subs = rows))
        assertNull(s.selectSubtitleTrack(natives, native(NativeSubtitleTrack(id = "source:60", codec = "ass")), null))
        assertNull(s.selectSubtitleTrack(natives, null, null))
    }

    @Test
    fun `a partial player catalog stays undecided until the selected row arrives`() {
        val info = sourceInfo(subs = listOf(sourceSub(10, language = "eng", selected = true), sourceSub(11, language = "fre")))
        assertNull(selector(info = info).selectSubtitleTrack(listOf(sub("2", lang = "fre")), null, null))
    }

    @Test
    fun `a preferred source waits for its position in a partial identical container catalog`() {
        val info = sourceInfo(
            subs = listOf(
                sourceSub(30, index = 0, language = "eng", title = "English", codec = "ass"),
                sourceSub(31, index = 1, language = "eng", title = "English", codec = "ass", selected = true),
            ),
        )
        val uri = "https://example.test/video.mkv"
        val preferred = sub("source:31", lang = "eng", title = "English", codec = "ass", isExternal = true, isContainer = true, uri = uri)
        val first = sub("native-0", lang = "eng", title = "English", codec = "ass", isExternal = true, isContainer = true, uri = uri)
        val second = sub("native-1", lang = "eng", title = "English", codec = "ass", isExternal = true, isContainer = true, uri = uri)
        val s = selector(info = info)
        assertNull(s.selectSubtitleTrack(listOf(first), native(preferred), null))
        assertEquals("native-1", s.selectSubtitleTrack(listOf(first, second), native(preferred), null)?.track?.id)
    }

    @Test
    fun `a preferred keyed source never fuzzy matches an early same language container track`() {
        val info = sourceInfo(
            subs = listOf(
                sourceSub(10, language = "eng", codec = "srt", external = true, key = "/library/streams/10"),
                sourceSub(11, language = "eng", codec = "srt"),
            ),
        )
        val preferred = sub("source:10", lang = "eng", codec = "srt", isExternal = true, uri = "https://example.test/library/streams/10.srt")
        val early = sub("native-0", lang = "eng", codec = "srt", isExternal = true, isContainer = true, uri = "https://example.test/video.mkv")
        assertNull(selector(info = info).selectSubtitleTrack(listOf(early), native(preferred), null))
    }

    @Test
    fun `a Jellyfin selected subtitle stream wins over DefaultSubtitleStreamIndex`() {
        val info = sourceInfo(
            defaultSubtitleStreamIndex = 10,
            subs = listOf(sourceSub(10, index = 10, language = "eng"), sourceSub(11, index = 11, language = "fre", selected = true)),
        )
        val result = selector(BackendKind.JELLYFIN, info).selectSubtitleTrack(listOf(sub("1", lang = "eng"), sub("2", lang = "fre")), null, null)!!
        assertEquals(SERVER_SELECTED, result.priority)
        assertEquals("fre", result.track.language)
    }
}
