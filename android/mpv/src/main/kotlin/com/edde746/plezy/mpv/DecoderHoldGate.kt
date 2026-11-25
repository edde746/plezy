package com.edde746.plezy.mpv

import com.edde746.plezy.playback.VideoInfo
import kotlinx.coroutines.CompletableDeferred
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Holds one file's video decoder at mpv's `on_preloaded` hook (the demuxer has opened the file, no decoder exists yet)
 * while the display switches mode for it ([MpvPlayerEngine.holdDecoder]): Kodi's order, and the one Amazon and Android
 * document (finish the switch, then start playback). A decoder made before an HDMI mode switch can stay bound to the old
 * mode: a Fire TV Stick 4K's Dolby Vision decoder ran through a 59.94 → 23.976 Hz switch and the TV, still in Dolby
 * Vision mode, showed the picture green and purple.
 *
 * The output arms a hold with its own token before the open ([arm]). The file's `on_preloaded` takes it ([take]),
 * answers the arm with the file's declared video and waits until that token is [release]d. An arm never outlives its
 * open: a newer arm supersedes it, its file ending before the hook cancels it, a release before the hook cancels it,
 * and [close] answers everything. Each arm is answered exactly once. Any thread.
 */
internal class DecoderHoldGate {
    class Hold(val token: Long, private val onVideo: (VideoInfo?) -> Unit) {
        private val answered = AtomicBoolean(false)

        /** Completes once the output released the hold (or the engine closed). */
        val released = CompletableDeferred<Unit>()

        /** mpv started a file after this arm: the arm belongs to that file. */
        var fileStarted = false

        /** Delivers the held file's declared video, or null when nothing is held. */
        fun answer(video: VideoInfo?) {
            if (answered.compareAndSet(false, true)) onVideo(video)
        }
    }

    private val lock = Any()
    private var armed: Hold? = null
    private var active: Hold? = null
    private var closed = false

    /** Arms a hold for the next file's `on_preloaded`; one still armed is answered with nothing. */
    fun arm(token: Long, onVideo: (VideoInfo?) -> Unit) {
        val hold = Hold(token, onVideo)
        val unanswered = synchronized(lock) { if (closed) hold else armed.also { armed = hold } }
        unanswered?.answer(null)
    }

    /** mpv started a file: an arm made before it now belongs to it. */
    fun onFileStarted() {
        synchronized(lock) { armed?.fileStarted = true }
    }

    /**
     * mpv ended a file. An arm whose own file ended before its hook (a failed open) will never be taken; the previous
     * file ending as the armed open replaces it is not that file.
     */
    fun onFileEnded() {
        val cancelled = synchronized(lock) { armed?.takeIf { it.fileStarted }?.also { armed = null } }
        cancelled?.answer(null)
    }

    /** The armed hold, now holding the hook; null when nothing is armed. */
    fun take(): Hold? = synchronized(lock) {
        armed?.also {
            armed = null
            active = it
        }
    }

    /** The hook is going on: [hold] no longer holds it. */
    fun finish(hold: Hold) {
        synchronized(lock) { if (active === hold) active = null }
    }

    /** The output's release of [token]: lets its held decoder open, or cancels its arm. Other tokens' holds stay. */
    fun release(token: Long) {
        val (cancelled, held) = synchronized(lock) {
            val cancelled = armed?.takeIf { it.token == token }?.also { armed = null }
            cancelled to active?.takeIf { it.token == token }
        }
        cancelled?.answer(null)
        held?.released?.complete(Unit)
    }

    /** The engine is going away: answers the armed hold and lets the held decoder go. */
    fun close() {
        val (cancelled, held) = synchronized(lock) {
            closed = true
            (armed to active).also {
                armed = null
                active = null
            }
        }
        cancelled?.answer(null)
        held?.released?.complete(Unit)
    }
}
