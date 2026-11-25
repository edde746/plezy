package com.edde746.plezy.desktop.harness

import org.jetbrains.skiko.SkiaLayer
import org.jetbrains.skiko.SkikoRenderDelegate
import java.awt.Component
import java.awt.Container
import java.awt.EventQueue
import java.awt.Window

/**
 * `--frame-times`: the window's Compose frames and the UI thread's stalls, for timing paths from the report.
 *
 * Each frame is the Skia layer's render call (Compose's frame: animations, recomposition, layout and drawing), kept as
 * its start in epoch ms and its length. A stall is a span over [STALL_MS] in which the UI thread ran nothing else: a
 * watcher posts an empty event every [PING_MS] and keeps the waits that took longer, by their start and length. The
 * report takes both with each sample ([take]); times are on the epoch clock the remote harness logs its input with.
 */
internal class FrameLog {
    private val wall0 = System.currentTimeMillis()
    private val nanos0 = System.nanoTime()
    private val frames = ArrayList<List<Double>>()
    private val stalls = ArrayList<List<Double>>()

    /** The Skia layer's renderer, set when [attach] found the layer. */
    @Volatile var renderer: String? = null
        private set

    private fun wall(nanos: Long): Double = round(wall0 + (nanos - nanos0) / 1e6)

    private fun round(ms: Double): Double = Math.round(ms * 10) / 10.0

    /** Times [window]'s Compose frames from now on and starts the stall watcher; false when it has no Skia layer. */
    fun attach(window: Window): Boolean {
        val layer = skiaLayer(window) ?: return false
        val inner = layer.renderDelegate ?: return false
        layer.renderDelegate = SkikoRenderDelegate { canvas, width, height, nanoTime ->
            val start = System.nanoTime()
            try {
                inner.onRender(canvas, width, height, nanoTime)
            } finally {
                val took = (System.nanoTime() - start) / 1e6
                synchronized(frames) { frames += listOf(wall(start), round(took)) }
            }
        }
        renderer = layer.renderInfo.lineSequence().firstOrNull { it.isNotBlank() }?.trim()
        Thread({
            while (true) {
                val posted = System.nanoTime()
                EventQueue.invokeAndWait { }
                val waited = System.nanoTime() - posted
                if (waited >= STALL_MS * 1_000_000) synchronized(stalls) { stalls += listOf(wall(posted), round(waited / 1e6)) }
                Thread.sleep(PING_MS)
            }
        }, "frame-log-stalls").apply { isDaemon = true; start() }
        return true
    }

    /** The frames (`[start, ms]`) and stalls since the last call, or null when there were none. */
    fun take(): Map<String, Any?>? {
        val taken = synchronized(frames) { frames.toList().also { frames.clear() } }
        val stalled = synchronized(stalls) { stalls.toList().also { stalls.clear() } }
        if (taken.isEmpty() && stalled.isEmpty()) return null
        return linkedMapOf("frames" to taken, "stalls" to stalled)
    }

    private fun skiaLayer(c: Component): SkiaLayer? =
        c as? SkiaLayer ?: (c as? Container)?.components?.firstNotNullOfOrNull(::skiaLayer)

    private companion object {
        const val STALL_MS = 50L
        const val PING_MS = 4L
    }
}
