package com.edde746.plezy

import android.app.Activity
import android.content.Context
import android.graphics.drawable.ColorDrawable
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.settings.ThemeMode
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

@RunWith(RobolectricTestRunner::class)
class SplashThemeTest {
    private fun mode(stored: ThemeMode, tv: Boolean = false) =
        SplashTheme.mode(AppTheme.resolve(stored, custom = null, unlocked = true, tv = tv))

    @Test
    fun `each theme launches on its own built in colour or the nearest by brightness`() {
        assertEquals("system", mode(ThemeMode.SYSTEM))
        assertEquals("oled", mode(ThemeMode.OLED))
        assertEquals("dark", mode(ThemeMode.DARK))
        assertEquals("light", mode(ThemeMode.LIGHT))
        // The Supporter presets have no launch colour of their own.
        assertEquals("dark", mode(ThemeMode.EMBER))
        assertEquals("dark", mode(ThemeMode.GLACIER))
        assertEquals("dark", mode(ThemeMode.FOREST))
        assertEquals("dark", mode(ThemeMode.PLUM))
        assertEquals("light", mode(ThemeMode.PAPER))
    }

    @Test
    fun `a locked preset launches on the device default theme`() {
        assertEquals("system", SplashTheme.mode(AppTheme.resolve(ThemeMode.EMBER, custom = null, unlocked = false, tv = false)))
        assertEquals("oled", SplashTheme.mode(AppTheme.resolve(ThemeMode.EMBER, custom = null, unlocked = false, tv = true)))
    }

    @Test
    fun `the window takes the launch colour of each mode and keeps its own for system`() {
        assertEquals(0xFF000000.toInt(), SplashTheme.color("oled"))
        assertEquals(0xFF0E0F12.toInt(), SplashTheme.color("dark"))
        assertEquals(0xFFF7F7F8.toInt(), SplashTheme.color("light"))
        assertNull(SplashTheme.color("system"))
        assertNull(SplashTheme.color(null))
        assertNull(SplashTheme.color("ember"))
    }

    // Android 12L: the system splash's theme (13+) is the platform's to keep, not this test's.
    @Config(sdk = [32])
    @Test
    fun `the kept launch mode paints the next window and a theme change replaces it`() {
        val activity = Robolectric.buildActivity(Activity::class.java).get()
        val preferences = activity.getSharedPreferences("plezy_prefs", Context.MODE_PRIVATE)
        // As an earlier release left it.
        preferences.edit().putString("splash_theme", "light").commit()
        SplashTheme.restore(activity)
        assertEquals(0xFFF7F7F8.toInt(), (activity.window.decorView.background as ColorDrawable).color)

        SplashTheme.save(activity, AppTheme.resolve(ThemeMode.OLED, custom = null, unlocked = true, tv = false), activity)
        assertEquals("oled", preferences.getString("splash_theme", null))
        // The window on screen takes it at once.
        assertEquals(0xFF000000.toInt(), (activity.window.decorView.background as ColorDrawable).color)
        val next = Robolectric.buildActivity(Activity::class.java).get()
        SplashTheme.restore(next)
        assertEquals(0xFF000000.toInt(), (next.window.decorView.background as ColorDrawable).color)
    }
}
