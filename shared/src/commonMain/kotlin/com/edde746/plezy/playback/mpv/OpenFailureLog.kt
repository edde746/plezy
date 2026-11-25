package com.edde746.plezy.playback.mpv

/** Why an open fails early for a line mpv logged ([OpenFailureLog.cause]). */
enum class OpenFailureCause {
    /** The audio device wouldn't open: always fatal, the stream can't help. */
    AUDIO_OUTPUT,

    /** A stream's decoder, filter chain or output couldn't start: the open never shows a frame. */
    STREAM_INIT,
}

/**
 * The mpv log lines that end an open early. mpv gives up a stream whose chain failed (`error_on_track`) but, with the
 * other stream alive, keeps the file going without an end-file: these lines are the only early sign, and without them
 * the open waits out its deadline. Exact matches only, so nothing mpv recovers from on its own counts: not a filter it
 * bypassed ("Disabling filter …"), not one hardware decoder's probe ("Could not open codec."), not HTTP status lines
 * (the 503 watchdog and the status latch have those).
 */
object OpenFailureLog {
    private const val AUDIO_OUTPUT_FAILED = "Could not open/initialize audio device -> no sound."
    private const val VIDEO_CHAIN_FAILED = "Could not initialize video chain."
    private const val OUTPUT_CONVERSION_FAILED = "Cannot convert decoder/filter output to any format supported by the output."
    private const val DECODER_INIT_FAILED = "Failed to initialize a decoder for codec"
    private const val LAVFI_RUN_FAILED = "error on filtering ("
    private val STREAM_INIT_FAILED = setOf(
        "Audio filter initialized failed!",
        "Error reinitializing audio.",
        "Error opening/initializing the selected video_out (--vo) device.",
    )

    /** A libav protocol's line ("https: …", "tcp: …"), for an engine that doesn't pass mpv's prefix. */
    private val PROTOCOL_LINE = Regex("""^(https?|tls|tcp|udp|crypto): """)

    /**
     * The cause an open fails with for one log line: [error] for mpv's error and fatal levels (nothing below counts),
     * [prefix] mpv's module prefix. The output conversion line fails only the audio chain (`af`): on the video chain mpv
     * first falls back to software decoding and logs the video chain line itself if that fails too. The libavfilter
     * line ("error on filtering (-12)") counts under its own prefix (`lavfi`) only.
     */
    fun cause(error: Boolean, prefix: String, text: String): OpenFailureCause? {
        if (!error) return null
        val line = text.trim()
        return when {
            line == AUDIO_OUTPUT_FAILED -> OpenFailureCause.AUDIO_OUTPUT
            line == VIDEO_CHAIN_FAILED -> OpenFailureCause.STREAM_INIT
            line == OUTPUT_CONVERSION_FAILED -> OpenFailureCause.STREAM_INIT.takeIf { prefix == "af" }
            line in STREAM_INIT_FAILED || line.startsWith(DECODER_INIT_FAILED) -> OpenFailureCause.STREAM_INIT
            prefix == "lavfi" && line.startsWith(LAVFI_RUN_FAILED) -> OpenFailureCause.STREAM_INIT
            else -> null
        }
    }

    /**
     * Whether a line is the stream's transport reporting a fault: libav's protocols (`https`, `tls`, `tcp`) log under
     * mpv's bare `ffmpeg` prefix, at warning level or worse ([warning]); decoders and demuxers log under
     * `ffmpeg/video`, `ffmpeg/demuxer`…, where warnings are routine mid-file. Without a [prefix] (an engine that doesn't
     * pass mpv's), the protocol's name at the start of the line tells.
     */
    fun isTransportFault(warning: Boolean, prefix: String, text: String): Boolean {
        if (!warning) return false
        return if (prefix.isEmpty()) PROTOCOL_LINE.containsMatchIn(text) else prefix == "ffmpeg"
    }
}
