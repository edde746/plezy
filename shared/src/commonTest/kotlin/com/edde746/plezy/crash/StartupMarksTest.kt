package com.edde746.plezy.crash

import com.edde746.plezy.log.Log
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

// Another test's app start may mark the shared steps meanwhile: these look only at the marks they make.
class StartupMarksTest {
    private val originalSink = Log.sink

    @AfterTest
    fun tearDown() {
        Log.sink = originalSink
        StartupMarks.persist = null
    }

    @Test
    fun `startup phase vocabulary is fixed and elapsed logging is monotonic`() {
        assertEquals(
            listOf(
                "native_on_create", "app_start", "first_frame", "database_open_started", "database_ready",
                "credentials_loaded", "binding_started", "main_screen",
            ),
            StartupMark.entries.map { it.id },
        )
        assertEquals(listOf("startup", "authentication", "main_screen", "player"), RuntimeUiState.entries.map { it.id })

        val marked = listOf(StartupMark.NATIVE_ON_CREATE, StartupMark.APP_START, StartupMark.FIRST_FRAME)
        val messages = mutableListOf<String>()
        Log.sink = Log.Sink { _, _, message, _ ->
            if (message.startsWith("Startup phase:") && marked.any { "phase=${it.id} " in message }) messages += message
        }
        marked.forEach(StartupMarks::mark)

        assertEquals(marked.map { "phase=${it.id}" }, messages.map { it.substringAfter("Startup phase: ").substringBefore(' ') })
        val elapsed = messages.map { Regex("""elapsedMs=(\d+)""").find(it)!!.groupValues[1].toLong() }
        assertTrue(elapsed[1] >= elapsed[0])
        assertTrue(elapsed[2] >= elapsed[1])
    }

    @Test
    fun `each mark keeps the mark and the ui state it implies for the next start`() {
        assertEquals(
            listOf("startup", "startup", "startup", "startup", "startup", "authentication", "authentication", "main_screen"),
            StartupMark.entries.map { it.uiState.id },
        )
        val kept = mutableListOf<String>()
        StartupMarks.persist = object : StartupMarks.Persist {
            override fun mark(mark: StartupMark) {
                if (mark == StartupMark.FIRST_FRAME) kept += mark.id
            }

            override fun uiState(state: RuntimeUiState) {
                if (kept.size == 1) kept += state.id
            }
        }
        StartupMarks.mark(StartupMark.FIRST_FRAME)

        assertEquals(listOf("first_frame", "startup"), kept)
    }
}
