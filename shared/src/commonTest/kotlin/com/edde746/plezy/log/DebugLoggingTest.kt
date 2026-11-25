@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.log

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

class DebugLoggingTest {
    @AfterTest
    fun restore() {
        Log.minLevel = Log.Level.INFO
    }

    @Test
    fun `the debug logging setting sets the level at startup and whenever it changes`() = runTest {
        val enabled = MutableStateFlow(true)
        val written = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { _, _, message, _ -> written += message }
        try {
            backgroundScope.launch { Log.followDebugLogging(enabled) }
            runCurrent()
            assertEquals(Log.Level.DEBUG, Log.minLevel, "on at startup: debug")
            Log.d("t") { "shown" }

            enabled.value = false
            runCurrent()
            assertEquals(Log.Level.INFO, Log.minLevel, "turned off: info")
            Log.d("t") { "hidden" }
            Log.i("t") { "info" }

            enabled.value = true
            runCurrent()
            assertEquals(Log.Level.DEBUG, Log.minLevel, "turned on again: debug")
        } finally {
            Log.sink = sink
        }
        assertEquals(listOf("shown", "info"), written)
    }
}
