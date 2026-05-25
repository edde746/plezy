package com.edde746.plezy.shared

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.util.Log
import android.view.Display
import android.view.WindowManager
import androidx.annotation.RequiresApi
import kotlin.math.abs
import kotlin.math.roundToInt

class FrameRateManager(
  private val activity: Activity,
  private val handler: Handler,
  private val log: (String) -> Unit = { Log.d(TAG, it) }
) {
  companion object {
    private const val TAG = "FrameRateManager"
    private const val DISPLAY_SETTLE_MS = 2000L
    private const val WATCHDOG_MARGIN_MS = 3000L
    private const val RATE_TOLERANCE = 0.1f
  }

  private data class RefreshRateMatch(
    val reason: String,
    val priority: Int,
    val error: Float
  )

  @RequiresApi(Build.VERSION_CODES.M)
  private data class DisplayModeCandidate(
    val mode: Display.Mode,
    val match: RefreshRateMatch
  )

  private var currentVideoFps: Float = 0f
  private var displayListener: DisplayManager.DisplayListener? = null
  private var pendingSettleRunnable: Runnable? = null
  private var watchdogRunnable: Runnable? = null
  private var pendingCompletion: ((switched: Boolean) -> Unit)? = null

  private fun getDisplayManager(): DisplayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

  // Request a display frame-rate switch. Invokes [onComplete] once, either:
  // - immediately with `switched=false` when no switch is needed (invalid fps,
  //   no matching mode, or already matching); or
  // - after the real DisplayListener event + [DISPLAY_SETTLE_MS] + the caller's
  //   [extraDelayMs], with `switched=true`; or
  // - via a watchdog if the real event never arrives, so the caller doesn't hang.
  //
  // The caller is responsible for pausing playback before calling and resuming
  // it after [onComplete] fires.
  fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    extraDelayMs: Long,
    onComplete: (switched: Boolean) -> Unit
  ) {
    currentVideoFps = fps
    if (fps <= 0f) {
      Log.d(TAG, "setVideoFrameRate: Invalid fps ($fps), skipping")
      onComplete(false)
      return
    }

    log(
      "request fps=$fps, duration=${videoDurationMs}ms, extraDelayMs=$extraDelayMs, " +
        "API=${Build.VERSION.SDK_INT}, currentMode=${currentModeDescription()}"
    )

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      setDisplayMode(fps, extraDelayMs, onComplete)
    } else {
      onComplete(false)
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

  // Release pending callbacks/listener without restoring the display mode.
  // Used by player-core dispose paths so a backend handoff (e.g. ExoPlayer→MPV
  // audio fallback) doesn't clobber the just-applied refresh-rate switch —
  // window-scoped preferredDisplayModeId persists across the SurfaceView swap,
  // letting MPV inherit the rate without a second HDMI renegotiation.
  fun releasePending() {
    Log.d(TAG, "releasePending")
    currentVideoFps = 0f
    firePendingCompletion("release", switched = false)
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
    log("complete reason=$reason, switched=$switched, currentMode=${currentModeDescription()}")
    cb(switched)
  }

  private fun registerDisplayListener(fps: Float, extraDelayMs: Long, onComplete: (switched: Boolean) -> Unit) {
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

        val settle = Runnable { firePendingCompletion("display settled", switched = currentRateMatch(fps) != null) }
        pendingSettleRunnable = settle
        handler.postDelayed(settle, DISPLAY_SETTLE_MS + extraDelayMs)
      }
    }
    getDisplayManager().registerDisplayListener(displayListener, handler)

    // Watchdog: if the TV never signals a display change (silently ignoring
    // the mode request), still complete after a bounded wait so the caller
    // doesn't hang.
    val watchdog = Runnable { firePendingCompletion("watchdog", switched = currentRateMatch(fps) != null) }
    watchdogRunnable = watchdog
    handler.postDelayed(watchdog, DISPLAY_SETTLE_MS + extraDelayMs + WATCHDOG_MARGIN_MS)
  }

  private fun matchRefreshRate(refreshRate: Float, fps: Float): RefreshRateMatch? {
    if (refreshRate <= 0f || fps <= 0f) return null

    val exactError = abs(refreshRate - fps)
    if (exactError < RATE_TOLERANCE) {
      return RefreshRateMatch(reason = "exact", priority = 0, error = exactError)
    }

    val multiple = (refreshRate / fps).roundToInt()
    if (multiple > 1) {
      val multipleError = abs(refreshRate - (fps * multiple))
      if (multipleError < RATE_TOLERANCE) {
        return RefreshRateMatch(reason = "${multiple}x", priority = 1, error = multipleError)
      }
    }

    return null
  }

  private fun currentRateMatch(fps: Float): RefreshRateMatch? {
    val current = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      currentDisplayMode()?.refreshRate
    } else {
      null
    } ?: return null
    return matchRefreshRate(current, fps)
  }

  private fun currentModeDescription(): String = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    describeMode(currentDisplayMode())
  } else {
    "unavailable"
  }

  @RequiresApi(Build.VERSION_CODES.M)
  private fun currentDisplay(): Display? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
    activity.display
  } else {
    @Suppress("DEPRECATION")
    (activity.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
  }

  @RequiresApi(Build.VERSION_CODES.M)
  private fun currentDisplayMode(): Display.Mode? = currentDisplay()?.mode

  @RequiresApi(Build.VERSION_CODES.M)
  private fun describeMode(mode: Display.Mode?): String {
    if (mode == null) return "unknown"
    return "#${mode.modeId} ${mode.physicalWidth}x${mode.physicalHeight}@${mode.refreshRate}Hz"
  }

  @RequiresApi(Build.VERSION_CODES.M)
  private fun describeSupportedModes(modes: Array<Display.Mode>): String = modes.joinToString(prefix = "[", postfix = "]") { describeMode(it) }

  @RequiresApi(Build.VERSION_CODES.M)
  private fun findBestModeMatch(fps: Float, currentMode: Display.Mode, supportedModes: Array<Display.Mode>): DisplayModeCandidate? = supportedModes.asSequence()
    .filter { mode ->
      mode.physicalHeight == currentMode.physicalHeight &&
        mode.physicalWidth == currentMode.physicalWidth
    }
    .mapNotNull { mode -> matchRefreshRate(mode.refreshRate, fps)?.let { DisplayModeCandidate(mode, it) } }
    .minWithOrNull(
      compareBy<DisplayModeCandidate> { it.match.priority }
        .thenBy { it.match.error }
        .thenBy { abs(it.mode.refreshRate - currentMode.refreshRate) }
    )

  @RequiresApi(Build.VERSION_CODES.M)
  private fun setDisplayMode(fps: Float, extraDelayMs: Long, onComplete: (switched: Boolean) -> Unit) {
    log("setDisplayMode fps=$fps")
    val display = currentDisplay()
    if (display == null) {
      log("display unavailable")
      onComplete(false)
      return
    }

    val supportedModes = display.supportedModes
    if (supportedModes == null) {
      log("supported display modes unavailable")
      onComplete(false)
      return
    }
    val currentMode = display.mode
    log("supported modes=${describeSupportedModes(supportedModes)}")

    val modeMatch = findBestModeMatch(fps, currentMode, supportedModes)
    if (modeMatch == null) {
      log("no matching display mode for ${fps}fps at ${currentMode.physicalWidth}x${currentMode.physicalHeight}")
      onComplete(false)
      return
    }

    val modeToUse = modeMatch.mode
    if (modeToUse.modeId == currentMode.modeId) {
      log("current mode already matches ${fps}fps (${modeMatch.match.reason}), no switch needed")
      onComplete(false)
      return
    }

    log(
      "switching to ${describeMode(modeToUse)} for ${fps}fps " +
        "(${modeMatch.match.reason}, error=${modeMatch.match.error})"
    )
    val window = activity.window
    if (window == null) {
      log("window unavailable")
      onComplete(false)
      return
    }
    registerDisplayListener(fps, extraDelayMs, onComplete)
    window.attributes = window.attributes.apply { preferredDisplayModeId = modeToUse.modeId }
  }
}
