package com.edde746.plezy

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Debug
import android.os.SystemClock
import android.util.Log as AndroidLog
import android.view.KeyEvent
import android.view.Window
import androidx.compose.ui.geometry.Rect
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.ui.probe.HOME_CONTENT_MARK
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.PerfProbe

/**
 * The `perf` extra's marks (the harness's perf runs read them): one INFO line per mark under the [TAG] logcat
 * tag, `<name> up=<uptime ms> key=<event time of the last key press, -1 before any> keycode=<its key code, -1>
 * gc=<ART's GC count> gcms=<ART's GC time in ms>`, then the mark's `k=v` details. The screens mark through
 * [PerfProbe] (ui/probe), the mpv engine through [AndroidPlatform.mpvEvents] (`engine.load`, `engine.loadfile`,
 * `engine.playing`, `engine.terminate`), and [focusProbe] marks `focus probe=<probe name>` and `blur probe=<probe
 * name>` as a named control gains and loses focus, which the harness walks the D-pad by. The key press is the last key
 * down (not a repeat) any of the app's activities received, read in front of the activity's own dispatch. The launch's
 * first `home.content` mark reports the activity fully drawn.
 */
internal class PerfMarks(private val application: PlezyApplication) : PerfProbe, Application.ActivityLifecycleCallbacks {
    private class KeyPress(val time: Long, val code: Int)

    @Volatile private var lastKey: KeyPress? = null

    /**
     * The layout probe of a perf run without a report: focus only, no element's bounds. A blur marks only the focused
     * control losing focus: every probed element reports an unfocused state as it is composed, a log line per card
     * the scroll it measures would otherwise pay for.
     */
    val focusProbe: LayoutProbe = object : LayoutProbe {
        /** The named control that has focus; main thread. */
        private var focused: String? = null

        override fun place(name: String, bounds: Rect?) {}

        override fun focus(name: String, focused: Boolean) {
            if (focused) {
                this.focused = name
                mark("focus", "probe=$name")
            } else if (name == this.focused) {
                this.focused = null
                mark("blur", "probe=$name")
            }
        }

        override val placements: Boolean get() = false
    }

    /** The first `home.content` mark reported the activity fully drawn; main thread. */
    private var fullyDrawn = false

    /** Starts reading the activities' key presses and the engine's events. */
    fun start() {
        application.registerActivityLifecycleCallbacks(this)
        application.platform.mpvEvents = { mark("engine.$it", "") }
    }

    fun stop() {
        application.platform.mpvEvents = null
        application.unregisterActivityLifecycleCallbacks(this)
    }

    override fun mark(name: String, detail: String) {
        val key = lastKey
        val line = buildString {
            append(name)
            append(" up=").append(SystemClock.uptimeMillis())
            append(" key=").append(key?.time ?: -1L)
            append(" keycode=").append(key?.code ?: -1)
            append(" gc=").append(Debug.getRuntimeStat("art.gc.gc-count"))
            append(" gcms=").append(Debug.getRuntimeStat("art.gc.gc-time"))
            if (detail.isNotEmpty()) append(' ').append(detail)
        }
        AndroidLog.i(TAG, line)
        if (name == HOME_CONTENT_MARK && !fullyDrawn) {
            fullyDrawn = true
            application.platform.activity?.reportFullyDrawn()
        }
    }

    // At start, not creation: the launch begins in its first activity's onCreate, after that activity was created. A
    // started activity hears keys only from its resume on; each activity's window is wrapped once.
    override fun onActivityStarted(activity: Activity) {
        val window = activity.window
        val callback = window.callback
        if (callback !is KeyPresses) window.callback = KeyPresses(callback)
    }

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}

    override fun onActivityResumed(activity: Activity) {}

    override fun onActivityPaused(activity: Activity) {}

    override fun onActivityStopped(activity: Activity) {}

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}

    override fun onActivityDestroyed(activity: Activity) {}

    /** The window's own [callback] (the activity), after noting each key press. */
    private inner class KeyPresses(private val callback: Window.Callback) : Window.Callback by callback {
        override fun dispatchKeyEvent(event: KeyEvent): Boolean {
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) lastKey = KeyPress(event.eventTime, event.keyCode)
            return callback.dispatchKeyEvent(event)
        }
    }

    private companion object {
        const val TAG = "PlezyPerf"
    }
}
