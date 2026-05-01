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
  private val log: (String) -> Unit = { Log.d(TAG, it) }
) {
  companion object {
    private const val TAG = "FrameRateManager"
    private const val SHORT_VIDEO_LENGTH_MS = 300000L // 5 minutes
    private const val DISPLAY_SETTLE_MS = 2000L
    private const val WATCHDOG_MARGIN_MS = 3000L
  }

  private var currentVideoFps: Float = 0f
  private var displayListener: DisplayManager.DisplayListener? = null
  private var pendingSettleRunnable: Runnable? = null
  private var watchdogRunnable: Runnable? = null
  private var pendingCompletion: ((switched: Boolean) -> Unit)? = null

  private fun getDisplayManager(): DisplayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

  // / Request a display frame-rate switch. Invokes [onComplete] once, either:
  // /  - immediately with `switched=false` when no switch is needed (invalid
  // /    fps, no matching mode, seamless fallback); or
  // /  - after the real DisplayListener event + [DISPLAY_SETTLE_MS] + the
  // /    caller's [extraDelayMs], with `switched=true`; or
  // /  - via a watchdog with `switched=true` if the real event never arrives,
  // /    so the caller doesn't hang.
  // /
  // / The caller is responsible for pausing playback before calling and
  // / resuming it after [onComplete] fires.
  fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    surface: Surface?,
    extraDelayMs: Long,
    onComplete: (switched: Boolean) -> Unit
  ) {
    currentVideoFps = fps
    if (fps <= 0f) {
      Log.d(TAG, "setVideoFrameRate: Invalid fps ($fps), skipping")
      onComplete(false)
      return
    }

    log("fps=$fps, duration=${videoDurationMs}ms, extraDelayMs=$extraDelayMs, API=${Build.VERSION.SDK_INT}")

    when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
        if (surface == null) {
          Log.d(TAG, "setVideoFrameRate: Surface not available")
          onComplete(false)
          return
        }
        setFrameRateS(fps, surface, videoDurationMs, extraDelayMs, onComplete)
      }
      // API R's Surface.setFrameRate() only supports seamless switching (no
      // CHANGE_FRAME_RATE_ALWAYS), so 60→24Hz won't switch. Fall through to
      // preferredDisplayModeId which directly sets the display mode.
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> setFrameRateM(fps, extraDelayMs, onComplete)
      else -> onComplete(false)
    }
  }

  fun clearVideoFrameRate() {
    Log.d(TAG, "clearVideoFrameRate")
    currentVideoFps = 0f
    // Resolve any pending setVideoFrameRate future as "not switched" so
    // the Dart caller's await doesn't hang on player dispose.
    firePendingCompletion("clear", switched = false)
    // Restore default display mode on API M (preferredDisplayModeId persists)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      activity.window?.attributes?.let { attrs ->
        attrs.preferredDisplayModeId = 0
        activity.window?.attributes = attrs
      }
    }
  }

  private fun cancelPendingCallbacks() {
    pendingSettleRunnable?.let { handler.removeCallbacks(it) }
    watchdogRunnable?.let { handler.removeCallbacks(it) }
    pendingSettleRunnable = null
    watchdogRunnable = null
  }

  private fun firePendingCompletion(reason: String, switched: Boolean) {
    cancelPendingCallbacks()
    displayListener?.let {
      getDisplayManager().unregisterDisplayListener(it)
      displayListener = null
    }
    val cb = pendingCompletion ?: return
    pendingCompletion = null
    Log.d(TAG, "FrameRateManager complete ($reason, switched=$switched)")
    cb(switched)
  }

  private fun registerDisplayListener(extraDelayMs: Long, onComplete: (switched: Boolean) -> Unit) {
    // Resolve any previous pending op before starting a new one.
    firePendingCompletion("superseded", switched = false)
    pendingCompletion = onComplete

    displayListener = object : DisplayManager.DisplayListener {
      override fun onDisplayAdded(displayId: Int) = Unit
      override fun onDisplayRemoved(displayId: Int) = Unit
      override fun onDisplayChanged(displayId: Int) {
        // Unregister immediately so a chatty display (e.g. several
        // onDisplayChanged events during HDMI renegotiation) doesn't
        // queue multiple settle callbacks.
        getDisplayManager().unregisterDisplayListener(this)
        displayListener = null

        val settle = Runnable { firePendingCompletion("display settled", switched = true) }
        pendingSettleRunnable = settle
        handler.postDelayed(settle, DISPLAY_SETTLE_MS + extraDelayMs)
      }
    }
    getDisplayManager().registerDisplayListener(displayListener, handler)

    // Watchdog: if the TV never signals a display change (silently ignoring
    // the mode request), still complete after a bounded wait so the caller
    // doesn't hang.
    val watchdog = Runnable { firePendingCompletion("watchdog", switched = true) }
    watchdogRunnable = watchdog
    handler.postDelayed(watchdog, DISPLAY_SETTLE_MS + extraDelayMs + WATCHDOG_MARGIN_MS)
  }

  private fun currentRateMatchesFps(fps: Float): Boolean {
    val current = activity.display?.mode?.refreshRate ?: return false
    if (current <= 0f) return false
    // Treat "equal within a frame" and "clean multiple" as a match —
    // same tolerance the API M matcher uses below.
    if (kotlin.math.abs(current - fps) < 0.1f) return true
    val mod = current % fps
    return mod < 0.1f || (fps - mod) < 0.1f
  }

  @RequiresApi(Build.VERSION_CODES.S)
  private fun setFrameRateS(
    fps: Float,
    surface: Surface,
    videoDurationMs: Long,
    extraDelayMs: Long,
    onComplete: (switched: Boolean) -> Unit
  ) {
    Log.d(TAG, "setFrameRateS: fps=$fps, duration=${videoDurationMs}ms")

    // If the current display rate already satisfies the video fps, issue
    // the hint for book-keeping but skip the listener — otherwise we'd
    // wait for an onDisplayChanged event that never fires and end up
    // burning the watchdog timeout for no reason.
    if (currentRateMatchesFps(fps)) {
      Log.d(TAG, "Current display rate already matches ${fps}fps, no switch needed")
      surface.setFrameRate(
        fps,
        Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
        Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
      )
      onComplete(false)
      return
    }

    if (videoDurationMs < SHORT_VIDEO_LENGTH_MS) {
      Log.d(TAG, "Short video, using seamless-only switching")
      surface.setFrameRate(
        fps,
        Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
        Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
      )
      onComplete(false)
      return
    }

    var seamless = false
    activity.display?.mode?.alternativeRefreshRates?.let { refreshRates ->
      for (rate in refreshRates) {
        if (fps.toString().startsWith(rate.toString()) ||
          rate.toString().startsWith(fps.toString()) ||
          rate % fps == 0f
        ) {
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
      registerDisplayListener(extraDelayMs, onComplete)
    } else {
      val userPreference = getDisplayManager().matchContentFrameRateUserPreference
      if (userPreference == DisplayManager.MATCH_CONTENT_FRAMERATE_ALWAYS) {
        Log.d(TAG, "User preference allows non-seamless switch")
        surface.setFrameRate(
          fps,
          Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
          Surface.CHANGE_FRAME_RATE_ALWAYS
        )
        registerDisplayListener(extraDelayMs, onComplete)
      } else {
        Log.d(TAG, "Non-seamless switch not allowed, using seamless-only")
        surface.setFrameRate(
          fps,
          Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
          Surface.CHANGE_FRAME_RATE_ONLY_IF_SEAMLESS
        )
        onComplete(false)
      }
    }
  }

  @RequiresApi(Build.VERSION_CODES.M)
  private fun setFrameRateM(fps: Float, extraDelayMs: Long, onComplete: (switched: Boolean) -> Unit) {
    Log.d(TAG, "setFrameRateM: fps=$fps")
    val wm = activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    @Suppress("DEPRECATION")
    val display = wm.defaultDisplay
    if (display == null) {
      onComplete(false)
      return
    }

    val supportedModes = display.supportedModes
    if (supportedModes == null) {
      onComplete(false)
      return
    }
    val currentMode = display.mode
    var modeToUse = currentMode

    for (mode in supportedModes) {
      if (mode.physicalHeight != currentMode.physicalHeight ||
        mode.physicalWidth != currentMode.physicalWidth
      ) {
        continue
      }

      if (BigDecimal(fps.toString()).setScale(1, RoundingMode.FLOOR) ==
        BigDecimal(mode.refreshRate.toString()).setScale(1, RoundingMode.FLOOR)
      ) {
        modeToUse = mode
        break
      } else if ((mode.refreshRate % fps).let { it < 0.1f || (fps - it) < 0.1f }) {
        modeToUse = mode
        break
      }
    }

    if (modeToUse == currentMode) {
      onComplete(false)
      return
    }

    Log.d(TAG, "Switching to mode ${modeToUse.modeId} (${modeToUse.refreshRate}Hz)")
    activity.window?.attributes?.let { attrs ->
      attrs.preferredDisplayModeId = modeToUse.modeId
      activity.window?.attributes = attrs
    }
    registerDisplayListener(extraDelayMs, onComplete)
  }
}
