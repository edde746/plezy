package com.edde746.plezy.exoplayer

import java.util.ArrayDeque
import java.util.concurrent.CancellationException

/**
 * Serializes raw user/normalization AF and app EQ changes independently.
 * Only successful writes become replay state. Never cache their composed chain
 * as the raw AF: that would resurrect a disabled EQ when the core is recreated.
 */
class MpvAudioFilterState(
  initialBase: String,
  initialEqualizer: String,
  private val apply: (String, (Result<Unit>) -> Unit) -> Unit
) {
  var base = initialBase
    private set
  var equalizer = initialEqualizer
    private set

  private data class Update(val base: String?, val equalizer: String?, val complete: (Result<Unit>) -> Unit)
  private val queue = ArrayDeque<Update>()
  private var running = false
  private var closed = false

  val combined: String get() = combine(base, equalizer)

  fun setBase(value: String, complete: (Result<Unit>) -> Unit) = enqueue(Update(value, null, complete))

  fun setEqualizer(value: String, complete: (Result<Unit>) -> Unit) = enqueue(Update(null, value, complete))

  fun invalidate() {
    if (closed) return
    closed = true
    val pending = queue.toList()
    queue.clear()
    for (update in pending) update.complete(Result.failure(CancellationException("MPV core replaced")))
  }

  private fun enqueue(update: Update) {
    if (closed) {
      update.complete(Result.failure(CancellationException("MPV core replaced")))
      return
    }
    queue.addLast(update)
    drain()
  }

  private fun drain() {
    if (running || closed || queue.isEmpty()) return
    running = true
    val update = queue.first
    val nextBase = update.base ?: base
    val nextEqualizer = update.equalizer ?: equalizer
    apply(combine(nextBase, nextEqualizer)) { outcome ->
      if (closed) return@apply
      if (outcome.isSuccess) {
        base = nextBase
        equalizer = nextEqualizer
      }
      queue.removeFirst()
      running = false
      update.complete(outcome)
      drain()
    }
  }

  companion object {
    fun combine(base: String, equalizer: String): String = listOf(base, equalizer).filter { it.isNotEmpty() }.joinToString(",")
  }
}
