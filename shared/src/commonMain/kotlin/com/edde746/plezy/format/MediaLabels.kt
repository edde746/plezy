package com.edde746.plezy.format

import com.edde746.plezy.strings.T
import kotlin.math.roundToLong

/** A video codec id as people know it: `h264` → `H.264`, `hevc` → `HEVC`; unknown ids upper-cased. */
fun formatVideoCodec(codec: String): String = when (codec.lowercase()) {
    "h264", "avc1", "avc" -> "H.264"
    "hevc", "h265", "hev1" -> "HEVC"
    "av1" -> "AV1"
    "vp8" -> "VP8"
    "vp9" -> "VP9"
    "mpeg2video", "mpeg2" -> "MPEG-2"
    "mpeg4" -> "MPEG-4"
    "vc1" -> "VC-1"
    else -> codec.uppercase()
}

/** `850 kbps`, `8.5 Mbps`. */
fun formatBitrate(kbps: Int): String {
    if (kbps < 1000) return "$kbps kbps"
    val tenths = (kbps / 100.0).roundToLong()
    return "${tenths / 10}.${tenths % 10} Mbps"
}

/** A server's resolution value for display: `4k`/`uhd`/≥2160 → `4K`, `sd` → `SD`, `1080` → `1080p`, else upper-cased. */
fun resolutionDisplayLabel(value: String): String {
    val normalized = value.trim().lowercase()
    if (normalized == "4k" || normalized == "uhd") return "4K"
    if (normalized == "sd") return "SD"
    val numeric = NUMERIC_RESOLUTION.matchEntire(normalized)
    if (numeric != null) {
        val digits = numeric.groupValues[1]
        val height = digits.toIntOrNull()
        if (height != null && height >= 2160) return "4K"
        return "${digits}p"
    }
    return value.trim().uppercase()
}

/** The resolution tier of a frame [height]: `4k`, `1080`, `720`, `480`, else the height itself. */
fun resolutionLabelFromHeight(height: Int?): String? = when {
    height == null -> null
    height >= 2160 -> "4k"
    height >= 1080 -> "1080"
    height >= 720 -> "720"
    height >= 480 -> "480"
    else -> height.toString()
}

/**
 * The resolution tier of a frame, from either dimension (a 1920×800 scope film is 1080). Width thresholds allow for
 * cropped encodes (3832×1600 is 4K); a 2560×1440 or 2048-wide frame is 1080.
 */
fun resolutionLabelFromDimensions(width: Int?, height: Int?): String? = when {
    (width != null && width >= 3600) || (height != null && height >= 2160) -> "4k"
    (width != null && width >= 1800) || (height != null && height >= 1080) -> "1080"
    (width != null && width >= 1200) || (height != null && height >= 720) -> "720"
    (width != null && width >= 800) || (height != null && height >= 480) -> "480"
    else -> resolutionLabelFromHeight(height)
}

/** The file extension a subtitle in [codec] is saved with: `ass`, `vtt`, `sup` (PGS), `sub` (VobSub, DVB), else `srt`. */
fun subtitleExtension(codec: String?): String = when (codec?.lowercase()) {
    "ass", "ssa" -> "ass"
    "webvtt", "vtt" -> "vtt"
    "pgs", "pgssub", "hdmv_pgs_subtitle" -> "sup"
    "dvd_subtitle", "dvdsub", "vobsub", "dvb_sub", "dvb_subtitle" -> "sub"
    else -> "srt"
}

/** Whether [codec] is a text subtitle format (SRT, ASS/SSA, WebVTT, MP4 timed text). */
fun isTextSubtitleCodec(codec: String?): Boolean = when (codec?.lowercase()) {
    "srt", "subrip", "ass", "ssa", "webvtt", "vtt", "mov_text" -> true
    else -> false
}

/** Whether [codec] is a bitmap subtitle format, which a transcode burns into the video. `dvbsub` is Jellyfin's spelling. */
fun isImageSubtitleCodec(codec: String?): Boolean = when (codec?.lowercase()) {
    "pgs", "pgssub", "hdmv_pgs_subtitle", "dvd_subtitle", "dvdsub", "vobsub", "dvb_sub", "dvbsub", "dvb_subtitle" -> true
    else -> false
}

/** Whether a transcode can deliver a subtitle in [codec]: text becomes segmented WebVTT, bitmaps are burned in. */
fun isTranscodableSubtitleCodec(codec: String?): Boolean = isTextSubtitleCodec(codec) || isImageSubtitleCodec(codec)

/** A subtitle codec id as people know it: `SUBRIP` → `SRT`, `hdmv_pgs_subtitle` → `PGS`; others upper-cased. */
fun formatSubtitleCodec(codec: String): String = when (val upper = codec.uppercase()) {
    "SUBRIP" -> "SRT"
    "DVD_SUBTITLE" -> "DVD"
    "WEBVTT" -> "VTT"
    "HDMV_PGS_SUBTITLE" -> "PGS"
    "MOV_TEXT" -> "MOV"
    else -> upper
}

/** An audio channel count as a layout name (2 → Stereo, 6 → `5.1`); null when [channels] is null or not positive. */
fun formatAudioChannels(channels: Int?): String? = when {
    channels == null || channels <= 0 -> null
    channels == 1 -> T.fileInfo.channelsMono
    channels == 2 -> T.videoSettings.audioOutputStereo
    channels == 3 -> "3.0"
    channels == 4 -> "4.0"
    channels == 5 -> "4.1"
    channels == 6 -> "5.1"
    channels == 7 -> "6.1"
    channels == 8 -> "7.1"
    else -> "${channels}ch"
}

/**
 * An audio codec's display name from an FFmpeg name (`eac3`), an RFC 6381 codec ID (`mp4a.40.2`, `ec-3`) or an
 * `audio/…` MIME type. [profile], FFmpeg's profile name, names the DTS variant, which the codec cannot.
 */
fun formatAudioCodec(codec: String, profile: String? = null): String {
    when (profile) {
        "DTS-ES", "DTS 96/24", "DTS-HD HRA", "DTS-HD MA", "DTS Express" -> return profile
        "DTS-HD MA + DTS:X", "DTS-HD MA + DTS:X IMAX" -> return "DTS:X"
    }
    val lower = codec.lowercase()
    if (lower.startsWith("audio/")) {
        return when (val rest = lower.removePrefix("audio/")) {
            "mp4a-latm" -> "AAC"
            "mpeg", "mpeg-l2" -> "MP3"
            "true-hd" -> "TrueHD"
            "vnd.dts" -> "DTS"
            "vnd.dts.hd", "vnd.dts.hd;profile=lbr" -> "DTS-HD"
            "vnd.dts.uhd;audio=p2" -> "DTS:X"
            "ac3" -> "AC3"
            "eac3", "eac3-joc" -> "E-AC3"
            "ac4" -> "AC4"
            "raw", "wav" -> "PCM"
            "alac" -> "ALAC"
            else -> formatAudioCodec(rest)
        }
    }
    // MP4 object types 0x69/0x6B under the mp4a prefix are MPEG layer audio; every other mp4a object type is AAC.
    if (lower == "mp4a.69" || lower == "mp4a.6b") return "MP3"
    if (lower == "mp4a" || lower.startsWith("mp4a.")) return "AAC"
    if (lower == "ac-4" || lower.startsWith("ac-4.")) return "AC4"
    return when (lower) {
        "aac" -> "AAC"
        "ac3", "ac-3" -> "AC3"
        "eac3", "ec3", "ec-3" -> "E-AC3"
        "truehd", "mlpa" -> "TrueHD"
        "dts", "dca", "dtsc", "dtse" -> "DTS"
        "dtshd", "dts-hd", "dtsh", "dtsl" -> "DTS-HD"
        "dtsx" -> "DTS:X"
        "flac" -> "FLAC"
        "mp3", "mp3float" -> "MP3"
        "opus" -> "Opus"
        "vorbis" -> "Vorbis"
        "pcm_s16le", "pcm_s24le", "pcm" -> "PCM"
        else -> codec.uppercase()
    }
}

private val NUMERIC_RESOLUTION = Regex("""^(\d+)p?$""")

/** A version's resolution for display: from its frame dimensions when known, else the server's [videoResolution]. */
fun versionResolutionLabel(videoResolution: String?, width: Int?, height: Int?): String? {
    resolutionLabelFromDimensions(width?.takeIf { it > 0 }, height?.takeIf { it > 0 })?.let { return resolutionDisplayLabel(it) }
    return videoResolution?.trim()?.takeIf { it.isNotEmpty() }?.let(::resolutionDisplayLabel)
}
