package com.edde746.plezy

import android.app.Activity
import android.content.Context
import android.content.res.Resources
import android.os.Build
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette

/**
 * The launch screen's colour, kept in the native preferences `plezy_prefs` (`splash_theme`) as the theme changes and
 * restored on the window before the activity's first frame, so a cold start shows the user's theme from the launch
 * screen on (no flash between the window's default and the app). The launch screen knows the built-in colours only:
 * a preset or custom theme launches on the nearest by brightness, System on the window's default (the device's light
 * or dark, black on a TV: `splash_background`). On Android 13+ the system splash of the next start takes it too
 * (`SplashTheme.*` styles).
 */
internal object SplashTheme {
    private const val PREFERENCES = "plezy_prefs"
    private const val KEY = "splash_theme"

    /** The launch-screen mode of [theme]: `system` for System (no palette), `oled`, else `light` or `dark`. */
    fun mode(theme: AppTheme): String {
        val palette = theme.palette ?: return "system"
        return when {
            palette == Palette.OLED -> "oled"
            palette.isDark -> "dark"
            else -> "light"
        }
    }

    /** The window colour of [mode] (ARGB), or null for System or an unknown mode: the window's default stays. */
    fun color(mode: String?): Int? = when (mode) {
        "oled" -> 0xFF000000.toInt()
        "dark" -> 0xFF0E0F12.toInt()
        "light" -> 0xFFF7F7F8.toInt()
        else -> null
    }

    /** Paints [activity]'s window in the kept launch colour; before `super.onCreate`, so its first frame has it. */
    fun restore(activity: Activity) {
        val mode = activity.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(KEY, null)
        color(mode)?.let { activity.window.decorView.setBackgroundColor(it) }
    }

    /**
     * Keeps [theme]'s launch mode for the next start when it changed, and paints [activity] (the one on screen, if any)
     * in it now: its window, and the system splash it registers for the next start.
     */
    fun save(context: Context, theme: AppTheme, activity: Activity?) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val mode = mode(theme)
        if (preferences.getString(KEY, null) == mode) return
        preferences.edit().putString(KEY, mode).apply()
        if (activity == null) return
        color(mode)?.let { activity.window.decorView.setBackgroundColor(it) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) activity.splashScreen.setSplashScreenTheme(splashStyle(mode))
    }

    /** The system splash's style for [mode]; none (the app's theme) for System. */
    private fun splashStyle(mode: String): Int = when (mode) {
        "dark" -> R.style.SplashTheme_Dark
        "oled" -> R.style.SplashTheme_Oled
        "light" -> R.style.SplashTheme_Light
        else -> Resources.ID_NULL
    }
}
