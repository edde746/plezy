package com.edde746.plezy.desktop.windows

import com.edde746.plezy.log.Log
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.playback.output.DisplayInfo
import com.edde746.plezy.playback.output.DisplayMode
import com.edde746.plezy.playback.output.DisplayRestore
import com.edde746.plezy.playback.output.OutputPlan
import com.edde746.plezy.playback.output.OutputPolicy
import com.edde746.plezy.playback.output.PlaybackOutputHost
import com.edde746.plezy.presentation.settings.DeviceFeatures
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.util.concurrent.Executors
import java.util.concurrent.ExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Display matching on Windows: each playback's [PlaybackOutputHost] ([host]) switches the display the window is on to
 * the mode and HDR state the shared policy picks (only while the player is fullscreen; leaving fullscreen brings a plan
 * without either, which puts them back), and back when the playback ends; [close] (the app's exit) and a JVM shutdown
 * hook put back whatever is still switched.
 *
 * Before each switch the original it replaces is persisted ([DisplayRecovery], in the registry), so what a process
 * that died mid-playback left switched is put back at the next start and at every display change
 * ([WindowsDisplayChanges]); a switch this process still holds is skipped there.
 *
 * One `display` thread does the switching and the recovery, in order (a switch blocks for a moment), so a playback
 * reads the display only after the one before it has restored it; the playback's read waits for that without blocking
 * the main thread. Switching HDR drops a temporary mode (Windows goes back to the mode in the registry), so a plan
 * switches HDR first and then sets its mode; a restore puts HDR back first, then the mode. Before HDR goes back mpv
 * stops presenting HDR (`target-colorspace-hint=no`) and the swapchain gets [HINT_SETTLE_MS] to follow. A plan that
 * switches anything holds its playback ([MpvPlayerEngine.holdForDisplay]) from before the switch until the plan's
 * display switch delay after it ([OutputPlan.switchDelaySeconds]; none at 0), while the monitor syncs to the new signal.
 * After each mode change the playback's mpv gets the new rate ([MpvPlayerEngine.setDisplayFps]), since its child
 * window hears nothing of the change, and presents HDR only with the plan's HDR output ([MpvPlayerEngine.setHdrOutput]);
 * while it presents HDR, SDR video's white is the display's SDR white level ([MpvPlayerEngine.setSdrWhite]), read at
 * each plan. The plan's audio passthrough goes to the playback's mpv as each plan comes
 * ([MpvPlayerEngine.setAudioPassthrough]), on every output: Windows doesn't say which formats a device takes undecoded.
 *
 * @param window the window's HWND, read on the main thread when a playback reads the display.
 * @param onEvent what was switched, for the test report.
 */
internal class WindowsDisplayMatching(
    private val window: () -> Long,
    private val onEvent: (name: String, detail: Map<String, Any?>) -> Unit = { _, _ -> },
) : AutoCloseable {
    private val thread: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "display").apply { isDaemon = true } }
    private val dispatcher = thread.asCoroutineDispatcher()
    private val shutdownHook = Thread(::close, "display-restore")

    // The display thread's state: the display of the playback, what it changed where (the originals to put back) and
    // whether those switches are this process's (live: recovery leaves them alone).
    private var display: WindowsDisplay? = null
    private var switchedTo: WindowsDisplay.Mode? = null
    private var modeDisplay: WindowsDisplay? = null
    private var originalMode: WindowsDisplay.Mode? = null
    private var hdrDisplay: WindowsDisplay? = null
    private var originalHdr: Boolean? = null
    private val restore = DisplayRestore()
    private var modeLive = false
    private var hdrLive = false

    /** The latest plan's hold: an earlier plan's (cancelled) end doesn't release a later one's. */
    private val holds = AtomicInteger()

    init {
        Runtime.getRuntime().addShutdownHook(shutdownHook)
        post("recovery") { recover() }
        WindowsDisplayChanges { post("recovery") { recover() } }
    }

    /**
     * What the display under the window can switch, for the Settings rows: HDR where it supports HDR, forcing the
     * frame rate where its resolution comes with more than one rate (Windows has no setting of its own that follows a
     * video's rate); neither when the display can't be read. Passthrough always. Read on the calling thread (a few
     * milliseconds).
     */
    fun features(): DeviceFeatures {
        val display = try {
            window().takeIf { it != 0L }?.let(WindowsDisplay::forWindow)
        } catch (e: Exception) {
            Log.w(TAG, e) { "reading the display failed; no display switching" }
            null
        }
        return DeviceFeatures(
            hardwareDecoding = true,
            hdr = display?.hdr()?.supported == true,
            matchFrameRate = (display?.modes()?.size ?: 0) > 1,
            audioPassthrough = true,
        )
    }

    /** The output host of the playback on [engine]. */
    fun host(engine: MpvPlayerEngine): PlaybackOutputHost = object : PlaybackOutputHost {
        override suspend fun display(): DisplayInfo {
            val hwnd = window()
            return withContext(dispatcher) { read(hwnd) }
        }

        override suspend fun apply(plan: OutputPlan): Boolean {
            engine.setAudioPassthrough(plan.audioPassthrough)
            if (thread.isShutdown) return false
            val hold = holds.incrementAndGet()
            val hdrTaken = CompletableDeferred<Boolean>()
            val held = withContext(dispatcher) { applyPlan(plan, engine) { hdrTaken.complete(it) } }
            if (held) {
                // The switch has landed (the calls return once the display reports it); the display switch delay
                // follows, the playback still held. A newer plan cancels this one, and its own hold carries on.
                try {
                    delay(plan.switchDelaySeconds * 1000L)
                } finally {
                    if (holds.get() == hold) engine.holdForDisplay(false)
                }
            }
            return hdrTaken.await()
        }

        override fun restore() = post("restore") { restoreDisplay(engine) }
    }

    /** Puts the display back as it was before a playback switched it (the app is closing), then stops the thread. */
    override fun close() {
        if (thread.isShutdown) return
        runCatching { Runtime.getRuntime().removeShutdownHook(shutdownHook) }
        post("restore") { restoreDisplay(null) }
        thread.shutdown()
        thread.awaitTermination(15, TimeUnit.SECONDS)
    }

    private fun post(what: String, block: () -> Unit) {
        if (thread.isShutdown) return
        thread.execute {
            try {
                block()
            } catch (e: Exception) {
                Log.w(TAG, e) { "display $what failed" }
            }
        }
    }

    private fun read(hwnd: Long): DisplayInfo {
        restoreDisplay(null) // Nothing is switched when a playback starts; a missed restore is undone before reading.
        val display = WindowsDisplay.forWindow(hwnd).also { display = it }
        val hdr = display.hdr()
        val info = DisplayInfo(
            modes = display.modes().map { it.toDisplayMode() },
            current = display.currentMode()?.toDisplayMode(),
            hdrSupported = hdr?.supported == true,
            hdrEnabled = hdr?.enabled == true,
        )
        onEvent("displayInfo", mapOf("device" to display.device, "current" to info.current?.describe(), "modes" to info.modes.map { it.describe() }, "hdrSupported" to info.hdrSupported, "hdrEnabled" to info.hdrEnabled))
        return info
    }

    /**
     * Switches the display to [plan]; true when it switched anything, the playback then held
     * ([MpvPlayerEngine.holdForDisplay]). [hdrTaken] hears whether the engine took the plan's HDR output.
     */
    private fun applyPlan(plan: OutputPlan, engine: MpvPlayerEngine, hdrTaken: (Boolean) -> Unit): Boolean {
        // A plan before the playback read the display has nothing to switch here.
        val display = display ?: run {
            engine.setHdrOutput(plan.hdrOutput, hdrTaken)
            return false
        }
        val mode = plan.mode
        val hdrOn = originalHdr != null
        val held = plan.enableHdr != hdrOn || (if (mode == null) switchedTo != null else switchedTo?.frequency != mode.id)
        if (held) engine.holdForDisplay(true)
        val (hdrSet, modeSet) = try {
            switch(display, plan, engine)
        } catch (e: Exception) {
            if (held) engine.holdForDisplay(false)
            throw e
        }
        // Without HDR output (the Hdr setting off) mpv tone-maps to SDR, even on a display whose HDR is on; set again
        // after an HDR switch, as the swapchain follows the display's new state.
        engine.setHdrOutput(plan.hdrOutput, hdrTaken)
        if (hdrSet == false || modeSet == false) Log.w(TAG) { "display switch refused: hdr=$hdrSet mode=$modeSet for $plan" }
        val state = state(display)
        if (modeSet != null) engine.setDisplayFps(if (switchedTo != null) state.refreshHz else null)
        // mpv presents in PQ: SDR video at the white DWM shows the controls and every other window at, not mpv's 203.
        val sdrWhite = if (plan.hdrOutput && state.hdrEnabled == true) display.sdrWhiteNits() else null
        engine.setSdrWhite(sdrWhite)
        onEvent(
            "displayApplied",
            mapOf(
                "frameRate" to plan.frameRate, "mode" to mode?.describe(), "enableHdr" to plan.enableHdr, "hdr" to plan.hdr, "hdrOutput" to plan.hdrOutput,
                "switchDelaySeconds" to plan.switchDelaySeconds, "sdrWhite" to sdrWhite,
                "hdrSet" to hdrSet, "modeSet" to modeSet, "held" to held,
            ) + state.fields,
        )
        return held
    }

    /** Switches [display]'s HDR state, then its mode, to [plan]'s: whether each switch was taken, null where none was due. */
    private fun switch(display: WindowsDisplay, plan: OutputPlan, engine: MpvPlayerEngine): Pair<Boolean?, Boolean?> {
        var hdrSet: Boolean? = null
        var modeSet: Boolean? = null
        if (plan.enableHdr != (originalHdr != null)) {
            hdrSet = if (plan.enableHdr) setHdr(display, true) else restoreHdr(engine)
            if (switchedTo != null && display.currentMode()?.frequency != switchedTo?.frequency) {
                // The HDR switch dropped the mode set before it: the display is back at its registry mode.
                modeRestored()
                if (plan.mode == null) modeSet = true
            }
        }
        val mode = plan.mode
        if (mode == null) {
            if (originalMode != null) modeSet = restoreMode()
        } else if (switchedTo?.frequency != mode.id) {
            modeSet = setMode(display, WindowsDisplay.Mode(mode.width, mode.height, mode.id, mode.refreshRate))
        }
        return hdrSet to modeSet
    }

    /**
     * Undoes what the playback switched: HDR first (after mpv stopped presenting HDR), then the mode; its mpv (if still
     * playing) reads the rate itself again. What fails to go back stays recorded, for the next restore or recovery.
     */
    private fun restoreDisplay(engine: MpvPlayerEngine?) {
        val display = display ?: modeDisplay ?: hdrDisplay
        this.display = null
        if (display == null || !restore.anyChanged) return
        var hdr: Boolean? = null
        var mode: Boolean? = null
        restore.restoreAll(
            restoreHdr = { restoreHdr(engine).also { hdr = it } },
            restoreMode = { restoreMode().also { mode = it } },
        )
        if (mode == true) engine?.setDisplayFps(null)
        onEvent("displayRestored", mapOf("modeRestored" to mode, "hdrRestored" to hdr) + state(display).fields)
    }

    // --- The switches, each recorded for crash recovery before Windows is asked ---

    private fun setMode(display: WindowsDisplay, target: WindowsDisplay.Mode): Boolean {
        val wasChanged = originalMode != null
        if (!wasChanged) {
            originalMode = display.currentMode() ?: return false
            modeDisplay = display
        }
        val original = originalMode!!
        val device = modeDisplay!!.device
        if (!DisplayRecovery.prepareMode(backend, device, original.width.toLong(), original.height.toLong(), original.frequency.toLong())) {
            if (!wasChanged) clearMode()
            return false
        }
        // Live before Windows is called: the display change the switch brings must not recover it.
        modeLive = true
        val changed = display.setMode(target)
        if (changed) {
            DisplayRecovery.finalize(backend, DisplayRecovery.Kind.MODE, osApplySucceeded = true)
            switchedTo = target
            restore.modeChanged = true
        } else if (!wasChanged) {
            val completed = DisplayRecovery.finalize(backend, DisplayRecovery.Kind.MODE, osApplySucceeded = false)
            modeLive = false
            clearMode()
            if (!completed) DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.MODE)
        }
        return changed
    }

    private fun restoreMode(): Boolean {
        val display = modeDisplay ?: return false
        if (!display.restoreMode()) {
            // Given up here: recovery at a later display change may finish it.
            modeLive = false
            DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.MODE)
            return false
        }
        modeRestored()
        return true
    }

    /** The mode is back at the original: retires its record. */
    private fun modeRestored() {
        clearMode()
        val completed = DisplayRecovery.complete(backend, DisplayRecovery.Kind.MODE)
        modeLive = false
        if (!completed) DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.MODE)
    }

    private fun clearMode() {
        originalMode = null
        modeDisplay = null
        switchedTo = null
        restore.modeChanged = false
    }

    private fun setHdr(display: WindowsDisplay, enabled: Boolean): Boolean {
        // HDR switched on another display (the window moved) goes back there first; if it can't, nothing else switches.
        if (originalHdr != null && hdrDisplay?.device != display.device && restoreHdr(null) != true) return false
        val wasChanged = originalHdr != null
        val target = if (wasChanged) hdrDisplay!! else display
        if (!wasChanged) {
            originalHdr = target.hdr()?.enabled ?: return false
            hdrDisplay = target
        }
        val original = originalHdr!!
        if (!DisplayRecovery.prepareHdr(backend, target.device, original)) {
            if (!wasChanged) clearHdr()
            return false
        }
        hdrLive = true
        val set = target.setHdr(enabled)
        // What the display shows, not what the call answered: a refused switch can still change it (a Remote Desktop
        // session's display does), and then it is this playback's to put back.
        val changed = set || target.hdr()?.enabled != original
        if (changed) {
            DisplayRecovery.finalize(backend, DisplayRecovery.Kind.HDR, osApplySucceeded = true)
            restore.hdrChanged = true
        } else if (!wasChanged) {
            val completed = DisplayRecovery.finalize(backend, DisplayRecovery.Kind.HDR, osApplySucceeded = false)
            hdrLive = false
            clearHdr()
            if (!completed) DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.HDR)
        }
        return set
    }

    /** HDR back to its original on the display it was switched on, after [engine]'s mpv stopped presenting HDR. */
    private fun restoreHdr(engine: MpvPlayerEngine?): Boolean {
        val original = originalHdr ?: return false
        val display = hdrDisplay ?: return false
        if (engine != null) {
            engine.setHdrOutput(false)
            Thread.sleep(HINT_SETTLE_MS)
        }
        val state = display.hdr()
        if (state == null || (state.enabled != original && !display.setHdr(original))) {
            hdrLive = false
            DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.HDR)
            return false
        }
        clearHdr()
        val completed = DisplayRecovery.complete(backend, DisplayRecovery.Kind.HDR)
        hdrLive = false
        if (!completed) DisplayRecovery.markTakeoverEligible(backend, DisplayRecovery.Kind.HDR)
        return true
    }

    private fun clearHdr() {
        originalHdr = null
        hdrDisplay = null
        restore.hdrChanged = false
    }

    /** Puts back what a process that died mid-playback left switched (none of this process's own switches). */
    private fun recover() {
        // A display change this process's own switches bring (both live) has nothing of a dead process's to put back.
        if ((modeLive && hdrLive) || !backend.recordExists()) return
        val completed = DisplayRecovery.recover(backend, modeLive, hdrLive)
        onEvent("displayRecovered", mapOf("completed" to completed, "modeLive" to modeLive, "hdrLive" to hdrLive))
    }

    /** The display's mode and HDR state now, as the report shows them. */
    private class State(val current: WindowsDisplay.Mode?, val hdrEnabled: Boolean?) {
        val refreshHz: Double? get() = current?.refreshHz
        val fields: Map<String, Any?> get() = mapOf("current" to current?.toDisplayMode()?.describe(), "hdrEnabled" to hdrEnabled)
    }

    private fun state(display: WindowsDisplay) = State(display.currentMode(), display.hdr()?.enabled)

    private companion object {
        const val TAG = "display"

        /** Where the crash-recovery record lives. */
        val backend: DisplayRecovery.Backend = RegistryRecoveryBackend

        /** How long mpv's swapchain gets to leave HDR before the display does. */
        const val HINT_SETTLE_MS = 200L

        /**
         * A GDI mode as the policy sees it: its id is the GDI frequency, which [WindowsDisplay.setMode] takes back, and
         * its rate the one that frequency stands for (23 Hz is 23.976).
         */
        fun WindowsDisplay.Mode.toDisplayMode() = DisplayMode(id = frequency, width = width, height = height, refreshRate = OutputPolicy.windowsRefreshRate(frequency))

        fun DisplayMode.describe(): String = "${width}x$height@${"%.3f".format(java.util.Locale.ROOT, refreshRate)}"
    }
}
