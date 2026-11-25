package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.SubtitlePreference
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PreferredSubtitleTest {
    @Test
    fun `no intent for null off and metadata less tracks`() {
        assertNull(PreferredSubtitle.intentOf(null))
        assertNull(PreferredSubtitle.intentOf(NativeSubtitleTrack.OFF))
        assertNull(PreferredSubtitle.intentOf(NativeSubtitleTrack(id = "3")))
    }

    @Test
    fun `an intent captures forced ness from the title`() {
        val intent = PreferredSubtitle.intentOf(sub("source:8", title = "FR Forced [ASS]", lang = "fre", codec = "ass"))!!
        assertTrue(intent.forced)
        assertEquals("fre", intent.language)
    }

    @Test
    fun `an intent captures forced ness from the flag`() {
        assertTrue(PreferredSubtitle.intentOf(sub("4", lang = "fre", isForced = true))!!.forced)
    }

    @Test
    fun `a full track makes a non forced intent`() {
        assertFalse(PreferredSubtitle.intentOf(sub("4", title = "French", lang = "fre", codec = "srt"))!!.forced)
    }

    @Test
    fun `off and intents pass a demotion null stays null`() {
        assertEquals(PreferredSubtitle.Off, PreferredSubtitle.demoteToIntent(PreferredSubtitle.Off))
        val intent = PreferredSubtitle.Intent(SubtitlePreference.Track(language = "fre", forced = true))
        assertEquals(intent, PreferredSubtitle.demoteToIntent(intent))
        assertNull(PreferredSubtitle.demoteToIntent(null))
    }

    @Test
    fun `a demoted track reference keeps its effective forced ness`() {
        val demoted = PreferredSubtitle.demoteToIntent(native(sub("source:8", title = "FR Forced", lang = "fre", codec = "ass")))
        assertEquals(PreferredSubtitle.Intent(SubtitlePreference.Track(language = "fre", forced = true, title = "FR Forced", codec = "ass")), demoted)
    }

    @Test
    fun `a sidecar reference loses its identity too`() {
        val demoted = PreferredSubtitle.demoteToIntent(native(NativeSubtitleTrack.fromUri("https://server/library/streams/9.srt", language = "eng", codec = "srt")))
        assertIs<PreferredSubtitle.Intent>(demoted)
        assertTrue(demoted.intent.isExternal)
    }

    @Test
    fun `a metadata less track reference demotes to null`() {
        assertNull(PreferredSubtitle.demoteToIntent(native(NativeSubtitleTrack(id = "2"))))
    }

    @Test
    fun `a source reference keeps its row for the server negotiation`() {
        val preference = native(sub("source:8", title = "French", lang = "fre", codec = "srt")).toPreference()
        assertEquals(SubtitlePreference.Track(language = "fre", title = "French", codec = "srt", sourceStreamId = 8), preference)
        assertEquals(SubtitlePreference.Off, PreferredSubtitle.Off.toPreference())
    }
}
