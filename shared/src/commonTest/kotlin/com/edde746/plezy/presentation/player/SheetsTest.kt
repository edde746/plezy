package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.ScrubFrame
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.format.clockTime
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaFilePart
import com.edde746.plezy.model.MediaFileVersion
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.session.NextEpisode
import com.edde746.plezy.playback.session.QueueEntry
import com.edde746.plezy.playback.session.SessionChapter
import com.edde746.plezy.playback.session.SourceTrack
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** The sheets' and the chrome's states beside the transport: chapters, the queue, file info, the sleep timer, errors. */
class SheetsTest {
    @Test
    fun chaptersComeFromTheServerWithTheirThumbnailsElseFromTheFile() = playerTest {
        playing(position = 100.0)
        engineState { it.copy(chapters = listOf(Chapter("Intro", 0.0), Chapter(null, 120.0))) }
        assertEquals(listOf("Intro", "Chapter 2"), state.chapters.map { it.title })
        assertEquals(listOf("0:00", "2:00"), state.chapters.map { it.start })
        assertEquals(listOf(true, false), state.chapters.map { it.current })
        assertEquals(listOf(null, null), state.chapters.map { it.imageUrl })

        sessionInfo { it.copy(chapters = listOf(SessionChapter("Opening", 0.0, imageUrl = "a.jpg"), SessionChapter("Act One", 300.0, imageUrl = "b.jpg"))) }
        assertEquals(listOf("Opening", "Act One"), state.chapters.map { it.title }, "the server's chapters replace the file's")
        assertEquals(listOf("a.jpg", "b.jpg"), state.chapters.map { it.imageUrl })
        position(310.0)
        assertEquals(listOf(false, true), state.chapters.map { it.current })

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.CHAPTERS))
        dispatch(assertNotNull(state.chapters[0].command))
        assertEquals(0.0, engine.seeks.last().first)
        assertNull(state.menu, "a pick closes the sheet")
        assertEquals(PlayerCommand.SeekToChapter(1), state.chapters[1].command)
    }

    @Test
    fun aGuestWhoMayNotSeekSeesTheChaptersWithoutCommands() = playerTest {
        playing()
        engineState { it.copy(chapters = listOf(Chapter("Intro", 0.0))) }
        store.attachWatch(FakeWatch(canControl = false, canChangeEpisode = false))
        assertNull(state.chapters.single().command)
    }

    @Test
    fun theQueueListsItsEntriesWithTheCurrentAndSpoilersMarked() = playerTest {
        playing()
        sessionInfo {
            it.copy(
                queue = listOf(
                    QueueEntry("1", "Pilot", "S1E1", "1.jpg", current = true),
                    QueueEntry("2", "Episode 2", "S1E2", "2.jpg", spoiler = true),
                ),
            )
        }
        assertEquals(
            listOf(
                QueueItem("1", "Pilot", "S1E1", "1.jpg", current = true),
                QueueItem("2", "Episode 2", "S1E2", "2.jpg", current = false, spoiler = true),
            ),
            state.queue,
        )
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.QUEUE))
        dispatch(PlayerCommand.PlayQueueItem("2"))
        assertEquals("queue 2", session.actions.last())
        assertNull(state.menu)
    }

    @Test
    fun theServersAudioTracksShowWhenThereIsMoreThanOne() = playerTest {
        playing()
        sessionInfo { it.copy(sourceAudio = listOf(SourceTrack(7, "English", "AAC"))) }
        assertEquals(emptyList(), state.sourceAudioTracks, "one track: nothing to choose")
        sessionInfo { it.copy(sourceAudio = listOf(SourceTrack(7, "English", "AAC", selected = true), SourceTrack(8, "French"))) }
        assertEquals(
            listOf(TrackItem(7, "English", "AAC", selected = true), TrackItem(8, "French", null, selected = false)),
            state.sourceAudioTracks,
        )
        assertTrue(state.showsAudioMenu)
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.AUDIO))
        dispatch(PlayerCommand.SelectSourceTrack(TrackKind.AUDIO, 8))
        assertEquals("source AUDIO 8", session.actions.last())
        assertNull(state.menu, "the pick closes the audio menu")
    }

    @Test
    fun fileInfoLoadsAsItsPageOpensOrSaysWhyNot() = playerTest {
        playing()
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        assertNull(state.fileInfo, "a server without file info has no page")

        sessionInfo { it.copy(fileInfo = true, title = "Movie", item = null) }
        val loaded = MediaFileInfo(
            listOf(
                MediaFileVersion(container = "mkv", parts = listOf(MediaFilePart(filePath = "/media/movie.mkv"))),
                MediaFileVersion(container = "mp4", parts = listOf(MediaFilePart(filePath = "/media/movie.mp4"))),
            ),
        )
        session.fileInfo = loaded
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        val info = assertNotNull(state.fileInfo)
        assertFalse(info.loading)
        assertNull(info.error)
        assertEquals(loaded, info.info, "every version, not only the one playing")
        assertEquals("Movie", info.title)

        val episode = testMediaItem("e2", MediaKind.EPISODE, "s", title = "Pilot", parentIndex = 1, grandparentTitle = "Show", index = 2)
        sessionInfo { it.copy(item = episode) }
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        assertEquals("Show · S1 E2 · Pilot", state.fileInfo?.title, "an episode's page names the episode, not its show")
        sessionInfo { it.copy(item = null) }

        session.fileInfo = null
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        assertEquals(T.messages.fileInfoNotAvailable, state.fileInfo?.error)

        session.fileInfoFailure = IllegalStateException("boom")
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        assertEquals(T.messages.errorLoadingFileInfo(T.errors.reasonUnexpected), state.fileInfo?.error)

        sessionInfo { it.copy(live = true) }
        assertNull(state.fileInfo, "live has no file")
    }

    @Test
    fun `file info of an earlier episode landing late does not replace the current one`() = playerTest {
        playing()
        val first = testMediaItem("e1", MediaKind.EPISODE, "s", title = "Pilot", parentIndex = 1, grandparentTitle = "Show", index = 1)
        val second = testMediaItem("e2", MediaKind.EPISODE, "s", title = "Second", parentIndex = 1, grandparentTitle = "Show", index = 2)
        sessionInfo { it.copy(fileInfo = true, item = first) }
        session.hold = true
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))
        dispatch(PlayerCommand.CloseMenu)
        sessionInfo { it.copy(item = second) }
        dispatch(PlayerCommand.OpenMenu(PlayerMenu.FILE_INFO))

        val secondInfo = MediaFileInfo(listOf(MediaFileVersion(container = "mkv", parts = listOf(MediaFilePart(filePath = "/media/e2.mkv")))))
        session.heldFileInfo[1].complete(secondInfo)
        advance(Duration.ZERO)
        session.heldFileInfo[0].complete(MediaFileInfo(listOf(MediaFileVersion(container = "mp4", parts = listOf(MediaFilePart(filePath = "/media/e1.mp4"))))))
        advance(Duration.ZERO)

        assertEquals("Show · S1 E2 · Second", state.fileInfo?.title)
        assertEquals(secondInfo, state.fileInfo?.info)
    }

    @Test
    fun theSleepTimersBannerCountsDownAndPlus15PushesItOn() = playerTest {
        playing()
        assertNull(state.sleepTimer)
        dispatch(PlayerCommand.SetSleepTimer(15))
        assertEquals(SleepTimerBanner("Playback will pause in 15m", "+15 min"), state.sleepTimer)
        advance(30.seconds)
        assertEquals("Playback will pause in 14m 30s", state.sleepTimer?.text)
        dispatch(PlayerCommand.ExtendSleepTimer)
        assertEquals("Playback will pause in 29m 30s", state.sleepTimer?.text)
        advance(29.minutes + 30.seconds)
        assertNotNull(state.stillWatching, "the extended timer runs out")
        assertNull(state.sleepTimer, "no banner while it asks")

        dispatch(PlayerCommand.SleepAtEndOfVideo)
        assertEquals(SleepTimerBanner(T.videoControls.playbackWillPauseAtEnd, null), state.sleepTimer, "no extension at the end")
        dispatch(PlayerCommand.ExtendSleepTimer)
        assertEquals(SleepTimerBanner(T.videoControls.playbackWillPauseAtEnd, null), state.sleepTimer)
        dispatch(PlayerCommand.CancelSleepTimer)
        assertNull(state.sleepTimer)
    }

    @Test
    fun theSettingsButtonIsHighlightedWhileTheZoomIsOff100() = playerTest {
        playing()
        assertFalse(state.settingsHighlighted)
        dispatch(PlayerCommand.SetZoom(1.1))
        assertTrue(state.settingsHighlighted)
        dispatch(PlayerCommand.ResetZoom)
        assertFalse(state.settingsHighlighted)
    }

    @Test
    fun theSettingsButtonIsHighlightedWhileAShaderRuns() = playerTest(shaderFiles = FakeShaderFiles()) {
        playing()
        assertFalse(state.settingsHighlighted)
        dispatch(PlayerCommand.ToggleShaders)
        assertTrue(state.settingsHighlighted)
    }

    @Test
    fun endsAtIsNowPlusTheTimeLeftAtTheSpeedToTheMinute() = playerTest {
        fun at(millis: Long) = clockTime(millis / 1000, use24HourClock = true)
        playing(position = 100.0, duration = 600.0)
        // 20:00:00 plus 500 s: 20:08:20, shown as 20:08.
        assertEquals(at(clock.nowMillis + 480_000), timeline.finishClock)
        assertEquals(T.videoControls.endsAt(timeline.finishClock), timeline.endsAt)
        dispatch(PlayerCommand.SetSpeed(2.0))
        assertEquals(at(clock.nowMillis + 240_000), timeline.finishClock, "250 s at twice the speed: 20:04")

        // Paused, the clock moves on and so does the end.
        engineState { it.copy(paused = true) }
        clock.nowMillis += 60_000
        advance(60.seconds)
        assertEquals(at(clock.nowMillis + 240_000), timeline.finishClock)

        position(600.0)
        assertEquals("", timeline.endsAt, "nothing remains")
        sessionInfo { it.copy(live = true) }
        assertEquals("", timeline.endsAt)
    }

    @Test
    fun endsAtFollowsThePlatformsTwelveOrTwentyFourHourClock() = playerTest {
        playing(position = 100.0, duration = 600.0)
        val finish = (clock.nowMillis + 480_000) / 1000
        assertEquals(clockTime(finish, use24HourClock = true), timeline.finishClock, "24 hours until the UI says otherwise")
        store.setUse24HourClock(false)
        assertEquals(clockTime(finish, use24HourClock = false), timeline.finishClock)
        assertTrue(timeline.finishClock.endsWith("AM") || timeline.finishClock.endsWith("PM"), timeline.finishClock)
        assertEquals(T.videoControls.endsAt(timeline.finishClock), timeline.endsAt)
        store.setUse24HourClock(true)
        assertFalse(timeline.finishClock.endsWith("AM") || timeline.finishClock.endsWith("PM"), timeline.finishClock)
    }

    @Test
    fun aScrubShowsTheServersThumbnailAtThePreview() = playerTest {
        playing(position = 100.0, duration = 600.0)
        val frame = ScrubFrame.SheetTile("sheet.jpg", 0, 0, 1, 1, 160, 90)
        val asked = mutableListOf<Duration>()
        sessionInfo {
            it.copy(
                scrubPreview = object : ScrubPreviewSource {
                    override val isAvailable = true
                    override fun frameAt(time: Duration): ScrubFrame {
                        asked += time
                        return frame
                    }
                    override fun dispose() = Unit
                },
            )
        }
        assertNull(timeline.scrub)
        dispatch(PlayerCommand.ScrubTo(0.5))
        assertEquals(frame, timeline.scrub?.frame)
        assertEquals(300.seconds, asked.last())
    }

    @Test
    fun upNextShowsTheNextEpisodesStillAndTheShuffle() = playerTest {
        sessionInfo { it.copy(nextEpisode = NextEpisode("Chapter Two", "S1E2", imageUrl = "still.jpg"), shuffled = true) }
        playing(position = 590.0, duration = 600.0)
        val prompt = assertNotNull(state.prompt)
        assertEquals("still.jpg", prompt.imageUrl)
        assertTrue(prompt.shuffled)
    }

    @Test
    fun theServersLimitOffersTranscodingWhereTheSessionCan() = playerTest {
        playing()
        sessionInfo { it.copy(failure = PlaybackFailure.ServerLimit(transcodeOffered = true)) }
        val error = assertNotNull(state.error)
        assertEquals(T.messages.serverLimitTitle, error.title)
        assertEquals(T.messages.serverLimitBody, error.message)
        assertEquals(listOf(ErrorAction.TRANSCODE, ErrorAction.CLOSE), error.buttons.map { it.action })
        assertEquals(ErrorAction.TRANSCODE, error.primary.action)
        dispatch(error.primary.command)
        assertEquals("transcode", session.actions.last())

        sessionInfo { it.copy(failure = PlaybackFailure.ServerLimit(transcodeOffered = false)) }
        assertEquals(listOf(ErrorAction.RETRY, ErrorAction.CLOSE), state.error?.buttons?.map { it.action }, "a refused transcode offers none")
        dispatch(PlayerCommand.ForceTranscode)
        assertEquals(1, session.actions.count { it == "transcode" })
    }

    @Test
    fun aServersRefusalShowsItsOwnMessage() = playerTest {
        sessionInfo { it.copy(failure = PlaybackFailure.Server(com.edde746.plezy.backend.PlaybackFailureReason.UNKNOWN, "Not allowed")) }
        val error = assertNotNull(state.error)
        assertEquals(T.player.error.title, error.title)
        assertEquals("Not allowed", error.message)
        assertEquals(listOf(ErrorAction.RETRY, ErrorAction.CLOSE), error.buttons.map { it.action })
    }
}
