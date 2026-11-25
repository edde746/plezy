package com.edde746.plezy.desktop.discord

import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.player.DiscordActivity
import com.edde746.plezy.presentation.player.DiscordPresenceHost
import com.edde746.plezy.presentation.player.DiscordRpc
import java.io.IOException
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Discord's Rich Presence on Windows and Linux ([DiscordPresenceHost]): the connection to the Discord app runs on a
 * thread of its own, started at the first activity, so nothing the app's main thread or the player does waits for
 * Discord. Only the newest activity counts: while one is being sent, later ones replace each other.
 *
 * While there is an activity to show, the thread stays connected: when Discord isn't running (or [open] finds no
 * endpoint it answers on) it tries again every [retry], and when Discord quits it notices within [poll] and connects
 * again, sending the activity anew. Without one it takes the activity down and disconnects. Each kind of failure is
 * logged once until the next connection, so Discord missing for hours writes one line.
 *
 * @param applicationId the Discord application the activity shows as, which each handshake names.
 * @param open the first endpoint Discord answers on ([openDiscordPipe]), or null.
 */
internal class DesktopDiscordPresence(
    private val applicationId: String,
    private val open: () -> DiscordPipe?,
    private val retry: Duration = 30.seconds,
    private val poll: Duration = 1.seconds,
    private val answerTimeout: Duration = 5.seconds,
    private val pid: Long = ProcessHandle.current().pid(),
) : DiscordPresenceHost, AutoCloseable {
    @Volatile private var wanted: DiscordActivity? = null

    @Volatile private var closed = false

    /** Wakes the thread when [wanted] changes or the app closes. */
    private val wake = ArrayBlockingQueue<Unit>(1)
    private var thread: Thread? = null

    override fun publish(activity: DiscordActivity?) {
        wanted = activity
        synchronized(this) {
            if (thread == null && activity != null && !closed) {
                thread = Thread(::run, "discord-presence").apply {
                    isDaemon = true
                    start()
                }
            }
        }
        wake.offer(Unit)
    }

    /** The app closes: the thread disconnects, and Discord takes the activity down with the connection. */
    override fun close() {
        closed = true
        wanted = null
        wake.offer(Unit)
    }

    private fun run() {
        var connection: Connection? = null
        var logged: String? = null
        fun note(problem: String) {
            if (problem != logged) Log.i(TAG) { problem }
            logged = problem
        }
        while (!closed) {
            val target = wanted
            if (target == null) {
                connection?.end()
                connection = null
                wake.take()
                continue
            }
            val live = connection ?: when (val opened = connect()) {
                is Connected -> opened.connection.also {
                    connection = it
                    if (logged != null) Log.i(TAG) { "connected to Discord" }
                    logged = null
                }
                is Failed -> {
                    note(opened.problem)
                    wake.poll(retry.inWholeMilliseconds, TimeUnit.MILLISECONDS)
                    continue
                }
            }
            try {
                if (target != live.shown) live.show(target)
                wake.poll(poll.inWholeMilliseconds, TimeUnit.MILLISECONDS)
                live.drain()
            } catch (e: IOException) {
                note("the connection to Discord ended: ${e.message}")
                live.pipe.close()
                connection = null
            }
        }
        connection?.pipe?.close()
    }

    private sealed interface Opened

    private class Connected(val connection: Connection) : Opened

    private class Failed(val problem: String) : Opened

    /** A pipe to Discord, after its handshake: READY within [answerTimeout], or a failure saying why not. */
    private fun connect(): Opened {
        val pipe = open() ?: return Failed("Discord isn't running (no IPC endpoint answers)")
        val connection = Connection(pipe)
        return try {
            pipe.write(DiscordFrame(DiscordRpc.OP_HANDSHAKE, DiscordRpc.handshake(applicationId)).encode())
            val deadline = System.nanoTime() + answerTimeout.inWholeNanoseconds
            while (!connection.awaitReady()) {
                if (System.nanoTime() > deadline) throw IOException("Discord didn't answer the handshake within $answerTimeout")
                Thread.sleep(HANDSHAKE_POLL_MILLIS)
            }
            Connected(connection)
        } catch (e: IOException) {
            pipe.close()
            Failed("Discord refused the connection: ${e.message}")
        }
    }

    /** One connection to Discord and what it shows of this app. */
    private inner class Connection(val pipe: DiscordPipe) {
        private val reader = DiscordFrameReader()
        private val buffer = ByteArray(READ_BYTES)
        private var nonce = 0L
        private var ready = false

        /** The activity Discord was last sent, or null. */
        var shown: DiscordActivity? = null
            private set

        fun show(activity: DiscordActivity?) {
            pipe.write(DiscordFrame(DiscordRpc.OP_FRAME, DiscordRpc.setActivity(activity, pid, (++nonce).toString())).encode())
            shown = activity
        }

        /** Reads what Discord sent: true once its READY has come. */
        fun awaitReady(): Boolean {
            drain()
            return ready
        }

        /** Handles what Discord sent: answers its pings, logs its errors; throws [IOException] once it has closed. */
        fun drain() {
            while (true) {
                val count = pipe.read(buffer)
                if (count == 0) return
                for (frame in reader.add(buffer, count)) {
                    when (frame.op) {
                        DiscordRpc.OP_PING -> pipe.write(DiscordFrame(DiscordRpc.OP_PONG, frame.json).encode())
                        DiscordRpc.OP_CLOSE -> throw IOException(DiscordRpc.errorOf(frame.json) ?: "Discord closed it")
                        DiscordRpc.OP_FRAME -> when {
                            DiscordRpc.isReady(frame.json) -> ready = true
                            else -> DiscordRpc.errorOf(frame.json)?.let { error -> Log.w(TAG) { "Discord refused an update: $error" } }
                        }
                    }
                }
            }
        }

        /** Takes the activity down, then disconnects; a Discord already gone takes it down itself. */
        fun end() {
            try {
                if (shown != null) show(null)
            } catch (e: IOException) {
                Log.d(TAG) { "Discord had gone before the activity was taken down: ${e.message}" }
            }
            pipe.close()
        }
    }

    companion object {
        private const val TAG = "DiscordPresence"
        private const val READ_BYTES = 8192
        private const val HANDSHAKE_POLL_MILLIS = 20L

        /** The presence as the Discord application [applicationId] over this computer's endpoints ([discordEndpoints]). */
        fun system(windows: Boolean, applicationId: String): DesktopDiscordPresence {
            val endpoints = discordEndpoints(windows, System.getenv())
            return DesktopDiscordPresence(applicationId, { openDiscordPipe(windows, endpoints) })
        }
    }
}
