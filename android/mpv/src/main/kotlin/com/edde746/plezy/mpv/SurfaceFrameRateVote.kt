package com.edde746.plezy.mpv

/**
 * The seamless frame-rate vote on the video Surface, as Media3's `VideoFrameReleaseHelper` places it:
 * `Surface.setFrameRate(rate, FIXED_SOURCE)` with the platform's default seamless-only switching. A display that can
 * change mode without a blank (or whose modes share one group) follows it; a switch that blanks the screen is the
 * output plan's (the window's preferred mode).
 *
 * The vote is the presented frame rate ([onFrameRate]: `EngineState.video`'s, fields and inverse telecine counted)
 * times the playback speed while playback runs ([onStarted]), cleared (rate 0) when it stops, cleared on a Surface the
 * player leaves and given to a new one even at an unchanged rate (a Surface may carry an earlier vote). [setFrameRate]
 * places a vote on a Surface ([S]). One thread at a time.
 */
internal class SurfaceFrameRateVote<S : Any>(private val setFrameRate: (S, Float) -> Unit) {
    private var surface: S? = null
    private var frameRate = 0f
    private var speed = 1f
    private var started = false

    /** The rate the current [surface] was last given; 0 means cleared. */
    private var voted = 0f

    /** The video Surface; null without a real one (the placeholder, destroyed, released). */
    fun onSurfaceChanged(surface: S?) {
        if (this.surface === surface) return
        clear()
        this.surface = surface
        update(force = true)
    }

    /** The presented frame rate, or 0 (or none that is finite and positive) while it is unknown. */
    fun onFrameRate(fps: Float) {
        val next = if (fps.isFinite() && fps > 0f) fps else 0f
        if (frameRate == next) return
        frameRate = next
        update(force = false)
    }

    fun onPlaybackSpeed(speed: Float) {
        val next = if (speed.isFinite() && speed > 0f) speed else 1f
        if (this.speed == next) return
        this.speed = next
        update(force = false)
    }

    /** Playback runs ([running]) or stopped: paused, held, not started. */
    fun onRunning(running: Boolean) {
        if (started == running) return
        started = running
        if (running) update(force = false) else clear()
    }

    private fun update(force: Boolean) {
        val target = surface ?: return
        val rate = if (started && frameRate > 0f) frameRate * speed else 0f
        if (!force && rate == voted) return
        voted = rate
        setFrameRate(target, rate)
    }

    private fun clear() {
        val target = surface ?: return
        if (voted == 0f) return
        voted = 0f
        setFrameRate(target, 0f)
    }
}
