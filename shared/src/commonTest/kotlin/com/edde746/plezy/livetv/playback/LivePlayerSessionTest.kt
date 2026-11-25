@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.livetv.playback

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.input.VideoClickAction
import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveProgramInfo
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvBackgroundPolicy
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvLaunch
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.livetv.LiveTvStartPosition
import com.edde746.plezy.livetv.liveTvChannelItem
import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.ScriptedEngine
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/** The player's live session: start, the watch-from-start question, heartbeats, zaps, the retry ladder, time-shift. */
class LivePlayerSessionTest {
    private val channels = listOf(
        LiveTvChannel(key = "ch-1", title = "Channel 5", serverId = "srv-1", thumb = "/logo/5"),
        LiveTvChannel(key = "ch-2", title = "Channel 6", serverId = "srv-1", thumb = "/logo/6"),
    )

    private inner class Rig(
        val test: TestScope,
        startPosition: LiveTvStartPosition = LiveTvStartPosition.ASK,
        tv: Boolean = false,
        start: Int = 0,
    ) {
        val engine = ScriptedEngine()
        val liveTv = FakeLiveTv()
        val backend = FakeMediaBackend("srv-1").also { it.liveTv = liveTv }
        val sessions = mutableMapOf<String, FakeLivePlaybackSession>()
        val events = mutableListOf<String>()
        val foreground = MutableStateFlow(true)
        val videoClick = MutableStateFlow(VideoClickAction.CONTROLS)
        var left = 0

        /** The messages the session left the player with, in order (null: it left without one). */
        val leftWith = mutableListOf<String?>()

        /** Whether the device lets video play now (a car's restrictions). */
        var playbackAllowed = true
        val clock = object : Clock {
            override fun now(): Instant = Instant.fromEpochSeconds(NOW) + test.testScheduler.currentTime.milliseconds
        }

        /** The server's guide: what its schedule answers, whatever the range asked. */
        var guide: suspend () -> List<LiveTvProgram> = { emptyList() }

        init {
            liveTv.start = { key, _, _ ->
                events += "tune $key"
                sessions.getOrPut(key) { fake(key) }
            }
            liveTv.schedule = { _, _ -> guide() }
        }

        fun fake(
            key: String,
            buffer: CaptureBuffer? = null,
            program: LiveProgramInfo = LiveProgramInfo(durationMs = 999),
            policy: LiveTvBackgroundPolicy = LiveTvBackgroundPolicy.RETAIN_SESSION,
            subtitles: List<MediaSubtitleTrack> = emptyList(),
        ) = FakeLivePlaybackSession(key, buffer, program, policy, subtitles) { state -> events += "$key $state (loads ${engine.loads.size})" }

        private val channel = channels[start]

        val session by lazy {
            LivePlayerSession(
                engine = engine,
                launch = LiveTvLaunch(
                    serverId = ServerId("srv-1"),
                    dvrKey = "dvr-1",
                    channel = channel,
                    channels = channels,
                    startPosition = startPosition,
                    item = liveTvChannelItem(channel, backend.backend, "srv-1"),
                ),
                servers = { listOf(LiveTvServerEntry(ServerId("srv-1"), "dvr-1")) },
                client = { if (it == backend.serverId) backend else null },
                playbackOptions = { OPTIONS },
                quality = { TranscodeQualityPreset.ORIGINAL },
                subtitleStyle = emptyFlow(),
                videoClick = videoClick,
                foreground = foreground,
                tv = tv,
                leave = { notice ->
                    leftWith += notice
                    left++
                },
                playbackAllowed = { playbackAllowed },
                parentScope = test.backgroundScope,
                backgroundScope = test.backgroundScope,
                clock = clock,
                timeSource = test.testScheduler.timeSource,
            ).also { test.runCurrent() }
        }

        fun advance(duration: Duration) {
            test.advanceTimeBy(duration)
            test.runCurrent()
        }
    }

    @Test
    fun aChannelPlaysAsALiveFileTitledAfterTheChannelWithItsLogo() = runTest {
        val rig = Rig(this)
        val info = rig.session.info.value
        assertEquals("Channel 5", info.title)
        assertEquals("/logo/5", info.artworkUrl)
        assertTrue(info.live)
        val load = rig.engine.loads.single()
        assertTrue(load.live)
        assertEquals("https://live.example/ch-1", load.url)
        assertEquals(mapOf("Accept-Language" to "en"), load.headers)
        assertNull(load.liveStartIndex)
        assertEquals(listOf("tune ch-1"), rig.events)
    }

    @Test
    fun theTitleIsTheAiringProgrammeOverTheChannelAndFollowsTheGuide() = runTest {
        val rig = Rig(this)
        rig.guide = {
            listOf(
                LiveTvProgram(title = "Morning News", beginsAt = NOW - 600, endsAt = NOW + 120, channelIdentifier = "ch-1"),
                LiveTvProgram(title = "Pilot", grandparentTitle = "Pattern Report", beginsAt = NOW + 120, endsAt = NOW + 1800, channelIdentifier = "ch-1"),
                LiveTvProgram(title = "Weather Loop", beginsAt = NOW - 600, endsAt = NOW + 1800, channelIdentifier = "ch-2"),
            )
        }
        rig.session
        fun titles() = rig.session.info.value.let { it.title to it.subtitle }
        assertEquals("Morning News" to "Channel 5", titles())

        rig.advance(119.seconds)
        assertEquals("Morning News" to "Channel 5", titles())
        rig.advance(1.seconds)
        assertEquals("Pattern Report" to "Channel 5", titles(), "the next programme as the airing ends; an episode by its series")

        rig.session.playNextEpisode()
        runCurrent()
        assertEquals("Weather Loop" to "Channel 6", titles(), "the zapped channel's programme")
    }

    @Test
    fun aChannelWithNoAiringKnownIsTitledByItsName() = runTest {
        val rig = Rig(this)
        rig.guide = { listOf(LiveTvProgram(title = " ", beginsAt = NOW - 600, endsAt = NOW + 600, channelIdentifier = "ch-1")) }
        rig.session
        assertEquals("Channel 5" to null, rig.session.info.value.let { it.title to it.subtitle }, "a programme without a title")

        rig.guide = { throw IllegalStateException("guide down") }
        rig.advance(10.minutes)
        assertEquals("Channel 5" to null, rig.session.info.value.let { it.title to it.subtitle }, "a guide that fails")

        rig.guide = { listOf(LiveTvProgram(title = "Late Show", beginsAt = NOW, endsAt = NOW + 3600, channelIdentifier = "ch-1")) }
        rig.advance(5.minutes)
        assertEquals("Late Show" to "Channel 5", rig.session.info.value.let { it.title to it.subtitle }, "read again a while later")
    }

    @Test
    fun aClickOnLiveFollowsTheClickSettingAsItChanges() = runTest {
        val rig = Rig(this)
        rig.session
        testScheduler.runCurrent()
        assertEquals(VideoClickAction.CONTROLS, rig.session.info.value.videoClick, "off: a click shows the controls")
        rig.videoClick.value = VideoClickAction.PAUSE
        testScheduler.runCurrent()
        assertEquals(VideoClickAction.PAUSE, rig.session.info.value.videoClick)
    }

    @Test
    fun nextAndPreviousZapThroughTheChannelListAndPreviousNeverRestarts() = runTest {
        val rig = Rig(this)
        rig.session
        var info = rig.session.info.value
        assertFalse(info.episode, "live shows no previous and next buttons; the keys still zap")
        assertEquals(false, info.hasPreviousEpisode)
        assertEquals("Channel 6", info.nextEpisode?.title)

        rig.session.playPreviousEpisode()
        runCurrent()
        assertEquals(listOf("tune ch-1"), rig.events, "the first channel has nothing before it, and live has no restart")
        assertEquals(1, rig.engine.loads.size)

        rig.session.playNextEpisode()
        runCurrent()
        info = rig.session.info.value
        assertEquals("Channel 6", info.title)
        assertEquals("/logo/6", info.artworkUrl)
        assertTrue(info.hasPreviousEpisode)
        assertNull(info.nextEpisode)
        // The new channel is tuned and opened first; the old one's last report follows, then the new one is adopted.
        assertEquals(listOf("tune ch-1", "tune ch-2", "ch-1 STOPPED (loads 2)"), rig.events)
        assertEquals("https://live.example/ch-2", rig.engine.loads.last().url)

        rig.advance(3.seconds)
        assertEquals(listOf(LiveTimelineState.PLAYING), rig.sessions.getValue("ch-2").states, "the heartbeat follows the new channel")
        assertEquals(listOf(LiveTimelineState.STOPPED), rig.sessions.getValue("ch-1").states)
    }

    @Test
    fun aZapDuringTheStartIsRefusedRatherThanTunedBesideIt() = runTest {
        val rig = Rig(this)
        val tune = CompletableDeferred<LiveTvPlaybackSession?>()
        rig.liveTv.start = { key, _, _ ->
            rig.events += "tune $key"
            tune.await()
        }
        rig.session.playNextEpisode()
        runCurrent()
        assertEquals(listOf("tune ch-1"), rig.events)

        tune.complete(null)
        runCurrent()
        assertEquals(listOf<String?>("Couldn't start the channel: Could not start the live channel"), rig.leftWith, "the start fails: it leaves with why")
        assertNull(rig.session.info.value.failure)
    }

    @Test
    fun aStartThatFailsReportsTheTuneStoppedAndLeavesWithWhy() = runTest {
        val rig = Rig(this)
        rig.sessions["ch-1"] = rig.fake("ch-1").apply { url = { _, _ -> null } }
        rig.session
        runCurrent()
        assertEquals(listOf(LiveTimelineState.STOPPED), rig.sessions.getValue("ch-1").states, "the adopted tune is reported stopped")
        assertEquals(1, rig.left)
        assertEquals(T.liveTv.playbackStartFailed(T.liveTv.failedToBuildStreamUrl), rig.leftWith.single())
        assertNull(rig.session.info.value.failure, "no failure card stays behind")
        assertEquals(0, rig.engine.loads.size)
    }

    @Test
    fun aCarThatForbidsVideoOpensTheChannelPaused() = runTest {
        val rig = Rig(this)
        rig.playbackAllowed = false
        rig.session
        runCurrent()
        assertEquals(1, rig.engine.loads.size)
        assertEquals(true, rig.engine.pauses.last(), "nothing plays while the car forbids it")

        rig.playbackAllowed = true
        rig.session.playNextEpisode()
        runCurrent()
        assertEquals(false, rig.engine.pauses.last(), "a zap once allowed plays")
    }

    @Test
    fun aZapNamesTheChannelTunedToFromThePressOn() = runTest {
        val rig = Rig(this)
        rig.session
        runCurrent()
        val tune = CompletableDeferred<LiveTvPlaybackSession?>()
        rig.liveTv.start = { _, _, _ -> tune.await() }
        rig.session.playNextEpisode()
        assertEquals("Channel 6", rig.session.info.value.title, "while it opens, the controls name where it goes")
        tune.complete(null)
        runCurrent()
        assertEquals("Channel 5", rig.session.info.value.title, "it failed: back to the channel playing")
    }

    @Test
    fun aFailedZapSaysSoAndKeepsTheChannel() = runTest {
        val rig = Rig(this)
        rig.session
        rig.liveTv.start = { _, _, _ -> null }
        rig.session.playNextEpisode()
        runCurrent()
        val info = rig.session.info.value
        assertEquals("Could not start the live channel", rig.session.info.value.notice?.text)
        assertEquals("Channel 5", info.title)
        assertEquals(1, rig.engine.loads.size)
    }

    @Test
    fun aZapWhoseStreamCantBeHadReleasesItsSession() = runTest {
        val rig = Rig(this)
        rig.session
        val broken = rig.fake("ch-2").apply { url = { _, _ -> throw IllegalStateException("decision refused") } }
        rig.sessions["ch-2"] = broken
        rig.session.playNextEpisode()
        runCurrent()
        assertEquals(1, broken.discarded)
        assertTrue(rig.session.info.value.notice?.text.orEmpty().startsWith("Couldn't switch channel: "))
        assertEquals("Channel 5", rig.session.info.value.title)
    }

    @Test
    fun aReplacementStreamFailingBeforeTheZapCommitsIsRecoveredOnceItDoes() = runTest {
        val rig = Rig(this)
        rig.session
        val old = rig.sessions.getValue("ch-1").apply { holdReports = true }
        rig.session.playNextEpisode()
        runCurrent()
        // The new stream fails while the zap still waits on the old session's last report.
        rig.engine.fail("connection reset")
        runCurrent()
        val new = rig.sessions.getValue("ch-2")
        assertTrue(new.recoveries.isEmpty(), "the zap owns the stream until it commits")
        assertTrue(old.recoveries.isEmpty())

        old.completeReport(0, null)
        runCurrent()
        assertEquals(listOf(false to true), new.recoveries, "the failed replacement takes the ladder once committed")
        assertTrue(old.recoveries.isEmpty())
    }

    @Test
    fun aZapWhileAnotherIsUnderWayIsDropped() = runTest {
        val rig = Rig(this)
        rig.session
        val tune = CompletableDeferred<LiveTvPlaybackSession?>()
        rig.liveTv.start = { key, _, _ ->
            rig.events += "tune $key"
            tune.await()
        }
        rig.session.playNextEpisode()
        runCurrent()
        rig.session.playNextEpisode()
        runCurrent()
        assertEquals(listOf("tune ch-1", "tune ch-2"), rig.events, "the second zap tunes nothing")

        tune.complete(rig.fake("ch-2"))
        runCurrent()
        assertEquals("Channel 6", rig.session.info.value.title)
        assertEquals(2, rig.engine.loads.size)
    }

    @Test
    fun aZapAwayFromAChannelBeingRecoveredReplacesItsStreamWithoutWaiting() = runTest {
        val rig = Rig(this)
        rig.session
        val recovered = CompletableDeferred<LiveTvPlaybackSession?>()
        val old = rig.sessions.getValue("ch-1").apply { this.recovered = { _, _ -> recovered.await() } }
        rig.engine.fail("connection reset")
        runCurrent()
        assertEquals(1, old.recoveries.size, "recovering")

        rig.session.playNextEpisode()
        runCurrent()
        assertEquals("Channel 6", rig.session.info.value.title, "the zap didn't wait for the recovery")
        assertEquals("https://live.example/ch-2", rig.engine.loads.last().url)

        val late = rig.fake("ch-1-late")
        recovered.complete(late)
        runCurrent()
        assertEquals(1, late.discarded, "what the superseded recovery brought back is let go")
        assertEquals("Channel 6", rig.session.info.value.title)
        assertEquals("https://live.example/ch-2", rig.engine.loads.last().url)
        assertNull(rig.session.info.value.failure)
    }

    @Test
    fun heartbeatsGoEveryTenSecondsTheFirstAfterThree() = runTest {
        val rig = Rig(this)
        rig.session
        val tuned = rig.sessions.getValue("ch-1")
        rig.advance(2.9.seconds)
        assertTrue(tuned.states.isEmpty())
        rig.advance(0.1.seconds)
        assertEquals(listOf(LiveTimelineState.PLAYING), tuned.states)
        rig.advance(7.seconds)
        rig.engine.setPaused(true)
        runCurrent()
        rig.advance(10.seconds)
        assertEquals(listOf(LiveTimelineState.PLAYING, LiveTimelineState.PLAYING, LiveTimelineState.PAUSED), tuned.states)
        assertEquals(listOf(3_000L, 10_000L, 20_000L), tuned.positions, "the position is the time since the stream started")
        assertEquals(listOf(999L, 999L, 999L), tuned.durations)
    }

    @Test
    fun historyInTheCaptureBufferAsksWhetherToWatchFromTheProgramsStart() = runTest {
        val rig = Rig(this)
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 1200.0, 0.0, 1200.0), LiveProgramInfo("prog", 3_600_000, NOW - 600))
        val choice = assertNotNull(rig.session.info.value.choice)
        assertEquals("Join Session in Progress", choice.title)
        assertEquals(listOf("Watch from start (10 min ago)", "Watch Live"), choice.options)
        assertTrue(rig.engine.loads.isEmpty())

        rig.session.answerChoice(0)
        runCurrent()
        assertNull(rig.session.info.value.choice)
        assertEquals(600L, rig.sessions.getValue("ch-1").urlRequests.single().first)
        assertEquals(0, rig.engine.loads.single().liveStartIndex, "an offset stream starts at its first segment")
    }

    @Test
    fun dismissingTheQuestionWatchesLive() = runTest {
        val rig = Rig(this)
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 1200.0, 0.0, 1200.0), LiveProgramInfo("prog", 3_600_000, NOW - 600))
        rig.session.answerChoice(null)
        runCurrent()
        assertNull(rig.sessions.getValue("ch-1").urlRequests.single().first)
        assertNull(rig.engine.loads.single().liveStartIndex)
    }

    @Test
    fun aLaunchCanAnswerTheQuestionAhead() = runTest {
        val beginning = Rig(this, startPosition = LiveTvStartPosition.BEGINNING)
        beginning.sessions["ch-1"] = beginning.fake("ch-1", CaptureBuffer(NOW - 1200.0, 0.0, 1200.0), LiveProgramInfo("p", 3_600_000, NOW - 600))
        assertNull(beginning.session.info.value.choice)
        assertEquals(600L, beginning.sessions.getValue("ch-1").urlRequests.single().first)

        val live = Rig(this, startPosition = LiveTvStartPosition.LIVE)
        live.sessions["ch-1"] = live.fake("ch-1", CaptureBuffer(NOW - 1200.0, 0.0, 1200.0), LiveProgramInfo("p", 3_600_000, NOW - 600))
        assertNull(live.session.info.value.choice)
        assertNull(live.sessions.getValue("ch-1").urlRequests.single().first)
    }

    @Test
    fun aProgramJustBegunStartsFromTheBuffersStart() = runTest {
        val rig = Rig(this, startPosition = LiveTvStartPosition.BEGINNING)
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 1200.0, 30.0, 1200.0), LiveProgramInfo("p", 3_600_000, NOW - 30))
        rig.session
        assertEquals(30L, rig.sessions.getValue("ch-1").urlRequests.single().first)
    }

    @Test
    fun aFreshTuneIsNeverAsked() = runTest {
        val rig = Rig(this)
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 20.0, 0.0, 20.0), LiveProgramInfo("p", 3_600_000, NOW - 20))
        assertNull(rig.session.info.value.choice)
        assertEquals(1, rig.engine.loads.size)
    }

    @Test
    fun streamErrorsClimbTheLadderAndAPlaybackRestartRefillsIt() = runTest {
        val rig = Rig(this)
        rig.session
        val tuned = rig.sessions.getValue("ch-1")
        rig.engine.open(0.0)
        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(listOf(false to true), tuned.recoveries)
        rig.engine.open(0.0)
        runCurrent()
        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(listOf(false to true, false to true), tuned.recoveries, "the restart refilled the ladder")

        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(false to false, tuned.recoveries.last())
        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(3, tuned.recoveries.size)
        assertEquals(listOf<String?>(T.messages.playbackFailedDetail("segment 404")), rig.leftWith, "the ladder is spent: it leaves with the error")
        assertNull(rig.session.info.value.failure)
    }

    @Test
    fun aRecoveryThatFailsSaysTheStreamWasInterruptedAndRetryTriesAgain() = runTest {
        val rig = Rig(this)
        rig.session
        val tuned = rig.sessions.getValue("ch-1").apply { recovered = { _, _ -> null } }
        rig.engine.fail("connection reset")
        runCurrent()
        val failure = assertIs<PlaybackFailure.Server>(rig.session.info.value.failure)
        assertEquals("The live stream was interrupted. Press play to retry.", failure.message)

        tuned.recovered = { _, _ -> tuned }
        rig.session.retry()
        runCurrent()
        assertNull(rig.session.info.value.failure)
        assertEquals(2, tuned.recoveries.size)
        assertEquals(2, rig.engine.loads.size)
    }

    @Test
    fun aServerSubtitleIsBurnedInByRebuildingTheStream() = runTest {
        val rig = Rig(this)
        val finnish = MediaSubtitleTrack(id = 5, index = 3, language = "Finnish", languageCode = "fin", selected = false, forced = false)
        rig.sessions["ch-1"] = rig.fake("ch-1", subtitles = listOf(finnish))
        assertEquals(listOf(5), rig.session.info.value.sourceSubtitles.map { it.id })

        rig.session.selectSourceTrack(TrackKind.SUBTITLE, 5)
        runCurrent()
        assertEquals(null to finnish, rig.sessions.getValue("ch-1").urlRequests.last())
        assertEquals("https://live.example/ch-1#burn=5", rig.engine.loads.last().url)
        assertTrue(rig.session.info.value.sourceSubtitles.single().selected)

        rig.session.selectSourceTrack(TrackKind.SUBTITLE, null)
        runCurrent()
        assertEquals("https://live.example/ch-1", rig.engine.loads.last().url)
        assertEquals(false, rig.session.info.value.sourceSubtitles.single().selected)
    }

    @Test
    fun theSubtitleCycleStepsThroughTheServersSubtitlesAndOff() = runTest {
        val rig = Rig(this)
        val finnish = MediaSubtitleTrack(id = 5, index = 3, language = "Finnish", languageCode = "fin", selected = false, forced = false)
        rig.sessions["ch-1"] = rig.fake("ch-1", subtitles = listOf(finnish))

        rig.session.cycleSourceSubtitles()
        runCurrent()
        assertEquals("https://live.example/ch-1#burn=5", rig.engine.loads.last().url)
        rig.session.cycleSourceSubtitles()
        runCurrent()
        assertEquals("https://live.example/ch-1", rig.engine.loads.last().url)
        assertEquals(false, rig.session.info.value.sourceSubtitles.single().selected)
    }

    @Test
    fun aRefusedSubtitleKeepsThePreviousChoice() = runTest {
        val rig = Rig(this)
        val finnish = MediaSubtitleTrack(id = 5, languageCode = "fin", selected = false, forced = false)
        rig.sessions["ch-1"] = rig.fake("ch-1", subtitles = listOf(finnish)).apply {
            url = { _, subtitle -> if (subtitle == null) "https://live.example/ch-1" else null }
        }
        rig.session.selectSourceTrack(TrackKind.SUBTITLE, 5)
        runCurrent()
        assertEquals(false, rig.session.info.value.sourceSubtitles.single().selected)
        assertEquals(1, rig.engine.loads.size)
    }

    @Test
    fun `a subtitle picked then turned off while the server confirms ends with no burn`() = runTest {
        val rig = Rig(this)
        val finnish = MediaSubtitleTrack(id = 5, languageCode = "fin", selected = false, forced = false)
        val confirmation = CompletableDeferred<Unit>()
        rig.sessions["ch-1"] = rig.fake("ch-1", subtitles = listOf(finnish)).apply {
            url = { _, subtitle ->
                if (subtitle != null) confirmation.await()
                "https://live.example/ch-1" + (subtitle?.let { "#burn=${it.id}" } ?: "")
            }
        }
        rig.session.selectSourceTrack(TrackKind.SUBTITLE, 5)
        runCurrent()
        rig.session.selectSourceTrack(TrackKind.SUBTITLE, null)
        runCurrent()
        confirmation.complete(Unit)
        runCurrent()

        assertEquals("https://live.example/ch-1", rig.engine.loads.last().url)
        assertEquals(false, rig.session.info.value.sourceSubtitles.single().selected)
    }

    @Test
    fun `a recovery under a fresh tune stops the old tune and a recovery of the same tune does not`() = runTest {
        val rig = Rig(this)
        rig.session
        val tuned = rig.sessions.getValue("ch-1")
        val fresh = rig.fake("ch-1-recovered")
        tuned.recovered = { _, _ -> fresh }
        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(LiveTimelineState.STOPPED, tuned.states.last())

        // The recovered tune recovers as itself, as a Jellyfin session does: it plays on, unstopped.
        rig.engine.fail("segment 404")
        runCurrent()
        assertEquals(1, fresh.recoveries.size)
        assertFalse(LiveTimelineState.STOPPED in fresh.states)
    }

    @Test
    fun `a programme older than the rewind window offers and opens the window start`() = runTest {
        val rig = Rig(this)
        // The window reaches back 15 minutes (offset 300 on); the programme began 18 minutes ago, before it.
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 1200.0, 300.0, 1200.0), LiveProgramInfo("prog", 3_600_000, NOW - 1080))
        assertEquals(listOf("Watch from start (15 min ago)", "Watch Live"), assertNotNull(rig.session.info.value.choice).options)

        rig.session.answerChoice(0)
        runCurrent()
        assertEquals(300L, rig.sessions.getValue("ch-1").urlRequests.single().first)
    }

    @Test
    fun theCaptureBufferIsTheRewindWindowAndAMoveReopensAtItsOffset() = runTest {
        val rig = Rig(this)
        rig.sessions["ch-1"] = rig.fake("ch-1", CaptureBuffer(NOW - 600.0, 0.0, 600.0))
        rig.session
        assertNull(rig.session.info.value.liveWindow, "no window before the open's clock is calibrated")
        rig.engine.open(0.0)
        runCurrent()
        val window = assertNotNull(rig.session.info.value.liveWindow)
        assertEquals(600.0, window.windowSeconds)
        assertTrue(window.atEdge(window.behind(0.0)))

        rig.session.seekLive(60.0)
        rig.session.seekLive(120.0)
        rig.advance(300.milliseconds)
        val tuned = rig.sessions.getValue("ch-1")
        assertEquals(listOf<Long?>(null, 480), tuned.urlRequests.map { it.first }, "one reopen for the burst, 2 min behind the edge")
        assertEquals(0, rig.engine.loads.last().liveStartIndex)

        rig.engine.open(0.0)
        runCurrent()
        val behind = assertNotNull(rig.session.info.value.liveWindow).behind(0.0)
        assertTrue(behind in 120.0..121.0, "2 min behind the edge, plus the time the reopen took: $behind")

        rig.session.seekLive(0.0)
        runCurrent()
        assertEquals(600L, tuned.urlRequests.last().first, "go to live reopens at the window's end")
    }

    @Test
    fun aHeartbeatsCaptureBufferBringsTheWindow() = runTest {
        val rig = Rig(this)
        rig.session
        rig.sessions.getValue("ch-1").timelineAnswer = LiveTimelineUpdate(captureBuffer = CaptureBuffer(NOW - 300.0, 0.0, 300.0))
        assertNull(rig.session.info.value.liveWindow)
        rig.advance(3.seconds)
        assertEquals(300.0, rig.session.info.value.liveWindow?.windowSeconds)
    }

    @Test
    fun aTvStopsASessionItCantKeepInTheBackgroundAndLeavesOnReturn() = runTest {
        val rig = Rig(this, tv = true)
        rig.sessions["ch-1"] = rig.fake("ch-1", policy = LiveTvBackgroundPolicy.STOP_AND_EXIT)
        rig.session
        rig.foreground.value = false
        runCurrent()
        assertEquals(listOf(LiveTimelineState.STOPPED), rig.sessions.getValue("ch-1").states)
        assertEquals(true, rig.engine.pauses.last())
        assertEquals(0, rig.left)
        rig.foreground.value = true
        runCurrent()
        assertEquals(1, rig.left)
    }

    @Test
    fun aKeptSessionPausesItsHeartbeatsInTheBackground() = runTest {
        val rig = Rig(this, tv = true)
        rig.session
        val tuned = rig.sessions.getValue("ch-1")
        rig.advance(3.seconds)
        rig.foreground.value = false
        rig.advance(60.seconds)
        assertEquals(1, tuned.states.size)
        rig.foreground.value = true
        rig.advance(3.seconds)
        assertEquals(2, tuned.states.size)
        assertEquals(0, rig.left)
    }

    @Test
    fun closingReportsTheSessionStoppedAndReleasesTheEngine() = runTest {
        val rig = Rig(this)
        rig.session.close()
        runCurrent()
        assertEquals(listOf(LiveTimelineState.STOPPED), rig.sessions.getValue("ch-1").states)
        assertTrue(rig.engine.released)
        rig.advance(30.seconds)
        assertEquals(1, rig.sessions.getValue("ch-1").states.size)
    }

    private companion object {
        const val NOW = 1_800_000_000L
        val OPTIONS = PlaybackOptions(hwdec = "no", demuxerMaxBytes = 1, demuxerMaxBackBytes = 1)
    }
}
