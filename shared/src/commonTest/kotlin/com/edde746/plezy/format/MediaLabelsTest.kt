package com.edde746.plezy.format

import com.edde746.plezy.strings.T
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MediaLabelsTest {
    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    @Test
    fun subtitleExtensionByCodecFamily() {
        assertEquals("srt", subtitleExtension(null))
        assertEquals("srt", subtitleExtension("subrip"))
        assertEquals("srt", subtitleExtension("SRT"))
        assertEquals("ass", subtitleExtension("ass"))
        assertEquals("ass", subtitleExtension("SSA"))
        assertEquals("vtt", subtitleExtension("webvtt"))
        assertEquals("vtt", subtitleExtension("VTT"))
        assertEquals("srt", subtitleExtension("mov_text"))
        assertEquals("sup", subtitleExtension("pgs"))
        assertEquals("sup", subtitleExtension("pgssub"))
        assertEquals("sup", subtitleExtension("HDMV_PGS_SUBTITLE"))
        for (codec in listOf("dvd_subtitle", "dvdsub", "vobsub", "dvb_sub", "dvb_subtitle")) {
            assertEquals("sub", subtitleExtension(codec), codec)
        }
        assertEquals("srt", subtitleExtension("weirdcodec"))
        assertEquals("srt", subtitleExtension(""))
    }

    @Test
    fun textSubtitleCodecsOnly() {
        for (codec in listOf("srt", "subrip", "ass", "ssa", "webvtt", "vtt", "mov_text", "ASS")) {
            assertTrue(isTextSubtitleCodec(codec), codec)
        }
        for (codec in listOf("pgs", "dvd_subtitle", "vobsub", "weird", null)) {
            assertFalse(isTextSubtitleCodec(codec), "$codec")
        }
    }

    @Test
    fun imageSubtitleCodecsOnlyIncludingJellyfinsDvbsub() {
        val image = listOf(
            "pgs", "pgssub", "hdmv_pgs_subtitle", "dvd_subtitle", "dvdsub", "vobsub", "dvb_sub", "dvbsub", "dvb_subtitle", "PGS",
        )
        for (codec in image) assertTrue(isImageSubtitleCodec(codec), codec)
        for (codec in listOf("srt", "ass", "mov_text", "weird", null)) assertFalse(isImageSubtitleCodec(codec), "$codec")
    }

    @Test
    fun transcodableCoversTextAndImageNotUnknown() {
        for (codec in listOf("srt", "ass", "pgs", "vobsub", "dvd_subtitle")) assertTrue(isTranscodableSubtitleCodec(codec), codec)
        assertFalse(isTranscodableSubtitleCodec("weird"))
        assertFalse(isTranscodableSubtitleCodec(null))
    }

    @Test
    fun subtitleCodecLabels() {
        assertEquals("SRT", formatSubtitleCodec("subrip"))
        assertEquals("SRT", formatSubtitleCodec("SUBRIP"))
        assertEquals("DVD", formatSubtitleCodec("dvd_subtitle"))
        assertEquals("VTT", formatSubtitleCodec("webvtt"))
        assertEquals("PGS", formatSubtitleCodec("hdmv_pgs_subtitle"))
        assertEquals("MOV", formatSubtitleCodec("mov_text"))
        assertEquals("FOO", formatSubtitleCodec("foo"))
        assertEquals("ASS", formatSubtitleCodec("ass"))
    }

    @Test
    fun videoCodecLabels() {
        for (codec in listOf("h264", "avc1", "avc", "H264")) assertEquals("H.264", formatVideoCodec(codec))
        for (codec in listOf("hevc", "h265", "hev1")) assertEquals("HEVC", formatVideoCodec(codec))
        assertEquals("AV1", formatVideoCodec("av1"))
        assertEquals("VP8", formatVideoCodec("vp8"))
        assertEquals("VP9", formatVideoCodec("vp9"))
        assertEquals("MPEG-2", formatVideoCodec("mpeg2video"))
        assertEquals("MPEG-2", formatVideoCodec("mpeg2"))
        assertEquals("MPEG-4", formatVideoCodec("mpeg4"))
        assertEquals("VC-1", formatVideoCodec("vc1"))
        assertEquals("FOO", formatVideoCodec("foo"))
        assertEquals("PRORES", formatVideoCodec("Prores"))
    }

    @Test
    fun audioCodecLabels() {
        assertEquals("AAC", formatAudioCodec("aac"))
        assertEquals("AAC", formatAudioCodec("AAC"))
        assertEquals("AC3", formatAudioCodec("ac3"))
        assertEquals("TrueHD", formatAudioCodec("truehd"))
        assertEquals("FLAC", formatAudioCodec("flac"))
        assertEquals("Opus", formatAudioCodec("opus"))
        assertEquals("Vorbis", formatAudioCodec("vorbis"))
        assertEquals("E-AC3", formatAudioCodec("eac3"))
        assertEquals("E-AC3", formatAudioCodec("ec3"))
        assertEquals("DTS", formatAudioCodec("dts"))
        assertEquals("DTS", formatAudioCodec("dca"))
        assertEquals("DTS-HD", formatAudioCodec("dtshd"))
        assertEquals("DTS-HD", formatAudioCodec("dts-hd"))
        assertEquals("MP3", formatAudioCodec("mp3"))
        assertEquals("MP3", formatAudioCodec("mp3float"))
        assertEquals("PCM", formatAudioCodec("pcm"))
        assertEquals("PCM", formatAudioCodec("pcm_s16le"))
        assertEquals("PCM", formatAudioCodec("pcm_s24le"))
        assertEquals("ALAC", formatAudioCodec("alac"))
        assertEquals("WEIRD", formatAudioCodec("weird"))
    }

    @Test
    fun dtsProfileNamesTheVariantMpvReportsAsPlainDts() {
        for (profile in listOf("DTS-HD MA", "DTS-HD HRA", "DTS-ES", "DTS 96/24", "DTS Express")) {
            assertEquals(profile, formatAudioCodec("dts", profile))
        }
        assertEquals("DTS:X", formatAudioCodec("dts", "DTS-HD MA + DTS:X"))
        assertEquals("DTS:X", formatAudioCodec("dts", "DTS-HD MA + DTS:X IMAX"))
        assertEquals("DTS", formatAudioCodec("dts", "DTS"))
        assertEquals("DTS", formatAudioCodec("dts", "Something New"))
        assertEquals("AAC", formatAudioCodec("aac", "LC"))
        assertEquals("AAC", formatAudioCodec("aac", "HE-AAC"))
        assertEquals("TrueHD", formatAudioCodec("truehd", null))
    }

    @Test
    fun rfc6381CodecIds() {
        for (codec in listOf("mp4a.40.2", "MP4A.40.2", "mp4a.40.5", "mp4a.40.29", "mp4a")) assertEquals("AAC", formatAudioCodec(codec))
        assertEquals("MP3", formatAudioCodec("mp4a.69"))
        assertEquals("MP3", formatAudioCodec("mp4a.6B"))
        assertEquals("AC3", formatAudioCodec("ac-3"))
        assertEquals("E-AC3", formatAudioCodec("ec-3"))
        assertEquals("AC4", formatAudioCodec("ac-4"))
        assertEquals("AC4", formatAudioCodec("ac-4.02.01.01"))
        assertEquals("TrueHD", formatAudioCodec("mlpa"))
        assertEquals("DTS", formatAudioCodec("dtsc"))
        assertEquals("DTS", formatAudioCodec("dtse"))
        assertEquals("DTS-HD", formatAudioCodec("dtsh"))
        assertEquals("DTS-HD", formatAudioCodec("dtsl"))
        assertEquals("DTS:X", formatAudioCodec("dtsx"))
    }

    @Test
    fun audioMimeTypes() {
        val expected = mapOf(
            "audio/mp4a-latm" to "AAC",
            "audio/mpeg" to "MP3",
            "audio/ac3" to "AC3",
            "audio/eac3" to "E-AC3",
            "audio/eac3-joc" to "E-AC3",
            "audio/true-hd" to "TrueHD",
            "audio/vnd.dts" to "DTS",
            "audio/vnd.dts.hd" to "DTS-HD",
            "audio/vnd.dts.hd;profile=lbr" to "DTS-HD",
            "audio/vnd.dts.uhd;audio=p2" to "DTS:X",
            "audio/flac" to "FLAC",
            "audio/opus" to "Opus",
            "audio/vorbis" to "Vorbis",
            "audio/ac4" to "AC4",
            "audio/raw" to "PCM",
            "audio/alac" to "ALAC",
        )
        for ((mime, label) in expected) assertEquals(label, formatAudioCodec(mime), mime)
    }

    @Test
    fun audioChannelLayouts() {
        assertEquals("Mono", formatAudioChannels(1))
        assertEquals("Stereo", formatAudioChannels(2))
        assertEquals("3.0", formatAudioChannels(3))
        assertEquals("4.0", formatAudioChannels(4))
        assertEquals("4.1", formatAudioChannels(5))
        assertEquals("5.1", formatAudioChannels(6))
        assertEquals("6.1", formatAudioChannels(7))
        assertEquals("7.1", formatAudioChannels(8))
        assertEquals("10ch", formatAudioChannels(10))
        assertNull(formatAudioChannels(null))
        assertNull(formatAudioChannels(0))
        assertNull(formatAudioChannels(-1))
    }
}
