package com.edde746.plezy.shared

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.util.Log
import android.view.Surface
import android.view.WindowManager
import androidx.annotation.RequiresApi
import java.math.BigDecimal
import java.math.RoundingMode

class FrameRateManager(
    private val activity: Activity,
    private val handler: Handler,
    private val onDisplayChanged: () -> Unit,
    private val log: (String) -> Unit = { Log.d(TAG, it) }
) {
    companion object {
        private const val TAG = "FrameRateManager"
        private const val SHORT_VIDEO_LENGTH_MS = 300000L // 5 minutes
    }

    private var currentVideoFps: Float = 0f
    private var displayListener: DisplayManager.DisplayListener? = null

    private fun getDisplayManager(): DisplayManager {
        return activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    }

    fun setVideoFrameRate(fps: Float, videoDurationMs: Long, surface: Surface?) {
        currentVideoFps = fps
        if (fps <= 0f) {
            Log.d(TAG, "setVideoFrameRate: Invalid fps ($fps), skipping")
            return
        }

        if (surface == null) {
            Log.d(TAG, "setVideoFrameRate: Surface not available")
            return
        }

        log("fps=$fps, duration=${videoDurationMs}ms, API=${Build.VERSION.SDK_INT}")

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> setFrameRateS(fps, surface, videoDurationMs)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R -> setFrameRateR(fps, surface)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> setFrameRateM(fps)
        }
    }

    fun clearVideoFrameRate() {
        Log.d(TAG, "clearVideoFrameRate")
        currentVideoFps = 0f
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
            displayListener = null
        }
    }

    private fun registerDisplayListener() {
        displayListener?.let {
            getDisplayManager().unregisterDisplayListener(it)
        }

        displayListener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = Unit
            override fun onDisplayRemoved(displayId: Int) = Unit
            override fun onDisplayChanged(displayId: Int) {
                handler.postDelayed({
                    onDisplayChanged()
                }, 2000L)
                getDisplayManager().unregisterDisplayListener(this)
                displayListener = null
            }
        }
        getDisplayManager().registerDisplayListener(displayListener, handler)
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun setFrameRateR(fps: Float, surface: Surface) {
        Log.d(TAG, "setFrameRateR: Setting frame rate to $fps")
        surface.setFrameRate(fps, Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE)
        registerDisplayListener()
    }

    @RequiresApi(Build.VERSION_CODES.S)
    private fun setFrameRateS(fps: Float, surface: Surface, videoDurationMs: Long) {
        Log.d(TAG, "setFrameRateS: fps=$fps, duration=${videoDurationMs}ms")

        if (videoDurationMs < SHORT_VIDEO_LENGTH_MS) {
            Log.d(TAG, "Short video, using seamless-only switching")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
            )
            return
        }

        var seamless = false
        activity.display?.mode?.alternativeRefreshRates?.let { refreshRates ->
            for (rate in refreshRates) {
                if (fps.toString().startsWith(rate.toString()) ||
                    rate.toString().startsWith(fps.toString()) ||
                    rate % fps == 0f) {
                    seamless = true
                    break
                }
            }
        }

        if (seamless) {
            log("Seamless switch available for ${fps}fps")
            surface.setFrameRate(
                fps,
                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                Surface.CHANGE_FRAME_RATE_ALWAYS
            )
            registerDisplayListener()
        } else {
            val userPreference = getDisplayManager().matchContentFrameRateUserPreference
            if (userPreference == DisplayManager.MATCH_CONTENT_FRAMERATE_ALWAYS) {
                Log.d(TAG, "User preference allows non-seamless switch")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ALWAYS
                )
                registerDisplayListener()
            } else {
                Log.d(TAG, "Non-seamless switch not allowed, using seamless-only")
                surface.setFrameRate(
                    fps,
                    Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                    Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
                )
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setFrameRateM(fps: Float) {
        Log.d(TAG, "setFrameRateM: fps=$fps")
        val wm = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        @Suppress("DEPRECATION")
        val display = wm.defaultDisplay ?: return

        display.supportedModes?.let { supportedModes ->
            val currentMode = display.mode
            var modeToUse = currentMode

            for (mode in supportedModes) {
                if (mode.physicalHeight != currentMode.physicalHeight ||
                    mode.physicalWidth != currentMode.physicalWidth) {
                    continue
                }

                if (BigDecimal(fps.toString()).setScale(1, RoundingMode.FLOOR) ==
                    BigDecimal(mode.refreshRate.toString()).setScale(1, RoundingMode.FLOOR)) {
                    modeToUse = mode
                    break
                } else if (mode.refreshRate % fps == 0f) {
                    modeToUse = mode
                    break
                }
            }

            if (modeToUse != currentMode) {
                Log.d(TAG, "Switching to mode ${modeToUse.modeId} (${modeToUse.refreshRate}Hz)")
                activity.window?.attributes?.let { attrs ->
                    attrs.preferredDisplayModeId = modeToUse.modeId
                    activity.window?.attributes = attrs
                }
                registerDisplayListener()
            }
        }
    }
}
