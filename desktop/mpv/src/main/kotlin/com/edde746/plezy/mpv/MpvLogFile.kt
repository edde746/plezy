package com.edde746.plezy.mpv

import com.edde746.plezy.log.Redactor
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.ffi.MpvFfi
import com.edde746.plezy.mpv.ffi.mpv_event
import com.edde746.plezy.mpv.ffi.mpv_event_log_message
import com.edde746.plezy.mpv.os.utf8
import java.io.IOException
import java.io.Writer
import java.nio.file.Files
import java.nio.file.Path
import java.util.Locale

/**
 * [MpvEngineOptions.logFile]: mpv's log at the debug level and in the form of mpv's own `log-file` (`[seconds][level
 * letter][prefix] text`), every line redacted ([Redactor]), since mpv names the links it opens and they carry account
 * keys. A weak client of its own, read on a thread of its own, so the engine's client gets its events and warnings as it
 * does without the file (mpv hands out a client's events before its log messages: a backlog of debug lines there would
 * hold a failed open's HTTP status back until after its end-file), and the core never lives on for it.
 */
internal object MpvLogFile {
    private val log = System.getLogger(MpvLogFile::class.java.name)

    /**
     * Starts writing [core]'s log to [path], truncated, from now to the core's end. [core] is initialized (mpv takes
     * clients only then), so mpv's lines from before, its start-up, are not in the file. A file that can't be opened,
     * or a client mpv refuses, is logged and left out.
     */
    fun start(core: MpvCore, path: Path) {
        val out = try {
            Files.newBufferedWriter(path)
        } catch (e: IOException) {
            log.log(System.Logger.Level.WARNING, "mpv log file {0}: {1}", path, e.message)
            return
        }
        val client = try {
            core.createWeakClient("log")
        } catch (e: IllegalStateException) {
            log.log(System.Logger.Level.WARNING, "mpv log file {0}: {1}", path, e.message)
            close(out)
            return
        }
        try {
            client.requestLogMessages("debug")
        } catch (e: IllegalStateException) {
            log.log(System.Logger.Level.WARNING, "mpv log file {0}: {1}", path, e.message)
            client.destroy()
            close(out)
            return
        }
        Thread({ write(client, out) }, "mpv-log").apply { isDaemon = true; start() }
    }

    /** Each log message as a line until the core shuts down; then the client is destroyed and the file closed. */
    private fun write(client: MpvCore, out: Writer) {
        val started = System.nanoTime()
        var file: Writer? = out
        var shutdown = false
        try {
            while (true) {
                // After MPV_EVENT_SHUTDOWN, the lines still queued behind it, until there is none.
                val ev = client.waitEvent(if (shutdown) 0.0 else -1.0)
                when (mpv_event.event_id(ev)) {
                    MpvFfi.MPV_EVENT_LOG_MESSAGE() -> if (file != null) {
                        val m = mpv_event.data(ev)
                        val seconds = (System.nanoTime() - started) / 1e9
                        val level = mpv_event_log_message.level(m).utf8()?.take(1)
                        val prefix = mpv_event_log_message.prefix(m).utf8()
                        val text = Redactor.redact(mpv_event_log_message.text(m).utf8().orEmpty().trimEnd())
                        try {
                            file.write(String.format(Locale.ROOT, "[%8.3f][%s][%s] %s\n", seconds, level, prefix, text))
                            file.flush()
                        } catch (e: IOException) {
                            log.log(System.Logger.Level.WARNING, "mpv log file: {0}", e.message)
                            close(file)
                            file = null
                        }
                    }
                    MpvFfi.MPV_EVENT_SHUTDOWN() -> {
                        if (shutdown) break
                        shutdown = true
                    }
                    else -> if (shutdown) break
                }
            }
        } finally {
            client.destroy()
            file?.let(::close)
        }
    }

    private fun close(file: Writer) {
        try {
            file.close()
        } catch (e: IOException) {
            log.log(System.Logger.Level.WARNING, "mpv log file: {0}", e.message)
        }
    }
}
