package com.edde746.plezy

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.provider.Settings
import android.view.Window
import android.view.WindowManager
import com.edde746.plezy.presentation.player.DeviceLevels
import kotlin.math.roundToInt

/**
 * The player's edge swipes on a phone or tablet. The brightness is the activity [window]'s own (`screenBrightness`),
 * which the system applies only while the window is in front and which [restoreBrightness] drops as the player closes,
 * leaving the system's. The volume is the system's media volume, set without the system's volume panel: the player
 * shows its own level, 0 at the stream's least step (above 0 on some devices, Android 9 on) and 1 at its most. It moves
 * in the system's steps (15 to 25 of them), so the level a swipe set reads back as set while the system's step is still
 * the one it took, and as the system's step once something else (the volume keys) moved it. Both read at once.
 */
internal class AndroidDeviceLevels(context: Context, private val window: () -> Window?) : DeviceLevels {
    private val audio = context.getSystemService(AudioManager::class.java)
    private val resolver = context.contentResolver

    /** The volume the swipes left, finer than the system's steps, and the step it set. */
    private var volume = 0.0
    private var volumeStep = -1

    override fun readBrightness(result: (Double?) -> Unit) {
        val own = window()?.attributes?.screenBrightness?.takeIf { it >= 0f }?.toDouble()
        result(own ?: systemBrightness())
    }

    override fun readVolume(result: (Double?) -> Unit) {
        val step = audio.getStreamVolume(AudioManager.STREAM_MUSIC)
        result(if (step == volumeStep) volume else levelOfStep(step, minVolume(), audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)))
    }

    override fun setBrightness(level: Double) {
        val window = window() ?: return
        val attributes = window.attributes
        attributes.screenBrightness = level.coerceIn(MIN_BRIGHTNESS, 1.0).toFloat()
        window.attributes = attributes
    }

    override fun setVolume(level: Double) {
        require(level.isFinite()) { "A volume level is a finite number, got $level" }
        volume = level.coerceIn(0.0, 1.0)
        volumeStep = stepOfLevel(volume, minVolume(), audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC))
        if (volumeStep != audio.getStreamVolume(AudioManager.STREAM_MUSIC)) audio.setStreamVolume(AudioManager.STREAM_MUSIC, volumeStep, 0)
    }

    override fun restoreBrightness() {
        val window = window() ?: return
        val attributes = window.attributes
        if (attributes.screenBrightness == WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE) return
        attributes.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
        window.attributes = attributes
    }

    /** The system's brightness setting (0 to 255), where a swipe starts before the window has one of its own. */
    private fun systemBrightness(): Double =
        Settings.System.getInt(resolver, Settings.System.SCREEN_BRIGHTNESS, MAX_SYSTEM_BRIGHTNESS / 2).toDouble() / MAX_SYSTEM_BRIGHTNESS

    /** The media stream's least step: Android reports one from Android 9 on, 0 before. */
    private fun minVolume(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) audio.getStreamMinVolume(AudioManager.STREAM_MUSIC) else 0

    internal companion object {
        const val MAX_SYSTEM_BRIGHTNESS = 255

        /** The dimmest a swipe goes: 0 would ask for the backlight's lowest, darker than the system's own slider goes. */
        const val MIN_BRIGHTNESS = 0.01

        /** The media volume's [step] as a level, 0 at the stream's [min] step and 1 at its [max]; 0 when it has no range. */
        fun levelOfStep(step: Int, min: Int, max: Int): Double = if (max <= min) 0.0 else (step - min).toDouble() / (max - min)

        /** The step nearest the 0-to-1 [level] between the stream's [min] and [max] steps. */
        fun stepOfLevel(level: Double, min: Int, max: Int): Int = (min + level * (max - min)).roundToInt().coerceIn(min, maxOf(min, max))
    }
}
