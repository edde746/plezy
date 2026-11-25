package com.edde746.plezy.log

import kotlinx.coroutines.flow.Flow
import kotlin.concurrent.Volatile

/**
 * The logging facade for shared code. Every message and every error's text passes through [Redactor] before a
 * [Sink] sees it, so sinks (console, logcat, OSLog) never receive a transport URL, stream URL or key. Messages are
 * built lazily and skipped below [minLevel]. What passes is kept in memory too ([LogBuffer]), for Settings → View Logs.
 */
object Log {
    enum class Level { DEBUG, INFO, WARN, ERROR }

    /** Receives redacted log records. [error] is the redacted stack trace of the throwable, if any. */
    fun interface Sink {
        fun write(level: Level, tag: String, message: String, error: String?)
    }

    /** Prints to standard output; the default until the app installs its platform sink. */
    val ConsoleSink: Sink = Sink { level, tag, message, error ->
        println("${level.name[0]}/$tag: $message" + if (error != null) "\n$error" else "")
    }

    @Volatile
    var sink: Sink = ConsoleSink

    @Volatile
    var minLevel: Level = Level.INFO

    fun d(tag: String, error: Throwable? = null, message: () -> String) = log(Level.DEBUG, tag, error, message)
    fun i(tag: String, error: Throwable? = null, message: () -> String) = log(Level.INFO, tag, error, message)
    fun w(tag: String, error: Throwable? = null, message: () -> String) = log(Level.WARN, tag, error, message)
    fun e(tag: String, error: Throwable? = null, message: () -> String) = log(Level.ERROR, tag, error, message)

    fun log(level: Level, tag: String, error: Throwable?, message: () -> String) {
        if (level < minLevel) return
        val text = Redactor.redact(message())
        val trace = error?.let { Redactor.redact(it.stackTraceToString()) }
        LogBuffer.append(level, tag, text, trace)
        sink.write(level, tag, text, trace)
    }

    /**
     * Sets [minLevel] from the Debug logging setting ([enabled], `enable_debug_logging`) from its first value on:
     * [Level.DEBUG] while it is on, [Level.INFO] while it is off. Returns only when [enabled] ends.
     */
    suspend fun followDebugLogging(enabled: Flow<Boolean>) {
        enabled.collect { minLevel = if (it) Level.DEBUG else Level.INFO }
    }
}
