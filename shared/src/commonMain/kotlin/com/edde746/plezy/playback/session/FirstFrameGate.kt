package com.edde746.plezy.playback.session

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * The first frame of a playback, as two flags apart: [uiReady] for what shows (the spinner goes, the controls work),
 * which a failure may force up to hide the spinner; and [rendered], the stricter latch progress reports and the
 * watchdogs read, set only by a frame actually shown. A reload takes a [snapshot] first and [restore]s it if the
 * replacement fails, so the old file's state comes back as it was.
 */
class FirstFrameGate {
    private val mutableUiReady = MutableStateFlow(false)
    val uiReady: StateFlow<Boolean> = mutableUiReady.asStateFlow()

    var rendered: Boolean = false
        private set

    /** A frame is on screen. */
    fun markReady() {
        rendered = true
        mutableUiReady.value = true
    }

    /** A new open is about to show its own first frame: the spinner shows. */
    fun resetUiForOpen() {
        mutableUiReady.value = false
    }

    /** A new playback attempt owns the reporting latch from here on. */
    fun resetRenderedForAttempt() {
        rendered = false
    }

    fun reset() {
        mutableUiReady.value = false
        rendered = false
    }

    /** Hides the spinner after a failure without latching [rendered]. */
    fun forceUiReadyOnFailure() {
        mutableUiReady.value = true
    }

    fun snapshot(): Snapshot = Snapshot(mutableUiReady.value, rendered)

    fun restore(snapshot: Snapshot) {
        mutableUiReady.value = snapshot.uiReady
        rendered = snapshot.rendered
    }

    data class Snapshot(val uiReady: Boolean, val rendered: Boolean)
}
