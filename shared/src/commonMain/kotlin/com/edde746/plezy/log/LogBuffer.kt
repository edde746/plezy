package com.edde746.plezy.log

import kotlin.time.Clock
import kotlinx.atomicfu.locks.SynchronizedObject
import kotlinx.atomicfu.locks.synchronized

/**
 * The last records [Log] wrote this run, in memory only, for Settings → View Logs: oldest first, the oldest dropped
 * once their text passes [MAX_BYTES]. Every record [Log] lets through lands here as well as in its sink, already
 * redacted. Safe from any thread.
 */
object LogBuffer {
    /** One record: when (epoch ms), how severe, from where, and its error's stack trace. */
    data class Entry(val epochMillis: Long, val level: Log.Level, val tag: String, val message: String, val error: String?) {
        /** About how much memory it takes, which [MAX_BYTES] counts: its text at two bytes a character, plus 12. */
        internal val size: Int get() = 12 + 2 * (tag.length + message.length + (error?.length ?: 0))
    }

    /** What the buffer keeps, by [Entry.size]: 5 MiB. */
    const val MAX_BYTES: Int = 5 * 1024 * 1024

    private val lock = SynchronizedObject()
    private val entries = ArrayDeque<Entry>()
    private var size = 0

    /** The records kept, oldest first. */
    fun snapshot(): List<Entry> = synchronized(lock) { entries.toList() }

    /** Forgets every record kept. */
    fun clear() {
        synchronized(lock) {
            entries.clear()
            size = 0
        }
    }

    internal fun append(level: Log.Level, tag: String, message: String, error: String?) {
        val entry = Entry(Clock.System.now().toEpochMilliseconds(), level, tag, message, error)
        synchronized(lock) {
            entries.addLast(entry)
            size += entry.size
            while (size > MAX_BYTES && entries.size > 1) size -= entries.removeFirst().size
        }
    }
}
