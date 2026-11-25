package com.edde746.plezy

import android.app.Application
import android.content.Context
import com.edde746.plezy.crash.StartupMark
import com.edde746.plezy.crash.StartupMarks
import org.junit.After
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import kotlin.test.assertEquals

@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class PreviousExitStoreTest {
    private val context: Context get() = RuntimeEnvironment.getApplication()
    private val preferences get() = context.getSharedPreferences("plezy_exit_diagnostics", Context.MODE_PRIVATE)

    @After
    fun tearDown() {
        StartupMarks.persist = null
    }

    /** Waits for the store's thread to have committed [key] as [value]. */
    private fun awaitString(key: String, value: String?) {
        val deadline = System.nanoTime() + 5_000_000_000
        while (preferences.getString(key, null) != value && System.nanoTime() < deadline) Thread.sleep(10)
        assertEquals(value, preferences.getString(key, null))
    }

    @Test
    fun `the previous launch is snapshotted before this ones start is marked`() {
        preferences.edit()
            .putString("last_startup_phase", "database_ready")
            .putString("ui_state", "player")
            .commit()

        PreviousExit.keepStartupMarks(context)

        awaitString("last_startup_phase", "native_on_create")
        awaitString("ui_state", "startup")
        assertEquals("database_ready", PreviousExit.previous.startupPhase)
        assertEquals("player", PreviousExit.previous.uiState)
    }

    @Test
    fun `marks are committed in order`() {
        PreviousExit.keepStartupMarks(context)
        StartupMarks.mark(StartupMark.MAIN_SCREEN)
        awaitString("last_startup_phase", "main_screen")
    }

    @Test
    fun `a kept value of another type is not trusted`() {
        preferences.edit().putString("last_startup_phase", "first_frame").putInt("ui_state", 3).commit()

        PreviousExit.keepStartupMarks(context)

        assertEquals(PreviousExit.Launch(), PreviousExit.previous)
    }
}
