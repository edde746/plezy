package com.edde746.plezy.mpv

import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.mpv.ffi.mpv_event
import com.edde746.plezy.mpv.ffi.mpv_event_end_file
import com.edde746.plezy.mpv.ffi.mpv_event_log_message
import com.edde746.plezy.mpv.ffi.mpv_event_property
import com.edde746.plezy.mpv.os.utf8
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.music.engine.MpvAudioCore
import com.edde746.plezy.music.engine.MpvAudioCoreListener
import com.edde746.plezy.music.engine.MpvAudioPlayer
import com.edde746.plezy.playback.mpv.MpvLog
import java.lang.foreign.MemorySegment
import java.lang.foreign.ValueLayout
import java.util.concurrent.CompletableFuture
import java.util.concurrent.LinkedBlockingQueue

/**
 * The music player on Windows and Linux: a dedicated audio-only mpv (its own handle, no window, never a video
 * engine's) on mpv's default audio output. [extraOptions] come last (a test run's `mute=yes`).
 */
fun desktopAudioPlayer(extraOptions: Map<String, String> = emptyMap()): AudioPlayer =
    MpvAudioPlayer(DesktopMpvAudioCore(), platformOptions = extraOptions)

/**
 * [MpvAudioCore] over the FFM bindings ([MpvCore]). One `mpv-audio` thread owns the handle: it runs the queued
 * requests in order, then waits for mpv's events (woken by `mpv_wakeup`), and answers and reports from there.
 * [destroy] ends the thread and terminates the handle on a throwaway thread, since that can block on network teardown.
 */
internal class DesktopMpvAudioCore : MpvAudioCore {
    private val requests = LinkedBlockingQueue<Request>()
    private val coreLock = Any()
    private val log = System.getLogger(DesktopMpvAudioCore::class.java.name)

    // Thread-confined, but [core] is also read under [coreLock] to wake the thread.
    private var core: MpvCore? = null
    private var listener: MpvAudioCoreListener? = null
    private var observed: List<String> = emptyList()
    @Volatile private var stopped = false

    private val thread = Thread(::run, "mpv-audio").apply { isDaemon = true; start() }

    override fun start(options: Map<String, String>, observed: List<String>, listener: MpvAudioCoreListener): String? {
        val result = CompletableFuture<String?>()
        post({ result.complete("the audio core is gone") }) {
            result.complete(
                try {
                    val c = MpvCore.create(options) { c ->
                        for ((i, name) in observed.withIndex()) c.observe(i.toLong(), name, MpvFfi.MPV_FORMAT_STRING())
                        c.requestLogMessages("warn")
                    }
                    this.observed = observed
                    this.listener = listener
                    synchronized(coreLock) { core = c }
                    null
                } catch (t: Throwable) {
                    log.log(System.Logger.Level.ERROR, "mpv audio core failed to start", t)
                    t.message ?: t.toString()
                },
            )
        }
        return result.get()
    }

    override fun command(args: List<String>, done: (String?) -> Unit) =
        request(done) { reason(it.command(*args.toTypedArray())) }

    override fun setProperty(name: String, value: String, done: (String?) -> Unit) =
        request(done) { reason(it.setString(name, value)) }

    override fun getProperty(name: String, done: (String?, String?) -> Unit) {
        post({ done(null, "the audio core is gone") }) {
            val c = core ?: return@post done(null, "the audio core is gone")
            done(c.getString(name), null)
        }
    }

    override fun setLogLevel(level: String) {
        post({}) { core?.requestLogMessages(level) }
    }

    override fun destroy() {
        post({}) {
            stopped = true
            listener = null
            val c = core ?: return@post
            synchronized(coreLock) { core = null }
            Thread({ c.terminateDestroy() }, "mpv-audio-terminate").apply { isDaemon = true; start() }
        }
    }

    private fun request(done: (String?) -> Unit, block: (MpvCore) -> String?) {
        post({ done("the audio core is gone") }) {
            val c = core ?: return@post done("the audio core is gone")
            done(block(c))
        }
    }

    private fun reason(rc: Int): String? = if (rc < 0) MpvCore.errorString(rc) else null

    /** A queued [block], and what answers its caller instead when the thread ends before running it. */
    private class Request(val rejected: () -> Unit, val block: () -> Unit)

    private fun post(rejected: () -> Unit, block: () -> Unit) {
        if (stopped) return rejected()
        val request = Request(rejected, block)
        requests.add(request)
        // The thread may have ended between the check and the add: then it is this call's to reject, unless the
        // thread's last drain took it.
        if (stopped && requests.remove(request)) return rejected()
        synchronized(coreLock) { core?.wakeup() }
    }

    private fun run() {
        while (!stopped) {
            val c = core
            if (c == null) {
                guarded(requests.take().block)
                continue
            }
            while (!stopped) guarded((requests.poll() ?: break).block)
            if (stopped || core == null) continue
            guarded { handle(c.waitEvent(-1.0)) }
        }
        // What came after the destroy finds the core gone.
        while (true) guarded((requests.poll() ?: break).rejected)
    }

    private inline fun guarded(block: () -> Unit) {
        try {
            block()
        } catch (t: Throwable) {
            log.log(System.Logger.Level.ERROR, "mpv audio core: a request or report failed", t)
        }
    }

    private fun handle(event: MemorySegment) {
        val listener = listener ?: return
        when (mpv_event.event_id(event)) {
            MpvFfi.MPV_EVENT_PROPERTY_CHANGE() -> {
                val name = observed.getOrNull(mpv_event.reply_userdata(event).toInt()) ?: return
                val property = mpv_event.data(event)
                val data = mpv_event_property.data(property)
                val value = if (mpv_event_property.format(property) == MpvFfi.MPV_FORMAT_STRING() && data.address() != 0L) {
                    data.get(ValueLayout.ADDRESS, 0).utf8()
                } else {
                    null
                }
                listener.onProperty(name, value)
            }
            MpvFfi.MPV_EVENT_FILE_LOADED() -> listener.onFileLoaded()
            MpvFfi.MPV_EVENT_END_FILE() -> {
                val end = mpv_event.data(event)
                val failed = mpv_event_end_file.reason(end) == MpvFfi.MPV_END_FILE_REASON_ERROR()
                listener.onEndFile(if (failed) MpvCore.errorString(mpv_event_end_file.error(end)) else null)
            }
            MpvFfi.MPV_EVENT_LOG_MESSAGE() -> {
                val m = mpv_event.data(event)
                val level = MpvLog.level(mpv_event_log_message.level(m).utf8().orEmpty())
                MpvLog.write(level, mpv_event_log_message.prefix(m).utf8().orEmpty(), mpv_event_log_message.text(m).utf8().orEmpty())
            }
        }
    }
}
