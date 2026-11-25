package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The decoders this device advertises: HEVC and AV1 only when the native decode probe accepts them and the user hasn't
 * refused them. H.264 is always accepted.
 */
data class VideoCodecSupport(val hevc: Boolean = true, val av1: Boolean = true) {
    /** Transcode output preference, best first: av1, hevc, h264, each only when accepted. */
    val transcodeCodecs: List<String> get() = listOfNotNull("av1".takeIf { av1 }, "hevc".takeIf { hevc }, "h264")
}

/** The `DeviceProfile` sent with `PlaybackInfo`. */
object JellyfinDeviceProfile {
    private const val FMP4_AUDIO = "aac,mp3,ac3,eac3,flac,opus,dts,truehd"
    private const val TS_AUDIO = "aac,mp3,ac3,eac3,opus,dts"

    fun build(
        dialect: MediaBrowserDialect,
        codecs: VideoCodecSupport,
        maxStreamingBitrate: Long?,
        isLiveTv: Boolean,
        audioProfile: Boolean,
        burnSubtitles: Boolean,
    ): JsonObject = buildJsonObject {
        put("Name", "Plezy")
        maxStreamingBitrate?.let { put("MaxStreamingBitrate", it) }
        put("CodecProfiles", JsonArray(emptyList()))
        put("TranscodingProfiles", buildJsonArray {
            // fMP4 first (TS cannot carry AV1). Emby live TV is TS-only; Jellyfin keeps TS second
            // because it drops non-TS profiles for HDHomeRun/M3U sources.
            if (!isLiveTv || !dialect.requiresMpegTsForLiveTv) {
                add(profile("Type" to "Video", "Container" to "mp4", "Protocol" to "hls",
                    "VideoCodec" to transcodeCodecs(dialect, codecs).joinToString(","), "AudioCodec" to FMP4_AUDIO))
            }
            add(profile("Type" to "Video", "Container" to "ts", "Protocol" to "hls",
                "VideoCodec" to codecs.transcodeCodecs.filter { it != "av1" }.joinToString(","), "AudioCodec" to TS_AUDIO))
            if (audioProfile) {
                add(profile("Type" to "Audio", "Container" to "mp3", "AudioCodec" to "mp3", "Protocol" to "http",
                    "Context" to "Streaming", "MaxAudioChannels" to "2"))
            }
        })
        put("DirectPlayProfiles", buildJsonArray {
            // No AudioCodec: an omitted list is "any", and mpv decodes every audio codec these containers carry.
            add(profile("Type" to "Video", "Container" to "mp4,mkv,m4v,webm,mov,ts,mpegts", "VideoCodec" to directPlayVideoCodecs(codecs)))
            if (audioProfile) {
                add(profile("Type" to "Audio", "Container" to "flac,mp3,ogg,oga,opus,m4a,m4b,aac,alac,wav,aiff,wma,webma",
                    "AudioCodec" to "flac,mp3,aac,alac,opus,vorbis,wav,wma"))
            }
        })
        // Embed serves the direct paths. External makes the server extract a stream as a file; withheld when burning so
        // the server falls through to Encode.
        put("SubtitleProfiles", buildJsonArray {
            for (format in listOf("srt", "ass", "ssa", "vtt", "pgssub", "dvdsub", "dvbsub")) add(profile("Format" to format, "Method" to "Embed"))
            if (!burnSubtitles) for (format in listOf("srt", "ass", "ssa", "vtt")) add(profile("Format" to format, "Method" to "External"))
        })
    }

    /**
     * The profile a transcoded download negotiates with: nothing plays directly, and the one transcode is a progressive
     * MPEG-TS stream (`stream.ts` over HTTP, not HLS) of H.264 and AAC, which every player opens and which has no index
     * to write at its end, so the file is whole as it arrives. The picture fits inside [maxWidth]×[maxHeight]. Text
     * subtitles are delivered as files; image ones have no profile.
     */
    fun download(maxStreamingBitrate: Long, maxWidth: Int, maxHeight: Int): JsonObject = buildJsonObject {
        put("Name", "Plezy download")
        put("MaxStreamingBitrate", maxStreamingBitrate)
        put("DirectPlayProfiles", JsonArray(emptyList()))
        put("TranscodingProfiles", buildJsonArray {
            add(profile("Type" to "Video", "Container" to "ts", "Protocol" to "http", "VideoCodec" to "h264", "AudioCodec" to "aac"))
        })
        put("CodecProfiles", buildJsonArray {
            add(buildJsonObject {
                put("Type", "Video")
                put("Conditions", buildJsonArray {
                    add(condition("Width", maxWidth))
                    add(condition("Height", maxHeight))
                })
            })
        })
        put("SubtitleProfiles", buildJsonArray {
            for (format in listOf("srt", "ass", "ssa", "vtt")) add(profile("Format" to format, "Method" to "External"))
        })
    }

    private fun condition(property: String, max: Int) = buildJsonObject {
        put("Condition", "LessThanEqual")
        put("Property", property)
        put("Value", max.toString())
        put("IsRequired", true)
    }

    /** `h265` is Jellyfin's alternate spelling of `hevc` and travels with it. */
    fun directPlayVideoCodecs(codecs: VideoCodecSupport): String = listOfNotNull(
        "hevc".takeIf { codecs.hevc }, "h264", "h265".takeIf { codecs.hevc }, "vp8", "vp9", "av1".takeIf { codecs.av1 }, "mpeg4", "mpeg2video",
    ).joinToString(",")

    /** Emby has no AV1 encoder and no codec rotation, so AV1 must not lead its list. */
    fun transcodeCodecs(dialect: MediaBrowserDialect, codecs: VideoCodecSupport): List<String> =
        codecs.transcodeCodecs.filter { it != "av1" || dialect.rotatesDisabledTranscodeCodecs }

    private fun profile(vararg fields: Pair<String, String>) = JsonObject(fields.associate { (k, v) -> k to JsonPrimitive(v) })
}
