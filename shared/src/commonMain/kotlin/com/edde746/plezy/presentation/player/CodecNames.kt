package com.edde746.plezy.presentation.player

import com.edde746.plezy.strings.T

/**
 * Display names for the FFmpeg and mpv names the engine reports: codecs (`hevc`, `eac3`, `hdmv_pgs_subtitle`) and their
 * profiles, channel counts and layouts, containers (`file-format`), pixel formats, colour spaces, hardware decoders
 * and audio drivers. These are technical names, the same in every language; unknown ones show in capitals or as mpv
 * gives them.
 */
internal object CodecNames {
    fun video(codec: String): String = when (codec.lowercase()) {
        "h264", "avc", "avc1" -> "H.264"
        "hevc", "h265", "hev1", "hvc1" -> "HEVC"
        "av1" -> "AV1"
        "vp8" -> "VP8"
        "vp9" -> "VP9"
        "mpeg2video", "mpeg2" -> "MPEG-2"
        "mpeg4" -> "MPEG-4"
        "vc1" -> "VC-1"
        else -> codec.uppercase()
    }

    /** The codec with FFmpeg's profile of it: "HEVC Main 10", "H.264 High", "VP9 Profile 2". */
    fun video(codec: String, profile: String?): String {
        val name = video(codec)
        val shown = profile?.trim()?.takeIf { it.isNotEmpty() && !it.equals("unknown", ignoreCase = true) } ?: return name
        return "$name $shown"
    }

    fun audio(codec: String): String {
        val lower = codec.lowercase()
        if (lower.startsWith("pcm_")) return "PCM"
        return when (lower) {
            "aac", "aac_latm" -> "AAC"
            "ac3" -> "AC3"
            "eac3" -> "E-AC3"
            "truehd", "mlp" -> "TrueHD"
            "dts", "dca" -> "DTS"
            "dtshd", "dts-hd" -> "DTS-HD"
            "flac" -> "FLAC"
            "alac" -> "ALAC"
            "opus" -> "Opus"
            "vorbis" -> "Vorbis"
            "mp3", "mp3float" -> "MP3"
            "mp2" -> "MP2"
            else -> codec.uppercase()
        }
    }

    /**
     * The codec as its profile makes it known: "TrueHD Atmos" and "E-AC3 Atmos" (FFmpeg's "Dolby TrueHD + Dolby
     * Atmos", "Dolby Digital Plus + Dolby Atmos"), DTS by its profile ("DTS-HD MA", "DTS-HD MA + DTS:X", "DTS-ES"),
     * AAC with its ("AAC LC", "HE-AAC"). Other codecs' profiles say nothing a listener knows them by.
     */
    fun audio(codec: String, profile: String?): String {
        val name = audio(codec)
        val shown = profile?.trim()?.takeIf { it.isNotEmpty() && !it.equals("unknown", ignoreCase = true) } ?: return name
        return when (codec.lowercase()) {
            "truehd", "eac3" -> if (shown.contains("Atmos", ignoreCase = true)) "$name Atmos" else name
            "dts", "dca", "dtshd", "dts-hd" -> if (shown.startsWith("DTS", ignoreCase = true)) shown else name
            "aac", "aac_latm" -> if (shown.contains("AAC", ignoreCase = true)) shown else "$name $shown"
            else -> name
        }
    }

    fun subtitle(codec: String): String = when (codec.lowercase()) {
        "subrip", "srt" -> "SRT"
        "ass" -> "ASS"
        "ssa" -> "SSA"
        "webvtt", "vtt" -> "WebVTT"
        "hdmv_pgs_subtitle", "pgssub" -> "PGS"
        "dvd_subtitle", "dvdsub" -> "VobSub"
        "dvb_subtitle" -> "DVB"
        "mov_text" -> "TX3G"
        else -> codec.uppercase()
    }

    /** "Mono", "Stereo", "5.1", "7.1" (FFmpeg's default layout for the count), "10 channels". */
    fun channels(count: Int): String = when (count) {
        1 -> T.player.track.mono
        2 -> T.player.track.stereo
        3 -> "3.0"
        4 -> "4.0"
        5 -> "5.0"
        6 -> "5.1"
        7 -> "6.1"
        8 -> "7.1"
        else -> T.player.track.channels(count)
    }

    /**
     * mpv's channel layout (`hr-channels`: "7.1", "5.1(side)", "stereo") as "7.1", "5.1 (side)", "Stereo"; a layout
     * without a name ("unknown8", a list of speakers) by [count] instead.
     */
    fun channelLayout(layout: String?, count: Int?): String? {
        val name = layout?.trim().orEmpty()
        return when {
            name == "mono" -> T.player.track.mono
            name == "stereo" -> T.player.track.stereo
            LAYOUT.matches(name) -> name.replace("(", " (")
            else -> count?.takeIf { it > 0 }?.let(::channels)
        }
    }

    /** mpv's `file-format` (the demuxer's name, or FFmpeg's list of names for one) as the container's name: "MKV". */
    fun container(format: String): String {
        val names = format.lowercase().split(',').map(String::trim)
        return when {
            "mkv" in names || "matroska" in names -> "MKV"
            "mp4" in names || "mov" in names -> "MP4"
            else -> CONTAINERS[names.first()] ?: names.first().uppercase()
        }
    }

    /**
     * What a pixel format says of the picture: its bit depth and chroma subsampling ("yuv420p10" is 10 bits, 4:2:0;
     * "p010" too; "nv12" 8 bits, 4:2:0; "gbrp" RGB). Null for a name it doesn't know, such as a hardware frame type
     * ("videotoolbox").
     */
    fun pixelFormat(name: String): PixelFormat? {
        val format = name.lowercase().removeSuffix("le").removeSuffix("be")
        PACKED[format]?.let { return it }
        YUV.matchEntire(format)?.let { yuv ->
            val (chroma, bits) = yuv.destructured
            return PixelFormat(bits.toIntOrNull() ?: 8, chroma.toList().joinToString(":"))
        }
        val rgb = RGB.matchEntire(format) ?: return null
        return PixelFormat(rgb.groupValues[1].toIntOrNull() ?: 8, null)
    }

    /** Bit depth and chroma subsampling ("4:2:0"); [chroma] null for RGB. */
    data class PixelFormat(val bits: Int, val chroma: String?)

    /** mpv's colour primaries (`video-params/primaries`) by their standard's name; null for "auto" and unknown ones. */
    fun primaries(name: String): String? = PRIMARIES[name.lowercase()]

    /** mpv's transfer function (`video-params/gamma`) by its standard's name. */
    fun transfer(name: String): String? = TRANSFERS[name.lowercase()]

    /** mpv's colour matrix (`video-params/colormatrix`) by its standard's name. */
    fun colorMatrix(name: String): String? = MATRICES[name.lowercase()]

    /** mpv's hardware decoder (`hwdec-current`: "videotoolbox", "d3d11va-copy") by its API's name: "D3D11VA copy". */
    fun hardwareDecoder(name: String): String {
        val lower = name.lowercase()
        val copy = lower.endsWith("-copy")
        val api = lower.removeSuffix("-copy")
        val shown = HARDWARE_DECODERS[api] ?: api
        return if (copy) "$shown copy" else shown
    }

    /**
     * mpv's audio output driver (`--ao`, `current-ao`, the part of `audio-device` before '/') by its platform's name;
     * mpv-build's `spatial` (TrueHD Atmos and DTS:X as Apple's spatial audio) by Apple's name in the interface language.
     */
    fun audioDriver(ao: String): String = if (ao == "spatial") T.player.info.spatialAudio else AUDIO_DRIVERS[ao] ?: ao

    private val LAYOUT = Regex("""\d+\.\d+(\([a-z]+\))?""")
    private val YUV = Regex("""(?:yuvj|yuva|yuv)(4[0-4][0-4])p(\d+)?""")
    private val RGB = Regex("""gbra?p(\d+)?""")

    private val PACKED = mapOf(
        "nv12" to PixelFormat(8, "4:2:0"),
        "nv21" to PixelFormat(8, "4:2:0"),
        "nv16" to PixelFormat(8, "4:2:2"),
        "nv24" to PixelFormat(8, "4:4:4"),
        "p010" to PixelFormat(10, "4:2:0"),
        "p012" to PixelFormat(12, "4:2:0"),
        "p016" to PixelFormat(16, "4:2:0"),
        "p210" to PixelFormat(10, "4:2:2"),
        "p216" to PixelFormat(16, "4:2:2"),
        "p410" to PixelFormat(10, "4:4:4"),
        "p416" to PixelFormat(16, "4:4:4"),
        "y210" to PixelFormat(10, "4:2:2"),
        "y212" to PixelFormat(12, "4:2:2"),
        "y410" to PixelFormat(10, "4:4:4"),
        "y412" to PixelFormat(12, "4:4:4"),
        "yuyv422" to PixelFormat(8, "4:2:2"),
        "uyvy422" to PixelFormat(8, "4:2:2"),
        "rgb24" to PixelFormat(8, null),
        "bgr24" to PixelFormat(8, null),
        "rgba" to PixelFormat(8, null),
        "bgra" to PixelFormat(8, null),
        "rgb0" to PixelFormat(8, null),
        "bgr0" to PixelFormat(8, null),
        "x2rgb10" to PixelFormat(10, null),
        "x2bgr10" to PixelFormat(10, null),
        "rgba64" to PixelFormat(16, null),
        "rgb48" to PixelFormat(16, null),
    )

    private val CONTAINERS = mapOf(
        "webm" to "WebM",
        "mpegts" to "MPEG-TS",
        "mpeg" to "MPEG-PS",
        "hls" to "HLS",
        "dash" to "DASH",
        "avi" to "AVI",
        "flv" to "FLV",
        "ogg" to "Ogg",
        "asf" to "ASF",
        "wav" to "WAV",
        "flac" to "FLAC",
        "mp3" to "MP3",
        "aac" to "AAC",
    )

    private val PRIMARIES = mapOf(
        "bt.601-525" to "BT.601",
        "bt.601-625" to "BT.601",
        "bt.709" to "BT.709",
        "bt.2020" to "BT.2020",
        "bt.470m" to "BT.470M",
        "apple" to "Apple RGB",
        "adobe" to "Adobe RGB",
        "prophoto" to "ProPhoto",
        "cie1931" to "CIE 1931",
        "dci-p3" to "DCI-P3",
        "display-p3" to "Display P3",
        "v-gamut" to "V-Gamut",
        "s-gamut" to "S-Gamut",
        "ebu3213" to "EBU 3213",
        "film-c" to "Film C",
        "aces-ap0" to "ACES AP0",
        "aces-ap1" to "ACES AP1",
    )

    private val TRANSFERS = mapOf(
        "bt.1886" to "BT.1886",
        "srgb" to "sRGB",
        "linear" to "Linear",
        "gamma1.8" to "Gamma 1.8",
        "gamma2.0" to "Gamma 2.0",
        "gamma2.2" to "Gamma 2.2",
        "gamma2.4" to "Gamma 2.4",
        "gamma2.6" to "Gamma 2.6",
        "gamma2.8" to "Gamma 2.8",
        "prophoto" to "ProPhoto",
        "st428" to "SMPTE ST 428",
        "pq" to "PQ",
        "hlg" to "HLG",
        "v-log" to "V-Log",
        "s-log1" to "S-Log",
        "s-log2" to "S-Log2",
    )

    private val MATRICES = mapOf(
        "bt.601" to "BT.601",
        "bt.709" to "BT.709",
        "smpte-240m" to "SMPTE 240M",
        "bt.2020-ncl" to "BT.2020 NCL",
        "bt.2020-cl" to "BT.2020 CL",
        "bt.2100-pq" to "ICtCp PQ",
        "bt.2100-hlg" to "ICtCp HLG",
        "dolbyvision" to "Dolby Vision",
        "rgb" to "RGB",
        "xyz" to "XYZ",
        "ycgco" to "YCgCo",
    )

    private val HARDWARE_DECODERS = mapOf(
        "videotoolbox" to "VideoToolbox",
        "mediacodec" to "MediaCodec",
        "d3d11va" to "D3D11VA",
        "d3d12va" to "D3D12VA",
        "dxva2" to "DXVA2",
        "nvdec" to "NVDEC",
        "cuda" to "CUDA",
        "vaapi" to "VA-API",
        "vdpau" to "VDPAU",
        "vulkan" to "Vulkan",
        "drm" to "DRM",
        "v4l2m2m" to "V4L2 M2M",
        "rkmpp" to "RKMPP",
    )

    /** mpv's audio outputs (`--ao`) by the names their platforms give them. */
    private val AUDIO_DRIVERS = mapOf(
        "coreaudio" to "Core Audio",
        "coreaudio_exclusive" to "Core Audio (exclusive)",
        "avfoundation" to "AVFoundation",
        "audiounit" to "AudioUnit",
        "wasapi" to "WASAPI",
        "pipewire" to "PipeWire",
        "pulse" to "PulseAudio",
        "alsa" to "ALSA",
        "jack" to "JACK",
        "oss" to "OSS",
        "openal" to "OpenAL",
        "sdl" to "SDL",
        "audiotrack" to "AudioTrack",
        "aaudio" to "AAudio",
        "opensles" to "OpenSL ES",
    )
}
