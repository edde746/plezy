package com.edde746.plezy.playback.session

import com.edde746.plezy.playback.TrackKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The subtitle shortcut through the server's subtitles: [off, English burned in, French sidecar]. */
class SourceSubtitleCycleTest {
    @Test
    fun pressesTogetherAddUpToOneSwitch() = runTest {
        with(subtitleRig(transcoding = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)

            session.cycleSourceSubtitles()
            session.cycleSourceSubtitles()
            idle()
            assertEquals(12, shownSourceSubtitle(), "two steps from off skip the English one")
            assertEquals(TrackKind.SUBTITLE to 2L, engine.selections.last())
            assertEquals(1, backend.initializations.size, "the burn-in passed over is never asked for")
        }
    }

    @Test
    fun pressesDuringAReloadApplyAsOneSwitchAfterIt() = runTest {
        with(subtitleRig(transcoding = true)) {
            play(movie())
            open(600.0)
            listSidecar(this)
            val gate = CompletableDeferred<Unit>()
            backend.initializationGate = gate

            session.cycleSourceSubtitles()
            runCurrent()
            session.cycleSourceSubtitles()
            session.cycleSourceSubtitles()
            runCurrent()
            assertEquals(1, backend.initializations.size, "the English burn-in is still being asked for")

            backend.initializationGate = null
            gate.complete(Unit)
            runCurrent()
            assertEquals(3, backend.initializations.size, "the two waiting presses made one more switch")
            open(600.0)
            idle()
            assertNull(shownSourceSubtitle(), "English, then two steps on: off")
            assertEquals(3, backend.initializations.size)
        }
    }
}
