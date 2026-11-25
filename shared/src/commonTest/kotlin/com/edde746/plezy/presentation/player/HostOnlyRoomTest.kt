package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.session.LiveWindow
import com.edde746.plezy.playback.session.NextEpisode
import kotlinx.coroutines.flow.update
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * A guest in a room where only the host controls playback ([com.edde746.plezy.presentation.watch.PlayerWatchUi.canControl]
 * false): whichever way it asks, nothing plays, pauses, seeks, changes the speed or the episode, here or in the room,
 * and the guest is told why.
 */
class HostOnlyRoomTest {
    /** One way to ask, on [profile]: [prepare] sets the playback up before the room is joined, [ask] asks. */
    private class Ask(
        val name: String,
        val profile: InputProfile = InputProfile.DESKTOP,
        val prepare: PlayerHarness.() -> Unit = {},
        val ask: PlayerHarness.() -> Unit,
    )

    private val controlsDown: PlayerHarness.() -> Unit = { advance(5.seconds) }

    private val asks = listOf(
        Ask("the seek buttons, VoiceOver's adjust, picture in picture's skips") {
            dispatch(PlayerCommand.SeekBy(10.0))
            dispatch(PlayerCommand.SeekBy(-10.0))
        },
        Ask("an arrow key held down") {
            input(InputEvent.KeyDown(InputKey.RIGHT))
            repeat(3) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true)) }
            input(InputEvent.KeyUp(InputKey.RIGHT))
        },
        Ask("a remote's Right, then the scrub's commit delay", InputProfile.TV, controlsDown) { press(InputKey.RIGHT) },
        Ask("a remote's Left, then Select", InputProfile.TV, controlsDown) {
            press(InputKey.LEFT)
            press(InputKey.SELECT)
        },
        Ask("a remote's Right held down", InputProfile.TV, controlsDown) {
            input(InputEvent.KeyDown(InputKey.RIGHT))
            advance(1.seconds)
            input(InputEvent.KeyUp(InputKey.RIGHT))
        },
        Ask("a remote's Right on the focused seek bar", InputProfile.TV, { store.onTimelineFocusChanged(true) }) {
            press(InputKey.RIGHT)
        },
        Ask("a drag of the seek bar, a swipe on a remote's touch surface") {
            dispatch(PlayerCommand.ScrubTo(0.5))
            dispatch(PlayerCommand.ScrubTo(0.7))
            dispatch(PlayerCommand.CommitScrub)
        },
        Ask("a tap on the seek bar") { dispatch(PlayerCommand.SeekToFraction(0.5)) },
        Ask("the chapter keys", prepare = { engineState { it.copy(chapters = listOf(Chapter("One", 0.0), Chapter("Two", 300.0))) } }) {
            press(InputKey.N)
            press(InputKey.P)
        },
        Ask("the skip button", prepare = { engineState { it.copy(chapters = listOf(Chapter("Opening", 90.0), Chapter("Episode", 120.0))) } }) {
            dispatch(PlayerCommand.SkipSegment)
        },
        Ask("go to live", prepare = {
            sessionInfo {
                it.copy(live = true, liveWindow = LiveWindow(90.0, 2.0, joinedBehindSeconds = 6.0, joinedPositionSeconds = 0.0, joinedAt = timeSource.markNow()))
            }
            playing(position = 0.0, duration = 6.0)
            engineState { it.copy(seekable = false) }
        }) {
            dispatch(PlayerCommand.GoToLive)
        },
        Ask("Space and the play button") {
            press(InputKey.SPACE)
            dispatch(PlayerCommand.TogglePause)
        },
        Ask("a double tap in a skip zone", InputProfile.TOUCH) {
            doubleTap(FORWARD)
            doubleTap(BACKWARD)
        },
        Ask("a remote's Select", InputProfile.TV, controlsDown) { press(InputKey.SELECT) },
        Ask("the media keys") {
            press(InputKey.MEDIA_PLAY_PAUSE)
            press(InputKey.MEDIA_FAST_FORWARD)
            press(InputKey.MEDIA_REWIND)
        },
        Ask("the system's media controls") {
            dispatch(PlayerCommand.Pause)
            dispatch(PlayerCommand.Play)
            dispatch(PlayerCommand.SeekTo(300.0))
        },
        Ask("the speed menu and keys") {
            dispatch(PlayerCommand.SetSpeed(1.5))
            press(InputKey.PLUS)
            press(InputKey.MINUS)
            press(InputKey.R)
        },
        Ask("the episode buttons and keys, up next's button", prepare = {
            sessionInfo { it.copy(episode = true, nextEpisode = NextEpisode("Next", null), hasPreviousEpisode = true) }
        }) {
            dispatch(PlayerCommand.NextEpisode)
            dispatch(PlayerCommand.PreviousEpisode)
            press(InputKey.N)
            press(InputKey.P)
            press(InputKey.MEDIA_NEXT)
        },
    )

    /** What reached the engine, the session or the room: nothing, while this device may not control the playback. */
    private fun PlayerHarness.reached(watch: FakeWatch): List<String> = listOfNotNull(
        engine.seeks.takeIf { it.isNotEmpty() }?.let { "seeks $it" },
        session.liveSeeks.takeIf { it.isNotEmpty() }?.let { "live seeks $it" },
        engine.paused.takeIf { it.isNotEmpty() }?.let { "paused $it" },
        engine.speeds.takeIf { it.isNotEmpty() }?.let { "speeds $it" },
        "the next episode".takeIf { session.nextEpisodes > 0 },
        "the previous episode".takeIf { session.previousEpisodes > 0 },
        watch.seeks.takeIf { it.isNotEmpty() }?.let { "the room's seeks $it" },
        watch.presses.takeIf { it.isNotEmpty() }?.let { "the room's presses $it" },
    )

    @Test
    fun aGuestMovesNothingWhicheverWayItAsks() {
        val outcomes = asks.associate { ask ->
            var outcome = emptyList<String>()
            playerTest(ask.profile) {
                playing(position = 100.0, duration = 600.0)
                ask.prepare(this)
                val watch = FakeWatch(canControl = false, canChangeEpisode = false)
                store.attachWatch(watch)
                advance(Duration.ZERO)
                val before = timeline
                ask.ask(this)
                outcome = buildList {
                    if (timeline != before) add("the timeline moved to ${timeline.scrub?.position ?: timeline.position}")
                    if (state.osd != "Only the host controls playback") add("the message read ${state.osd}")
                    advance(2.seconds)
                    addAll(reached(watch))
                }
            }
            ask.name to outcome
        }
        assertEquals(asks.associate { it.name to emptyList<String>() }, outcomes)
    }

    /** A seek under way: [start] begins it while this device controls the playback, [finish] ends it after. */
    private class UnderWay(
        val name: String,
        val profile: InputProfile = InputProfile.DESKTOP,
        val start: PlayerHarness.() -> Unit,
        val finish: PlayerHarness.() -> Unit,
    )

    private val underWay = listOf(
        UnderWay(
            "a remote's scrub",
            InputProfile.TV,
            start = {
                advance(5.seconds)
                input(InputEvent.KeyDown(InputKey.RIGHT))
            },
            finish = { input(InputEvent.KeyUp(InputKey.RIGHT)) },
        ),
        UnderWay(
            "a drag of the seek bar",
            start = { dispatch(PlayerCommand.ScrubTo(0.5)) },
            finish = { dispatch(PlayerCommand.CommitScrub) },
        ),
        UnderWay(
            "an arrow key held down",
            start = {
                input(InputEvent.KeyDown(InputKey.RIGHT))
                repeat(2) { input(InputEvent.KeyDown(InputKey.RIGHT, repeat = true)) }
            },
            finish = { input(InputEvent.KeyUp(InputKey.RIGHT)) },
        ),
    )

    /** The host makes the room host-only while a guest scrubs or holds a seek key: the seek goes nowhere. */
    @Test
    fun aSeekUnderWayWhenTheRoomTakesControlAwayGoesNowhere() {
        val outcomes = underWay.associate { case ->
            var outcome = emptyList<String>()
            playerTest(case.profile) {
                playing(position = 100.0, duration = 600.0)
                val watch = FakeWatch(canControl = true, canChangeEpisode = false)
                store.attachWatch(watch)
                advance(Duration.ZERO)
                case.start(this)
                val seeks = engine.seeks.toList()
                val roomSeeks = watch.seeks.toList()
                watch.state.update { it?.copy(canControl = false) }
                advance(Duration.ZERO)
                case.finish(this)
                advance(2.seconds)
                outcome = listOfNotNull(
                    timeline.scrub?.let { "the preview stayed at ${it.position}" },
                    engine.seeks.drop(seeks.size).takeIf { it.isNotEmpty() }?.let { "seeks $it" },
                    watch.seeks.drop(roomSeeks.size).takeIf { it.isNotEmpty() }?.let { "the room's seeks $it" },
                )
            }
            case.name to outcome
        }
        assertEquals(underWay.associate { it.name to emptyList<String>() }, outcomes)
    }

    /** A guest's click on the video brings the controls up and down, as for anyone with Controls as the click's action. */
    @Test
    fun aGuestWhoMayNotControlClicksTheControlsUpAndDown() = playerTest {
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        playing()
        advance(3.seconds)
        assertFalse(state.controlsVisible)
        input(InputEvent.Click(x = 0.5f))
        assertNull(state.osd)
        assertTrue(state.controlsVisible)
    }
}
