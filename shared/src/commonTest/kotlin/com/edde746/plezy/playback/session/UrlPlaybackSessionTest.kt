package com.edde746.plezy.playback.session

import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.SubtitleStyle
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class UrlPlaybackSessionTest {
    private val options = PlaybackOptions(hwdec = "auto", demuxerMaxBytes = 1, demuxerMaxBackBytes = 1)

    private fun TestScope.session(engine: ScriptedEngine, url: String = "https://media.example/films/Big%20Buck%20Bunny.mkv?api_key=s3cr3t") =
        UrlPlaybackSession(engine, url, { options }, flowOf(SubtitleStyle.DEFAULT), backgroundScope).also { runCurrent() }

    @Test
    fun aUrlPlaysFromItsStartTitledByItsFileName() = runTest {
        val engine = ScriptedEngine()
        val session = session(engine)
        assertEquals("Big Buck Bunny.mkv", session.info.value.title)
        val load = engine.loads.single()
        assertEquals(0.0, load.startSeconds)
        assertEquals(options, load.options)
        assertEquals(false, engine.pauses.last())
        assertEquals(listOf(SubtitleStyle.DEFAULT), engine.subtitleStyles)
    }

    @Test
    fun aFailedFileShowsTheEngineErrorAndRetryLoadsItAgainWhereItStopped() = runTest {
        val engine = ScriptedEngine()
        val session = session(engine)
        engine.open(600.0)
        engine.play(42.0)
        runCurrent()
        engine.fail("Failed to open https://media.example/films/a.mkv?api_key=s3cr3t", kind = EngineErrorKind.OPEN)
        runCurrent()
        val failure = assertIs<PlaybackFailure.Engine>(session.info.value.failure)
        assertTrue("s3cr3t" !in failure.error.message, failure.error.message)
        session.retry()
        runCurrent()
        assertNull(session.info.value.failure)
        assertEquals(listOf(0.0, 42.0), engine.loads.map { it.startSeconds })
    }

    @Test
    fun closingReleasesTheEngine() = runTest {
        val engine = ScriptedEngine()
        session(engine).close()
        assertTrue(engine.released)
    }

    @Test
    fun aUrlWithoutAFileIsTitledByItsHostAndAMalformedEscapeStaysAsItIs() {
        assertEquals("media.example", UrlPlaybackSession.fileName("https://media.example/"))
        assertEquals("100%.mkv", UrlPlaybackSession.fileName("file:///videos/100%.mkv"))
    }
}
