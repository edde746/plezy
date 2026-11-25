package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.Hotkeys
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.KeySource
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.SourceTrack
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The player's keys at the store: the controls' auto-hide around them, Select and Tab on the player itself, Back and
 * Escape, the reserved keys, the volume keys and wheel, and rebound shortcuts.
 */
class KeysStoreTest {
    private fun PlayerHarness.remote(key: InputKey): Boolean {
        val handled = input(InputEvent.KeyDown(key, source = KeySource.REMOTE))
        input(InputEvent.KeyUp(key))
        return handled
    }

    // Auto-hide

    @Test
    fun aRemotePressRestartsTheFiveSecondDelayAndAnIdleRemoteLetsTheControlsGo() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        advance(4.seconds)
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(remote(InputKey.RIGHT), "focus navigation is the platform's")
        advance(4999.milliseconds)
        assertTrue(state.controlsVisible)
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun pausingKeepsTheControlsUpUntilTheViewerDismissesThemWithARemote() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        dispatch(PlayerCommand.Pause)
        advance(60.seconds)
        assertTrue(state.controlsVisible)
        dispatch(PlayerCommand.Back)
        assertFalse(state.controlsVisible)
        assertEquals(0, host.closed)
    }

    @Test
    fun theDesktopsPlayerNavigationSettingTakesTheRemotesRules() = playerTest(preferences = PlayerChoices(playerNavigation = true)) {
        playing()
        advance(4999.milliseconds)
        assertTrue(state.controlsVisible, "5 s, not the mouse's 3 s")
        advance(1.milliseconds)
        assertFalse(state.controlsVisible)
        // Left and right seek with the controls down instead of the seek shortcuts.
        remote(InputKey.RIGHT)
        assertFalse(state.controlsVisible)
        assertEquals(1, engine.seeks.size)
    }

    @Test
    fun aHeldVolumeSliderKeepsDesktopControlsUp() = playerTest {
        playing()
        input(InputEvent.PointerDown(pointer = 7))
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        input(InputEvent.PointerUp(pointer = 7))
        advance(3.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun draggingOutOfThePlayerHidesTheControlsOnlyOnRelease() = playerTest {
        playing()
        input(InputEvent.PointerDown(pointer = 1))
        input(InputEvent.PointerExit)
        assertTrue(state.controlsVisible)
        input(InputEvent.PointerUp(pointer = 1))
        assertFalse(state.controlsVisible)
    }

    @Test
    fun aDragThatLeavesAndReturnsKeepsTheControlsAfterRelease() = playerTest {
        playing()
        input(InputEvent.PointerDown(pointer = 1))
        input(InputEvent.PointerExit)
        input(InputEvent.PointerMove)
        input(InputEvent.PointerUp(pointer = 1))
        assertTrue(state.controlsVisible)
    }

    @Test
    fun aHeldTimelineKeepsPhoneControlsUp() = playerTest(InputProfile.TOUCH) {
        playing()
        input(InputEvent.PointerDown(pointer = 3))
        advance(30.seconds)
        assertTrue(state.controlsVisible)
        input(InputEvent.PointerUp(pointer = 3))
        advance(5.seconds)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun theEndOfTheFileShowsTheControlsAndKeepsThem() = playerTest {
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        engineState { it.copy(eof = true, paused = true) }
        assertTrue(state.controlsVisible)
        advance(60.seconds)
        assertTrue(state.controlsVisible)
    }

    @Test
    fun noFirstFrameNoAutoHide() = playerTest {
        advance(30.seconds)
        assertTrue(state.controlsVisible)
    }

    // Select and Tab on the player itself

    @Test
    fun aRemotesFirstSelectOnlyRaisesTheChromeWithFocusTheNextToggles() = playerTest(InputProfile.TV) {
        playing()
        advance(5.seconds)
        assertTrue(remote(InputKey.SELECT))
        assertTrue(state.controlsVisible)
        assertEquals(1, state.playPauseFocus)
        assertTrue(engine.paused.isEmpty(), "the first press only shows the controls")
        // One press acts once, however long it is held.
        input(InputEvent.KeyDown(InputKey.SELECT, source = KeySource.REMOTE))
        repeat(3) { input(InputEvent.KeyDown(InputKey.SELECT, repeat = true, source = KeySource.REMOTE)) }
        input(InputEvent.KeyUp(InputKey.SELECT))
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun appleTvsSelectPausesAsItRaisesTheChrome() = playerTest(
        InputProfile.TV,
        config = PlayerConfig.defaults(InputProfile.TV, doubleClickIntervalMillis = 300, remoteSelectPauses = true),
    ) {
        playing()
        advance(5.seconds)
        assertTrue(remote(InputKey.SELECT))
        assertTrue(state.controlsVisible)
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun aKeyboardEnterTogglesWithoutMovingFocus() = playerTest {
        playing()
        press(InputKey.SELECT)
        assertEquals(listOf(true), engine.paused)
        assertEquals(0, state.playPauseFocus)
    }

    @Test
    fun selectOnAFocusedControlIsTheControls() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(remote(InputKey.SELECT))
        assertTrue(engine.paused.isEmpty())
    }

    @Test
    fun selectSkipsWhileTheButtonIsTheOnlyThingOnScreenAndPausesAfter() = playerTest(InputProfile.TV) {
        engineState { it.copy(chapters = listOf(Chapter("Opening", 30.0), Chapter("Episode", 120.0))) }
        playing(position = 40.0, duration = 600.0)
        advance(5.seconds)
        assertFalse(state.controlsVisible)
        assertTrue(remote(InputKey.SELECT))
        assertEquals(120.0, engine.seeks.last().first)
        assertTrue(engine.paused.isEmpty())
        // Focus is back on the player: the next Select shows the controls, the one after pauses.
        assertTrue(remote(InputKey.SELECT))
        assertTrue(state.controlsVisible)
        assertTrue(engine.paused.isEmpty())
        assertTrue(remote(InputKey.SELECT))
        assertEquals(listOf(true), engine.paused)
    }

    @Test
    fun aGuestsSelectOnlyShowsTheControls() = playerTest(InputProfile.TV) {
        playing()
        advance(5.seconds)
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        advance(0.seconds)
        remote(InputKey.SELECT)
        assertTrue(state.controlsVisible)
        assertTrue(engine.paused.isEmpty())
    }

    @Test
    fun channelKeysZapLiveChannelsAndOnATvSoDoUpAndDownWithTheControlsDown() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(live = true, nextEpisode = NextEpisode("Plezy Two", null), hasPreviousEpisode = true) }
        playing()
        advance(10.seconds)
        assertFalse(state.controlsVisible)
        assertTrue(remote(InputKey.CHANNEL_UP))
        assertEquals(1, session.nextEpisodes)
        assertTrue(state.controlsVisible, "the controls come up to name the channel")
        assertTrue(remote(InputKey.CHANNEL_DOWN))
        assertEquals(1, session.previousEpisodes)
        dispatch(PlayerCommand.HideControls)
        assertTrue(remote(InputKey.UP))
        assertEquals(2, session.nextEpisodes)
        dispatch(PlayerCommand.HideControls)
        assertTrue(remote(InputKey.DOWN))
        assertEquals(2, session.previousEpisodes)
        remote(InputKey.UP)
        assertEquals(2, session.nextEpisodes, "with the controls up Up moves between them")
    }

    @Test
    fun channelKeysDoNothingOffLive() = playerTest(InputProfile.TV) {
        sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode("Two", null)) }
        playing()
        advance(10.seconds)
        remote(InputKey.CHANNEL_UP)
        remote(InputKey.UP)
        assertEquals(0, session.nextEpisodes)
    }

    @Test
    fun tabRaisesHiddenControlsWithFocusAndIsTraversalOnceUp() = playerTest {
        playing()
        advance(3.seconds)
        assertTrue(press(InputKey.TAB))
        assertTrue(state.controlsVisible)
        assertEquals(1, state.playPauseFocus)
        assertFalse(press(InputKey.TAB))
    }

    @Test
    fun anArrowWithTheControlsUpAndNothingFocusedLandsOnPlayPause() = playerTest(InputProfile.TV) {
        playing()
        assertTrue(remote(InputKey.DOWN))
        assertEquals(1, state.playPauseFocus)
        assertTrue(engine.seeks.isEmpty())
    }

    @Test
    fun withoutPlayerNavigationAnArrowOnThePlayerItselfSeeksAndTakesNoFocus() = playerTest {
        playing(position = 600.0, duration = 3600.0)
        assertTrue(state.controlsVisible)
        assertTrue(press(InputKey.LEFT))
        assertEquals(listOf(590.0), engine.seeks.map { it.first })
        assertEquals(0, state.playPauseFocus)
    }

    // Window refocus

    @Test
    fun reActivatingTheWindowHandsTheRemoteBackToThePlayer() = playerTest(InputProfile.TV) {
        playing()
        advance(5.seconds)
        input(InputEvent.ControlFocus(onControl = true))
        input(InputEvent.ControlFocus(onControl = false))
        assertTrue(remote(InputKey.RIGHT), "the player's own seek")
        assertEquals(1, engine.seeks.size)
    }

    @Test
    fun aPromptHoldingFocusKeepsTheArrows() = playerTest(InputProfile.TV) {
        playing()
        dispatch(PlayerCommand.ShowControls)
        input(InputEvent.ControlFocus(onControl = true))
        for (key in listOf(InputKey.LEFT, InputKey.RIGHT, InputKey.UP, InputKey.DOWN)) assertFalse(remote(key), "$key")
    }

    @Test
    fun aControlTheViewerFocusedKeepsTheRemoteButNotTheShortcuts() = playerTest {
        playing()
        input(InputEvent.ControlFocus(onControl = true))
        assertFalse(press(InputKey.RIGHT), "the arrows move focus")
        assertTrue(press(InputKey.SPACE), "Space still plays and pauses")
        assertEquals(listOf(true), engine.paused)
    }

    // Back and Escape

    @Test
    fun backActsAsItComesUp() = playerTest {
        playing()
        assertTrue(input(InputEvent.KeyDown(InputKey.BACKSPACE)))
        assertTrue(state.controlsVisible, "nothing yet")
        assertTrue(input(InputEvent.KeyUp(InputKey.BACKSPACE)))
        assertFalse(state.controlsVisible)
        press(InputKey.ESCAPE)
        assertEquals(1, host.closed)
    }

    @Test
    fun physicalEscapeLeavesFullscreenBeforeBack() = playerTest {
        playing()
        dispatch(PlayerCommand.ToggleFullscreen)
        press(InputKey.ESCAPE)
        assertEquals(listOf(true, false), host.fullscreenRequests)
        assertTrue(state.controlsVisible)
        // A remote's Escape is Back.
        dispatch(PlayerCommand.ToggleFullscreen)
        input(InputEvent.KeyDown(InputKey.ESCAPE, source = KeySource.REMOTE))
        input(InputEvent.KeyUp(InputKey.ESCAPE))
        assertEquals(listOf(true, false, true), host.fullscreenRequests)
        assertFalse(state.controlsVisible)
    }

    @Test
    fun escapeIsBackOverFullscreenFromBeforeThePlayer() = playerTest(fullscreen = true) {
        playing()
        assertTrue(state.fullscreen)
        assertFalse(store.ownsFullscreen)
        press(InputKey.ESCAPE)
        assertTrue(host.fullscreenRequests.isEmpty())
        assertFalse(state.controlsVisible, "Escape went back: the controls hid")
        // The toggle leaves the window's fullscreen; entered again here, it is the player's, and Escape leaves it.
        dispatch(PlayerCommand.ToggleFullscreen)
        dispatch(PlayerCommand.ToggleFullscreen)
        assertTrue(store.ownsFullscreen)
        press(InputKey.ESCAPE)
        assertEquals(listOf(false, true, false), host.fullscreenRequests)
    }

    @Test
    fun withPlayerNavigationEscapeIsBackEvenInTheFullscreenThePlayerEntered() = playerTest(preferences = PlayerChoices(playerNavigation = true)) {
        playing()
        dispatch(PlayerCommand.ToggleFullscreen)
        assertTrue(store.ownsFullscreen)
        press(InputKey.ESCAPE)
        assertEquals(listOf(true), host.fullscreenRequests)
        assertFalse(state.controlsVisible, "Escape went back: the controls hid")
    }

    @Test
    fun escapeClosesAnOpenMenuFirst() = playerTest {
        playing()
        dispatch(PlayerCommand.ToggleFullscreen)
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.SPEED))
        press(InputKey.ESCAPE)
        assertEquals(PlayerMenu.OPTIONS, state.menu, "the speed page goes back to the options")
        press(InputKey.ESCAPE)
        assertEquals(null, state.menu)
        assertEquals(listOf(true), host.fullscreenRequests)
    }

    @Test
    fun homeIsThePlatforms() = playerTest {
        playing()
        assertFalse(press(InputKey.HOME))
    }

    @Test
    fun reservedKeysNothingTookStayThePlayers() = playerTest(InputProfile.TV) {
        playing()
        assertTrue(remote(InputKey.MENU))
        assertFalse(remote(InputKey.Q))
    }

    // Volume

    @Test
    fun theVolumeKeysStepByTen() = playerTest {
        playing()
        engineState { it.copy(volume = 50.0) }
        press(InputKey.UP)
        press(InputKey.DOWN)
        press(InputKey.DOWN)
        assertEquals(listOf(60.0, 50.0, 40.0), engine.volumes)
    }

    @Test
    fun theWheelMovesTheVolumeByAPointPerTwentyPixelsAndShowsTheControls() = playerTest {
        playing()
        engineState { it.copy(volume = 50.0) }
        advance(3.seconds)
        assertTrue(input(InputEvent.Wheel(deltaY = -100.0)))
        assertEquals(55.0, engine.volumes.last())
        assertTrue(state.controlsVisible)
        input(InputEvent.Wheel(deltaY = 30.0))
        assertEquals(53.5, engine.volumes.last())
    }

    @Test
    fun twentyWheelTicksKeepOnlyTheFinalVolumeOnce() = playerTest {
        playing()
        engineState { it.copy(volume = 50.0) }
        advance(3.seconds)
        repeat(20) {
            input(InputEvent.Wheel(deltaY = -20.0))
            advance(20.milliseconds)
        }
        advance(1.seconds)
        assertEquals(70.0, engine.volumes.last())
        assertEquals(listOf(70.0), preferences.volumes)
    }

    @Test
    fun noWheelVolumeOffTheDesktop() = playerTest(InputProfile.TV) {
        playing()
        assertFalse(input(InputEvent.Wheel(deltaY = -100.0)))
    }

    // Shortcuts

    @Test
    fun aReboundShortcutActsAndItsOldKeyNoLonger() = playerTest(
        preferences = PlayerChoices(
            hotkeys = Hotkeys.decode(Json.parseToJsonElement("""{"play_pause":{"key":"00070013","modifiers":[]},"mute_toggle":{"disabled":true}}""").jsonObject),
        ),
    ) {
        playing()
        assertFalse(press(InputKey.SPACE))
        press(InputKey.P)
        assertEquals(listOf(true), engine.paused)
        assertFalse(press(InputKey.M))
        assertTrue(engine.mutes.isEmpty())
    }

    @Test
    fun theRebindingFollowsTheSettingWhileThePlayerIsOpen() = playerTest {
        playing()
        choices { it.copy(hotkeys = Hotkeys.decode(Json.parseToJsonElement("""{"fullscreen_toggle":{"key":"00070009","modifiers":["shift"]}}""").jsonObject)) }
        assertFalse(press(InputKey.F))
        press(InputKey.F, KeyModifiers(shift = true))
        assertEquals(listOf(true), host.fullscreenRequests)
    }

    @Test
    fun aKeyStoredForAnActionThisReleaseDoesNotKnowIsConsumedAndDoesNothing() = playerTest(
        preferences = PlayerChoices(
            hotkeys = Hotkeys.decode(Json.parseToJsonElement("""{"future_action":{"key":"00070014","modifiers":[]}}""").jsonObject),
        ),
    ) {
        playing()
        assertTrue(press(InputKey.Q))
        assertFalse(press(InputKey.Q, KeyModifiers(shift = true)))
        assertTrue(engine.paused.isEmpty())
    }

    @Test
    fun zoomRepeatsWhileHeldAndOtherShortcutsActOnce() = playerTest {
        playing()
        val alt = KeyModifiers(alt = true)
        input(InputEvent.KeyDown(InputKey.PLUS, alt))
        input(InputEvent.KeyDown(InputKey.PLUS, alt, repeat = true))
        input(InputEvent.KeyUp(InputKey.PLUS))
        assertEquals(1.02, engine.layouts.last().zoom)
        input(InputEvent.KeyDown(InputKey.M))
        input(InputEvent.KeyDown(InputKey.M, repeat = true))
        input(InputEvent.KeyUp(InputKey.M))
        assertEquals(listOf(true), engine.mutes)
    }

    @Test
    fun theSpeedShortcutsStepAQuarterWithinThePlayersRange() = playerTest {
        playing()
        repeat(30) { press(InputKey.PLUS) }
        assertEquals((1..28).map { 1.0 + it * 0.25 }, engine.speeds, "to eight times and no further, past the menu's presets")
        press(InputKey.R)
        assertEquals(1.0, engine.speeds.last())
    }

    @Test
    fun theSubtitleShortcutHidesAndShowsTheTrackWithoutChoosingOne() = playerTest {
        playing()
        engineState {
            it.copy(
                tracks = listOf(
                    Track(1, TrackKind.SUBTITLE, "English", "en", "subrip", selected = true, external = false),
                    Track(2, TrackKind.SUBTITLE, "German", "de", "subrip", selected = false, external = false),
                ),
            )
        }
        engine.echo = false
        press(InputKey.S)
        assertEquals("Subtitles off", state.osd)
        assertTrue(state.subtitlesHidden, "the tracks button shows subtitles off")
        press(InputKey.S)
        assertEquals(listOf<Long?>(null, 1), engine.selections.map { it.second })
        assertFalse(state.subtitlesHidden)
        assertTrue(session.trackPicks.isEmpty(), "hiding isn't a choice of track")
    }

    @Test
    fun theSubtitleShortcutDoesNothingWithoutSubtitles() = playerTest {
        playing()
        press(InputKey.S)
        assertTrue(engine.selections.isEmpty())
    }

    @Test
    fun theSubtitleShortcutLeavesSubtitlesTurnedOffAndTheLastOfQuickPressesWins() = playerTest {
        playing()
        engineState {
            it.copy(
                tracks = listOf(
                    Track(1, TrackKind.SUBTITLE, "English", "en", "subrip", selected = false, external = false),
                    Track(2, TrackKind.SUBTITLE, "German", "de", "subrip", selected = false, external = false),
                ),
            )
        }
        press(InputKey.S)
        assertTrue(engine.selections.isEmpty(), "subtitles off: nothing to hide or show")
        assertNull(state.osd)

        engineState { it.copy(tracks = it.tracks.map { track -> track.copy(selected = track.id == 1L) }) }
        engine.echo = false
        repeat(3) { press(InputKey.S) }
        assertEquals(listOf<Long?>(null, 1, null), engine.selections.map { it.second })
        assertTrue(state.subtitlesHidden, "the third press hides them again")
    }

    @Test
    fun theSubtitleCycleGoesThroughTheServersSubtitlesWhileTheyAreTheChoice() = playerTest {
        playing()
        engineState { it.copy(tracks = listOf(Track(1, TrackKind.SUBTITLE, "English", "en", "subrip", selected = false, external = false))) }
        dispatch(PlayerCommand.CycleSubtitles)
        assertEquals(listOf<Pair<TrackKind, Long?>>(TrackKind.SUBTITLE to 1L), engine.selections, "the engine's tracks without a catalog")
        assertEquals(listOf<Pair<TrackKind, Long?>>(TrackKind.SUBTITLE to 1L), session.trackPicks, "kept as the viewer's pick")

        sessionInfo { it.copy(transcoding = true, sourceSubtitles = listOf(SourceTrack(11, "English"), SourceTrack(12, "French"))) }
        dispatch(PlayerCommand.CycleSubtitles)
        assertEquals("cycle source subtitles", session.actions.last())
        assertEquals(1, engine.selections.size, "the server's catalog decides, not the engine's tracks")
    }

    @Test
    fun screenshotAndSubtitleSeekReachTheEngine() = playerTest {
        playing()
        val ctrl = KeyModifiers(ctrl = true)
        press(InputKey.S, ctrl)
        assertEquals(1, engine.screenshots.size)
        assertEquals("Screenshot saved", state.osd)
        assertEquals(OsdIcon.SCREENSHOT, state.osdIcon)
        engine.screenshotSaves = false
        press(InputKey.S, ctrl)
        assertEquals("Couldn't take a screenshot", state.osd)
        assertNull(state.osdIcon)
        press(InputKey.RIGHT, ctrl)
        press(InputKey.LEFT, ctrl)
        assertEquals(listOf(true, false), engine.subtitleSeeks)
    }

    @Test
    fun aGuestsPlaybackShortcutsAreRefusedWithTheRoomsReason() = playerTest {
        playing()
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        advance(0.seconds)
        assertTrue(press(InputKey.SPACE))
        assertTrue(engine.paused.isEmpty())
        assertEquals("Only the host controls playback", state.osd)
    }
}
