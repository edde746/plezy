package com.edde746.plezy.plex

import com.edde746.plezy.net.UriComponent
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/** What a transcode decision allows. */
enum class TranscodeDecisionOutcome { TRANSCODE_OK, DIRECT_PLAY_ONLY, FAILED }

/**
 * Plex's universal transcoder protocol: the decision and start parameters, the client profile, the start path and the
 * reading of the decision. Pure: the client runs the requests.
 */
object PlexTranscode {
    const val VIDEO_START_ENDPOINT = "/video/:/transcode/universal/start.m3u8"
    const val VIDEO_PING_ENDPOINT = "/video/:/transcode/universal/ping"
    const val MUSIC_START_ENDPOINT = "/music/:/transcode/universal/start.mp3"

    /** Containers a VOD decision must echo back: fMP4 for the primary target, MPEG-TS for the fallback. */
    const val VOD_CONTAINER = "mp4"
    const val VOD_TS_CONTAINER = "mpegts"

    /**
     * The only platform name PMS accepts on the decision endpoint for an arbitrary client: `MacOSX`, `Mac` and
     * `Linux` get HTTP 400. `Generic` brings no transcode targets; the profile extra adds ours.
     */
    const val PLATFORM = "Generic"

    private const val AUDIO_CODECS = "aac%2Cac3%2Ceac3%2Cmp3"

    /**
     * VOD target: HLS with fMP4 segments offering the device's ranked transcode codecs. HEVC must never go into an
     * MPEG-TS target: PMS's HEVC encode → TS segmenter emits parameter sets mpv rejects ("PPS changed between slices").
     */
    fun vodVideoTarget(videoCodecIds: List<String>): String =
        "add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mp4" +
            "&videoCodec=${videoCodecIds.joinToString("%2C")}&audioCodec=$AUDIO_CODECS)"

    /** Fallback for a server that ignores the fMP4 container: H.264-only MPEG-TS. */
    const val VOD_TS_VIDEO_TARGET =
        "add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts&videoCodec=h264" +
            "&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)"

    /**
     * Live TV target at Original quality: MPEG-TS with the broadcast codecs. A tuned channel is mostly copied (TS to TS),
     * and HEVC or MPEG-2 *copied* into TS plays clean, so this keeps H.264 first and stays on TS. HEVC is offered only
     * when the device decodes it ([acceptsHevc]); a capped live preset can force an encode and takes
     * [VOD_TS_VIDEO_TARGET] instead, which has no HEVC.
     */
    fun liveVideoTarget(acceptsHevc: Boolean): String =
        "add-transcode-target(type=videoProfile&context=streaming&protocol=hls&container=mpegts" +
            "&videoCodec=h264${if (acceptsHevc) "%2Chevc" else ""}%2Cmpeg2video&audioCodec=$AUDIO_CODECS)"

    const val SUBTITLE_TARGET =
        "add-transcode-target(type=subtitleProfile&context=streaming&protocol=hls&container=webvtt&subtitleCodec=webvtt)"

    /** Without a musicProfile target PMS rejects the decision with code 4005. */
    const val MUSIC_PROFILE_EXTRA =
        "add-transcode-target(type=musicProfile&context=streaming&protocol=http&container=mp3&audioCodec=mp3)"

    fun clientProfileExtra(videoTarget: String, maxVideoBitrateKbps: Int?): String = buildList {
        add("add-settings(DirectPlayStreamSelection=true)")
        if (maxVideoBitrateKbps != null) {
            add(
                "add-limitation(scope=videoCodec&scopeName=*&type=upperBound&name=video.bitrate" +
                    "&value=$maxVideoBitrateKbps&replace=true)",
            )
        }
        add(videoTarget)
        add(SUBTITLE_TARGET)
    }.joinToString("+")

    /** Identity every decision and start request carries. Device, device name and token only when known. */
    fun clientParams(config: PlexConfig): Map<String, String> = buildMap {
        put("X-Plex-Product", config.product)
        put("X-Plex-Version", config.version)
        put("X-Plex-Client-Identifier", config.clientIdentifier)
        put("X-Plex-Platform", PLATFORM)
        config.device?.let { put("X-Plex-Device", it) }
        config.deviceName?.let { put("X-Plex-Device-Name", it) }
        config.token?.let { put("X-Plex-Token", it) }
    }

    /**
     * Video decision/start parameters, in wire order. No `offset`: the player seeks in-band, and pre-warming the
     * transcoder at the resume point made PMS leave a racing segment open (endless buffering).
     *
     * - [burnSubtitle]: a burn is a re-encode, so it forces `directPlay=0` (PMS answers HTTP 400 to both at once).
     * - [withholdDirectPlay]: a refused source codec or a file the server refused (HTTP 500) also forces it.
     * - [maxVideoBitrateKbps], [videoResolution] and [videoQuality] are the preset's caps, all null for Original.
     */
    fun videoParams(
        config: PlexConfig,
        ratingKey: String,
        mediaIndex: Int,
        partIndex: Int = 0,
        isOriginal: Boolean,
        maxVideoBitrateKbps: Int?,
        videoResolution: String?,
        videoQuality: Int?,
        sessionIdentifier: String,
        transcodeSessionId: String,
        transcodeVideoCodecIds: List<String>,
        audioStreamId: Int? = null,
        burnSubtitle: Boolean = false,
        useTsFallbackTarget: Boolean = false,
        withholdDirectPlay: Boolean = false,
    ): Map<String, String> {
        val profileExtra = clientProfileExtra(
            videoTarget = if (useTsFallbackTarget) VOD_TS_VIDEO_TARGET else vodVideoTarget(transcodeVideoCodecIds),
            maxVideoBitrateKbps = if (isOriginal) null else maxVideoBitrateKbps,
        )
        return buildMap {
            put("hasMDE", "1")
            put("path", "/library/metadata/$ratingKey")
            put("mediaIndex", mediaIndex.toString())
            put("partIndex", partIndex.toString())
            put("protocol", "hls")
            put("fastSeek", "1")
            put("directPlay", if (!burnSubtitle && isOriginal && !withholdDirectPlay) "1" else "0")
            put("directStream", if (isOriginal) "1" else "0")
            put("subtitleSize", "100")
            put("audioBoost", "100")
            put("location", "lan")
            put("addDebugOverlay", "0")
            put("autoAdjustQuality", "0")
            videoResolution?.let { put("videoResolution", it) }
            videoQuality?.let { put("videoQuality", it.toString()) }
            put("directStreamAudio", "1")
            put("mediaBufferSize", "102400")
            put("session", transcodeSessionId)
            put("subtitles", if (burnSubtitle) "burn" else "none")
            audioStreamId?.let { put("audioStreamID", it.toString()) }
            put("Accept-Language", "en")
            put("X-Plex-Session-Identifier", sessionIdentifier)
            put("X-Plex-Client-Profile-Extra", profileExtra)
            put("X-Plex-Incomplete-Segments", "1")
            put("X-Plex-Features", "external-media,indirect-media")
            put("X-Plex-Model", "standalone")
            put("X-Plex-Language", "en")
            put("X-Plex-Client-Profile-Name", "Generic")
            putAll(clientParams(config))
        }
    }

    /** Music decision/start parameters: HTTP MP3, no video or subtitle params; no bitrate for Original. */
    fun musicParams(
        config: PlexConfig,
        ratingKey: String,
        mediaIndex: Int,
        partIndex: Int = 0,
        bitrateKbps: Int?,
        sessionIdentifier: String,
        transcodeSessionId: String,
    ): Map<String, String> = buildMap {
        put("hasMDE", "1")
        put("path", "/library/metadata/$ratingKey")
        put("mediaIndex", mediaIndex.toString())
        put("partIndex", partIndex.toString())
        put("protocol", "http")
        put("directPlay", "0")
        put("directStream", "0")
        bitrateKbps?.let { put("musicBitrate", it.toString()) }
        put("session", transcodeSessionId)
        put("X-Plex-Session-Identifier", sessionIdentifier)
        put("X-Plex-Client-Profile-Extra", MUSIC_PROFILE_EXTRA)
        putAll(clientParams(config))
    }

    /** The decision endpoint beside [startEndpoint]: its path up to the last `/`, plus `/decision`. */
    fun decisionEndpoint(startEndpoint: String): String = startEndpoint.substring(0, startEndpoint.lastIndexOf('/')) + "/decision"

    /**
     * `endpoint?query` of [params] without the token, every key and value [plexEncode]d. The caller makes it
     * absolute and appends the token.
     */
    fun startPath(params: Map<String, String>, endpoint: String = VIDEO_START_ENDPOINT): String =
        endpoint + "?" + params.entries.filter { it.key != "X-Plex-Token" }
            .joinToString("&") { "${plexEncode(it.key)}=${plexEncode(it.value)}" }

    /** Plex Web's strict encoder: `encodeURIComponent` plus `(` `)` `*` `'` `!`. */
    fun plexEncode(value: String): String = UriComponent.encode(value)
        .replace("(", "%28").replace(")", "%29").replace("*", "%2A").replace("'", "%27").replace("!", "%21")

    /**
     * Reads a decision body (`MediaContainer`, or the body itself): any decision code ≥ 2000 fails; Original converts;
     * otherwise transcode 1000 / general 1000 mean direct play only and anything else converts.
     */
    fun parseDecisionOutcome(data: JsonElement?, isOriginal: Boolean): TranscodeDecisionOutcome {
        val container = data.mediaContainer() ?: (data as? JsonObject) ?: return TranscodeDecisionOutcome.FAILED
        val general = container["generalDecisionCode"].flexInt()
        val transcode = container["transcodeDecisionCode"].flexInt()
        val mde = container["mdeDecisionCode"].flexInt()
        if (listOf(general, transcode, mde).any { it != null && it >= 2000 }) return TranscodeDecisionOutcome.FAILED
        if (isOriginal) return TranscodeDecisionOutcome.TRANSCODE_OK
        return when {
            transcode == 1000 -> TranscodeDecisionOutcome.DIRECT_PLAY_ONLY
            transcode == 1001 -> TranscodeDecisionOutcome.TRANSCODE_OK
            general == 1001 -> TranscodeDecisionOutcome.TRANSCODE_OK
            general == 1000 -> TranscodeDecisionOutcome.DIRECT_PLAY_ONLY
            else -> TranscodeDecisionOutcome.TRANSCODE_OK
        }
    }

    /** The container of the decision's selected media entry, or null when it names none. */
    fun decisionSelectedContainer(data: JsonElement?): String? =
        data.mediaContainer()?.get("Metadata").firstObject()?.get("Media").firstObject()?.get("container").scalarString()
}
