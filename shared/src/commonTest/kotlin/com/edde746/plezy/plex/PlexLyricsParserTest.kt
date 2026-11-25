package com.edde746.plezy.plex

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlexLyricsParserTest {
    @Test
    fun `parses timed Plex XML and joins inline spans`() {
        val lyrics = parsePlexLyricsResponse(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <MediaContainer size="1">
              <Lyrics provider="com.plexapp.agents.localmedia" timed="1">
                <Line startOffset="500">
                  <Span text="First line" />
                </Line>
                <Line startOffset="4000">
                  <Span text="Second " />
                  <Span text="line" />
                </Line>
              </Lyrics>
            </MediaContainer>
            """.trimIndent(),
        )
        assertNotNull(lyrics)
        assertTrue(lyrics.synced)
        assertEquals(listOf("First line", "Second line"), lyrics.lines.map { it.text })
        assertEquals(listOf(500L, 4000L), lyrics.lines.map { it.startMs })
    }

    @Test
    fun `explicitly untimed Plex lyrics discard synthetic offsets`() {
        val lyrics = parsePlexLyricsResponse(
            Json.parseToJsonElement(
                """{"MediaContainer":{"Lyrics":{"timed":"0","Line":[
                  {"startOffset":0,"Span":{"text":"Plain first line"}},
                  {"startOffset":1000,"Span":{"text":"Plain second line"}}
                ]}}}""",
            ),
        )
        assertNotNull(lyrics)
        assertFalse(lyrics.synced)
        assertEquals(listOf("Plain first line", "Plain second line"), lyrics.lines.map { it.text })
        assertTrue(lyrics.lines.all { it.startMs == null })
    }

    @Test
    fun `retains raw LRC and text compatibility`() {
        val synced = parsePlexLyricsResponse("[00:01.00]Timed line")
        val plain = parsePlexLyricsResponse(JsonPrimitive("Plain first line\nPlain second line"))

        assertNotNull(synced)
        assertTrue(synced.synced)
        assertEquals(1000L, synced.lines.single().startMs)
        assertNotNull(plain)
        assertFalse(plain.synced)
        assertEquals(listOf("Plain first line", "Plain second line"), plain.lines.map { it.text })
    }

    @Test
    fun `returns null for XML with unclosed tags`() {
        assertNull(parsePlexLyricsResponse("""<MediaContainer><Lyrics><Line><Span text="Truncated">"""))
    }

    @Test
    fun `LRC applies the offset tag repeats multi stamp lines and sorts by time`() {
        val lyrics = parsePlexLyricsResponse("[ar:Artist]\n[offset:+500]\n[00:10.5][00:02]Chorus\n[00:05.25]Verse")
        assertNotNull(lyrics)
        assertEquals(listOf(1500L, 4750L, 10000L), lyrics.lines.map { it.startMs })
        assertEquals(listOf("Chorus", "Verse", "Chorus"), lyrics.lines.map { it.text })
    }

    @Test
    fun `LRC parses synced lines ordered by tick`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[00:20.00]Second line\n[00:10.00]First line\n[01:05.00]Third line"))
        assertTrue(lyrics.synced)
        assertEquals(listOf("First line", "Second line", "Third line"), lyrics.lines.map { it.text })
        assertEquals(listOf(10_000L, 20_000L, 65_000L), lyrics.lines.map { it.startMs })
    }

    @Test
    fun `LRC emits a multi timestamp line once per timestamp`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[00:05.00]Verse\n[00:10.00][00:30.00]Chorus"))
        assertEquals(listOf("Verse", "Chorus", "Chorus"), lyrics.lines.map { it.text })
        assertEquals(listOf(5_000L, 10_000L, 30_000L), lyrics.lines.map { it.startMs })
    }

    @Test
    fun `LRC applies the offset tag and clamps below zero`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[offset:+500]\n[00:01.00]Late start\n[00:00.20]Clamped"))
        assertEquals(listOf(0L, 500L), lyrics.lines.map { it.startMs })
        assertEquals(listOf("Clamped", "Late start"), lyrics.lines.map { it.text })
    }

    @Test
    fun `LRC scales the fractional part by its digit count`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[00:01.5]One digit\n[00:02.50]Two digits\n[00:03.500]Three digits"))
        assertEquals(listOf(1_500L, 2_500L, 3_500L), lyrics.lines.map { it.startMs })
    }

    @Test
    fun `LRC skips metadata id tags`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[ar:The Synth Pops]\n[ti:Dawn]\n[al:Album]\n[00:01.00]Actual line"))
        assertTrue(lyrics.synced)
        assertEquals(listOf("Actual line"), lyrics.lines.map { it.text })
    }

    @Test
    fun `LRC falls back to unsynced plain text when no timestamps exist`() {
        val lyrics = assertNotNull(parsePlexLyricsResponse("[ar:Artist]\nJust some words\nAnother line"))
        assertFalse(lyrics.synced)
        assertEquals(listOf("Just some words", "Another line"), lyrics.lines.map { it.text })
        assertTrue(lyrics.lines.all { it.startMs == null })
    }

    @Test
    fun `LRC returns null for blank input`() {
        assertNull(parsePlexLyricsResponse(""))
        assertNull(parsePlexLyricsResponse("  \n\n  "))
        assertNull(parsePlexLyricsResponse("[ar:Only tags]"))
    }
}
