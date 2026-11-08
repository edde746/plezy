package com.edde746.plezy.mpv

import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CompletableDeferred

/**
 * Holds one file's video decoder at mpv's `on_preloaded` hook — the demuxer
 * has opened the file, no decoder exists yet — while the app switches the
 * display mode for it: Kodi's order, and the one Amazon and Android document
 * (finish the switch, then start playback). A decoder created before an HDMI
 * mode switch can stay bound to the old mode: on the Fire TV Stick 4K
 * (MT8695) the Dolby Vision decoder ran through a 59.94 → 23.976 Hz switch
 * and the TV, still in Dolby Vision mode, showed the picture green and
 * purple (#2998).
 *
 * Dart arms a hold with its own token before it opens the file ([arm]). The
 * file's `on_preloaded` takes it ([take]), answers the arm with the demuxed
 * video format and waits until Dart [release]s that token. An arm never
 * outlives its open: a newer arm supersedes it, its file ending before the
 * hook cancels it, a release before the hook cancels it, and [close] answers
 * everything. Each arm is answered exactly once.
 */
internal class DecoderHold {
  class Hold(val token: Long, private val onFormat: (Map<String, Any?>?) -> Unit) {
    private val answered = AtomicBoolean(false)

    /** Completes once Dart released the hold (or the session closed). */
    val released = CompletableDeferred<Unit>()

    /** mpv started a file after this arm: the arm belongs to that file. */
    var fileStarted = false

    /** Delivers the held file's demuxed format, or null when nothing is held. */
    fun answer(format: Map<String, Any?>?) {
      if (answered.compareAndSet(false, true)) onFormat(format)
    }
  }

  private val lock = Any()
  private var armed: Hold? = null
  private var active: Hold? = null
  private var closed = false

  /** Arms a hold for the next file's `on_preloaded`; one still armed is answered with nothing. */
  fun arm(token: Long, onFormat: (Map<String, Any?>?) -> Unit) {
    val hold = Hold(token, onFormat)
    val unanswered = synchronized(lock) {
      if (closed) hold else armed.also { armed = hold }
    }
    unanswered?.answer(null)
  }

  /** mpv started a file: an arm made before it now belongs to it. */
  fun onFileStarted() {
    synchronized(lock) { armed?.fileStarted = true }
  }

  /**
   * mpv ended a file. An arm whose own file ended before its hook (a failed
   * open) will never be taken; the previous file ending as the armed open
   * replaces it is not that file.
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

  /** The hook is continuing: [hold] no longer holds it. */
  fun finish(hold: Hold) {
    synchronized(lock) { if (active === hold) active = null }
  }

  /** Dart's release of [token]: lets its held decoder open, or cancels its arm. Other tokens' holds stay. */
  fun release(token: Long) {
    val (cancelled, held) = synchronized(lock) {
      val cancelled = armed?.takeIf { it.token == token }?.also { armed = null }
      cancelled to active?.takeIf { it.token == token }
    }
    cancelled?.answer(null)
    held?.released?.complete(Unit)
  }

  /** The session is going away: answers the armed hold and lets the held decoder go. */
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
