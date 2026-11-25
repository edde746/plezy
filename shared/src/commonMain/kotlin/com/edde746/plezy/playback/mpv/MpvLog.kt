package com.edde746.plezy.playback.mpv

import com.edde746.plezy.log.Log

/**
 * mpv's own log lines in the app's log ([Log]: the platform's console, View Logs, uploaded logs), redacted there as
 * every line is: mpv names the URLs it opens, and stream URLs carry keys.
 */
object MpvLog {
    /**
     * The app's level for one of mpv's, by its `mpv_log_level` name (mpv-android spells `v` out as `verbose`): fatal
     * and error are errors, warn a warning, info and verbose info, debug and trace (and a name mpv adds later) debug.
     */
    fun level(mpvLevel: String): Log.Level = when (mpvLevel.lowercase()) {
        "fatal", "error" -> Log.Level.ERROR
        "warn" -> Log.Level.WARN
        "info", "v", "verbose" -> Log.Level.INFO
        else -> Log.Level.DEBUG
    }

    /** Writes [text], a line of mpv's module [prefix] at [level], as `[prefix] text`. */
    fun write(level: Log.Level, prefix: String, text: String) = Log.log(level, TAG, null) { "[$prefix] ${text.trimEnd()}" }

    private const val TAG = "mpv"
}
