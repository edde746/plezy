package com.edde746.plezy.app

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.settings.AppSettings
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * With "ask for a profile on open", a return to the app shows the picker over an open player, which stays paused until
 * a profile is chosen; a backgrounding spent in picture in picture asks for none.
 */
class AppProfileHoldTest {
    private class App(val session: AppSession, val platform: FakeAppPlatform, val graph: AppGraph) {
        val engine get() = platform.playbacks.last().scripted
        val store get() = assertNotNull(session.player.value).store
        val pickerShown get() = session.navigator.backStack.value.any { it == Route.ProfilePicker(required = true) }
    }

    private suspend fun TestScope.app(): App {
        val data = testData()
        data.profiles.upsert(LocalProfile(id = "a", displayName = "Ann", createdAt = 0))
        data.profiles.upsert(LocalProfile(id = "b", displayName = "Ben", createdAt = 0))
        ProfileIdentity(data).setActiveProfileId("a")
        data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)
        val graph = testGraph(data)
        graph.setForeground(true)
        val platform = FakeAppPlatform(formFactor = FormFactor.HANDHELD)
        val app = App(AppSession(graph, platform), platform, graph)
        app.session.play(VIDEO)
        runCurrent()
        app.engine.open(600.0)
        runCurrent()
        assertEquals(listOf(false), app.engine.pauses, "the video plays")
        return app
    }

    private fun TestScope.away(app: App) {
        app.graph.setForeground(false)
        runCurrent()
        app.graph.setForeground(true)
        runCurrent()
    }

    @Test
    fun `the profile picker over a playing video holds it paused until a profile is chosen`() = runTest {
        val app = app()
        away(app)
        assertTrue(app.pickerShown, "the picker shows over the player")
        assertTrue(app.engine.state.paused, "the return didn't start the video: ${app.engine.pauses}")

        app.store.dispatch(PlayerCommand.Play)
        app.store.dispatch(PlayerCommand.TogglePause)
        app.store.dispatch(PlayerCommand.SystemResume)
        runCurrent()
        assertTrue(app.engine.state.paused, "no press starts it under the picker")

        // Audio focus back: the engine starts by itself.
        app.engine.report { it.copy(paused = false) }
        runCurrent()
        assertTrue(app.engine.state.paused, "a start from outside pauses again")

        app.session.onboarding.profileChosen(Route.ProfilePicker(required = true))
        runCurrent()
        assertFalse(app.pickerShown)
        assertTrue(app.engine.state.paused, "the same profile chosen, it stays paused")

        app.store.dispatch(PlayerCommand.Play)
        runCurrent()
        assertEquals(false, app.engine.pauses.last(), "the viewer plays it again")
        app.session.close()
    }

    @Test
    fun `a video playing on in picture in picture asks for no profile on return`() = runTest {
        val app = app()
        app.store.onPictureInPictureChanged(true)
        away(app)
        assertFalse(app.pickerShown)
        assertEquals(listOf(false), app.engine.pauses, "it played on")

        app.store.onPictureInPictureChanged(false)
        away(app)
        assertTrue(app.pickerShown, "a backgrounding out of picture in picture asks again")
        app.session.close()
    }

    private companion object {
        val VIDEO = PlayRequest.Url("http://h/video.mkv")
    }
}
