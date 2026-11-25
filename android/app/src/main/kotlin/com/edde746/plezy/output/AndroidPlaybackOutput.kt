package com.edde746.plezy.output

import android.content.Context
import android.hardware.display.DisplayManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Display
import android.view.Window
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.DisplayMode
import com.edde746.plezy.playback.output.ModeSwitch
import com.edde746.plezy.playback.output.OutputPlan
import com.edde746.plezy.playback.output.PauseSuppression
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.playback.output.awaitHdrOutput
import kotlinx.coroutines.flow.MutableStateFlow

/**
 * One playback's output on Android (display mode, HDR, passthrough), following the shared [OutputPlan]:
 * - Mode: the window asks for the plan's mode (`preferredDisplayModeId`). A mode the display already shows is pinned,
 *   so the system's own refresh policy (idle timer, thermal) can't leave it mid-playback. A switch holds playback
 *   ([MpvPlayerEngine.holdForDisplay]) from the request until the display landed on the mode and settled
 *   ([ModeSwitch.await]: 2 s and the display switch delay, given up 3 s after that when the display never lands), then
 *   restarts the decoder against the new mode ([MpvPlayerEngine.refreshDecoder]) and lets go. The frame-rate vote on
 *   the video Surface, which follows the content seamlessly where the display can, is the engine's own.
 * - Pauses: for a [PauseSuppression] window from a switch's start, while the hold lasts and for another window from
 *   its release, [switching] says so to the media session: a TV box (Fire TV) sends a pause, and HDMI audio becomes
 *   noisy, as HDMI renegotiates, a noisy route seen as late as playback goes on again (a SHIELD's comes with the
 *   release). Neither is the viewer's.
 * - HDR: without HDR output ([OutputPlan.hdrOutput]: the Hdr setting off, or no HDR display) the video Surface's HDR
 *   headroom is capped at SDR (API 35+); mpv tone-maps a format the display doesn't take
 *   ([MpvPlayerEngine.setHdrOutput]).
 * - Passthrough: with the setting on, mpv's `audio-spdif` lists the formats the current route takes undecoded, again
 *   whenever the route changes (a receiver or headphones come and go).
 * - Before the open: the mode is switched before the engine opens a file the server described
 *   ([switchesBeforeOpen]), and for any other file while mpv holds its decoder ([holdDecoder]), since a decoder made
 *   before the switch can stay bound to the old mode.
 *
 * [restore] (the playback ended) lets go of a hold and hands the window's mode back to the system: at once, or
 * [HDR_EXIT_MS] later when the playback showed HDR, so the display leaves HDR (with the video Surface) before it
 * renegotiates the mode, two quick steps where together they can take a sink chain many seconds. A mode switch of a
 * later playback cancels that pending restore. Main thread.
 */
internal class AndroidPlaybackOutput(
    context: Context,
    private val engine: MpvPlayerEngine,
    private val window: () -> Window?,
    private val switching: (Boolean) -> Unit,
) : PlaybackOutputHost {
    private val context = context.applicationContext
    private val audio = this.context.getSystemService(AudioManager::class.java)
    private val displays = this.context.getSystemService(DisplayManager::class.java)
    private val handler = Handler(Looper.getMainLooper())
    private var passthrough = false
    private var routeWatched = false

    /** The default display's mode as last seen, while [modes] listens. */
    private val shown = MutableStateFlow<DisplayMode?>(null)
    private var listening = false

    /** Playback is held for a display switch. */
    private var held = false
    private val suppression = PauseSuppression()
    private val suppressionOver = Runnable { switching(held) }

    /** The last plan showed HDR video as HDR: the restore waits for the display to leave HDR. */
    private var hdrShown = false

    private val route = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) = applyPassthrough()

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) = applyPassthrough()
    }

    /** The default display's mode changes; nothing else any display reports counts. */
    private val modes = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit

        override fun onDisplayRemoved(displayId: Int) = Unit

        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            val mode = DeviceOutput.display(context)?.current ?: return
            if (mode == shown.value) return
            shown.value = mode
            Log.i(TAG, "Display mode now ${mode.id} (${mode.width}x${mode.height} at ${mode.refreshRate} Hz)")
        }
    }

    /** HDMI renegotiated once the audio output is open breaks passthrough on a SHIELD's and a receiver's chain. */
    override val switchesBeforeOpen = true

    override fun holdDecoder() = engine.holdDecoder()

    override suspend fun display(): DisplayInfo {
        val display = DeviceOutput.display(context) ?: DisplayInfo(emptyList(), null, hdrSupported = false, hdrEnabled = false)
        shown.value = display.current
        if (!listening) {
            displays?.registerDisplayListener(modes, handler)
            listening = true
        }
        Log.i(TAG, "Display: $display")
        return display
    }

    override suspend fun apply(plan: OutputPlan): Boolean {
        Log.i(TAG, "Output plan: $plan")
        val hdrTaken = engine.awaitHdrOutput(plan.hdrOutput)
        engine.setDolbyVisionConversion(plan.dolbyVisionConversion)
        follow(plan)
        return hdrTaken
    }

    /** The plan's passthrough and mode ([apply]). */
    private suspend fun follow(plan: OutputPlan) {
        hdrShown = plan.hdr
        passthrough = plan.audioPassthrough
        if (passthrough && !routeWatched) {
            // Registering reports the current devices at once, which applies the passthrough.
            audio.registerAudioDeviceCallback(route, handler)
            routeWatched = true
        } else {
            applyPassthrough()
        }
        val target = plan.mode
        if (target == null) {
            requestMode(0)
            return
        }
        cancelPendingRestore()
        val start = shown.value
        if (target.id == start?.id) {
            Log.i(TAG, "The display already shows mode ${target.id}: pinned")
            requestMode(target.id)
            return
        }
        if (window() == null) {
            Log.w(TAG, "No window to switch the display's mode with")
            return
        }
        suppress(plan.switchDelaySeconds)
        hold()
        try {
            requestMode(target.id)
            Log.i(TAG, "Switching the display to mode ${target.id} (${target.width}x${target.height} at ${target.refreshRate} Hz) for ${plan.frameRate} fps")
            val switched = ModeSwitch.await(shown, target, start?.id ?: NO_MODE, plan.frameRate ?: 0.0, plan.switchDelaySeconds * 1_000L)
            Log.i(TAG, "Display switch ${if (switched) "done" else "not taken by the display"}: mode ${shown.value?.id}")
            if (switched) engine.refreshDecoder()
        } finally {
            suppress(plan.switchDelaySeconds)
            release()
        }
    }

    /** Opens a [PauseSuppression] window for a switch with [delaySeconds] of display switch delay. */
    private fun suppress(delaySeconds: Int) {
        suppression.begin(delaySeconds)
        handler.removeCallbacks(suppressionOver)
        handler.postDelayed(suppressionOver, PauseSuppression.length(delaySeconds).inWholeMilliseconds)
    }

    override fun restore() {
        // The display's mode is followed a while longer, so the log shows it landing back on its own mode.
        if (listening) {
            handler.postDelayed({ displays?.unregisterDisplayListener(modes) }, RESTORE_WATCH_MS)
            listening = false
        }
        handler.removeCallbacks(suppressionOver)
        suppression.clear()
        release()
        restoreMode(window(), afterHdr = hdrShown)
        if (routeWatched) {
            audio.unregisterAudioDeviceCallback(route)
            routeWatched = false
        }
    }

    private fun hold() {
        if (held) return
        held = true
        switching(true)
        engine.holdForDisplay(true)
        Log.i(TAG, "Playback held for a display switch")
    }

    private fun release() {
        if (held) {
            held = false
            engine.holdForDisplay(false)
            Log.i(TAG, "Playback released after the display switch")
        }
        switching(suppression.active)
    }

    /** The window's preferred display mode; 0 leaves it to the system. */
    private fun requestMode(id: Int) {
        val window = window() ?: return
        val attributes = window.attributes
        if (attributes.preferredDisplayModeId == id) return
        attributes.preferredDisplayModeId = id
        window.attributes = attributes
        Log.i(TAG, "Preferred display mode: ${if (id == 0) "the system's" else id}")
    }

    private fun applyPassthrough() {
        engine.setAudioPassthrough(if (passthrough) DeviceOutput.passthroughCodecs(context) else emptyList())
    }

    private companion object {
        const val TAG = "PlaybackOutput"

        /** No display mode: what a switch started from when the display's mode wasn't known. */
        const val NO_MODE = -1

        /** How long after the restore the display's mode is still followed for the log. */
        const val RESTORE_WATCH_MS = 10_000L

        /**
         * How long the restore after a playback that showed HDR waits for the display to leave HDR first: the video
         * Surface's teardown commits the HDR exit within about 50 ms of the release.
         */
        const val HDR_EXIT_MS = 400L

        /** The restore waiting for the HDR exit; a later playback's switch cancels it. Main thread. */
        private val restoreHandler = Handler(Looper.getMainLooper())
        private var pendingRestore: Runnable? = null

        fun cancelPendingRestore() {
            pendingRestore?.let(restoreHandler::removeCallbacks)
            pendingRestore = null
        }

        /** Hands [window]'s mode back to the system, [HDR_EXIT_MS] later [afterHdr]; nothing when no mode was asked for. */
        fun restoreMode(window: Window?, afterHdr: Boolean) {
            cancelPendingRestore()
            if (window == null || window.attributes.preferredDisplayModeId == 0) return
            val restore = Runnable {
                pendingRestore = null
                val attributes = window.attributes
                attributes.preferredDisplayModeId = 0
                window.attributes = attributes
                Log.i(TAG, "Preferred display mode: the system's")
            }
            if (afterHdr) {
                pendingRestore = restore
                restoreHandler.postDelayed(restore, HDR_EXIT_MS)
            } else {
                restore.run()
            }
        }
    }
}
