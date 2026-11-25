package com.edde746.plezy.app

/**
 * The test builds' crash (Android's CrashTrigger, the desktop harness launcher's `--crash-after`): its message carries
 * [PROBE_URL], a server URL with an API key, which no crash report may hold.
 */
class DevCrashException : IllegalStateException("Crash probe: the request to $PROBE_URL failed") {
    companion object {
        /** The key is made up, 52 capitals and digits; the harness looks for [PROBE_KEY] in what was sent. */
        const val PROBE_KEY = "PLEZYCRASHPROBEABCDEFGHIJKLMNOPQRSTUVWXYZ234567ABC"
        const val PROBE_URL = "https://media.example/library/sections?X-Plex-Token=$PROBE_KEY"
    }
}

/** Apple's debug builds' crash: Swift can't throw a Kotlin exception, so it calls [crash], which throws one. */
object DevCrash {
    fun crash(): Unit = throw DevCrashException()
}
