package com.edde746.plezy.mpv.video

import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.TimeUnit

/**
 * The thread a video plane does all its GL and Wayland work on: jobs posted from any thread run there in order, and
 * between them the plane's own [turn] (dispatching its event queue, presenting) and its [wait] (a poll on the Wayland
 * connection and the wake-up [wake] signals).
 *
 * A job that throws is logged and the loop goes on: one failed render must not stop the plane. [shutdownAndJoin] stops
 * new jobs, lets the queued ones run, and waits a bounded time; a thread still stuck in a job then (a driver call that
 * never returns) is abandoned rather than joined, and the caller leaks what that job might still touch instead of
 * freeing it under it.
 *
 * @param turn the plane's work between jobs; returns how long the next [wait] may last, in ms (-1: until woken).
 */
internal class PlaneLoop(
    name: String,
    private val turn: () -> Int,
    private val wait: (timeoutMs: Int) -> Unit,
    private val wake: () -> Unit,
) {
    private val jobs = ConcurrentLinkedQueue<() -> Unit>()
    @Volatile private var accepting = true
    @Volatile private var stopping = false
    private val log = System.getLogger(PlaneLoop::class.java.name)
    private val thread = Thread(::run, name).apply { isDaemon = true }

    /** Whether the calling thread is the loop's own. */
    val isLoopThread: Boolean get() = Thread.currentThread() === thread

    fun start() = thread.start()

    /** Queues [job] for the loop; false once [shutdownAndJoin] has begun, when it will never run. */
    fun post(job: () -> Unit): Boolean {
        if (!accepting) return false
        jobs += job
        wake()
        return true
    }

    /**
     * Refuses new jobs, runs the queued ones, then ends the loop. True once the thread has finished within
     * [timeoutMs]; false when it is still inside a job, and is left running.
     */
    fun shutdownAndJoin(timeoutMs: Long): Boolean {
        accepting = false
        stopping = true
        wake()
        if (isLoopThread) return true
        thread.join(TimeUnit.MILLISECONDS.toMillis(timeoutMs))
        return !thread.isAlive
    }

    private fun run() {
        while (true) {
            while (true) {
                val job = jobs.poll() ?: break
                try {
                    job()
                } catch (t: Throwable) {
                    log.log(System.Logger.Level.ERROR, "video plane job failed", t)
                }
            }
            if (stopping) return
            val timeout = try {
                turn()
            } catch (t: Throwable) {
                log.log(System.Logger.Level.ERROR, "video plane turn failed", t)
                RETRY_MS
            }
            if (jobs.isEmpty() && !stopping) wait(timeout)
        }
    }

    private companion object {
        /** How long a failed turn waits before the next, so a lasting failure doesn't spin the thread. */
        const val RETRY_MS = 100
    }
}
