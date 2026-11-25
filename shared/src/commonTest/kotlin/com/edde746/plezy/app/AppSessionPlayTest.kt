package com.edde746.plezy.app

import com.edde746.plezy.crash.Breadcrumb
import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.downloads.ObservedDriver
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/** The running app's playbacks: how they open the player, end in their release order, and come once per launch. */
class AppSessionPlayTest {
    private suspend fun TestScope.app(exitFullscreenOnClose: Boolean = false): Pair<AppSession, FakeAppPlatform> {
        val platform = FakeAppPlatform()
        val graph = testGraph()
        graph.data.deviceSettings.set(AppSettings.exitFullscreenOnPlayerClose, exitFullscreenOnClose)
        return AppSession(graph, platform) to platform
    }

    @Test
    fun aPlayOpensThePlayerOverItsOwnPlayback() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        val active = assertNotNull(app.player.value)
        assertSame(active.store, platform.playbacks.single().attached)
        assertSame(platform.playbacks.single().engine, active.engine)
        assertEquals(listOf(Route.Home, Route.Player), app.navigator.backStack.value)
        assertEquals(FIRST.url, platform.playbacks.single().scripted.loads.single().url)
        app.close()
    }

    @Test
    fun playingAgainEndsTheCurrentPlaybackFirstInReleaseOrder() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value).store.dispatch(PlayerCommand.ToggleFullscreen)
        runCurrent()

        app.play(SECOND)
        runCurrent()
        assertEquals(
            listOf(
                "1: attached",
                "fullscreen true",
                // The first playback ends before the second one's engine exists; its fullscreen stays on.
                "1: controls hidden",
                "1: platform released",
                "1: engine released",
                "2: attached",
            ),
            platform.log.filter { !it.startsWith("1: display") },
        )
        assertSame(platform.playbacks[1].engine, assertNotNull(app.player.value).engine)
        // Still one player on the stack.
        assertEquals(listOf(Route.Home, Route.Player), app.navigator.backStack.value)
        app.close()
    }

    @Test
    fun aPlayOfWhatAlreadyPlaysOnlyShowsThePlayer() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        app.play(FIRST)
        runCurrent()
        val active = assertNotNull(app.player.value)
        app.play(FIRST)
        runCurrent()
        assertEquals(1, platform.playbacks.size, "a second launch of the same video while it opens or plays")
        assertSame(active, app.player.value)

        app.play(SECOND)
        runCurrent()
        assertEquals(2, platform.playbacks.size)
        app.close()
    }

    @Test
    fun theMusicSessionIsGoneBeforeTheVideosEngineIsBuilt() = runTest {
        val graph = testGraph()
        val platform = FakeAppPlatform()
        val app = AppSession(graph, platform)
        val musicGone = CompletableDeferred<Unit>()
        var playbacksAtStop: Int? = null
        graph.playbackCoordinator.registerMusicSession {
            playbacksAtStop = platform.playbacks.size
            musicGone.await()
        }
        app.play(FIRST)
        runCurrent()
        assertEquals(0, playbacksAtStop, "the music stops before the video's playback exists")
        assertTrue(platform.playbacks.isEmpty(), "the video waits until the music's core is gone")

        musicGone.complete(Unit)
        runCurrent()
        assertEquals(1, platform.playbacks.size)
        app.close()
    }

    @Test
    fun theDisplayStaysAwakeAsThePlayerSaysAndIsLetGoWhenThePlaybackEnds() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        val first = platform.playbacks.single()
        val store = assertNotNull(app.player.value).store
        assertEquals(store.state.value.keepAwake, first.awake.last(), "as the player says")
        store.onVisibleChanged(false)
        runCurrent()
        assertFalse(first.awake.last(), "out of sight")

        // Replaced: whatever its player said last, the display may sleep, and nothing more comes from it.
        val before = first.awake.toList()
        app.play(SECOND)
        runCurrent()
        assertEquals(before + false, first.awake)

        val second = platform.playbacks[1]
        val playing = second.awake.toList()
        app.close()
        runCurrent()
        assertEquals(playing + false, second.awake)
    }

    @Test
    fun leavingThePlayerEndsThePlaybackAndKeepsTheApp() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value).store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertEquals(listOf(Route.Home), app.navigator.backStack.value)
        assertNull(app.player.value)
        assertTrue(platform.playbacks.single().scripted.released)
        assertEquals(0, platform.exits)
        app.close()
    }

    @Test
    fun aSecondCloseWhileThePlayerLeavesDoesNothing() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        val store = assertNotNull(app.player.value).store
        store.dispatch(PlayerCommand.Close)
        store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertEquals(listOf(Route.Home), app.navigator.backStack.value)
        assertEquals(1, platform.log.count { it == "1: engine released" })
        assertEquals(0, platform.exits)
        app.close()
    }

    @Test
    fun aPlaybacksOpeningFirstFrameAndDisposalAreLeftInTheCrashReportsTrail() = runTest {
        val trail = mutableListOf<Breadcrumb>()
        // The trail earlier tests left waiting for a reporter goes to one that drops it.
        CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink {}
        CrashCapture.breadcrumbs = CrashCapture.BreadcrumbSink { trail += it }
        try {
            val (app, platform) = app()
            app.play(FIRST)
            runCurrent()
            platform.playbacks.single().scripted.report { it.copy(loaded = true, video = VideoInfo(1920, 1080, "h264", 24.0, DynamicRange.SDR)) }
            runCurrent()
            assertNotNull(app.player.value).store.dispatch(PlayerCommand.Close)
            runCurrent()
            val lifecycle = trail.filter { it.category == "player.lifecycle" }
            assertEquals(listOf("Player opened", "First frame", "Player disposed"), lifecycle.map { it.message })
            assertEquals(true, lifecycle.first().data["url"])
            assertEquals(false, lifecycle.last().data["replaced"])
            app.close()
        } finally {
            CrashCapture.breadcrumbs = null
        }
    }

    @Test
    fun settingsNeverOpensOverThePlayer() = runTest {
        val (app, _) = app()
        app.play(FIRST)
        runCurrent()
        assertFalse(app.openSettings())
        assertEquals(listOf(Route.Home, Route.Player), app.navigator.backStack.value)
        assertNotNull(app.player.value).store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertTrue(app.openSettings())
        runCurrent()
        assertEquals(com.edde746.plezy.presentation.navigation.TopLevelDestination.SETTINGS, app.shell.state.value.selected)
        app.close()
    }

    @Test
    fun aPlayerIsDisposedOfOnceItsWatchTogetherRoomLetGoOfItOrAfterTwoSeconds() = runTest {
        val (app, platform) = app()
        val releasing = mutableListOf<Boolean>()
        var held = Job()
        app.playbacks.roomRelease = { _, replaced ->
            releasing += replaced
            held
        }
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value).store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertEquals(listOf(false), releasing)
        assertNull(app.player.value)
        assertFalse(platform.playbacks.single().scripted.released, "the room still commands the player")
        held.complete()
        runCurrent()
        assertTrue(platform.playbacks.single().scripted.released)

        held = Job()
        app.play(SECOND)
        runCurrent()
        app.play(FIRST)
        runCurrent()
        assertEquals(listOf(false, true), releasing)
        assertEquals(2, platform.playbacks.size, "the next player waits for the one before to go")
        advanceTimeBy(1_999)
        assertFalse(platform.playbacks[1].scripted.released)
        advanceTimeBy(2)
        runCurrent()
        assertTrue(platform.playbacks[1].scripted.released, "a room that never lets go holds the player 2 s at most")
        assertEquals(3, platform.playbacks.size)
        assertEquals(FIRST.url, platform.playbacks[2].scripted.loads.single().url)
        app.playbacks.roomRelease = null
        app.close()
    }

    @Test
    fun fullscreenThePlayerEnteredCarriesToTheNextEpisodeAndOutlivesThePlayerByDefault() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value).store.dispatch(PlayerCommand.ToggleFullscreen)
        app.play(SECOND)
        runCurrent()
        val next = assertNotNull(app.player.value).store
        assertTrue(next.state.value.fullscreen)
        assertTrue(next.ownsFullscreen, "the replaced player's fullscreen is the next one's")
        assertEquals(listOf("fullscreen true"), platform.log.filter { it.startsWith("fullscreen") })

        next.dispatch(PlayerCommand.Close)
        runCurrent()
        assertEquals(listOf("fullscreen true"), platform.log.filter { it.startsWith("fullscreen") })
        assertTrue(platform.isFullscreen, "Exit fullscreen on player close is off")
        app.close()
    }

    @Test
    fun withExitFullscreenOnPlayerCloseClosingThePlayerLeavesFullscreen() = runTest {
        val (app, platform) = app(exitFullscreenOnClose = true)
        platform.windowFullscreen = true
        app.play(FIRST)
        runCurrent()
        val store = assertNotNull(app.player.value).store
        assertFalse(store.ownsFullscreen)

        store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertFalse(platform.isFullscreen)
        assertEquals(listOf("fullscreen false"), platform.log.filter { it.startsWith("fullscreen") })
        app.close()
    }

    @Test
    fun withExitFullscreenOnPlayerCloseTheNextEpisodeKeepsFullscreen() = runTest {
        val (app, platform) = app(exitFullscreenOnClose = true)
        platform.windowFullscreen = true
        app.play(FIRST)
        runCurrent()
        app.play(SECOND)
        runCurrent()
        assertTrue(platform.isFullscreen, "a playback replaced at once keeps the window fullscreen")
        app.close()
    }

    @Test
    fun fullscreenFromBeforeThePlayerOutlivesIt() = runTest {
        val (app, platform) = app()
        // Start in fullscreen, or F11 at a screen.
        platform.windowFullscreen = true
        app.play(FIRST)
        runCurrent()
        val store = assertNotNull(app.player.value).store
        assertTrue(store.state.value.fullscreen, "the player shows the window's fullscreen")
        assertFalse(store.ownsFullscreen)

        store.dispatch(PlayerCommand.Close)
        runCurrent()
        assertTrue(platform.isFullscreen)
        assertTrue(platform.log.none { it.startsWith("fullscreen") })
        app.close()
    }

    @Test
    fun aUrlsVideoHasNoPlayingKey() = runTest {
        val (app, _) = app()
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value)
        assertNull(app.playingKey.value)
        app.close()
    }

    @Test
    fun aSettingWrittenWhilePlayingRereadsTheSettingsOnlyAFewTimes() = runTest {
        var reads = 0
        val factory = inMemoryDatabase()
        val data = LocalData(
            { schema -> ObservedDriver(factory.createDriver(schema)) { sql, _ -> if ("device_setting" in sql) reads++ } },
            { 1_790_000_000_000L }, StandardTestDispatcher(testScheduler), {}, null,
        )
        val app = AppSession(testGraph(data), FakeAppPlatform())
        app.play(FIRST)
        runCurrent()
        assertNotNull(app.player.value)
        reads = 0
        data.deviceSettings.set(AppSettings.volume, 30.0)
        runCurrent()
        assertTrue(reads <= MAX_SETTINGS_READS, "a write read the device settings $reads times")
        app.close()
    }

    @Test
    fun aServerItemPlaysInItsOwnPlaybackUnderItsKey() = runTest {
        val (app, platform) = app()
        app.play(ITEM)
        runCurrent()
        assertNotNull(app.player.value)
        assertEquals("server-1:42", app.playingKey.value)
        assertEquals(listOf(Route.Home, Route.Player), app.navigator.backStack.value)

        app.play(ITEM)
        runCurrent()
        assertEquals(1, platform.playbacks.size, "the same item again only shows the player")
        app.close()
        assertNull(app.playingKey.value)
        assertTrue(platform.playbacks.single().scripted.released)
    }

    @Test
    fun closingEndsThePlaybackOnceAndForAll() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        runCurrent()

        app.close()
        assertNull(app.player.value)
        assertTrue(platform.playbacks.single().scripted.released)

        app.close()
        app.play(SECOND)
        runCurrent()
        assertEquals(1, platform.playbacks.size, "a closed app starts no playback")
        assertEquals(1, platform.log.count { it.endsWith("engine released") })
    }

    @Test
    fun aPlayStillOpeningWhenTheAppClosesNeverStarts() = runTest {
        val (app, platform) = app()
        app.play(FIRST)
        app.close()
        runCurrent()
        assertTrue(platform.playbacks.isEmpty())
        assertNull(app.player.value)
    }

    @Test
    fun aPlayWaitingOnTheMusicsTeardownOpensNothingOnceTheProfileSwitched() = runTest {
        val data = testData()
        data.profiles.upsert(LocalProfile(id = "profile-a", displayName = "A", createdAt = 0))
        data.profiles.upsert(LocalProfile(id = "profile-b", displayName = "B", createdAt = 0))
        ProfileIdentity(data).setActiveProfileId("profile-a")
        val graph = testGraph(data)
        val platform = FakeAppPlatform()
        val app = AppSession(graph, platform)
        app.profiles.hydrated.first { it }
        val teardown = CompletableDeferred<Unit>()
        graph.playbackCoordinator.registerMusicSession { teardown.await() }

        app.play(FIRST)
        runCurrent()
        app.profiles.switchProfile(app.profiles.profiles.value.single { it.id == "profile-b" }) { _, _ -> null }
        runCurrent()
        teardown.complete(Unit)
        runCurrent()

        assertEquals("profile-b", app.profiles.active.value?.id)
        assertTrue(platform.playbacks.isEmpty(), "the last profile's play never starts")
        assertNull(app.player.value)
        assertFalse(Route.Player in app.navigator.backStack.value)
        app.close()
    }

    @Test
    fun aVideoOpenWithNoProfilePlaysOnAsTheFirstProfileBecomesActive() = runTest {
        val data = testData()
        val graph = testGraph(data)
        val platform = FakeAppPlatform()
        val app = AppSession(graph, platform)
        app.profiles.hydrated.first { it }
        app.play(FIRST)
        runCurrent()
        val active = assertNotNull(app.player.value)

        // A sign-in makes the session's first profile active while the video plays.
        data.profiles.upsert(LocalProfile(id = "profile-a", displayName = "A", createdAt = 0))
        runCurrent()
        app.profiles.switchProfile(app.profiles.profiles.value.single()) { _, _ -> null }
        runCurrent()

        assertEquals("profile-a", app.profiles.active.value?.id)
        assertEquals(1, app.profileSession.value, "the screens start anew")
        assertSame(active, app.player.value, "the video plays on")
        assertFalse(platform.playbacks.single().scripted.released)
        assertEquals(listOf(Route.Home, Route.Player), app.navigator.backStack.value)
        app.close()
    }

    @Test
    fun aScreenOpenedOnceTheScreensAreTheNewProfilesStays() = runTest {
        val data = testData()
        val graph = testGraph(data)
        val app = AppSession(graph, FakeAppPlatform())
        app.profiles.hydrated.first { it }
        data.profiles.upsert(LocalProfile(id = "profile-a", displayName = "A", createdAt = 0))
        runCurrent()

        // The switch returns before the screens restart for it (the dev launch's Watch Together room went with that
        // restart): opened after the wait, the screen is the new profile's and stays.
        app.profiles.switchProfile(app.profiles.profiles.value.single()) { _, _ -> null }
        app.awaitScreensFor("profile-a")
        assertEquals(1, app.profileSession.value, "the screens started anew first")
        app.navigator.navigate(Route.WatchTogether)
        runCurrent()

        assertEquals(listOf(Route.Home, Route.WatchTogether), app.navigator.backStack.value)
        app.close()
    }

    @Test
    fun aStopBeforeThePlayerOpensCancelsThePlay() = runTest {
        val graph = testGraph()
        val platform = FakeAppPlatform()
        val app = AppSession(graph, platform)
        val teardown = CompletableDeferred<Unit>()
        graph.playbackCoordinator.registerMusicSession { teardown.await() }

        app.play(FIRST)
        runCurrent()
        app.playbacks.stop()
        teardown.complete(Unit)
        runCurrent()
        assertTrue(platform.playbacks.isEmpty())
        assertNull(app.player.value)
        assertFalse(Route.Player in app.navigator.backStack.value)

        // The same video plays when asked again.
        app.play(FIRST)
        runCurrent()
        assertEquals(1, platform.playbacks.size)
        app.close()
    }

    private companion object {
        val FIRST = PlayRequest.Url("http://h/first.mkv")
        val SECOND = PlayRequest.Url("http://h/second.mkv")
        val ITEM = PlayRequest.Item(ServerId("server-1"), "42")

        /** The queries one device setting's write may rerun while a video plays: one per group of settings observed. */
        const val MAX_SETTINGS_READS = 24
    }
}
