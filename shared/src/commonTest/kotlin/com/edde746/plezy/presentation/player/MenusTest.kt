package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.ExternalSubtitle
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class MenusTest {
    private val tracks = listOf(
        Track(1, TrackKind.VIDEO, null, null, "hevc", selected = true, external = false),
        Track(1, TrackKind.AUDIO, null, "eng", "eac3", selected = true, external = false, isDefault = true, channels = 6),
        Track(2, TrackKind.AUDIO, "Commentary", "jpn", "aac", selected = false, external = false, channels = 2),
        Track(3, TrackKind.AUDIO, "English", "eng", "truehd", selected = false, external = false, visualImpaired = true, channels = 8),
        Track(1, TrackKind.SUBTITLE, "German (Forced)", "ger", "ass", selected = false, external = false, forced = true),
        Track(2, TrackKind.SUBTITLE, null, "en", "subrip", selected = false, external = true, hearingImpaired = true),
        Track(3, TrackKind.SUBTITLE, null, "und", "hdmv_pgs_subtitle", selected = false, external = false),
    )

    @Test
    fun trackMenusNameTheLanguageThenTheDetails() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        assertEquals(
            listOf(
                TrackItem(1, "English", "E-AC3 · 5.1 · Default", selected = true),
                TrackItem(2, "Japanese", "\u2068Commentary\u2069 · AAC · Stereo", selected = false),
                TrackItem(3, "English", "Audio description · TrueHD · 7.1", selected = false),
            ),
            state.audioTracks,
        )
        assertEquals(
            listOf(
                TrackItem(null, "Off", null, selected = true),
                TrackItem(1, "German", "\u2068German (Forced)\u2069 · ASS", selected = false),
                TrackItem(2, "English", "SDH · SRT · External", selected = false),
                TrackItem(3, "Track 3", "PGS", selected = false),
            ),
            state.subtitleTracks,
        )
    }

    /** A forced track the engine picked by itself (the file's default) is the subtitle menu's checked row, Off not. */
    @Test
    fun aForcedTrackTheEnginePickedIsTheCheckedRow() = playerTest {
        playing()
        engineState { state -> state.copy(tracks = tracks.map { if (it.kind == TrackKind.SUBTITLE && it.forced) it.copy(selected = true) else it }) }
        assertEquals(listOf(false, true, false, false), state.subtitleTracks.map { it.selected })
    }

    @Test
    fun choosingATrackClosesItsMenuAndShowsBeforeTheEngineReports() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        engine.echo = false
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 2))
        assertEquals(listOf<Pair<TrackKind, Long?>>(TrackKind.SUBTITLE to 2L), engine.selections)
        assertEquals(listOf<Pair<TrackKind, Long?>>(TrackKind.SUBTITLE to 2L), session.trackPicks, "the session hears the user's pick")
        assertNull(state.menu)
        assertEquals(listOf(false, false, true, false), state.subtitleTracks.map { it.selected })
        // A menu choice needs no message: the menu showed it.
        assertNull(state.osd)
    }

    @Test
    fun tracksAskedForAsTheFileEndsAreNotTheNextFilesChoice() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        engine.echo = false
        dispatch(PlayerCommand.SelectTrack(TrackKind.AUDIO, 2))
        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 2))
        dispatch(PlayerCommand.ToggleSecondSubtitle(3))
        // The file ends before the engine applied them, and the next opens with the same tracks as the last did.
        engineState { it.copy(loaded = false, tracks = emptyList()) }
        engineState { it.copy(loaded = true, tracks = tracks) }
        assertEquals(listOf(true, false, false), state.audioTracks.map { it.selected })
        assertEquals(listOf(true, false, false, false), state.subtitleTracks.map { it.selected })
        assertTrue(state.subtitleTracks.none { it.second })
    }

    @Test
    fun aSecondActionOnATrackShowsItAsTheSecondSubtitleAndAgainTakesItAway() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 2))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))

        dispatch(PlayerCommand.ToggleSecondSubtitle(3))
        assertEquals(PlayerMenu.SUBTITLES, state.menu, "the menu stays open, showing the mark")
        assertEquals(listOf<Long?>(3), engine.secondSelections)
        assertEquals(listOf<Long?>(3), session.secondSubtitlePicks, "the session hears the user's pick")
        assertEquals(listOf(false, false, true, false), state.subtitleTracks.map { it.selected })
        assertEquals(listOf(false, false, false, true), state.subtitleTracks.map { it.second })

        dispatch(PlayerCommand.ToggleSecondSubtitle(3))
        assertEquals(PlayerMenu.SUBTITLES, state.menu)
        assertEquals(listOf<Long?>(3, null), engine.secondSelections, "the second's own row takes it away")
        assertEquals(listOf<Long?>(3, null), session.secondSubtitlePicks)
        assertTrue(state.subtitleTracks.none { it.second })
    }

    @Test
    fun theSecondActionOnOffTakesTheSecondAwayAndOnTheSubtitleDoesNothing() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.ToggleSecondSubtitle(null))
        assertEquals(emptyList(), engine.secondSelections, "no second to take away")

        // With subtitles off a track can still be the second.
        dispatch(PlayerCommand.ToggleSecondSubtitle(1))
        assertEquals(listOf<Long?>(1), engine.secondSelections)
        dispatch(PlayerCommand.ToggleSecondSubtitle(null))
        assertEquals(listOf<Long?>(1, null), engine.secondSelections, "Off takes the second away")
        assertEquals(listOf<Pair<TrackKind, Long?>>(), engine.selections, "and leaves the subtitle as it is")

        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 2))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.ToggleSecondSubtitle(2))
        assertEquals(listOf<Long?>(1, null), engine.secondSelections, "the subtitle's track is no second one")
        assertEquals(PlayerMenu.SUBTITLES, state.menu)
        assertTrue(state.subtitleTracks.none { it.second })
    }

    @Test
    fun pickingTheSecondsTrackSwapsItAndOffTurnsBothOff() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 2))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.ToggleSecondSubtitle(3))

        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 3))
        assertNull(state.menu)
        assertEquals(listOf<Long?>(3, null), engine.secondSelections, "the second lets its track go before the subtitle takes it")
        assertEquals(listOf<Long?>(3, null), session.secondSubtitlePicks)
        assertEquals(listOf(false, false, false, true), state.subtitleTracks.map { it.selected })
        assertTrue(state.subtitleTracks.none { it.second })

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.ToggleSecondSubtitle(1))
        dispatch(PlayerCommand.SelectTrack(TrackKind.SUBTITLE, null))
        assertNull(state.menu)
        assertEquals(listOf<Long?>(3, null, 1, null), engine.secondSelections, "Off turns the second off too")
        assertEquals(listOf(true, false, false, false), state.subtitleTracks.map { it.selected })
        assertTrue(state.subtitleTracks.none { it.second })
    }

    @Test
    fun theSecondsMarkShowsBeforeTheEngineReports() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        engine.echo = false
        dispatch(PlayerCommand.ToggleSecondSubtitle(1))
        assertEquals(listOf(false, true, false, false), state.subtitleTracks.map { it.second })
        dispatch(PlayerCommand.ToggleSecondSubtitle(1))
        assertEquals(listOf<Long?>(1, null), engine.secondSelections, "the pending second's row takes it away")
        assertTrue(state.subtitleTracks.none { it.second })
        assertTrue(state.audioTracks.none { it.second })
    }

    @Test
    fun cyclingSubtitlesGoesThroughOffAndBuildsOnPendingChoices() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        engine.echo = false
        val shift = KeyModifiers(shift = true)
        press(InputKey.S, shift)
        assertEquals("Subtitles: German", state.osd)
        press(InputKey.S, shift)
        press(InputKey.S, shift)
        press(InputKey.S, shift)
        assertEquals("Subtitles off", state.osd)
        assertEquals(listOf(1L, 2L, 3L, null), engine.selections.map { it.second })
        advance(1.5.seconds)
        assertNull(state.osd)
    }

    @Test
    fun cyclingAudioWraps() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        press(InputKey.A)
        press(InputKey.A)
        assertEquals("Audio: English", state.osd)
        press(InputKey.A)
        assertEquals(listOf(2L, 3L, 1L), engine.selections.map { it.second })
        assertEquals(listOf(true, false, false), state.audioTracks.map { it.selected })
    }

    @Test
    fun moreSubtitlesGoByLanguageAndOneChosenIsAddedAndClosesTheMenu() = playerTest {
        playing()
        engineState { it.copy(tracks = tracks) }
        sessionInfo {
            it.copy(
                moreSubtitles = listOf(
                    ExternalSubtitle("https://subs.example/ja.srt", "ja", "OpenSubtitles"),
                    ExternalSubtitle("https://subs.example/text.srt", null, "Português"),
                    ExternalSubtitle("https://subs.example/en2.srt", "en", "OpenSubtitles 2"),
                    ExternalSubtitle("https://subs.example/en3.srt", "en", "OpenSubtitles 3"),
                    ExternalSubtitle("https://subs.example/de.srt", "de", "OpenSubtitles"),
                ),
            )
        }
        // The languages the menu has first, then the others by name; no language code last.
        assertEquals(
            listOf(Triple("en", "English", "2"), Triple("de", "German", "1"), Triple("ja", "Japanese", "1"), Triple("", "Other", "1")),
            state.moreSubtitles.map { Triple(it.key, it.label, it.count) },
        )
        assertEquals("5", state.moreSubtitlesCount)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLES))
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.MORE_SUBTITLES))
        dispatch(PlayerCommand.OpenSubtitleLanguage("en"))
        assertEquals(PlayerMenu.SUBTITLE_LANGUAGE, state.menu)
        assertEquals(listOf("OpenSubtitles 2", "OpenSubtitles 3"), state.subtitleLanguage?.subtitles?.map { it.label })
        dispatch(PlayerCommand.Back)
        assertEquals(PlayerMenu.MORE_SUBTITLES, state.menu)
        dispatch(PlayerCommand.Back)
        assertEquals(PlayerMenu.SUBTITLES, state.menu)

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.MORE_SUBTITLES))
        dispatch(PlayerCommand.OpenSubtitleLanguage(""))
        dispatch(state.subtitleLanguage!!.subtitles.single().command)
        assertEquals(listOf("https://subs.example/text.srt"), session.addedSubtitles)
        assertNull(state.menu)
    }

    @Test
    fun delayStepsAddUpExactlyAndStayWithinTheRange() = playerTest {
        playing()
        engine.echo = false
        repeat(3) { dispatch(PlayerCommand.AdjustSubtitleDelay(0.1)) }
        assertEquals(listOf(0.1, 0.2, 0.3), engine.subtitleDelays)
        assertEquals("+0.3 s", state.subtitleDelay.label)
        assertEquals("Subtitle delay +0.3 s", state.osd)
        assertTrue(state.subtitleDelay.canReset)
        assertEquals(listOf("subtitle offset 0.1", "subtitle offset 0.2", "subtitle offset 0.3"), session.actions, "each offset goes to the session")

        dispatch(PlayerCommand.SetSubtitleDelay(9.95))
        dispatch(PlayerCommand.AdjustSubtitleDelay(0.1))
        assertEquals(10.0, engine.subtitleDelays.last(), "the sync stops at ten seconds")
        assertFalse(state.subtitleDelay.canIncrease)
        assertTrue(state.subtitleDelay.canDecrease)

        dispatch(PlayerCommand.SetSubtitleDelay(-500.0))
        assertEquals(-10.0, engine.subtitleDelays.last())
        assertEquals("−10.0 s", state.subtitleDelay.label)
        assertFalse(state.subtitleDelay.canDecrease)

        dispatch(PlayerCommand.AdjustAudioDelay(-0.1))
        dispatch(PlayerCommand.AdjustAudioDelay(-0.1))
        assertEquals(listOf(-0.1, -0.2), engine.audioDelays)
        assertEquals("−0.2 s", state.audioDelay.label)
        assertEquals("audio offset -0.2", session.actions.last())
        dispatch(PlayerCommand.SetAudioDelay(0.0))
        assertEquals("0.0 s", state.audioDelay.label)
        assertFalse(state.audioDelay.canReset)
    }

    /**
     * Each sync bar names itself, its − and + by the way they move it, and its page; its buttons send a step each way
     * (10 ms for audio, 50 ms for subtitles) and Reset zero. Reset is offered at every offset, enabled only while it
     * isn't zero.
     */
    @Test
    fun aDelayControlCarriesItsNamesItsStepsAndAResetEnabledAwayFromZero() = playerTest {
        playing()
        val text = T.player.menu
        for (kind in listOf(TrackKind.SUBTITLE, TrackKind.AUDIO)) {
            val subtitles = kind == TrackKind.SUBTITLE
            fun delay() = if (subtitles) state.subtitleDelay else state.audioDelay
            fun sent() = if (subtitles) engine.subtitleDelays else engine.audioDelays
            val page = if (subtitles) PlayerMenu.SUBTITLE_DELAY else PlayerMenu.AUDIO_DELAY
            val title = if (subtitles) T.videoSettings.subtitleSync else T.videoSettings.audioSync
            val step = if (subtitles) 0.05 else 0.01
            assertEquals(page, delay().menu)
            assertEquals(title, delay().title)
            assertEquals(title, state.menuTitle(page), "the page is titled by its sync")
            assertEquals(
                if (subtitles) text.subtitleDelayEarlier to text.subtitleDelayLater else text.audioDelayEarlier to text.audioDelayLater,
                delay().decreaseLabel to delay().increaseLabel,
            )
            assertEquals(step, delay().stepSeconds)
            assertEquals(10.0, delay().limitSeconds)
            assertEquals("0.0 s", delay().label)
            assertFalse(delay().canReset, "$kind at zero: Reset shows disabled")

            dispatch(PlayerCommand.OpenMenu(page))
            dispatch(delay().increase)
            dispatch(delay().increase)
            dispatch(delay().decrease)
            assertEquals(if (subtitles) listOf(0.05, 0.1, 0.05) else listOf(0.01, 0.02, 0.01), sent())
            assertEquals(if (subtitles) "+0.05 s" else "+0.01 s", delay().label)
            assertTrue(delay().canReset, "$kind moved: Reset is enabled")
            dispatch(delay().reset)
            assertEquals(0.0, sent().last())
            assertEquals("0.0 s", delay().label)
            assertFalse(delay().canReset, "$kind reset: Reset shows disabled again")
            assertEquals(page, state.menu, "the page stays open")
            dispatch(PlayerCommand.CloseMenu)
        }
    }

    @Test
    fun volumeStaysInRangeAndTurningItUpUnmutes() = playerTest {
        playing()
        engineState { it.copy(volume = 97.0) }
        press(InputKey.UP)
        press(InputKey.UP)
        assertEquals(listOf(100.0, 100.0), engine.volumes)
        assertEquals("100%", state.volume.label)
        assertEquals("Volume 100%", state.osd)

        press(InputKey.M)
        assertEquals("Muted", state.volume.label)
        assertTrue(state.volume.muted)
        press(InputKey.DOWN)
        assertTrue(state.volume.muted)
        input(InputEvent.Wheel(deltaY = -40.0))
        assertEquals(listOf(true, false), engine.mutes)
        assertEquals(VolumeState(percent = 92, fraction = 0.92f, muted = false, label = "92%"), state.volume, "Down took 10, the wheel's 40 px gave 2")
        input(InputEvent.Wheel(deltaY = 3000.0))
        assertEquals(0.0, engine.volumes.last())
    }

    @Test
    fun chapterKeysJumpBetweenChapterStarts() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engineState { it.copy(chapters = listOf(Chapter("Intro", 0.0), Chapter(null, 90.0), Chapter("Credits", 540.0))) }
        press(InputKey.N)
        assertEquals(540.0 to true, engine.seeks.last())
        assertEquals("Chapter: \u2068Credits\u2069", state.osd, "the chapter's title isolated")
        position(541.0)
        // Just past a chapter start, "previous" goes to the chapter before.
        press(InputKey.P)
        assertEquals(90.0 to true, engine.seeks.last())
        assertEquals("Chapter 2", state.osd)
        position(120.0)
        press(InputKey.P)
        assertEquals(90.0 to true, engine.seeks.last())
        press(InputKey.N)
        press(InputKey.N)
        assertEquals(listOf(540.0, 90.0, 90.0, 540.0), engine.seeks.map { it.first })
    }
}
