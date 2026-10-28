package com.edde746.plezy.shared

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.view.Display
import android.view.Window
import android.view.WindowManager
import androidx.annotation.RequiresApi

/**
 * Owns the window's `preferredDisplayModeId` for one Activity. The video
 * [com.edde746.plezy.mpv.MpvPlayerPlugin] holds it, not a player core: the
 * mode is window state that a player→player replacement inherits, so the
 * request, the deferred HDR-exit restore and the restore observation outlive
 * any one core and stay cancellable by its successor.
 */
class FrameRateManager(
  private val activity: Activity,
  private val handler: Handler,
  private val log: (String) -> Unit = { message -> PlayerDebugLog.d(TAG) { message } }
) {
  companion object {
    private const val TAG = "FrameRateManager"
    private const val DISPLAY_SETTLE_MS = 2000L
    private const val WATCHDOG_MARGIN_MS = 3000L

    // How long to let the HDR-exit commit land before restoring the refresh
    // rate. Restoring while the display is still signaling HDR folds the
    // HDR-exit and the mode change into one HDMI renegotiation, which some
    // sink chains take 8-30 s to complete (#2172); sequenced, the HDR
    // infoframe clear is free and the SDR mode switch takes ~1 s. Hiding or
    // tearing down the player's surface commits the HDR exit within ~50 ms,
    // so 400 ms covers it with margin even on a busy main thread.
    private const val HDR_EXIT_SETTLE_MS = 400L

    // How long the display must hold a mode other than the content mode,
    // with no further mode change, before a restore counts as landed. A sink
    // can step through an intermediate mode; the settle waits out the steps.
    private const val RESTORE_SETTLE_MS = 250L

    // Bounds a restore whose mode change is never reported.
    private const val RESTORE_WATCHDOG_MS = 3000L

    private const val NO_MODE = -1
  }

  private var currentVideoFps: Float = 0f
  private var currentVideoWidth: Int = 0
  private var currentVideoHeight: Int = 0
  private var currentMatchResolution: Boolean = false
  private var displayListener: DisplayManager.DisplayListener? = null
  private var pendingSettleRunnable: Runnable? = null
  private var watchdogRunnable: Runnable? = null
  private var pendingCompletion: ((switched: Boolean) -> Unit)? = null

  private var pendingRestoreRunnable: Runnable? = null

  // The display's mode when this window's first request was applied: where a
  // restore lands. A pinned mode that already was that mode changes nothing.
  // Kept until a restore lands, so a session that starts while the previous
  // restore is still in flight does not mistake the content mode for it.
  private var modeBeforeRequest: Int = NO_MODE

  // A restore requested while a switch was still waiting for the display:
  // the display may land on that switch's target before it comes back.
  private var restoreInterruptsSwitch = false

  // Restore observation: the display leaving [restoringFromModeId] after the
  // window's preference went back to the default.
  private var restoringFromModeId: Int = NO_MODE
  private var restoreObservedModeId: Int = NO_MODE
  private var restoreListener: DisplayManager.DisplayListener? = null
  private var restoreSettleRunnable: Runnable? = null
  private var restoreWatchdogRunnable: Runnable? = null
  private val restoreWaiters = mutableListOf<() -> Unit>()

  private fun getDisplayManager(): DisplayManager = activity.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

  // Request a display mode switch for the video's frame rate and/or, with
  // [matchResolution], its native resolution. Invokes [onComplete] once, either:
  // - immediately with `switched=false` when no switch is needed (no usable
  //   fps/resolution target, no matching mode, or already matching); or
  // - after our display reports the requested mode (other display changes are
  //   ignored) + [DISPLAY_SETTLE_MS] + the caller's [extraDelayMs], with
  //   `switched=true`; or
  // - via a watchdog if that event never arrives, so the caller doesn't hang.
  //
  // fps <= 0 with [matchResolution] requests a resolution-only switch that
  // keeps the refresh rate as close to the current one as possible.
  //
  // The caller is responsible for pausing playback before calling and resuming
  // it after [onComplete] fires.
  fun setVideoFrameRate(
    fps: Float,
    videoDurationMs: Long,
    extraDelayMs: Long,
    videoWidth: Int = 0,
    videoHeight: Int = 0,
    matchResolution: Boolean = false,
    onComplete: (switched: Boolean) -> Unit
  ) {
    // A new session's switch must not be clobbered by a still-pending
    // deferred restore from the previous session's teardown, and whoever
    // waits for that restore must not wait on this switch.
    cancelPendingRestore()
    restoreInterruptsSwitch = false
    finishRestore("superseded")
    currentVideoFps = fps
    currentVideoWidth = videoWidth
    currentVideoHeight = videoHeight
    currentMatchResolution = matchResolution
    val hasResolutionTarget = matchResolution && videoWidth > 0 && videoHeight > 0
    if (fps <= 0f && !hasResolutionTarget) {
      PlayerDebugLog.d(TAG) { "setVideoFrameRate: no usable target (fps=$fps, video=${videoWidth}x$videoHeight), skipping" }
      onComplete(false)
      return
    }

    log(
      "request fps=$fps, duration=${videoDurationMs}ms, extraDelayMs=$extraDelayMs, " +
        "video=${videoWidth}x$videoHeight, matchResolution=$matchResolution, " +
        "API=${Build.VERSION.SDK_INT}, currentMode=${currentModeDescription()}"
    )

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      setDisplayMode(fps, extraDelayMs, onComplete)
    } else {
      onComplete(false)
    }
  }

  // Restore the window's default display mode.
  //
  // [hdrActive]: the session was outputting HDR. The restore is then deferred
  // by [HDR_EXIT_SETTLE_MS] so the caller's surface teardown can commit the
  // HDR exit first — see [HDR_EXIT_SETTLE_MS] for why stacking them is slow.
  //
  // [onRestored] runs once: when the display has left the content mode and
  // settled ([RESTORE_SETTLE_MS]); at once when nothing is applied or the
  // pinned mode already is the default; after [RESTORE_WATCHDOG_MS] when the
  // change is never reported; or early when a new switch supersedes the
  // restore. A caller can hold the screen on it so the page underneath is not
  // shown at the content rate and then blanked by the HDMI renegotiation.
  fun clearVideoFrameRate(hdrActive: Boolean = false, onRestored: (() -> Unit)? = null) {
    log("clearVideoFrameRate(hdrActive=$hdrActive, awaitRestore=${onRestored != null})")
    currentVideoFps = 0f
    // Resolve any pending setVideoFrameRate future as "not switched" so
    // the Dart caller's await doesn't hang on player dispose.
    if (displayListener != null) restoreInterruptsSwitch = true
    firePendingCompletion("clear", switched = false)
    onRestored?.let { restoreWaiters += it }
    cancelPendingRestore()
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      finishRestore("unsupported")
      return
    }
    // Nothing to restore when no preferred mode is applied. A restore that
    // is still landing keeps its observation; a new waiter joins it.
    if ((activity.window?.attributes?.preferredDisplayModeId ?: 0) == 0) {
      if (restoreListener == null) finishRestore("nothing to restore")
      return
    }
    if (hdrActive) {
      val restore = Runnable {
        pendingRestoreRunnable = null
        log("restoring default display mode after HDR exit")
        restorePreferredDisplayMode()
      }
      pendingRestoreRunnable = restore
      handler.postDelayed(restore, HDR_EXIT_SETTLE_MS)
    } else {
      restorePreferredDisplayMode()
    }
  }

  private fun restorePreferredDisplayMode() {
    // preferredDisplayModeId persists on the window; restore the default.
    val window = activity.window
    val attrs = window?.attributes
    if (attrs == null) {
      finishRestore("window unavailable")
      return
    }
    val contentModeId = currentModeId()
    val requestedModeId = attrs.preferredDisplayModeId
    val interruptedSwitchModeId = if (restoreInterruptsSwitch) requestedModeId else NO_MODE
    restoreInterruptsSwitch = false
    // The window attribute is what this restores; the display lands on its
    // default mode asynchronously, so the second line names the mode still
    // active at the point of the request.
    log(
      "restorePreferredDisplayMode: preferredDisplayModeId=${attrs.preferredDisplayModeId} -> 0, " +
        "before currentMode=${currentModeDescription()}"
    )
    attrs.preferredDisplayModeId = 0
    window.attributes = attrs
    log("restorePreferredDisplayMode: applied, after currentMode=${currentModeDescription()}")
    observeRestore(contentModeId, modeBeforeRequest, interruptedSwitchModeId)
  }

  private fun observeRestore(contentModeId: Int, defaultModeId: Int, interruptedSwitchModeId: Int) {
    stopRestoreObservation()
    val fromModeId = when {
      contentModeId == NO_MODE -> NO_MODE
      contentModeId != defaultModeId -> contentModeId
      // Still on the default because the interrupted switch has not landed:
      // it may land before the display comes back.
      else -> interruptedSwitchModeId
    }
    if (fromModeId == NO_MODE || (contentModeId == defaultModeId && fromModeId == contentModeId)) {
      finishRestore("no mode change expected", landed = true)
      return
    }
    restoringFromModeId = fromModeId
    restoreObservedModeId = contentModeId
    val listener = object : DisplayManager.DisplayListener {
      override fun onDisplayAdded(displayId: Int) = Unit
      override fun onDisplayRemoved(displayId: Int) = Unit
      override fun onDisplayChanged(displayId: Int) {
        if (displayId == currentDisplayId()) onRestoreDisplayChanged()
      }
    }
    restoreListener = listener
    getDisplayManager().registerDisplayListener(listener, handler)
    val watchdog = Runnable { finishRestore("watchdog") }
    restoreWatchdogRunnable = watchdog
    handler.postDelayed(watchdog, RESTORE_WATCHDOG_MS)
    // The platform may already have applied the change.
    onRestoreDisplayChanged()
  }

  // Each mode change restarts the settle; a return to the content mode
  // cancels it until the display leaves again or the watchdog fires.
  private fun onRestoreDisplayChanged() {
    val modeId = currentModeId()
    if (modeId == restoreObservedModeId) return
    restoreObservedModeId = modeId
    restoreSettleRunnable?.let { handler.removeCallbacks(it) }
    restoreSettleRunnable = null
    if (modeId == restoringFromModeId) {
      log("display returned to the content mode during the restore")
      return
    }
    log("display left the content mode, now ${currentModeDescription()}; settling")
    val settle = Runnable {
      restoreSettleRunnable = null
      finishRestore("display restored", landed = true)
    }
    restoreSettleRunnable = settle
    handler.postDelayed(settle, RESTORE_SETTLE_MS)
  }

  // [landed]: the display is on its default mode, so the next request records
  // the mode it starts from afresh.
  private fun finishRestore(reason: String, landed: Boolean = false) {
    if (landed) modeBeforeRequest = NO_MODE
    val wasObserving = restoreListener != null
    stopRestoreObservation()
    val waiters = restoreWaiters.toList()
    restoreWaiters.clear()
    if (!wasObserving && waiters.isEmpty()) return
    log("display restore complete reason=$reason, currentMode=${currentModeDescription()}")
    waiters.forEach { it() }
  }

  private fun stopRestoreObservation() {
    restoreListener?.let { getDisplayManager().unregisterDisplayListener(it) }
    restoreListener = null
    restoreSettleRunnable?.let { handler.removeCallbacks(it) }
    restoreSettleRunnable = null
    restoreWatchdogRunnable?.let { handler.removeCallbacks(it) }
    restoreWatchdogRunnable = null
    restoringFromModeId = NO_MODE
    restoreObservedModeId = NO_MODE
  }

  private fun cancelPendingRestore() {
    pendingRestoreRunnable?.let { handler.removeCallbacks(it) }
    pendingRestoreRunnable = null
  }

  // Resolve a pending switch without restoring the display mode: a
  // player→player replacement (Dart's dispose(preserveDisplayMode: true))
  // inherits the window's mode instead of renegotiating HDMI twice. A
  // deferred restore and its waiters stay; the successor's own request
  // cancels and releases them.
  fun releasePending() {
    log("releasePending")
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

  private fun registerDisplayListener(
    fps: Float,
    targetModeId: Int,
    startModeId: Int,
    extraDelayMs: Long,
    onComplete: (switched: Boolean) -> Unit
  ) {
    // Resolve any previous pending op before starting a new one.
    firePendingCompletion("superseded", switched = false)
    pendingCompletion = onComplete

    displayListener = object : DisplayManager.DisplayListener {
      override fun onDisplayAdded(displayId: Int) = Unit
      override fun onDisplayRemoved(displayId: Int) = Unit
      override fun onDisplayChanged(displayId: Int) {
        // onDisplayChanged fires for any property of any logical display:
        // the previous title's deferred HDR-exit restore, the TV's own HDR
        // entry, a display state change, rotation, a secondary display. Only
        // our display landing on the requested mode starts the settle clock;
        // everything else keeps the listener armed.
        if (displayId != (currentDisplay()?.displayId ?: Display.DEFAULT_DISPLAY)) return
        if (!currentMatchesRequest(fps, targetModeId, startModeId)) {
          log("ignoring unrelated display change, currentMode=${currentModeDescription()}")
          return
        }
        // Unregister now so a chatty display (several events during HDMI
        // renegotiation) doesn't queue multiple settle callbacks, and let the
        // settle own the completion instead of a watchdog that would fire
        // first after a late event.
        getDisplayManager().unregisterDisplayListener(this)
        displayListener = null
        cancelPendingCallbacks()

        val settle = Runnable {
          firePendingCompletion("display settled", switched = currentMatchesRequest(fps, targetModeId, startModeId))
        }
        pendingSettleRunnable = settle
        handler.postDelayed(settle, DISPLAY_SETTLE_MS + extraDelayMs)
      }
    }
    getDisplayManager().registerDisplayListener(displayListener, handler)

    // Watchdog: if the TV never signals a display change (silently ignoring
    // the mode request), still complete after a bounded wait so the caller
    // doesn't hang.
    val watchdog = Runnable { firePendingCompletion("watchdog", switched = currentMatchesRequest(fps, targetModeId, startModeId)) }
    watchdogRunnable = watchdog
    handler.postDelayed(watchdog, DISPLAY_SETTLE_MS + extraDelayMs + WATCHDOG_MARGIN_MS)
  }

  // Whether the display left the mode the request started from and landed on
  // the requested one: the exact target, or — for a rate request — any mode
  // whose refresh presents [fps] (a TV may pick a different-but-equivalent
  // mode). The start mode is never a match even when its rate is a multiple
  // of [fps]: the request exists because a better mode was selected over it.
  // A resolution-only request (fps <= 0) only counts the exact target.
  private fun currentMatchesRequest(fps: Float, targetModeId: Int, startModeId: Int): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
    val current = currentDisplayMode() ?: return false
    if (current.modeId == startModeId) return false
    if (current.modeId == targetModeId) return true
    return DisplayModeSelector.matchRefreshRate(current.refreshRate, fps) != null
  }

  private fun currentModeDescription(): String = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    describeMode(currentDisplayMode())
  } else {
    "unavailable"
  }

  private fun currentModeId(): Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    currentDisplayMode()?.modeId ?: NO_MODE
  } else {
    NO_MODE
  }

  private fun currentDisplayId(): Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    currentDisplay()?.displayId ?: Display.DEFAULT_DISPLAY
  } else {
    Display.DEFAULT_DISPLAY
  }

  /**
   * The display's current mode and every mode it exposes, for the session
   * log. [setDisplayMode] logs the same list, but only when the user matches
   * frame rates; a report from a user who does not still needs to show what
   * the panel offered (#2255).
   */
  fun describeDisplay(): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return "modes unavailable"
    val display = currentDisplay() ?: return "display unavailable"
    val supported = display.supportedModes ?: return "current=${describeMode(display.mode)} modes unavailable"
    return "current=${describeMode(display.mode)} supported=${describeSupportedModes(supported)}"
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
  private fun Display.Mode.toModeInfo(): DisplayModeSelector.ModeInfo = DisplayModeSelector.ModeInfo(modeId, physicalWidth, physicalHeight, refreshRate)

  @RequiresApi(Build.VERSION_CODES.M)
  private fun setDisplayMode(fps: Float, extraDelayMs: Long, onComplete: (switched: Boolean) -> Unit) {
    log("setDisplayMode fps=$fps, matchResolution=$currentMatchResolution")
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

    val selection = DisplayModeSelector.findBestMode(
      fps,
      currentMode.toModeInfo(),
      supportedModes.map { it.toModeInfo() },
      currentVideoWidth,
      currentVideoHeight,
      currentMatchResolution
    )
    if (selection == null) {
      // A panel that exposes no clean multiple of the content rate (a 60/50/30
      // Hz-only set for 23.976 fps) is the usual reason; name it so a report
      // separates "never asked" from "nothing to ask for".
      val cleanMultiple = supportedModes.any { DisplayModeSelector.matchRefreshRate(it.refreshRate, fps) != null }
      val lowestRate = supportedModes.minOfOrNull { it.refreshRate }
      log(
        "no matching display mode for ${fps}fps at ${currentMode.physicalWidth}x${currentMode.physicalHeight} " +
          "(video=${currentVideoWidth}x$currentVideoHeight, matchResolution=$currentMatchResolution)" +
          (if (cleanMultiple) "" else "; no exposed mode is a clean multiple of ${fps}fps") +
          " (lowest exposed rate=${lowestRate}Hz)"
      )
      onComplete(false)
      return
    }

    val modeToUse = supportedModes.firstOrNull { it.modeId == selection.mode.modeId }
    if (modeToUse == null) {
      log("selected mode #${selection.mode.modeId} disappeared from supported modes")
      onComplete(false)
      return
    }
    val window = activity.window
    if (modeToUse.modeId == currentMode.modeId) {
      // Nothing to switch, but the choice still has to be pinned: without an
      // app request the platform's own policy (idle timer, brightness zones,
      // thermal) is free to leave this mode mid-playback, and on a panel
      // whose modes switch seamlessly it does — 120 Hz for 23.976 fps came
      // and went on a Pixel 7 Pro, dragging the vo's release grid along
      // (#2361). clearVideoFrameRate restores the default, as after a switch.
      if (window != null && window.attributes.preferredDisplayModeId != modeToUse.modeId) {
        log("current mode already matches ${fps}fps (${selection.reason}), pinning it")
        applyPreferredMode(window, modeToUse.modeId, currentMode.modeId)
      } else {
        log("current mode already matches ${fps}fps (${selection.reason}), no switch needed")
      }
      onComplete(false)
      return
    }

    log("switching to ${describeMode(modeToUse)} for ${fps}fps (${selection.reason})")
    if (window == null) {
      log("window unavailable")
      onComplete(false)
      return
    }
    registerDisplayListener(fps, modeToUse.modeId, currentMode.modeId, extraDelayMs, onComplete)
    applyPreferredMode(window, modeToUse.modeId, currentMode.modeId)
  }

  private fun applyPreferredMode(window: Window, modeId: Int, currentModeId: Int) {
    if (window.attributes.preferredDisplayModeId == 0 && modeBeforeRequest == NO_MODE) modeBeforeRequest = currentModeId
    window.attributes = window.attributes.apply { preferredDisplayModeId = modeId }
  }
}
