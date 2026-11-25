package com.edde746.plezy.playback.mpv

import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.ServerStream
import com.edde746.plezy.playback.resolve.LivePlaylist
import com.edde746.plezy.settings.DeinterlaceMode
import kotlin.math.roundToLong

/**
 * What a [LoadRequest] sets in mpv for its file, one table for every engine. Every engine sets each value as mpv's
 * property right before a plain `loadfile <url> replace`, none as a per-file option of the loadfile: mpv drops a file's
 * per-file options on the files it opens from that file's playlist (an HLS open that fails falls back to the
 * playlist's entries), which would then start at the beginning, without the file's title, demuxer and headers.
 * - The file's own values ([fileProperties]) and its headers ([headerFields]) go on every load, so no file's value
 *   carries into the next.
 * - The decoding and cache options ([decodingOptions]): Android and the desktop write each only when it differs from
 *   mpv's (a `hwdec` write re-creates the playing file's decoder); Apple, whose requests are all async, writes them on
 *   every load, ahead of the loadfile that replaces the playing file.
 *
 * `http-header-fields` is a string list (`,`-separated). mpv unescapes only a backslash directly before the separator,
 * so each item escapes its separators and nothing else (verified against mpv 0.41's parser).
 */
object MpvLoad {
    /**
     * The file's decoding and cache options, from this device's settings ([PlaybackOptions]): a [live] file plays the
     * film mode of the Deinterlacing setting as plain deinterlacing, as broadcasts mix telecined film with sport and
     * news shot at field rate, which inverse telecine makes stutter.
     */
    fun decodingOptions(options: PlaybackOptions, live: Boolean): Map<String, String> = mapOf(
        "hwdec" to options.hwdec,
        "demuxer-max-bytes" to options.demuxerMaxBytes.toString(),
        "demuxer-max-back-bytes" to options.demuxerMaxBackBytes.toString(),
        "deinterlace" to (if (live && options.deinterlace == DeinterlaceMode.FILM) DeinterlaceMode.VIDEO else options.deinterlace).mpvValue,
    )

    /**
     * The file's own values as mpv's properties, every one on every load: its title (`force-media-title`), where it
     * starts (`start`, seconds), the lavf demuxer it opens with instead of probing (`demuxer-lavf-format`) and lavf's
     * options, here the hls demuxer's first segment of a live playlist (`demuxer-lavf-o`, a live rewind's
     * `live_start_index`). Where the request has none, the property's own "unset": `start=none`, an empty string for
     * the others.
     *
     * A live file ([LoadRequest.live]) goes on after a stall only with [LIVE_BUFFER_SECONDS] buffered
     * (`cache-pause-wait`): it arrives at 1×, so mpv's own value (go on at 1 s) rides the live edge with a segment to
     * spare and stalls on every late segment. It starts so too (`cache-pause-initial`) unless it joins its playlist
     * [LivePlaylist.JOIN_SEGMENTS] or more segments before the end ([LoadRequest.liveStartIndex], a reopen): that join
     * reads the hold-back at once and plays from its first frame, where the live window places it. mpv's initial wait
     * counts only what lies past what its decoders have read, which three 2-s segments never fill, so it would wait
     * for the edge to move on and play that much further behind it. A first open (lavf's own join, or a stream that
     * isn't HLS) and a join closer to the end wait. Any other file keeps mpv's values and starts at its first frame.
     *
     * A download mpv reads uncached gets a read-ahead hysteresis ([demuxerHysteresisSecs]); [uncachedRoots] are the
     * engine's roots of such files, [cacheForced] a `cache=yes` line in the user's mpv.conf.
     */
    fun fileProperties(
        request: LoadRequest,
        streamBufferCap: Long = MAX_STREAM_BUFFER_BYTES,
        uncachedRoots: List<String> = emptyList(),
        cacheForced: Boolean = false,
    ): Map<String, String> = linkedMapOf(
        "force-media-title" to request.title.orEmpty(),
        "start" to (request.startSeconds.takeIf { it > 0 }?.let(::seconds) ?: "none"),
        "demuxer-lavf-format" to request.demuxerFormat.orEmpty(),
        "demuxer-lavf-o" to listOfNotNull(
            TRANSCODE_RECONNECT.takeIf { request.server?.transcode == true },
            request.liveStartIndex?.let { "live_start_index=$it" },
        ).joinToString(","),
        "cache-pause-initial" to
            if (request.live && request.liveStartIndex.let { it == null || it > -LivePlaylist.JOIN_SEGMENTS }) "yes" else "no",
        "cache-pause-wait" to if (request.live) LIVE_BUFFER_SECONDS else "1",
        "demuxer-hysteresis-secs" to demuxerHysteresisSecs(request.url, uncachedRoots, cacheForced),
    ) + networkProperties(request.server, streamBufferCap)

    /**
     * mpv's `demuxer-hysteresis-secs` for the file at [url]: half a second for a file mpv reads straight off the
     * device's own storage, with no demuxer cache in front of it (a [url] under one of [uncachedRoots]), else mpv's own
     * 0 (off). Without it the demuxer thread wakes for every packet the decoders take, to keep its one second of
     * read-ahead full (3.5 % of the app's CPU playing a download on a Pixel 7); with it the thread sleeps until half a
     * second is left and reads the next half second in one go. The value is absolute, so it stays off wherever mpv
     * caches (a network stream, or every file under a `cache=yes` line, [cacheForced]): there the read-ahead is the
     * cache, which would drain to half a second before every refill. A `demuxer-hysteresis-secs` line keeps its value
     * ([MpvUserConfig.appWrites]).
     */
    fun demuxerHysteresisSecs(url: String, uncachedRoots: List<String>, cacheForced: Boolean): String =
        if (!cacheForced && uncachedRoots.any(url::startsWith)) "0.5" else "0"

    /**
     * Android's roots of files mpv reads uncached: the app's own data directory (`/data/`). Shared storage (FUSE from
     * Android 11), a document's `content://` and a memory card may have a network or a slow bus behind them, which mpv
     * caches like a stream.
     */
    val ANDROID_UNCACHED_ROOTS: List<String> = listOf("file:///data/")

    /** An iPhone's or iPad's app containers, the only place its downloads live. */
    val IOS_UNCACHED_ROOTS: List<String> = listOf(
        "file:///var/mobile/Containers/Data/Application/",
        "file:///private/var/mobile/Containers/Data/Application/",
    )

    /**
     * How a media server's stream ([server]) is read, every value on every load so no file's carries into the next:
     * - FFmpeg reconnects a dropped stream for up to ten minutes (`stream-lavf-o`), on a 503 too, which a server
     *   answers while it restarts (without it the cut body plays as the file's end); any other HTTP error still fails
     *   at once, so the server's error shows.
     * - A transcode's segments are read by lavf's hls demuxer, past mpv's stream layer and its reconnects: each stalled
     *   read gives up after 20 seconds (`network-timeout`) and the demuxer re-requests the segment (`demuxer-lavf-o`,
     *   in [fileProperties]). Any other file has mpv's 60.
     * - Direct play of a QuickTime file, or of a Matroska one at a high bitrate, reads through a larger ring
     *   (`stream-buffer-size`, [streamBufferBytes]) within [streamBufferCap].
     */
    private fun networkProperties(server: ServerStream?, streamBufferCap: Long): Map<String, String> = linkedMapOf(
        "stream-lavf-o" to if (server != null) STREAM_RECONNECT else "",
        "network-timeout" to if (server?.transcode == true) "20" else "60",
        "stream-buffer-size" to (
            server?.takeIf { !it.transcode }?.let { streamBufferBytes(it.container, it.bitrateKbps, streamBufferCap) } ?: DEFAULT_STREAM_BUFFER_BYTES
            ).toString(),
    )

    /**
     * mpv's `stream-buffer-size` for direct play of [container] at [bitrateKbps], or null where mpv's own 128 KiB
     * does. A QuickTime file (an iPhone's recording) can keep its audio seconds of bytes away from the video beside it,
     * so the demuxer's reads swing back and forth in the file, and over HTTP each swing past the ring is a seek that
     * drops and redials the connection. The ring holds six seconds of the stream (mpv keeps half of it behind, three
     * seconds of skew), rounded up to a power of two, from 16 MiB up to [cap] (at most 128 MiB); a QuickTime file
     * whose bitrate the server doesn't say gets 64 MiB. A Matroska file interleaves well, but a UHD remux from 40 Mb/s
     * on overruns the default ring in the demuxer's bursts.
     */
    fun streamBufferBytes(container: String?, bitrateKbps: Int?, cap: Long = MAX_STREAM_BUFFER_BYTES): Long? {
        val names = container?.lowercase()?.split(',')?.map { it.trim() } ?: return null
        val quickTime = names.any { it in QUICKTIME_CONTAINERS }
        val matroska = names.any { it in MATROSKA_CONTAINERS }
        if (!quickTime && !matroska) return null
        val ceiling = cap.coerceIn(MIN_STREAM_BUFFER_BYTES, MAX_STREAM_BUFFER_BYTES)
        if (bitrateKbps == null || bitrateKbps <= 0) return if (quickTime) minOf(UNKNOWN_BITRATE_STREAM_BUFFER_BYTES, ceiling) else null
        if (!quickTime && bitrateKbps < HIGH_BITRATE_MATROSKA_KBPS) return null
        val wanted = bitrateKbps * 1000L / 8 * STREAM_BUFFER_SECONDS
        var ring = 1L
        while (ring < wanted) ring = ring shl 1
        return ring.coerceIn(MIN_STREAM_BUFFER_BYTES, ceiling)
    }

    /** mpv's own `stream-buffer-size`. */
    const val DEFAULT_STREAM_BUFFER_BYTES = 128L * 1024
    const val MIN_STREAM_BUFFER_BYTES = 16L * 1024 * 1024
    const val MAX_STREAM_BUFFER_BYTES = 128L * 1024 * 1024
    private const val UNKNOWN_BITRATE_STREAM_BUFFER_BYTES = 64L * 1024 * 1024
    private const val STREAM_BUFFER_SECONDS = 6
    private const val HIGH_BITRATE_MATROSKA_KBPS = 40_000
    private val QUICKTIME_CONTAINERS = setOf("mp4", "mov", "m4v", "3gp", "3g2")
    private val MATROSKA_CONTAINERS = setOf("mkv", "matroska", "webm")
    private const val STREAM_RECONNECT =
        "reconnect=1,reconnect_on_network_error=1,reconnect_on_http_error=503,reconnect_streamed=1,reconnect_delay_max=600"
    private const val TRANSCODE_RECONNECT = "reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1"

    /** Three 2-s segments: the hold-back HLS asks of a client (RFC 8216, 6.3.3). */
    private const val LIVE_BUFFER_SECONDS = "6"

    /** [headers] as mpv's `http-header-fields` value, in their order; empty for none, which clears the last file's. */
    fun headerFields(headers: Map<String, String>): String =
        headers.entries.joinToString(STRING_LIST_SEPARATOR) { (name, value) -> "$name: $value".replace(STRING_LIST_SEPARATOR, "\\$STRING_LIST_SEPARATOR") }

    private const val STRING_LIST_SEPARATOR = ","

    /**
     * Android's GL vo surface for an engine whose first file has [contentTransfer] ([ServerStream.colorTransfer]): a
     * BT.2020 PQ surface mpv renders HDR into (`android-surface-colorspace`, `target-trc`, `target-prim`) when that
     * file is PQ or HLG, the display takes HDR ([displayTakesHdr]) and HDR output is on ([hdrOutput]); else none, and
     * the default surface tone-maps HDR to SDR. The video plane carries HDR in its decoder's dataspace and ignores
     * these. The surface's colorspace is fixed as it's made, so the first file decides for the engine's life: a PQ
     * surface shows SDR right, an sRGB one tone-maps HDR as before.
     */
    fun hdrSurfaceOptions(contentTransfer: String?, displayTakesHdr: Boolean, hdrOutput: Boolean): Map<String, String> =
        if (contentTransfer in HDR_TRANSFERS && displayTakesHdr && hdrOutput) {
            mapOf("android-surface-colorspace" to "bt2020-pq", "target-trc" to "pq", "target-prim" to "bt.2020")
        } else {
            emptyMap()
        }

    private val HDR_TRANSFERS = setOf("smpte2084", "arib-std-b67")

    /**
     * Whether mpv refusing the load's value [name] (one of [decodingOptions], [fileProperties] or the headers) refuses
     * the load: every value but where the file starts (`start`), a playback default whose refusal leaves mpv's own (the
     * file's beginning), which the engine only logs before the file opens. A load refused so never replaced the file
     * playing ([MpvLifecycle.keepOutgoing]).
     */
    fun refusalFailsLoad(name: String): Boolean = name != "start"

    /** Positive [value] seconds with three decimals: `61.500`. */
    private fun seconds(value: Double): String {
        val millis = (value * 1000).roundToLong()
        return "${millis / 1000}.${(millis % 1000).toString().padStart(3, '0')}"
    }
}
