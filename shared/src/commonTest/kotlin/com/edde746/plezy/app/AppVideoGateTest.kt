package com.edde746.plezy.app

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.FakeCarSource
import com.edde746.plezy.playback.session.PlayRequest
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * Video in a car (Android Automotive) follows the vehicle's driving restrictions, and on a TV in the background nothing
 * starts it: the app's playbacks as the controller gates them.
 */
class AppVideoGateTest {
    private class App(val session: AppSession, val platform: FakeAppPlatform, val graph: AppGraph) {
        val engine get() = platform.playbacks.last().scripted
        val store get() = assertNotNull(session.player.value).store
    }

    private fun TestScope.app(car: FakeCarSource? = null, formFactor: FormFactor = FormFactor.DESKTOP, foreground: Boolean = true): App {
        val graph = testGraph()
        graph.setForeground(foreground)
        val platform = FakeAppPlatform(formFactor = formFactor, car = car)
        return App(AppSession(graph, platform), platform, graph)
    }

    /** The file opens and its first frame shows. */
    private fun TestScope.opens(app: App) {
        app.engine.open(600.0)
        runCurrent()
    }

    @Test
    fun `a play in a car waits for the vehicles answer before the video opens`() = runTest {
        val car = FakeCarSource(FakeCarSource.PARKED).apply { answerGate = CompletableDeferred() }
        val app = app(car)
        app.session.play(VIDEO)
        runCurrent()
        assertTrue(app.platform.playbacks.isEmpty(), "nothing opens before the vehicle answers")

        car.releaseAnswers()
        runCurrent()
        assertEquals(1, app.platform.playbacks.size)
        assertEquals(listOf(false), app.engine.pauses, "parked: it plays")
        app.session.close()
    }

    @Test
    fun `a car that never answers opens after its wait by the foreground rule`() = runTest {
        val car = FakeCarSource().apply { neverAnswer = true }
        val app = app(car, foreground = false)
        app.session.play(VIDEO)
        advanceTimeBy(1900.milliseconds)
        runCurrent()
        assertTrue(app.platform.playbacks.isEmpty())
        advanceTimeBy(200.milliseconds)
        runCurrent()
        assertEquals(listOf(true), app.engine.pauses, "no verdict and not in front: it opens paused")
        app.session.close()
    }

    @Test
    fun `off a car nothing waits`() = runTest {
        val app = app(foreground = false)
        app.session.play(VIDEO)
        runCurrent()
        assertEquals(listOf(false), app.engine.pauses)
        app.session.close()
    }

    @Test
    fun `while driving a video opens paused nothing starts it and a start from outside pauses again`() = runTest {
        val app = app(FakeCarSource(FakeCarSource.DRIVING))
        app.session.play(VIDEO)
        runCurrent()
        assertEquals(listOf(true), app.engine.pauses)
        opens(app)

        app.store.dispatch(PlayerCommand.Play)
        runCurrent()
        assertTrue(app.engine.pauses.none { !it }, "${app.engine.pauses}")

        // Audio focus back: the engine starts by itself.
        app.engine.report { it.copy(paused = false) }
        runCurrent()
        assertEquals(true, app.engine.pauses.last())
        assertTrue(app.engine.state.paused)
        app.session.close()
    }

    @Test
    fun `a restriction while the video plays pauses it and parking plays nothing`() = runTest {
        val car = FakeCarSource(FakeCarSource.PARKED)
        val app = app(car)
        app.session.play(VIDEO)
        runCurrent()
        opens(app)
        assertEquals(listOf(false), app.engine.pauses)

        car.push(FakeCarSource.DRIVING)
        runCurrent()
        assertEquals(listOf(false, true), app.engine.pauses)
        car.push(FakeCarSource.PARKED)
        runCurrent()
        assertEquals(listOf(false, true), app.engine.pauses, "parking doesn't start it")

        app.store.dispatch(PlayerCommand.Play)
        runCurrent()
        assertEquals(false, app.engine.pauses.last(), "the viewer may again")
        app.session.close()
    }

    @Test
    fun `a car whose service goes falls back to the foreground rule`() = runTest {
        val car = FakeCarSource(FakeCarSource.PARKED)
        val app = app(car)
        app.session.play(VIDEO)
        runCurrent()
        opens(app)
        car.push(FakeCarSource.GONE)
        runCurrent()
        assertEquals(listOf(false), app.engine.pauses, "in front: still allowed")
        app.session.close()
    }

    @Test
    fun `on a TV in the background whatever starts the video pauses it again`() = runTest {
        val app = app(formFactor = FormFactor.TV)
        app.session.play(VIDEO)
        runCurrent()
        opens(app)
        app.graph.setForeground(false)
        runCurrent()
        assertEquals(listOf(false, true), app.engine.pauses, "the background paused it")

        app.engine.report { it.copy(paused = false) }
        runCurrent()
        assertEquals(true, app.engine.pauses.last())

        app.graph.setForeground(true)
        runCurrent()
        assertEquals(false, app.engine.pauses.last(), "back: it plays again")
        app.engine.report { it.copy(paused = false) }
        runCurrent()
        assertEquals(false, app.engine.pauses.last(), "and nothing holds it")
        app.session.close()
    }

    private companion object {
        val VIDEO = PlayRequest.Url("http://h/video.mkv")
    }
}
