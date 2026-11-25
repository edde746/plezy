package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.input.InputSteps
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * How the player behaves on one platform. Times are in milliseconds: `kotlin.time.Duration` reaches Swift as its raw
 * internal encoding.
 *
 * @param doubleClickIntervalMillis the platform's double-click (double-tap) interval: a second click within it is the
 *   double click (Windows `GetDoubleClickTime`, macOS
 *   `NSEvent.doubleClickInterval`, Android `ViewConfiguration.getDoubleTapTimeout`).
 * @param speeds the speed menu's presets, ascending, within [MIN_SPEED] and [MAX_SPEED]; 1.0 must be one of them. Any
 *   other speed in that range is the menu's custom speed ([com.edde746.plezy.input.PlayerMenu.CUSTOM_SPEED]).
 * @param maxDelaySeconds subtitle and audio delays (the sync offsets) stay within ± this.
 * @param osdMillis how long a transient message (volume, speed, delay, track) stays up.
 * @param sleepTimerMinuteSeconds how many seconds each of the sleep timer's minutes lasts ([SleepTimer]): 60, but a
 *   tenth of that in a development session's fast timers (`player.fastTimers`), so a UI test sees its 5 minutes run out
 *   into "Still watching?" after 30 s.
 * @param escapeLeavesFullscreen a keyboard's Escape takes the player out of the fullscreen it entered before it is Back
 *   (Windows, Linux; `PlayerStore.ownsFullscreen`); on macOS it is Back alone, the window's own full screen being the
 *   system's.
 * @param development a development build's player ([com.edde746.plezy.app.AppBootstrap.Companion.product]'s
 *   `development`): the settings end with the debug entries (Dolby Vision conversion where the engine has it, a
 *   simulated HTTP status).
 * @param remoteSelectPauses a remote's Select on the video with the controls down pauses as well as showing them: the
 *   Apple TV's system player does; an Android TV remote's first press only shows them.
 */
data class PlayerConfig(
    val profile: InputProfile,
    val doubleClickIntervalMillis: Long,
    val steps: InputSteps = InputSteps(),
    val speeds: List<Double> = DEFAULT_SPEEDS,
    val maxDelaySeconds: Double = 10.0,
    val osdMillis: Long = 1500,
    val sleepTimerMinuteSeconds: Int = 60,
    /** The device offers audio passthrough ([com.edde746.plezy.presentation.settings.DeviceFeatures.audioPassthrough]). */
    val audioPassthrough: Boolean = false,
    /** Audio passthrough is on: the device offers it and its setting is on (`DeviceSettings.audioPassthroughOn`). */
    val audioPassthroughOn: Boolean = false,
    val escapeLeavesFullscreen: Boolean = true,
    val development: Boolean = false,
    val remoteSelectPauses: Boolean = false,
) {
    init {
        require(speeds.isNotEmpty() && speeds.zipWithNext().all { (a, b) -> a < b }) { "speeds must ascend: $speeds" }
        require(1.0 in speeds) { "speeds must include 1.0: $speeds" }
        require(speeds.first() >= MIN_SPEED && speeds.last() <= MAX_SPEED) { "speeds must lie within $MIN_SPEED and $MAX_SPEED: $speeds" }
        require(sleepTimerMinuteSeconds > 0) { "sleepTimerMinuteSeconds must be positive: $sleepTimerMinuteSeconds" }
    }

    internal val doubleClickInterval: Duration get() = doubleClickIntervalMillis.milliseconds
    internal val osdDuration: Duration get() = osdMillis.milliseconds

    companion object {
        /** The speed menu's presets: the common speeds. */
        val DEFAULT_SPEEDS = listOf(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)

        /** The slowest and the fastest the player plays: the custom speed's range, which the speed shortcuts keep within. */
        const val MIN_SPEED = 0.5
        const val MAX_SPEED = 8.0

        /** The custom speed's step: its − and + and its slider's grid. */
        const val CUSTOM_SPEED_STEP = 0.05

        /**
         * The defaults for [profile]; [doubleClickIntervalMillis] is the platform's.
         */
        fun defaults(
            profile: InputProfile,
            doubleClickIntervalMillis: Long,
            escapeLeavesFullscreen: Boolean = true,
            remoteSelectPauses: Boolean = false,
        ): PlayerConfig =
            PlayerConfig(
                profile = profile,
                doubleClickIntervalMillis = doubleClickIntervalMillis,
                escapeLeavesFullscreen = escapeLeavesFullscreen,
                remoteSelectPauses = remoteSelectPauses,
            )
    }
}
