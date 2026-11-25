package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.TranscodeFallbackReason
import com.edde746.plezy.backend.PlaybackFailureReason
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackSubtitleSidecar
import com.edde746.plezy.backend.SubtitleSidecar
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.jellyfin.PlaybackFixture
import com.edde746.plezy.jellyfin.params
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaChapter
import com.edde746.plezy.model.MediaDisplayCriteria
import com.edde746.plezy.model.MediaMarker
import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPartTimeline
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.SubtitlePlaybackMode
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.queue.maestroEpisodes
import com.edde746.plezy.playback.queue.maestroServer
import com.edde746.plezy.playback.source.FakeDownloads
import com.edde746.plezy.playback.tracks.TrackType
import com.edde746.plezy.plex.PlexClientEnvironment
import com.edde746.plezy.plex.TEST_SERVER_ID
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ScopedPlayerPrefs
import com.edde746.plezy.settings.json.MediaVersionPreferences
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.respond
import io.ktor.http.Url
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readString
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** The playback session end to end over a fake server and a scripted engine. */
class PlaybackSessionTest {
    private fun TestScope.rig(backend: BackendKind = BackendKind.PLEX) = SessionRig(this, SessionBackend(backend = backend))

    @Test
    fun aLaunchedPlayResolvesBeforeItsEngineIsUsedAndOpensWhatItResolved() = runTest {
        with(rig()) {
            val launch = PlaybackSession.prepare(PlayRequest.Item(ServerId("srv"), "m1", item = movie()), env, backgroundScope)
            runCurrent()
            assertEquals(1, backend.initializations.size, "resolved before the session starts")
            assertEquals(emptyList(), engine.loads)
            session.start(launch)
            runCurrent()
            assertEquals(1, backend.initializations.size, "not resolved again")
            assertEquals("https://srv/m1/v1080", engine.loads.single().url)
        }
    }

    @Test
    fun aLaunchedPlayResolvesOnTheServersAsTheyWereWhenItWasAsked() = runTest {
        with(rig()) {
            val launch = PlaybackSession.prepare(PlayRequest.Item(ServerId("srv"), "m1", item = movie()), env, backgroundScope)
            // A health check that turns the server away after the tap doesn't reach the start already under way.
            servers.refusedServerIds = setOf(ServerId("srv"))
            servers.hidden += ServerId("srv")
            runCurrent()
            session.start(launch)
            runCurrent()
            assertEquals(1, backend.initializations.size)
            assertEquals("https://srv/m1/v1080", engine.loads.single().url)
        }
    }

    @Test
    fun aPlexMovieResumesWithTheServersHeadersAndReportsPlayingProgressAndStopped() = runTest {
        with(rig()) {
            play(movie(viewOffsetMs = 120_000))
            val load = engine.loads.single()
            assertEquals("https://srv/m1/v1080", load.url)
            assertEquals(120.0, load.startSeconds)
            assertEquals("t0ken", load.headers["X-Plex-Token"])
            assertEquals("Movie m1", session.info.value.title)
            assertEquals("srv:m1", session.playingKey.value)
            assertEquals(120.0.seconds, backend.initializations.single().startPosition)

            open(600.0)
            assertEquals(listOf("playing"), backend.states)
            assertEquals(listOf("started m1 @120000 playing=true"), trackers.events)
            at(125.0)
            elapse(10.seconds)
            assertEquals("playing", backend.states.last())
            assertTrue("position @125000" in trackers.events)

            session.close()
            idle()
            assertEquals("stopped", backend.states.last())
            assertEquals(125_000, backend.reports.last().positionMs)
            assertEquals("stopped @125000", trackers.events.last())
            assertTrue(engine.released)
            assertNull(session.playingKey.value)
        }
    }

    @Test
    fun nothingIsReportedBeforeTheFirstFrame() = runTest {
        with(rig()) {
            play(movie())
            elapse(30.seconds)
            session.close()
            idle()
            assertEquals(emptyList(), backend.states, "a stop without a frame ends nothing on the server")
            assertEquals(emptyList(), trackers.events)
        }
    }

    @Test
    fun aJellyfinVersionSwitchReportsTheOldSessionStoppedThenReopensAtThePosition() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN))
            open(600.0)
            at(300.0)
            assertEquals(2, session.info.value.versions.size)
            assertEquals(0, session.info.value.versionIndex)

            session.selectVersion(1)
            idle()
            assertEquals(listOf("playing", "stopped"), backend.states)
            assertEquals(300_000, backend.reports.last().positionMs)
            val reopen = backend.initializations.last()
            assertEquals(1, reopen.selectedMediaIndex)
            assertEquals("v4k", reopen.selectedMediaSourceId)
            assertEquals(300.seconds, reopen.startPosition)
            assertEquals("https://srv/m1/v4k", engine.loads.last().url)
            assertEquals(300.0, engine.loads.last().startSeconds)
            assertEquals(1, session.info.value.versionIndex)
            assertEquals(listOf("started m1 @0 playing=true", "stopped @300000"), trackers.events.filter { !it.startsWith("position") })

            open(600.0)
            assertEquals("playing", backend.states.last(), "the new file starts a new report session")
        }
    }

    @Test
    fun aQualityPickReopensTranscodedAtThePositionAndOutranksTheDefault() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(42.0)
            assertFalse(session.info.value.transcoding)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            val reopen = backend.initializations.last()
            assertEquals(TranscodeQualityPreset.P720_2MBPS, reopen.qualityPreset)
            assertEquals(42.seconds, reopen.startPosition)
            assertEquals("https://srv/m1/transcode/P720_2MBPS", engine.loads.last().url)
            assertTrue(session.info.value.transcoding)
            assertEquals(TranscodeQualityPreset.P720_2MBPS, session.info.value.quality?.selected)
        }
    }

    @Test
    fun theSourcesTransferIsToldBeforeTheOpenUnlessTheServerTranscodes() = runTest {
        with(rig()) {
            backend.initialize = { options ->
                val stream = SessionBackend.streamOf(options)
                stream.copy(mediaInfo = stream.mediaInfo?.copy(displayCriteria = MediaDisplayCriteria(transfer = "smpte2084")))
            }
            play(movie())
            open(600.0)
            assertEquals("smpte2084", engine.loads.single().server?.colorTransfer)

            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            assertEquals("https://srv/m1/transcode/P720_2MBPS", engine.loads.last().url)
            assertNull(engine.loads.last().server?.colorTransfer)
        }
    }

    @Test
    fun aSwitchThatFailsBeforeItsFileOpensRollsBackToTheFilePlaying() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(60.0)
            backend.initialize = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "refused", statusCode = 503) }
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            assertEquals(1, engine.loads.size, "nothing new loaded")
            assertNull(session.info.value.failure)
            assertNotNull(session.info.value.notice, "the failure shows as a notice")
            assertEquals(false, engine.pauses.last(), "playing again as it was")
            assertEquals("srv:m1", session.playingKey.value)
            assertEquals(TranscodeQualityPreset.ORIGINAL, session.info.value.quality?.selected)
        }
    }

    @Test
    fun aNextEpisodeLoadTheEngineRefusesRollsBackToTheEpisodeItPlaysOn() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            backend.episodes = listOf(first, episode("e2", 2))
            engine.fileTracks = EPISODE_1_TRACKS
            play(first)
            open(1200.0)
            idle()
            at(600.0)
            val tracks = session.engineState.value.tracks
            session.playNextEpisode()
            idle()
            assertEquals("https://srv/e2/v1080", engine.loads.last().url)
            assertEquals("stopped", backend.states.last())
            val stoppedAt = trackers.events.size

            engine.refuse("loadfile failed")
            idle()
            assertNull(session.info.value.failure, "the file the engine plays on isn't a failure")
            assertEquals(T.messages.errorLoading("loadfile failed"), session.info.value.notice?.text)
            assertEquals("srv:e1", session.playingKey.value)
            assertEquals("e1", session.launched?.itemId)
            assertEquals(1L, session.opened.value?.loadId)
            assertEquals("S1E1 · Episode 1", session.info.value.subtitle)
            assertEquals("Episode 2", session.info.value.nextEpisode?.title)
            with(session.engineState.value) {
                assertEquals(1L, loadId)
                assertEquals(600.0, positionSeconds)
                assertFalse(paused, "playing on as it was")
                assertEquals(tracks, this.tracks)
            }
            assertEquals("playing", backend.states.last(), "the old file's reports resume")
            assertEquals("started e1 @600000 playing=true", trackers.events[stoppedAt])

            session.close()
            idle()
            assertEquals("stopped", backend.states.last())
            assertEquals("e1", backend.reports.last().itemId)
            assertEquals(600_000, backend.reports.last().positionMs)
            assertEquals("stopped @600000", trackers.events.last())
        }
    }

    @Test
    fun theNextEpisodeComesFromTheSeriesAndPlaysInPlace() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            val first = episode("e1", 1)
            val second = episode("e2", 2)
            backend.episodes = listOf(first, second)
            play(first)
            open(1200.0)
            idle()
            val next = assertNotNull(session.info.value.nextEpisode)
            assertEquals("Episode 2", next.title)
            assertEquals("S1E2", next.subtitle)
            assertTrue(next.autoplay)
            assertEquals(5, next.countdownSeconds)
            assertEquals("The Show", session.info.value.title)
            assertEquals("S1E1 · Episode 1", session.info.value.subtitle)

            at(1190.0)
            session.playNextEpisode()
            idle()
            assertEquals("srv:e2", session.playingKey.value)
            assertEquals("e2", backend.initializations.last().metadata.id)
            assertEquals("https://srv/e2/v1080", engine.loads.last().url)
            assertEquals("stopped", backend.states.last())
            assertEquals("stopped @1190000", trackers.events.last())
            open(1200.0)
            assertEquals("started e2 @0 playing=true", trackers.events.last())
            assertTrue(session.info.value.hasPreviousEpisode)
        }
    }

    @Test
    fun previousPlaysThePreviousEpisodeAndTheFirstRestarts() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1), episode("e2", 2))
            play(episode("e2", 2))
            open(1200.0)
            idle()
            at(400.0)
            session.playPreviousEpisode()
            idle()
            assertEquals("https://srv/e1/v1080", engine.loads.last().url, "where it plays is the store's to weigh")
            open(1200.0)
            idle()
            at(400.0)
            session.playPreviousEpisode()
            idle()
            assertEquals(0.0, engine.state.positionSeconds, "nothing before the first: a restart")
            assertEquals(2, engine.loads.size)
        }
    }

    @Test
    fun offlineTheNextAndPreviousEpisodesAreTheShowsDownloadsInEpisodeOrder() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            servers.online.clear()
            val episodes = listOf(episode("e4", 4).copy(thumbPath = "/thumb/e4"), episode("e1", 1), episode("e2", 2))
            for (e in episodes) downloads.add(FakeDownloads.Copy("srv", e.id, listOf("file:///dl/${e.id}.mkv")))
            downloads.artwork["srv:/thumb/e4"] = "file:///art/e4.jpg"
            downloadedEpisodes = episodes + episode("other", 3).copy(grandparentId = "another show")
            play(episodes[2]) { it.copy(offline = true) }
            assertEquals("file:///dl/e2.mkv", engine.loads.last().url)
            open(1200.0)
            idle()
            val next = assertNotNull(session.info.value.nextEpisode, "no server answers, the downloads do")
            assertEquals("Episode 4", next.title)
            assertEquals("S1E4", next.subtitle)
            assertEquals("file:///art/e4.jpg", next.imageUrl, "the still its download saved")
            assertTrue(session.info.value.hasPreviousEpisode)

            session.playNextEpisode()
            idle()
            assertEquals("file:///dl/e4.mkv", engine.loads.last().url)
            open(1200.0)
            idle()
            assertNull(session.info.value.nextEpisode, "the last download has no next")

            session.playPreviousEpisode()
            idle()
            assertEquals("file:///dl/e2.mkv", engine.loads.last().url)
            open(1200.0)
            idle()
            session.playPreviousEpisode()
            idle()
            assertEquals("file:///dl/e1.mkv", engine.loads.last().url)
            assertEquals(0, backend.initializations.size, "nothing asked of the server")
        }
    }

    @Test
    fun theRealEndReportsStoppedAtTheDurationOnce() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            engine.report { it.copy(positionSeconds = 600.0, eof = true, paused = true) }
            idle()
            engine.report { it.copy(positionSeconds = 600.0) }
            idle()
            assertEquals(1, backend.states.count { it == "stopped" })
            assertEquals(600_000, backend.reports.last { it.state == "stopped" }.positionMs)
            assertEquals("stopped @600000", trackers.events.last())
            assertTrue(engine.state.eof)
        }
    }

    @Test
    fun aStreamThatDiesMidFileReloadsAtThePositionInsteadOfEnding() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            engine.report { it.copy(positionSeconds = 200.0, eof = true, transportFault = true) }
            idle()
            assertFalse(session.engineState.value.eof, "the end isn't the video's")
            assertEquals(2, engine.loads.size)
            assertEquals(200.0, engine.loads.last().startSeconds)
            assertNull(session.info.value.failure)
            assertTrue(backend.reports.none { it.state == "stopped" && it.positionMs == 600_000L })
        }
    }

    @Test
    fun aSizedDirectPlayFileThatEndsShortWithoutATransportFaultEndsThere() = runTest {
        with(rig()) {
            play(movie(durationMs = 3_019_584))
            open(3019.584)
            engine.report { it.copy(positionSeconds = 2933.68, eof = true, fileSizeBytes = 12_572_719_464, fileFormat = "matroska,webm") }
            idle()
            assertEquals(1, engine.loads.size)
            assertTrue(session.engineState.value.eof)
        }
    }

    /** A movie stacked across two files, part 1 50 minutes and part 2 40: the server opens the part holding the start. */
    private fun SessionRig.stackParts() {
        val parts = listOf(MediaPart(id = "p1", durationMs = 3_000_000), MediaPart(id = "p2", durationMs = 2_400_000))
        backend.initialize = { options ->
            val start = options.startPosition ?: 0.seconds
            val index = if (start >= 3000.seconds) 1 else 0
            val info = MediaSourceInfo("https://srv/m1/part$index", emptyList(), emptyList(), emptyList(), partId = index, partTimeline = MediaPartTimeline.fromParts(parts, index))
            SessionBackend.streamOf(options).copy(videoUrl = info.videoUrl, mediaInfo = info)
        }
    }

    @Test
    fun aStackedItemsPartEndOpensTheNextPartAndSeeksCrossParts() = runTest {
        with(rig()) {
            stackParts()
            play(movie(durationMs = 5_400_000))
            open(3000.0)
            assertEquals(5400.0, session.engineState.value.durationSeconds, "the item's whole timeline")
            engine.report { it.copy(positionSeconds = 3000.0, eof = true) }
            idle()
            assertEquals("https://srv/m1/part1", engine.loads.last().url)
            assertEquals(0.0, engine.loads.last().startSeconds, "the next part from its start")
            open(2400.0)
            assertEquals(3000.0, session.engineState.value.positionSeconds, "item time")

            session.engine.seek(1800.0, exact = false)
            idle()
            assertEquals("https://srv/m1/part0", engine.loads.last().url)
            assertEquals(1800.0, engine.loads.last().startSeconds)
            assertTrue(backend.reports.none { it.state == "stopped" && it.positionMs == 5_400_000L }, "a part's end isn't the item's")
        }
    }

    @Test
    fun aSeekPastTheOpenPartOpensThePartHoldingItAndOneInsideSeeksNatively() = runTest {
        with(rig()) {
            stackParts()
            play(movie(durationMs = 5_400_000, viewOffsetMs = 120_000))
            assertEquals("https://srv/m1/part0", engine.loads.single().url)
            assertEquals(120.0, engine.loads.single().startSeconds)
            open(3000.0)

            session.engine.seek(4200.0, exact = false)
            idle()
            assertEquals(4200.seconds, backend.initializations.last().startPosition)
            assertEquals("https://srv/m1/part1", engine.loads.last().url)
            assertEquals(1200.0, engine.loads.last().startSeconds, "70 minutes in: 20 into the second file")
            open(2400.0)

            session.engine.seek(4500.0, exact = false)
            idle()
            assertEquals(2, engine.loads.size, "inside the open file: a seek, no open")
            assertEquals(1500.0, engine.state.positionSeconds)
            assertEquals(4500.0, session.engineState.value.positionSeconds)

            session.engine.seek(600.0, exact = false)
            idle()
            assertEquals("https://srv/m1/part0", engine.loads.last().url)
            assertEquals(600.0, engine.loads.last().startSeconds)
        }
    }

    @Test
    fun aDownloadOutranksTheSavedDefaultQualityAcrossReloads() = runTest {
        with(rig()) {
            settings.set(AppSettings.defaultQualityPreset, TranscodeQualityPreset.P720_2MBPS)
            downloads.add(FakeDownloads.Copy("srv", "m1", listOf("content://sdcard/m1.mkv")))
            play(movie())
            open(600.0)
            at(30.0)
            engine.fail("demuxer died")
            idle()
            session.retry()
            idle()
            assertEquals(listOf("content://sdcard/m1.mkv", "content://sdcard/m1.mkv"), engine.loads.map { it.url })
        }
    }

    @Test
    fun withoutAServerClientPlayGoesToTheResolverAndPlaysAnyDownloadedVersion() = runTest {
        with(rig()) {
            servers.hidden += ServerId("srv")
            downloads.add(FakeDownloads.Copy("srv", "m1", listOf("content://sdcard/m1-v2.mkv"), mediaIndex = 1, mediaSourceId = "source-b"))
            play(movie())
            idle()
            assertEquals(listOf("content://sdcard/m1-v2.mkv"), engine.loads.map { it.url })
        }
    }

    @Test
    fun aQualityPickedInThePlayerOutranksTheDownloadUntilOriginalIsPicked() = runTest {
        with(rig()) {
            downloads.add(FakeDownloads.Copy("srv", "m1", listOf("content://sdcard/m1.mkv")))
            play(movie())
            open(600.0)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            open(600.0)
            at(30.0)
            engine.fail("demuxer died")
            idle()
            session.retry()
            idle()
            open(600.0)
            session.selectQuality(TranscodeQualityPreset.ORIGINAL)
            idle()
            assertEquals(
                listOf("content://sdcard/m1.mkv", "https://srv/m1/transcode/P720_2MBPS", "https://srv/m1/transcode/P720_2MBPS", "content://sdcard/m1.mkv"),
                engine.loads.map { it.url },
            )
        }
    }

    @Test
    fun aRoomStartOpensPausedForTheRoomToStart() = runTest {
        with(rig()) {
            play(movie()) { it.copy(roomStart = true) }
            assertEquals(true, engine.pauses.last())
            open(600.0)
            idle()
            assertTrue(engine.state.paused)
        }
    }

    @Test
    fun aRoomOpensItsFileInPlacePausedOnTheRoomsVersionAtItsSavedPosition() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN))
            open(600.0)
            at(30.0)
            val room = movie("m2", backend = BackendKind.JELLYFIN, viewOffsetMs = 90_000)
            val opening = backgroundScope.async { session.openForRoom(room, 1, "v4k") { true } }
            idle()
            assertEquals(ReloadOutcome.OPENED, opening.await())
            assertEquals("https://srv/m2/v4k", engine.loads.last().url)
            assertEquals(90.0, engine.loads.last().startSeconds)
            assertEquals(true, engine.pauses.last(), "the room starts it")
            assertEquals("srv:m2", session.playingKey.value)
            val opened = assertNotNull(session.opened.value)
            assertEquals("m2", opened.item.id)
            assertEquals(1, opened.mediaIndex)
            assertEquals(90_000, opened.startMs, "where it opens, before the engine reports it")
            open(600.0)
            idle()
            assertTrue(engine.state.paused)
        }
    }

    @Test
    fun aRoomOpenWaitsForAReloadUnderWayAndIsDroppedOnceTheRoomMovedOn() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN))
            open(600.0)
            at(30.0)
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.selectVersion(1)
            runCurrent()
            var wanted = true
            val opening = backgroundScope.async { session.openForRoom(movie("m2", backend = BackendKind.JELLYFIN), 0, null) { wanted } }
            runCurrent()
            assertFalse(opening.isCompleted, "it waits for the version switch")

            wanted = false
            gate.complete(Unit)
            idle()
            assertEquals(ReloadOutcome.SUPERSEDED, opening.await())
            assertEquals(listOf("https://srv/m1/v1080", "https://srv/m1/v4k"), engine.loads.map { it.url })
        }
    }

    @Test
    fun whileARoomStartsTheFilesAReloadOfAPlayingFileStaysPaused() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN))
            open(600.0)
            at(30.0)
            session.roomOwnsStart = { true }
            session.selectVersion(1)
            idle()
            assertEquals("https://srv/m1/v4k", engine.loads.last().url)
            assertEquals(true, engine.pauses.last(), "the room starts it again")
        }
    }

    @Test
    fun eachFileCommittedToTheEngineIsPublishedUntilTheSessionCloses() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            assertNull(session.opened.value)
            play(movie(backend = BackendKind.JELLYFIN))
            val first = assertNotNull(session.opened.value)
            assertEquals("m1", first.item.id)
            assertEquals(0, first.mediaIndex)
            assertEquals("v1080", first.mediaSourceId)
            assertFalse(first.offline)
            open(600.0)
            at(10.0)

            session.selectVersion(1)
            idle()
            val second = assertNotNull(session.opened.value)
            assertEquals(1, second.mediaIndex)
            assertEquals("v4k", second.mediaSourceId)
            open(600.0)
            at(20.0)

            engine.fail("demuxer died")
            idle()
            session.retry()
            idle()
            val third = assertNotNull(session.opened.value)
            assertEquals(second.copy(serial = third.serial, loadId = third.loadId, startMs = third.startMs), third, "the same file again")
            assertEquals(20_000, third.startMs, "where the retry opens it")
            assertTrue(third.loadId != second.loadId, "a new load")
            assertTrue(third.serial > second.serial, "a reload is a new value")

            session.close()
            idle()
            assertNull(session.opened.value)
        }
    }

    @Test
    fun aStrictVersionTheServerDoesntPlayFailsInsteadOfFallingBack() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.initialize = { SessionBackend.streamOf(it).copy(selectedMediaIndex = 0, selectedMediaSourceId = "v1080") }
            play(movie(backend = BackendKind.JELLYFIN)) { it.copy(mediaIndex = 1, mediaSourceId = "v4k", strictMediaSelection = true) }
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, failure.reason)
            assertTrue(engine.loads.isEmpty())
        }
    }

    @Test
    fun aPlayByIdFetchesTheItemFirst() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1))
            session.start(PlayRequest.Item(backend.serverId, "e1"))
            runCurrent()
            assertEquals("https://srv/e1/v1080", engine.loads.single().url)
            assertEquals("The Show", session.info.value.title)
            assertEquals("S1E1 · Episode 1", session.info.value.subtitle)
        }
    }

    @Test
    fun aResolveThatFailsShowsTheServersVerdictAndRetryStartsOver() = runTest {
        with(rig()) {
            backend.initialize = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "forbidden", statusCode = 403) }
            play(movie())
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.PLAYBACK_NOT_ALLOWED, failure.reason)
            assertFalse(session.info.value.resolving)
            assertTrue(engine.loads.isEmpty())

            backend.initialize = SessionBackend::streamOf
            session.retry()
            idle()
            assertNull(session.info.value.failure)
            assertEquals(1, engine.loads.size)
        }
    }

    @Test
    fun anHttp403TheEngineLoggedIsNotAllowedAndOutranksA404() = runTest {
        with(rig()) {
            play(movie())
            engine.report { it.copy(httpErrorStatus = 404) }
            engine.report { it.copy(httpErrorStatus = 403) }
            engine.fail("loading failed", kind = EngineErrorKind.OPEN)
            idle()
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.PLAYBACK_NOT_ALLOWED, failure.reason)
        }
    }

    @Test
    fun anHttp404IsTheMediaUnreadable() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("loading failed", httpStatus = 404, kind = EngineErrorKind.OPEN)
            idle()
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.NO_PLAYABLE_SOURCE, failure.reason)
        }
    }

    @Test
    fun anHttp500OnAnOriginalPlexOpenOffersOneTranscodeAndARefusedTranscodeNoMore() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = true), session.info.value.failure)

            session.forceTranscode()
            idle()
            val reopen = backend.initializations.last()
            assertTrue(reopen.forceTranscode, "the refused file isn't asked for again")
            assertEquals(TranscodeQualityPreset.ORIGINAL, reopen.qualityPreset, "no cap of ours")
            assertEquals("https://srv/m1/transcode/ORIGINAL", engine.loads.last().url)
            assertNull(session.info.value.failure)

            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = false), session.info.value.failure)
            session.forceTranscode()
            idle()
            assertEquals(2, engine.loads.size, "nothing more opens")
        }
    }

    @Test
    fun aCappedPresetOrAJellyfinServerGetsNoTranscodeOffer() = runTest {
        with(rig()) {
            play(movie()) { it.copy(qualityPreset = TranscodeQualityPreset.P720_3MBPS) }
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = false), session.info.value.failure)
        }
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN))
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = false), session.info.value.failure)
        }
    }

    @Test
    fun aForcedTranscodeCarriesToReloadsOfTheSameItemAtTheSamePreset() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            session.forceTranscode()
            idle()
            open(600.0)
            at(90.0)
            engine.report { it.copy(positionSeconds = 90.0, eof = true, transportFault = true) }
            idle()
            assertTrue(backend.initializations.last().forceTranscode, "the recovery reload stays transcoded")
        }
    }

    @Test
    fun anOpenThatStopsProgressingFailsAfterItsDeadline() = runTest {
        with(rig()) {
            play(movie())
            elapse(OpenOutcome.DEADLINE - 1.seconds)
            assertNull(session.info.value.failure)
            elapse(1.seconds)
            assertIs<PlaybackFailure.Engine>(session.info.value.failure)
        }
    }

    @Test
    fun anOpenTheServerAnswersWith503ForTwentySecondsIsTheServerBusy() = runTest {
        with(rig()) {
            play(movie())
            engine.report { it.copy(httpErrorStatus = 503, cacheEndSeconds = 1.0) }
            elapse(Http503Watchdog.PATIENCE - 1.seconds)
            assertNull(session.info.value.failure)
            elapse(1.seconds)
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(PlaybackFailureReason.SERVER_UNAVAILABLE, failure.reason)
        }
    }

    @Test
    fun a503ThatEndsWithAFrameIsRiddenOut() = runTest {
        with(rig()) {
            play(movie())
            engine.report { it.copy(httpErrorStatus = 503) }
            elapse(10.seconds)
            open(600.0)
            elapse(Http503Watchdog.PATIENCE)
            assertNull(session.info.value.failure)
        }
    }

    @Test
    fun aDeadAudioOutputIsFatal() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("Could not open/initialize audio device -> no sound.", kind = EngineErrorKind.AUDIO_OUTPUT)
            idle()
            val failure = assertIs<PlaybackFailure.Engine>(session.info.value.failure)
            assertEquals(EngineErrorKind.AUDIO_OUTPUT, failure.error.kind)
        }
    }

    @Test
    fun theServersMarkersAndChaptersBecomeSegmentsAndChapters() = runTest {
        with(rig()) {
            backend.extras = PlaybackExtras(
                chapters = listOf(
                    MediaChapter(id = 1, startTimeOffset = 0, endTimeOffset = 90_000, title = "Intro", thumb = "/c1.jpg"),
                    MediaChapter(id = 2, startTimeOffset = 90_000, endTimeOffset = 600_000, title = "Story", thumb = "/c2.jpg"),
                ),
                markers = listOf(MediaMarker(1, MediaMarker.INTRO, 5_000, 85_000), MediaMarker(2, MediaMarker.CREDITS, 560_000, 600_000)),
            )
            downloads.artwork["srv:/c2.jpg"] = "file:///art/c2.jpg"
            play(movie(durationMs = 600_000))
            idle()
            val segments = assertNotNull(session.info.value.segments)
            assertEquals(listOf(SkipKind.INTRO, SkipKind.CREDITS), segments.map { it.kind })
            assertTrue(segments.last().toEnd)
            val chapters = assertNotNull(session.info.value.chapters)
            assertEquals("/c1.jpg", chapters.first().imageUrl, "the server's without a saved one")
            assertEquals("file:///art/c2.jpg", chapters.last().imageUrl, "the thumbnail a download saved")
            assertEquals(90.0, chapters.last().startSeconds)
        }
    }

    @Test
    fun aServerBackOnlineWhileBufferingReconnectsTheStream() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(100.0)
            serverStatus.emit(mapOf(backend.serverId to false))
            idle()
            engine.report { it.copy(buffering = true) }
            idle()
            serverStatus.emit(mapOf(backend.serverId to true))
            idle()
            assertEquals(100.0, engine.state.positionSeconds)
            assertEquals(2, engine.state.playbackRestarts, "a seek in place")
        }
    }

    @Test
    fun closingHandsTheLastStoppedReportToTheVideoRegistry() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            backend.reports.clear()
            session.close()
            val stop = async(start = CoroutineStart.UNDISPATCHED) { videoSessions.shutdownVideo() }
            assertFalse(stop.isCompleted, "a stop waits for the stopped report")
            idle()
            assertTrue(stop.isCompleted)
            assertEquals(listOf("stopped"), backend.states)
        }
    }

    @Test
    fun aDownloadThePlayIsResolvedToPlaysLocallyWithoutAQualityChoice() = runTest {
        with(rig()) {
            backend.initialize = { options -> SessionBackend.streamOf(options).copy(isOffline = true, videoUrl = "file:///downloads/m1.mkv") }
            play(movie())
            open(600.0)
            assertEquals("file:///downloads/m1.mkv", engine.loads.single().url)
            assertTrue(session.info.value.local)
            assertNull(session.info.value.quality)
        }
    }

    @Test
    fun anEndPinnedAtTheDurationCompletesTheItemThere() = runTest {
        with(rig()) {
            play(movie(durationMs = 2_623_668))
            open(2623.668)
            at(2620.0)
            engine.report { it.copy(positionSeconds = 2623.668, paused = true, eof = true) }
            idle()
            assertEquals(1, engine.loads.size)
            assertTrue(session.engineState.value.eof)
            assertEquals(2_623_668, backend.reports.last { it.state == "stopped" }.positionMs)
        }
    }

    @Test
    fun theSameEndFromAStaleMidFilePositionReloadsThere() = runTest {
        with(rig()) {
            play(movie(durationMs = 2_623_668))
            open(2623.668)
            at(1200.0)
            engine.report { it.copy(positionSeconds = 1200.0, paused = true, eof = true) }
            idle()
            assertFalse(session.engineState.value.eof, "a dead stream, not the end")
            assertEquals(2, engine.loads.size)
            assertEquals(1200.0, engine.loads.last().startSeconds)
        }
    }

    @Test
    fun retryAfterASwitchThatFailedToOpenRestoresTheFileThatPlayed() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(60.0)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            engine.fail("Failed to open stream", kind = EngineErrorKind.OPEN)
            idle()
            assertIs<PlaybackFailure.Engine>(session.info.value.failure, "the failed switch isn't silent")

            session.retry()
            idle()
            assertEquals(
                listOf("https://srv/m1/v1080", "https://srv/m1/transcode/P720_2MBPS", "https://srv/m1/v1080"),
                engine.loads.map { it.url },
                "Retry restores the request that played before the switch",
            )
            assertEquals(60.0, engine.loads.last().startSeconds)
            assertEquals(TranscodeQualityPreset.ORIGINAL, backend.initializations.last().qualityPreset)
            assertNull(session.info.value.failure)
        }
    }

    @Test
    fun aFailedFileThatHadPlayedRetriesFromThePlayhead() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(30.0)
            engine.fail("demuxer died")
            idle()
            assertIs<PlaybackFailure.Engine>(session.info.value.failure)
            session.retry()
            idle()
            assertEquals(listOf("https://srv/m1/v1080", "https://srv/m1/v1080"), engine.loads.map { it.url })
            assertEquals(30.0, engine.loads.last().startSeconds)
        }
    }

    @Test
    fun aRetryThatFailsBeforeItsFileOpensShowsTheFailureItRetriedFrom() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(30.0)
            engine.fail("demuxer died")
            idle()
            val failure = assertIs<PlaybackFailure.Engine>(session.info.value.failure)
            backend.initialize = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "down", statusCode = 503) }
            session.retry()
            idle()
            assertEquals(failure, session.info.value.failure)
            assertFalse(session.info.value.resolving)
            assertNull(session.info.value.notice, "the failure view, not a toast")
            assertEquals(1, engine.loads.size)
        }
    }

    @Test
    fun theServerLimitTranscodeIsOfferedAgainForTheNextItem() = runTest {
        with(rig()) {
            val first = episode("e1", 1, BackendKind.PLEX)
            backend.episodes = listOf(first, episode("e2", 2, BackendKind.PLEX))
            play(first)
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            session.forceTranscode()
            idle()
            open(1200.0)
            idle()
            assertNotNull(session.info.value.nextEpisode)

            session.playNextEpisode()
            idle()
            val next = backend.initializations.last()
            assertEquals("e2", next.metadata.id)
            assertFalse(next.forceTranscode, "the next item asks for its file as it is")
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = true), session.info.value.failure)
        }
    }

    @Test
    fun aForcedTranscodeThatCantStartShowsTheLimitWithoutTheOffer() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("loading failed", httpStatus = 500, kind = EngineErrorKind.OPEN)
            idle()
            backend.initialize = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "busy", statusCode = 503) }
            session.forceTranscode()
            idle()
            assertEquals(PlaybackFailure.ServerLimit(transcodeOffered = false), session.info.value.failure)
            assertEquals(1, engine.loads.size)
        }
    }

    @Test
    fun scrubPreviewsLoadAfterTheFirstFrameAndOutliveASwitchOfTheSamePart() = runTest {
        with(rig()) {
            val previews = mutableListOf<FakeScrubPreview>()
            backend.scrubPreviews = { FakeScrubPreview().also { previews += it } }
            play(movie())
            idle()
            assertEquals(0, backend.scrubPreviewRequests, "nothing before the first frame")
            open(600.0)
            idle()
            val preview = previews.single()
            assertSame(preview, session.info.value.scrubPreview)

            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            open(600.0)
            idle()
            assertSame(preview, session.info.value.scrubPreview, "the same part's previews are kept")
            assertFalse(preview.disposed)
            assertEquals(1, backend.scrubPreviewRequests)

            session.close()
            idle()
            assertTrue(preview.disposed)
        }
    }

    @Test
    fun extrasFoundEmptyAreAskedForAgainPastTheCacheAtTheFirstFrameAndKeptAcrossASwitch() = runTest {
        with(rig()) {
            backend.refreshedExtras = PlaybackExtras(emptyList(), listOf(MediaMarker(1, MediaMarker.INTRO, 5_000, 85_000)))
            play(movie())
            idle()
            assertNull(session.info.value.segments)
            assertEquals(listOf(false), backend.extrasRequests)
            open(600.0)
            idle()
            assertEquals(listOf(false, true), backend.extrasRequests)
            assertEquals(listOf(SkipKind.INTRO), session.info.value.segments?.map { it.kind })

            session.selectVersion(1)
            idle()
            open(600.0)
            idle()
            assertEquals(listOf(SkipKind.INTRO), session.info.value.segments?.map { it.kind }, "a switch keeps the item's markers")
            assertEquals(2, backend.extrasRequests.size)
        }
    }

    @Test
    fun extrasTheServerCantSendComeFromItsCache() = runTest {
        with(rig()) {
            backend.extrasFail = true
            backend.cachedExtras = PlaybackExtras(emptyList(), listOf(MediaMarker(2, MediaMarker.CREDITS, 560_000, 600_000)))
            play(movie(durationMs = 600_000))
            idle()
            val segments = assertNotNull(session.info.value.segments)
            assertEquals(listOf(SkipKind.CREDITS), segments.map { it.kind })
            assertTrue(segments.single().toEnd)
        }
    }

    @Test
    fun rewindOnResumeFollowsTheSetting() = runTest {
        with(rig()) {
            settings.set(AppSettings.rewindOnResume, 10)
            idle()
            play(movie())
            idle()
            assertEquals(10, session.info.value.rewindOnResumeSeconds, "a setting read before the play")
            settings.set(AppSettings.rewindOnResume, 5)
            idle()
            assertEquals(5, session.info.value.rewindOnResumeSeconds)
        }
    }

    @Test
    fun chapterMarksFollowTheSetting() = runTest {
        with(rig()) {
            play(movie())
            idle()
            assertTrue(session.info.value.chapterMarks)
            settings.set(AppSettings.showChapterMarkersOnTimeline, false)
            idle()
            assertFalse(session.info.value.chapterMarks)
        }
    }

    @Test
    fun aRestartOfTheOutgoingFileDuringASwitchRevealsNothingEarly() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(50.0)
            val reported = backend.reports.size
            val heard = trackers.events.size
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            runCurrent()
            engine.report { it.copy(positionSeconds = 51.0, playbackRestarts = it.playbackRestarts + 1) }
            runCurrent()
            gate.complete(Unit)
            idle()
            assertEquals(2, engine.loads.size)
            assertTrue(backend.states.drop(reported).none { it == "playing" }, "the replacement has shown no frame")
            assertTrue(trackers.events.drop(heard).none { it.startsWith("started") })

            open(600.0)
            assertEquals("playing", backend.states.last())
            assertEquals("started m1 @50000 playing=true", trackers.events.last())
        }
    }

    @Test
    fun aSidecarSubtitleThatNeverAnswersHoldsUpNothingAndIsLeftOutAfterItsTimeout() = runTest {
        val warnings = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { level, tag, message, _ -> if (level == Log.Level.WARN && tag == "SidecarFetcher") warnings += message }
        try {
            with(rig()) {
                subtitleServer = { awaitCancellation() }
                backend.initialize = withSidecar("https://srv/library/streams/9.srt")
                engine.fileTracks = EPISODE_1_TRACKS
                play(movie())
                assertEquals("https://srv/m1/v1080", engine.loads.single().url, "the file loads without waiting")
                assertEquals("t0ken", subtitleRequests.single().headers["X-Plex-Token"], "the server's headers go with it")
                open(600.0)
                at(5.0)
                assertEquals(listOf("playing"), backend.states)
                // As the player store picks: the engine selects, the session records the viewer's pick.
                for ((kind, id) in listOf(TrackKind.AUDIO to 2L, TrackKind.SUBTITLE to 4L)) {
                    session.engine.selectTrack(kind, id)
                    session.onTrackSelected(kind, id)
                }
                runCurrent()
                fun selected(kind: TrackKind) = engine.state.tracks.single { it.kind == kind && it.selected }.id
                assertEquals(2L to 4L, selected(TrackKind.AUDIO) to selected(TrackKind.SUBTITLE))
                assertEquals(emptyList(), warnings)

                elapse(10.seconds)
                assertEquals(emptyList(), engine.addedSubtitles)
                assertEquals(1, warnings.size, "$warnings")
                assertTrue("no answer within 10 s" in warnings.single(), warnings.single())
                at(16.0)
                assertEquals(null, engine.state.error)
                assertEquals(2L to 4L, selected(TrackKind.AUDIO) to selected(TrackKind.SUBTITLE), "the viewer's picks hold")
            }
        } finally {
            Log.sink = sink
        }
    }

    @Test
    fun aFetchedSidecarSubtitleIsAddedAsItsFileOnTheDevice() = runTest {
        val subtitle = "1\n00:00:01,000 --> 00:00:02,000\nHello\n"
        with(rig()) {
            try {
                subtitleServer = { respond(subtitle) }
                backend.initialize = withSidecar("https://srv/library/streams/9.srt")
                play(movie())
                val (path, title, language) = engine.addedSubtitles.single()
                assertTrue(path.startsWith(subtitleDirectory.toString()) && path.endsWith(".srt"), path)
                assertEquals(subtitle, SystemFileSystem.source(Path(path)).buffered().use { it.readString() })
                assertEquals("English" to "en", title to language)
            } finally {
                SystemFileSystem.list(subtitleDirectory).forEach { SystemFileSystem.delete(it) }
                SystemFileSystem.delete(subtitleDirectory)
            }
        }
    }

    /** The server's stream with a sidecar subtitle at [url], loaded with the file. */
    private fun withSidecar(url: String): (PlaybackInitializationOptions) -> PlaybackInitializationResult = { options ->
        SessionBackend.streamOf(options).copy(
            subtitleSidecars = listOf(PlaybackSubtitleSidecar(null, SubtitleSidecar(url, "English", "en"), preload = true)),
        )
    }

    @Test
    fun aMeteredNetworkStartsAtTheCellularQuality() = runTest {
        with(rig()) {
            settings.set(AppSettings.cellularQualityPreset, TranscodeQualityPreset.P720_2MBPS)
            metered = true
            play(movie())
            assertEquals(TranscodeQualityPreset.P720_2MBPS, backend.initializations.single().qualityPreset)
        }
    }

    @Test
    fun anExplicitQualityOutranksTheCellularOne() = runTest {
        with(rig()) {
            settings.set(AppSettings.cellularQualityPreset, TranscodeQualityPreset.P720_2MBPS)
            metered = true
            play(movie()) { it.copy(qualityPreset = TranscodeQualityPreset.ORIGINAL) }
            assertEquals(TranscodeQualityPreset.ORIGINAL, backend.initializations.single().qualityPreset)
        }
    }

    @Test
    fun reportsCarryTheTrackSelectionsOnlyWhileTheyAreRemembered() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.initialize = { options -> SessionBackend.streamOf(options).let { r -> r.copy(mediaInfo = r.mediaInfo?.copy(mediaSourceId = "src1")) } }
            play(movie(backend = BackendKind.JELLYFIN))
            open(600.0)
            idle()
            val remembered = backend.reports.first { it.state == "playing" }
            assertEquals("src1", remembered.mediaSourceId)
            assertEquals(-1, remembered.subtitleStreamIndex, "subtitles off, reported")

            settings.set(AppSettings.rememberTrackSelections, false)
            idle()
            session.close()
            idle()
            val stopped = backend.reports.last()
            assertEquals("stopped", stopped.state)
            assertEquals("src1", stopped.mediaSourceId)
            assertNull(stopped.subtitleStreamIndex)
            assertNull(stopped.audioStreamIndex)
        }
    }

    @Test
    fun aLocalFileWaitsForTheAccountPreferencesAndPicksItsAudioByThem() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            downloads.add(FakeDownloads.Copy("srv", "e1", listOf("content://sdcard/e1.mkv")))
            engine.fileTracks = EPISODE_1_TRACKS
            val load = CompletableDeferred<Unit>()
            profileLoad = load
            play(episode("e1", 1))
            idle()
            assertEquals(emptyList(), engine.loads, "nothing opens before the account's preferences are known")

            profile = AccountPreferences(preferredAudioLanguage = "ger", selectAudioByLanguage = true)
            load.complete(Unit)
            idle()
            open(1200.0)
            idle()
            assertEquals(TrackKind.AUDIO to 2L, engine.selections.last { it.first == TrackKind.AUDIO }, "the account's German")
        }
    }

    @Test
    fun aJellyfinPickTurnsTheAccountsMemoryOn() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            engine.fileTracks = EPISODE_1_TRACKS
            play(episode("e1", 1))
            open(1200.0)
            idle()
            session.onTrackSelected(TrackKind.AUDIO, 2)
            idle()
            assertEquals(listOf(TrackType.AUDIO), memoryRequests)
            assertNull(session.info.value.notice, "the server remembers it")

            remembers = false
            session.onTrackSelected(TrackKind.SUBTITLE, 4)
            idle()
            assertEquals(listOf(TrackType.AUDIO, TrackType.SUBTITLE), memoryRequests)
            assertNotNull(session.info.value.notice, "the pick is for this playback only")
        }
    }

    @Test
    fun aPlexPickNeverAsksForAnAccountsMemory() = runTest {
        with(rig()) {
            engine.fileTracks = EPISODE_1_TRACKS
            play(movie())
            open(600.0)
            idle()
            session.onTrackSelected(TrackKind.AUDIO, 2)
            idle()
            assertEquals(emptyList(), memoryRequests)
        }
    }

    @Test
    fun aRoomsFileKeepsTheRoomsSpeedWhenItsTracksAreSelected() = runTest {
        with(rig()) {
            val item = movie()
            ScopedPlayerPrefs.write(settings, ScopedPlayerPrefs.playbackSpeed, item, 1.5, 0L)
            engine.fileTracks = EPISODE_1_TRACKS
            play(item) { it.copy(roomStart = true) }
            open(600.0)
            idle()
            assertEquals(1.0, engine.state.speed, "the room sets the speed")
        }
    }

    @Test
    fun aFileOutsideARoomTakesItsSavedSpeed() = runTest {
        with(rig()) {
            val item = movie()
            ScopedPlayerPrefs.write(settings, ScopedPlayerPrefs.playbackSpeed, item, 1.5, 0L)
            engine.fileTracks = EPISODE_1_TRACKS
            play(item)
            open(600.0)
            idle()
            assertEquals(1.5, engine.state.speed)
        }
    }

    @Test
    fun closingAnOpenThatShowedNoFrameStillEndsItsServerSessionWithoutAScrobble() = runTest {
        with(rig()) {
            play(movie(viewOffsetMs = 120_000))
            engine.report { it.copy(durationSeconds = 600.0) }
            idle()
            session.close()
            idle()
            assertEquals(listOf("stopped"), backend.states)
            assertEquals(120_000, backend.reports.single().positionMs, "the resume point, not a position it never reached")
            assertEquals(emptyList(), backend.watched)
        }
    }

    @Test
    fun switchingAwayFromAnOpenThatShowedNoFrameReportsItStoppedBeforeTheNextResolve() = runTest {
        with(rig()) {
            play(movie(viewOffsetMs = 60_000))
            engine.report { it.copy(durationSeconds = 600.0) }
            idle()
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            assertEquals(listOf("stopped"), backend.states, "stopped before the transcode resolves")
            assertEquals(1, backend.initializations.size)
            gate.complete(Unit)
            idle()
            assertEquals(2, engine.loads.size)
        }
    }

    @Test
    fun trackersHearTheItemsPositionInALaterStackedPart() = runTest {
        with(rig()) {
            stackParts()
            play(movie(durationMs = 5_400_000)) { it.copy(startPosition = 3600.seconds) }
            open(2400.0)
            assertEquals(3600.0, session.engineState.value.positionSeconds)
            at(700.0)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            assertEquals("stopped @3700000", trackers.events.last(), "a reload's stop")
            open(2400.0)
            at(800.0)
            session.close()
            idle()
            assertEquals("stopped @3800000", trackers.events.last(), "the close's stop")
        }
    }

    @Test
    fun aPausedStreamThatDiesReopensPaused() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            at(200.0)
            session.engine.setPaused(true)
            runCurrent()
            engine.report { it.copy(eof = true, transportFault = true) }
            idle()
            assertEquals(2, engine.loads.size, "recovered")
            assertEquals(true, engine.pauses.last(), "still paused")
        }
    }

    @Test
    fun aPlayingStreamThatDiesReopensPlaying() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            at(200.0)
            engine.report { it.copy(eof = true, transportFault = true) }
            idle()
            assertEquals(2, engine.loads.size)
            assertEquals(false, engine.pauses.last())
        }
    }

    @Test
    fun theEndOfAReplacedLoadNeverReachesThePlayer() = runTest {
        with(rig()) {
            play(movie(durationMs = 600_000))
            open(600.0)
            at(100.0)
            session.selectQuality(TranscodeQualityPreset.P720_2MBPS)
            idle()
            open(600.0)
            at(101.0)
            engine.report { it.copy(loadId = 1, positionSeconds = 600.0, eof = true) }
            idle()
            assertFalse(session.engineState.value.eof, "the old file's end")
            assertEquals(101.0, session.engineState.value.positionSeconds)
        }
    }

    @Test
    fun aSecondPlayWhileTheFirstResolvesOpensOnlyTheSecond() = runTest {
        with(rig()) {
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            play(movie("m1"))
            play(movie("m2"))
            gate.complete(Unit)
            idle()
            assertEquals(listOf("https://srv/m2/v1080"), engine.loads.map { it.url })
            assertEquals(listOf("m2"), backend.initializations.map { it.metadata.id }, "the first resolve died with its attempt")
            assertEquals("srv:m2", session.playingKey.value)
            assertNull(session.info.value.failure)
        }
    }

    @Test
    fun theFileOpensAndReportsWithoutWaitingForTheSeriesQueue() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1), episode("e2", 2))
            val gate = CompletableDeferred<Unit>()
            backend.episodeQueueGate = gate
            play(episode("e1", 1))
            open(1200.0)
            idle()
            assertEquals(1, engine.loads.size)
            assertEquals(listOf("playing"), backend.states)
            assertEquals(listOf("started e1 @0 playing=true"), trackers.events)
            assertNull(session.info.value.nextEpisode, "the queue is still loading")
            gate.complete(Unit)
            idle()
            assertEquals("Episode 2", session.info.value.nextEpisode?.title)
        }
    }

    @Test
    fun anEpisodeOpenedOnItsOwnKeepsTheSeriesQueueItsLookupBuilt() = runTest {
        with(rig(BackendKind.EMBY)) {
            val series = listOf(episode("e1", 1, BackendKind.EMBY), episode("e2", 2, BackendKind.EMBY), episode("e3", 3, BackendKind.EMBY))
            backend.episodes = series
            val gate = CompletableDeferred<Unit>()
            backend.episodeQueueGate = gate
            // Continue watching's copy of the episode, with its resume point: not the series list's.
            play(series[1].copy(viewOffsetMs = 40_000))
            // The series answers as the first frame comes.
            gate.complete(Unit)
            open(1200.0)
            idle()
            val info = session.info.value
            assertEquals(listOf(false, true, false), info.queue.map { it.current }, "the series around the episode")
            assertTrue(info.hasPreviousEpisode)
            assertEquals("Episode 3", info.nextEpisode?.title)
            assertTrue(playbackState.isQueueActive, "the queue stays for the next episode")
        }
    }

    /** A Plex server queueing its show "show-1" as e1, e2 and e3 from the episode asked for: the show's server queue. */
    private fun plexShowQueues(): MediaBackend {
        val ids = listOf("e1", "e2", "e3")
        return testPlexClient(
            { request ->
                if (request.url.encodedPath == "/playQueues") {
                    val selected = 900 + ids.indexOf(request.url.parameters["key"]?.substringAfterLast('/'))
                    val rows = ids.mapIndexed { i, id ->
                        """{"playQueueItemID":${900 + i},"ratingKey":"$id","type":"episode","title":"Episode ${i + 1}",""" +
                            """"grandparentRatingKey":"show-1","parentIndex":1,"index":${i + 1}}"""
                    }
                    jsonResponse(
                        """{"MediaContainer":{"playQueueID":42,"playQueueVersion":1,"playQueueSelectedItemID":$selected,""" +
                            """"playQueueTotalCount":3,"Metadata":[${rows.joinToString(",")}]}}""",
                    )
                } else {
                    jsonResponse("{}", status = 404)
                }
            },
            environment = PlexClientEnvironment(specialsOrdering = { SpecialsOrdering.AIR_DATE }),
            machineIdentifier = "machine-1",
        )
    }

    @Test
    fun aPlexEpisodeKeepsItsShowsQueueFromEveryStart() = runTest {
        // A show's or an episode's Play opens the episode as its page lists it; Continue Watching with its resume point.
        val listed = episode("e2", 2, BackendKind.PLEX).copy(serverId = TEST_SERVER_ID, grandparentId = "show-1")
        for (start in listOf(listed, listed.copy(viewOffsetMs = 40_000))) {
            with(SessionRig(this, SessionBackend(serverId = TEST_SERVER_ID, backend = BackendKind.PLEX), queueServer = plexShowQueues())) {
                play(start)
                open(1200.0)
                idle()
                val info = session.info.value
                assertEquals(listOf(false, true, false), info.queue.map { it.current }, "the show's queue around the episode")
                assertTrue(info.hasPreviousEpisode)
                assertEquals("Episode 3", info.nextEpisode?.title)
                assertEquals(42, playbackState.playQueueId, "the show's queue stays for the next episode")
            }
        }
    }

    @Test
    fun aShowsPlayOnEmbyStartsTheQueueAtItsNextEpisodeAndAnEpisodePlayedOnItsOwnHasTheSeriesAround() = runTest {
        // Maestro Show as a test Emby server holds it: its Special first in the server's order.
        for (showPlay in listOf(true, false)) {
            val server = maestroServer(MediaBrowserDialect.EMBY)
            val first = maestroEpisodes(server).getValue("s1e1")
            with(SessionRig(this, SessionBackend(serverId = server.serverId.value, backend = BackendKind.EMBY), queueServer = server)) {
                play(first) { it.copy(showPlay = showPlay) }
                open(1200.0)
                idle()
                assertEquals(!showPlay, session.info.value.hasPreviousEpisode, "showPlay=$showPlay")
                assertEquals("Maestro Episode 2", session.info.value.nextEpisode?.title)
                session.playNextEpisode()
                idle()
                open(1200.0)
                idle()
                assertTrue(session.info.value.hasPreviousEpisode, "Episode 2 after Episode 1, showPlay=$showPlay")
                assertEquals("Maestro Episode 3", session.info.value.nextEpisode?.title)
            }
        }
    }

    @Test
    fun theNextEpisodeNeverShowsTheLastOnesPlaceInTheQueue() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1), episode("e2", 2), episode("e3", 3))
            play(episode("e2", 2))
            open(1200.0)
            idle()
            assertEquals(listOf(false, true, false), session.info.value.queue.map { it.current })
            val shown = mutableListOf<SessionInfo>()
            backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { session.info.collect { shown += it } }
            session.playNextEpisode()
            idle()
            open(1200.0)
            idle()
            val third = shown.filter { it.item?.id == "e3" }
            assertTrue(third.isNotEmpty())
            for (info in third) {
                assertEquals(listOf(false, false, true), info.queue.map { it.current }, "the queue moves on as the episode opens")
                assertNull(info.nextEpisode, "the last episode has none after it")
            }
            assertTrue(third.last().hasPreviousEpisode)
        }
    }

    @Test
    fun aRetryIsAFreshAttemptThatTheFailedFilesLateErrorCannotFail() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(30.0)
            engine.fail("demuxer died")
            idle()
            assertIs<PlaybackFailure.Engine>(session.info.value.failure)
            session.retry()
            idle()
            assertNull(session.info.value.failure)
            assertEquals(2L, engine.state.loadId)
            engine.report { it.copy(loadId = 1, error = EngineError("late", kind = EngineErrorKind.OTHER)) }
            engine.report { it.copy(loadId = 2, error = null) }
            idle()
            assertNull(session.info.value.failure, "the failed file's late error")
            open(600.0)
            assertEquals("playing", backend.states.last(), "the fatal latch is off: reports run again")
        }
    }

    @Test
    fun aSourceWithoutAFileFailsAsFileInfoNotAvailableAfterTheResumePointResolved() = runTest {
        with(rig()) {
            backend.initialize = { SessionBackend.streamOf(it).copy(isOffline = true, videoUrl = null) }
            play(movie(viewOffsetMs = 60_000))
            assertEquals(60.seconds, backend.initializations.single().startPosition)
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(T.messages.fileInfoNotAvailable, failure.message)
            assertTrue(engine.loads.isEmpty())
        }
    }

    @Test
    fun aQualityTheServerCouldntTranscodeSaysItFellBackToOriginalAndOriginalSaysNothing() = runTest {
        with(rig()) {
            backend.initialize = { SessionBackend.streamOf(it).copy(fallbackReason = TranscodeFallbackReason.DECISION_FAILED) }
            play(movie()) { it.copy(qualityPreset = TranscodeQualityPreset.P720_2MBPS) }
            assertEquals(T.videoControls.transcodeUnavailableFallback, session.info.value.notice?.text)
            assertEquals(TranscodeQualityPreset.ORIGINAL, session.info.value.quality?.selected, "the quality shown is what plays")
        }
        with(rig()) {
            backend.initialize = { SessionBackend.streamOf(it).copy(fallbackReason = TranscodeFallbackReason.DIRECT_PLAY_ONLY) }
            play(movie())
            assertNull(session.info.value.notice)
        }
    }

    @Test
    fun anOnlineOpenIsRecordedInTheLocalHistoryAndADownloadIsNot() = runTest {
        with(rig()) {
            play(movie("m1"))
            idle()
            assertTrue(env.history.snapshot().keys.any { "m1" in it })
            backend.initialize = { options -> SessionBackend.streamOf(options).copy(isOffline = true, videoUrl = "file:///downloads/m2.mkv") }
            play(movie("m2"))
            idle()
            assertTrue(session.info.value.local)
            assertFalse(env.history.snapshot().keys.any { "m2" in it })
        }
    }

    @Test
    fun theDisplayIsReadyBeforeTheFileLoads() = runTest {
        with(rig()) {
            val opened = mutableListOf<Int>()
            session.beforeOpen = { opened += engine.loads.size }
            play(movie())
            assertEquals(listOf(0), opened)
            assertEquals(1, engine.loads.size)
        }
    }

    @Test
    fun aVersionSwitchIsSavedForTheItemAndReopensWithoutTheOldAudioStream() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            play(movie(backend = BackendKind.JELLYFIN)) { it.copy(audioStreamId = 3, qualityPreset = TranscodeQualityPreset.P720_2MBPS) }
            open(600.0)
            at(120.0)
            session.selectVersion(1)
            idle()
            val reopen = backend.initializations.last()
            assertEquals(1, reopen.selectedMediaIndex)
            assertNull(reopen.selectedAudioStreamId)
            assertEquals(120.seconds, reopen.startPosition)
            assertEquals("v4k", MediaVersionPreferences(settings).saved(movie(backend = BackendKind.JELLYFIN))?.versionId)
        }
    }

    @Test
    fun theChosenServerAudioGoesToTheTranscoderButNotToAnOriginalPlay() = runTest {
        with(rig()) {
            play(movie()) { it.copy(audioStreamId = 42, qualityPreset = TranscodeQualityPreset.P720_2MBPS) }
            assertEquals(42, backend.initializations.last().selectedAudioStreamId)
        }
        with(rig()) {
            play(movie()) { it.copy(audioStreamId = 42) }
            assertEquals(TranscodeQualityPreset.ORIGINAL, backend.initializations.last().qualityPreset)
            assertNull(backend.initializations.last().selectedAudioStreamId)
        }
    }

    @Test
    fun anOpenThatFailedReportsNothingUntilItsRetryShowsAFrame() = runTest {
        with(rig()) {
            play(movie())
            engine.fail("Failed to open stream", kind = EngineErrorKind.OPEN)
            idle()
            assertIs<PlaybackFailure.Engine>(session.info.value.failure)
            assertTrue(backend.states.none { it == "playing" })
            assertEquals(emptyList(), trackers.events)
            session.retry()
            idle()
            open(600.0)
            assertEquals("playing", backend.states.last())
            assertEquals(listOf("started m1 @0 playing=true"), trackers.events)
        }
    }

    @Test
    fun aSecondNextWhileTheFirstLoadsIsIgnored() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1), episode("e2", 2), episode("e3", 3))
            play(episode("e1", 1))
            open(1200.0)
            idle()
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate
            session.playNextEpisode()
            runCurrent()
            session.playNextEpisode()
            runCurrent()
            gate.complete(Unit)
            idle()
            assertEquals(listOf("e1", "e2"), backend.initializations.map { it.metadata.id })
            assertEquals("srv:e2", session.playingKey.value)
        }
    }

    @Test
    fun theViewersPicksCarryToEveryLaterEpisodeAndOffStaysOff() = runTest {
        with(rig(BackendKind.JELLYFIN)) {
            backend.episodes = listOf(episode("e1", 1), episode("e2", 2), episode("e3", 3))
            engine.fileTracks = EPISODE_1_TRACKS
            play(episode("e1", 1))
            open(1200.0)
            idle()
            session.onTrackSelected(TrackKind.AUDIO, 2)
            session.onTrackSelected(TrackKind.SUBTITLE, 5)
            idle()

            engine.fileTracks = EPISODE_2_TRACKS
            session.playNextEpisode()
            idle()
            open(1200.0)
            idle()
            assertEquals(3L, selected(TrackKind.AUDIO), "German")
            assertEquals(2L, selected(TrackKind.SUBTITLE), "French")

            session.onTrackSelected(TrackKind.SUBTITLE, null)
            idle()
            engine.fileTracks = EPISODE_1_TRACKS
            session.playNextEpisode()
            idle()
            open(1200.0)
            idle()
            assertEquals(2L, selected(TrackKind.AUDIO), "German still, the automatic pick of e2 replaced nothing")
            assertNull(selected(TrackKind.SUBTITLE), "off stays off")
        }
    }

    @Test
    fun aParkedStreamReloadsWhereItParkedOnceItsServerIsBackOnline() = runTest {
        with(rig()) {
            park(this, at = 200.0)
            serverStatus.emit(mapOf(backend.serverId to false))
            idle()
            serverStatus.emit(mapOf(backend.serverId to true))
            idle()
            assertNull(session.info.value.failure)
            assertEquals(4, engine.loads.size)
            assertEquals(200.0, engine.loads.last().startSeconds)
        }
    }

    @Test
    fun aSeekOnAParkedStreamReloadsAtItsTarget() = runTest {
        with(rig()) {
            park(this, at = 200.0)
            session.onSeek(300.0)
            idle()
            assertNull(session.info.value.failure)
            assertEquals(4, engine.loads.size)
            assertEquals(300.0, engine.loads.last().startSeconds)
        }
    }

    private fun SessionRig.selected(kind: TrackKind): Long? = session.engineState.value.tracks.firstOrNull { it.kind == kind && it.selected }?.id

    /** The stream dies at [at] until the recovery gives up: parked, its failure shown. */
    private fun TestScope.park(rig: SessionRig, at: Double) = with(rig) {
        play(movie(durationMs = 600_000))
        open(600.0)
        repeat(SpuriousEofRecovery.MAX_ATTEMPTS + 1) { attempt ->
            at(at)
            engine.report { it.copy(eof = true, transportFault = true) }
            idle()
            if (attempt < SpuriousEofRecovery.MAX_ATTEMPTS) open(600.0)
        }
        assertIs<PlaybackFailure.Engine>(session.info.value.failure)
        assertEquals(SpuriousEofRecovery.MAX_ATTEMPTS + 1, engine.loads.size)
    }

    @Test
    fun aPlaybacksSessionIdentifiersAre24LowercaseLettersOrDigitsNewForEachPlayback() {
        val ids = List(3) { PlaybackSession.SessionIds() }.flatMap { listOf(it.playback, it.transcode) }
        for (id in ids) assertTrue(Regex("[a-z0-9]{24}").matches(id), id)
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun creditsRunToTheEndOnlyWithinASecondOfIt() {
        fun toEnd(endMs: Long) = PlaybackSession.segmentsOf(listOf(MediaMarker(1, MediaMarker.CREDITS, 1_000_000, endMs)), 1200.0)!!.single().toEnd
        assertFalse(toEnd(1_195_000), "five seconds short")
        assertTrue(toEnd(1_199_000), "a second short")
    }

    @Test
    fun `the media controls artwork is a sized image on Plex and Jellyfin`() = runTest {
        val plex = testPlexClient({ jsonResponse("{}", status = 404) })
        with(rig()) {
            backend.images = plex::thumbnailUrl
            play(movie().copy(thumbPath = "/library/metadata/m1/thumb/7"))
            val artwork = Url(assertNotNull(session.info.value.artworkUrl))
            assertEquals("/photo/:/transcode", artwork.encodedPath)
            assertEquals("1280", artwork.parameters["width"])
            assertEquals("1280", artwork.parameters["height"])
            assertEquals("0", artwork.parameters["minSize"], "fits the square, uncropped")
        }
        val jellyfin = PlaybackFixture().playback
        with(rig(BackendKind.JELLYFIN)) {
            backend.images = jellyfin::thumbnailUrl
            play(movie(backend = BackendKind.JELLYFIN).copy(thumbPath = "/Items/m1/Images/Primary?tag=7"))
            val artwork = assertNotNull(session.info.value.artworkUrl)
            assertEquals(mapOf("tag" to "7", "maxWidth" to "1280", "maxHeight" to "1280"), params(artwork))
        }
    }
}
