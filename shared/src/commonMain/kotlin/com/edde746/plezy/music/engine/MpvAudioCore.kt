package com.edde746.plezy.music.engine

/**
 * One dedicated libmpv handle for one [MpvAudioPlayer], never the video engine's: the thin platform side (Android's
 * mpv-android, the desktop's FFM bindings, MPVKit on Apple), so every rule of the audio player lives once, in
 * [MpvAudioPlayer]. Requests reach mpv in call order; their answers and the [MpvAudioCoreListener] calls may come on
 * any thread, the listener's in mpv's order.
 */
interface MpvAudioCore {
    /**
     * Creates and initializes the handle with [options] (mpv's startup options), observes each of [observed] as its
     * string value, and from then on reports to [listener]. Null once started, else mpv's reason (no handle then).
     */
    fun start(options: Map<String, String>, observed: List<String>, listener: MpvAudioCoreListener): String?

    /** `mpv_command` [args]; [done] gets null when mpv accepted it, else mpv's reason. */
    fun command(args: List<String>, done: (String?) -> Unit)

    /** Writes [name] as a string; [done] gets null when mpv accepted it, else mpv's reason. */
    fun setProperty(name: String, value: String, done: (String?) -> Unit)

    /** Reads [name] as a string: [done] gets its value (null when mpv has none) and null, or null and mpv's reason. */
    fun getProperty(name: String, done: (String?, String?) -> Unit)

    /** mpv's log lines from [level] (`v`, `warn`) up go to the platform's log. */
    fun setLogLevel(level: String)

    /** Ends the handle after every earlier request; the listener hears nothing after. */
    fun destroy()
}

/** What an [MpvAudioCore] reports, in mpv's order. */
interface MpvAudioCoreListener {
    /** An observed property changed: its string value, or null while mpv has none. */
    fun onProperty(name: String, value: String?)

    /** mpv's `file-loaded`: an entry of the playlist started. */
    fun onFileLoaded()

    /** mpv's `end-file`; [error] is mpv's reason when the entry failed, else null. */
    fun onEndFile(error: String?)
}

/**
 * Android's `content://` documents as file descriptors mpv opens itself (`fdclose://<fd>`): mpv cannot open a
 * `content://` URI, and it closes an `fdclose://` descriptor once it opened the entry.
 */
interface ContentFds {
    /** A detached descriptor of [uri] for reading; throws when the document doesn't open. */
    fun open(uri: String): Int

    /** Closes a descriptor from [open] that mpv never opened. */
    fun close(fd: Int)
}
